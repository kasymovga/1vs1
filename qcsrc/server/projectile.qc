.float csqcprojectile_type;
.float csqcprojectile_sendangles;
float sv_projectile_tracecull;

float() projectile_no_impact_check {
	// zero hitcontents = this is not the real impact, but either the
	// mirror-impact of something hitting the projectile instead of the
	// projectile hitting the something, or a touchareagrid one. Neither of
	// these stop the projectile from moving, so...
	if(trace_dphitcontents == 0)
		checkclient();

    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
        return 1;
    if (other == world && self.size != '0 0 0')
    {
        vector tic;
        tic = self.velocity * sys_ticrate;
        tic = tic + normalize(tic) * vlen(self.maxs - self.mins);
        trace_line(self.origin - tic, self.origin + tic, MOVE_NORMAL, self);
        if (trace_fraction < 0 && (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
            return 1;
    }

    return 0;
}


float(entity to, float sf) projectile_send {
	sf = sf & 31;
	if (self.teleport_time) {
		sf |= 32;
		self.teleport_time = 0;
	}

	if(self.csqcprojectile_clientanimate) {
        sf &~= 4;
		sf |= 128; // client animated, not interpolated
    } else if(!self.csqcprojectile_sendangles) {
        sf &~= 4;
    }

	if(self.flags & FL_ONGROUND) {
		sf |= 64;
	}

	if(self.team <= 0) {
		sf &~= 16;
	}

	WriteByte(MSG_ENTITY, ENT_CLIENT_PROJECTILE);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);

		if(sf & 128)
		{
			WriteCoord(MSG_ENTITY, self.velocity_x);
			WriteCoord(MSG_ENTITY, self.velocity_y);
			WriteCoord(MSG_ENTITY, self.velocity_z);
			WriteCoord(MSG_ENTITY, self.gravity);
		}
	}

	if(sf & 2) {
		WriteByte(MSG_ENTITY, self.csqcprojectile_type); // TODO maybe put this into sf?
		if(sf & 16)
			WriteChar(MSG_ENTITY, self.team);
	}

    if(sf & 4) {
        WriteCoord(MSG_ENTITY, self.angles_x);
        WriteCoord(MSG_ENTITY, self.angles_y);
        WriteCoord(MSG_ENTITY, self.angles_z);
    }

	return 1;
}

.vector csqcprojectile_oldorigin;
void(entity e) projectile_check {
	if(e.csqcprojectile_clientanimate)
	if(e.flags & FL_ONGROUND)
	if(e.origin != e.csqcprojectile_oldorigin)
		projectile_update(e);
	e.csqcprojectile_oldorigin = e.origin;
}

void(float type) projectile_init {
	vector sizes;
	CVAR_CACHE(sv_projectile_tracecull);
	sizes = '0 0 0';
	switch (type) {
	case PROJECTILE_FIREBALL:
		sizes = '8 -8 8';
		break;
	case PROJECTILE_FIREMINE:
		sizes = '4 -4 4';
		break;
	case PROJECTILE_ROCKET:
		sizes = stov(cvar_string("sv_projectile_rocket_size"));
		break;
	case PROJECTILE_ELECTRO:
	case PROJECTILE_GRENADE_BOUNCING:
	case PROJECTILE_HG_NAPALMSHARD:
		sizes = '0 -3 -3';
		break;
	}
	projectile_register_auto(type, sizes);
}

entity(float clientanimate, float type, float docull, entity _owner) projectile {
	entity e = spawn();
	if not(sv_projectile_tracecull)
		e.culltracemode = CULLTRACEMODE_NONE;

	e.realowner = e.owner = Akimbo_Owner(_owner);
	projectile_set_size(e, type);
	net_link_entity(e, docull, 0, projectile_send);
	e.csqcprojectile_clientanimate = clientanimate;
	e.csqcprojectile_type = type;
	e.flags = FL_PROJECTILE;
	e.classname = "projectile";
	return e;
}

void(entity e, vector _origin, float deathtype, float _dmg, float _dmg_edge, float _dmg_radius, float _force) projectile_setup {
	e.projectiledeathtype = deathtype;
	PROJECTILE_MAKETRIGGER(e);
	setorigin(e, _origin);
	e.dmg = _dmg;
	e.dmg_force = _force;
	e.dmg_radius = _dmg_radius;
	e.dmg_edge = _dmg_edge;
	e.bot_dodge = TRUE;
	e.bot_dodgerating = _dmg;
}

void(entity e) projectile_update {
	if(e.SendEntity == projectile_send)
	{
		// send new origin data
		e.SendFlags |= 1;
	}
}

void(entity e) projectile_update_angles {
    if(e.SendEntity == projectile_send)
    {
        // send new angles data (does nothing in predictive mode)
        e.SendFlags |= 4;
        e.csqcprojectile_sendangles = TRUE;
    }
}

void(entity e) projectile_update_after_teleport {
	if(e.SendEntity == projectile_send)
	{
		// send new origin data and mark as teleported
		e.teleport_time = time;
		e.SendFlags |= 0x1;
	}
}

.void(void) csqcprojectile_oldthink;
.float csqcprojectile_oldnextthink;

void() projectile_update_think {
	projectile_update(self);
	self.think = self.csqcprojectile_oldthink;
	self.nextthink = max(time, self.csqcprojectile_oldnextthink);
}

void(entity e) projectile_update_next_frame {
	if(e.SendEntity == projectile_send)
	if(e.think != projectile_update_think)
	{
		e.csqcprojectile_oldthink = e.think;
		e.csqcprojectile_oldnextthink = e.nextthink;
		e.think = projectile_update_think;
		e.nextthink = time;
	}
}

void(void) projectile_think2use {
    entity o, a;
    o = other;
    a = activator;
    activator = world;
    other = world;
    self.use();
    other = o;
    activator = a;
}

void(void) projectile_explode {
	self.event_damage = stdproc_nothing;
	self.takedamage = DAMAGE_NO;
	damage_radius(self, self.realowner, self.dmg, self.dmg_edge, self.dmg_radius, world, self.dmg_force, self.projectiledeathtype, other);
	remove(self);
}

void(void) projectile_touch_explode {
	PROJECTILE_TOUCH;
	projectile_explode();
}

void(void) projectile_info_send {
	float i;
	WriteByte(MSG_ENTITY, projinfo_highest_registered);
	for(i = 0; i < projinfo_highest_registered; ++i) {
		float type = projinfo_type[i];

		WriteByte(MSG_ENTITY, type);
		switch(type) {
			case PROJINFO_TYPE_UNREGISTERED:
			case PROJINFO_TYPE_POINT_000:
			case PROJINFO_TYPE_POINT_00n3:
				break;

			case PROJINFO_TYPE_UNCENTERED:
			case PROJINFO_TYPE_POINT:
			case PROJINFO_TYPE_CENTERED:
				WriteCoord(MSG_ENTITY, projinfo_sizes[i]);
				break;

			default: {
				error(strcat("Invalid projectile info type ", ftos(type)));
			}
		}
	}
}
