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

void(string s) entity_abort {
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
            continue;

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
        return TRUE;
    }
    else
        return FALSE;
}

void(entity platform) entity_drop_entities {
    const nudge = '1 1 1';
    entity e;

    while((e = findflags(e, flags, FL_ONGROUND))) {
        if(math_boxes_overlap(platform.absmin, platform.absmax, e.absmin - nudge, e.absmax + nudge)) {
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

.vector originjitter;
.vector anglesjitter;
.float anglejitter;
.string gametypefilter;
.string gametype;
.string not_gametype;
.string cvarfilter;
string entity_gametype_patterns;
void(void) SV_OnEntityPreSpawnFunction {
	if(!self) //Skip pre-spawn function for world.
		return;

	if (entity_gametype_patterns == "") {
		entity_gametype_patterns = cvar_string("g_gametype_patterns");
		if (entity_gametype_patterns == "") { //Trying to guess
			if (teamplay)
				entity_gametype_patterns = "team|ctf";
			else if(cvar("g_maxplayers") == 2)
				entity_gametype_patterns = "tournament|duel";
			else
				entity_gametype_patterns = "ffa";
		}
	}
	string s;
	float i, n;
	if(self.gametypefilter != "")
	if not(gametype_filter(game, teamplay, self.gametypefilter)) {
		remove(self);
		return;
	}
	if (self.gametype != "") {
		s = entity_gametype_patterns;
		float matched;
		matched = 0;
		n = tokenizebyseparator(s, "|");
		for (i = 0; i < n; i++) {
			s = argv(i);
			if(s == "")
				continue;

			if(strstrofs(self.gametype, s, 0) >= 0) {
				print(strcat("Found pattern '", s, "' for entity '", self.classname, "' with gametype '", self.gametype, "'\n"));
				matched = 1;
				break;
			}
		}
		if not(matched) {
			print(strcat("Removed entity '", self.classname, "' with gametype '", self.gametype, "' because no patterns found\n"));
			remove(self);
			return;
		}
	}
	if (self.not_gametype != "") {
		s = entity_gametype_patterns;
		n = tokenizebyseparator(s, "|");
		for (i = 0; i < n; i++) {
			s = argv(i);
			if(s == "")
				continue;

			if(strstrofs(self.not_gametype, s, 0) >= 0) {
				print(strcat("Removed entity '", self.classname, "' with not allowed gametype '", self.not_gametype, "' because patterns found\n"));
				remove(self);
				return;
			}
		}
	}
	if(self.cvarfilter != "") {
		float o, inv;
		string k, v;
		inv = 0;

		s = self.cvarfilter;
		if(substring(s, 0, 1) == "+") {
			s = substring(s, 1, -1);
		} else if(substring(s, 0, 1) == "-") {
			inv = 1;
			s = substring(s, 1, -1);
		}

		n = tokenize(s);
		for(i = 0; i < n; ++i) {
			s = argv(i);
			// syntax:
			// var>x
			// var<x
			// var>=x
			// var<=x
			// var==x
			// var!=x
			// var===x
			// var!==x
			if((o = strstrofs(s, ">=", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) < stof(v))
					goto cvar_fail;
			} else if((o = strstrofs(s, "<=", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) > stof(v))
					goto cvar_fail;
			} else if((o = strstrofs(s, ">", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) <= stof(v))
					goto cvar_fail;
			} else if((o = strstrofs(s, "<", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) >= stof(v))
					goto cvar_fail;
			} else if((o = strstrofs(s, "===", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+3, -1);
				if (cvar_string(k) != v)
					goto cvar_fail;
			} else if((o = strstrofs(s, "!==", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+3, -1);
				if(cvar_string(k) == v)
					goto cvar_fail;
			} else if((o = strstrofs(s, "==", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) != stof(v))
					goto cvar_fail;
			} else if((o = strstrofs(s, "!=", 0)) >= 0) {
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) == stof(v))
					goto cvar_fail;
			} else if(substring(s, 0, 1) == "!") {
				k = substring(s, 1, -1);
				if(cvar(k))
					goto cvar_fail;
			} else {
				k = s;
				if not(cvar(k))
					goto cvar_fail;
			}
		}
		inv = !inv;
:cvar_fail
		// now inv is 1 if we want to keep the item, and 0 if we want to get rid of it
		if not(inv) {
			print(self.classname, " removed by cvarfilter\n");
			remove(self);
			return;
		} else
			print(self.classname, " keeped by cvarfilter\n");
	}
	// support special -1 and -2 angle from radiant
	if (self.angles == '0 -1 0')
		self.angles = '-90 0 0';
	else if (self.angles == '0 -2 0')
		self.angles = '+90 0 0';

	if(self.originjitter_x != 0)
		self.origin_x = self.origin_x + (random() * 2 - 1) * self.originjitter_x;

	if(self.originjitter_y != 0)
		self.origin_y = self.origin_y + (random() * 2 - 1) * self.originjitter_y;

	if(self.originjitter_z != 0)
		self.origin_z = self.origin_z + (random() * 2 - 1) * self.originjitter_z;

	if(self.anglesjitter_x != 0)
		self.angles_x = self.angles_x + (random() * 2 - 1) * self.anglesjitter_x;

	if(self.anglesjitter_y != 0)
		self.angles_y = self.angles_y + (random() * 2 - 1) * self.anglesjitter_y;

	if(self.anglesjitter_z != 0)
		self.angles_z = self.angles_z + (random() * 2 - 1) * self.anglesjitter_z;

	if(self.anglejitter != 0)
		self.angles_y = self.angles_y + (random() * 2 - 1) * self.anglejitter;

	string repl = cvar_string(strcat("sv_spawnreplace_", self.classname));
	if(repl != "") {
		entity e;
		print("Entity ", self.classname, " replaced with ", repl, "\n");
		if ((e = find(world, classname, repl))) {
			self.classname = e.classname;
		} else
			self.classname = strzone(repl);
	}
	GameHookChain_EntityPreSpawn();
}
