vector(entity box, vector org) entity_nearest_point_on_box {
	vector m1, m2, nearest;
	m1 = box.mins + box.origin;
	m2 = box.maxs + box.origin;
	nearest_x = bound(m1_x, org_x, m2_x);
	nearest_y = bound(m1_y, org_y, m2_y);
	nearest_z = bound(m1_z, org_z, m2_z);
	return nearest;
}

/*
==================
SUB_VanishOrRemove

Makes client invisible or removes non-client
==================
*/
void(entity ent) entity_fade_vanish_or_remove {
	if (ent.flags & FL_CLIENT) {
		// vanish
		ent.model = "";
		ent.effects = 0;
		ent.glow_size = 0;
		ent.pflags = 0;
	} else {
		// remove
		remove (ent);
	}
}

void(void) entity_fade_think {
	self.nextthink = self.fade_time;
	self.alpha = 1 - (time - self.fade_time) * self.fade_rate;
	if (self.alpha < 0.01)
		entity_fade_vanish_or_remove(self);

	self.alpha = bound(0.01, self.alpha, 1);
}

/*
==================
SUB_SetFade

Fade 'ent' out when time >= 'when'
==================
*/
void(entity ent, float when, float fadetime) entity_fade_setup {
	//if (ent.flags & FL_CLIENT) // && ent.deadflag != DEAD_NO)
	//	return;
	//ent.alpha = 1;
	ent.fade_rate = 1/fadetime;
	ent.fade_time = when;
	ent.think = entity_fade_think;
	ent.nextthink = when;
}

void() entity_movedir_setup {
	if (self.movedir != '0 0 0')
		self.movedir = normalize(self.movedir);
	else {
		makevectors (self.angles);
		self.movedir = v_forward;
	}
	self.angles = '0 0 0';
}

void objerror(string s)
{
    objerror_builtin(s);
}

float initialize_entities_done;
void(entity for_e, void(void) func, float order) entity_initialize {
	entity e = spawn();
	e.classname = "initialize_entity";
	e.enemy = for_e;
    e.think = func;
    e.cnt = order;
	initialize_entities_done = FALSE;
}

void(void) entity_initialize_run {
	if (initialize_entities_done)
		return;

	entity oldself = self;
	entity e;
	float i;
	for (i = INITPRIO_FIRST; i <= INITPRIO_LAST; i++)
		for (e = find(world, classname, "initialize_entity"); e; e = find(e, classname, "initialize_entity")) {
			if (e.cnt != i)
				continue;

			self = e.enemy;
			e.think();
			remove(e);
		}
	self = oldself;
	initialize_entities_done = TRUE;
}

// deferred dropping
void(void) entity_droptofloor_handler {
    droptofloor_builtin();
    self.dropped_origin = self.origin;
}

void(void) entity_droptofloor {
    entity_initialize(self, entity_droptofloor_handler, INITPRIO_DROPTOFLOOR);
}

float(entity e, float goodcontents, float badcontents, float badsurfaceflags, float attempts, float maxaboveground, float shiftdistance) entity_move_to_random_location {
    float m, i;
    vector start, org, delta, end, enddown;

    m = e.dphitcontentsmask;
    e.dphitcontentsmask = goodcontents | badcontents;

    org = world.mins;
    delta = world.maxs - world.mins;
	entity firstspot = findchain(classname, "info_player_deathmatch");
	random_selection_init();
	entity spot;
	for(spot = firstspot; spot; spot = spot.chain)
		random_selection_add(spot, 0, string_null, 1, 1);

    for (i = 0; i < attempts; ++i)
    {
		start = random_selection_chosen_ent.origin;
		if (random_selection_chosen_ent.mins_z > e.mins_z)
			start_z = start_z - e.mins_z + random_selection_chosen_ent.mins_z;

        end_x = random() - 0.5;
        end_y = random() - 0.5;
        end_z = random() / 2;
        end = start + normalize(end) * (vlen(delta) * random() + shiftdistance);
        tracebox(start, e.mins, e.maxs, end, MOVE_NORMAL, e);
		end = start;
		start = trace_endpos;

        // rule 1: start inside world bounds, and outside
        // solid, and don't start from somewhere where you can
        // fall down to evil
        tracebox(start, e.mins, e.maxs, start - '0 0 1' * delta_z, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;
        if (trace_startsolid)
            continue;
        if (trace_dphitcontents & badcontents)
            continue;
        if (trace_dphitq3surfaceflags & badsurfaceflags)
            continue;

        // rule 2: if we are too high, lower the point
        if (trace_fraction * delta_z > maxaboveground)
            start = trace_endpos + '0 0 1' * maxaboveground;

        enddown = trace_endpos;

        // rule 3: we must not end up in trigger_hurt
        if (trigger_tracebox_hits_hurt(start, e.mins, e.maxs, enddown))
        {
            dprint("trigger_hurt! ouch! and nothing else could find it!\n");
            continue;
        }

        break;
    }

    e.dphitcontentsmask = m;

    if (i < attempts)
    {
        setorigin(e, trace_endpos);
		e.flags &~= FL_ONGROUND;
        e.angles = vectoangles(start - end);
		e.angles_x = 0;
		e.angles_z = 0;
        dprint("Needed ", ftos(i + 1), " attempts\n");
        return TRUE;
    }
    else
        return FALSE;
}

void(entity platform) entity_drop_entities {
    const nudge = '1 1 1';
    entity e;

    while((e = findflags(e, flags, FL_ONGROUND))) {
        if(boxesoverlap(platform.absmin, platform.absmax, e.absmin - nudge, e.absmax + nudge)) {
            e.flags &~= FL_ONGROUND;
            projectile_update_next_frame(e);
        }
    }

    while((e = findentity(e, aiment, platform))) {
        if(e.movetype == MOVETYPE_FOLLOW) {
            e.movetype = MOVETYPE_TOSS;
            e.aiment = world;
            e.flags &~= FL_ONGROUND;
            projectile_update_next_frame(e);
        }
    }
}

void(entity e, vector by, float t) entity_move_out_of_solid_expand {
    float eps = 0.0625;
    tracebox(e.origin, e.mins - '1 1 1' * eps, e.maxs + '1 1 1' * eps, e.origin + by, t, e);
    if (trace_startsolid)
        return;

    if (trace_fraction < 1) {
        // hit something
        // adjust origin in the other direction...
        setorigin(e,e.origin - by * (1 - trace_fraction));
    }
}

float(entity e, float t) entity_move_out_of_solid_with_type {
    vector o, m0, m1;
    o = e.origin;
    traceline(o, o, t, e);
    if (trace_startsolid)
        return 0;

    tracebox(o, e.mins, e.maxs, o, t, e);
    if (!trace_startsolid)
        return 1;

    m0 = e.mins;
    m1 = e.maxs;
    e.mins = '0 0 0';
    e.maxs = '0 0 0';
    entity_move_out_of_solid_expand(e, '1 0 0' * m0_x, t);
    e.mins_x = m0_x;
    entity_move_out_of_solid_expand(e, '1 0 0' * m1_x, t);
    e.maxs_x = m1_x;
    entity_move_out_of_solid_expand(e, '0 1 0' * m0_y, t);
    e.mins_y = m0_y;
    entity_move_out_of_solid_expand(e, '0 1 0' * m1_y, t);
    e.maxs_y = m1_y;
    entity_move_out_of_solid_expand(e, '0 0 1' * m0_z, t);
    e.mins_z = m0_z;
    entity_move_out_of_solid_expand(e, '0 0 1' * m1_z, t);
    e.maxs_z = m1_z;
    setorigin(e, e.origin);
    tracebox(e.origin, e.mins, e.maxs, e.origin, MOVE_WORLDONLY, e);
    if (trace_startsolid) {
        setorigin(e, o);
        return 0;
    }
    return 1;
}
