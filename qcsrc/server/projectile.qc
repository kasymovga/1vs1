.float csqcprojectile_type;
.float csqcprojectile_sendangles;
float sv_projectile_tracecull;

float() projectile_no_impact_check {
	// zero hitcontents = this is not the real impact, but either the
	// mirror-impact of something hitting the projectile instead of the
	// projectile hitting the something, or a touchareagrid one. Neither of
	// these stop the projectile from moving, so...
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		return 1;

	if (other == world && self.size != '0 0 0') {
		vector tic;
		tic = self.velocity * sys_ticrate;
		tic = tic + normalize(tic) * vlen(self.maxs - self.mins);
		trace_line(self.origin - tic, self.origin + tic, TRACE_MOVE_NORMAL, self);
		if (trace_fraction < 0 && (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
			return 1;
	}
	return 0;
}

float(entity to, float sf) projectile_send {
	sf = sf & 23; //1, 2, 4, 16
	if (self.teleport_time) {
		if (self.teleport_time >= time - sys_ticrate * 2)
			sf |= 32;
		else
			self.teleport_time = 0;
	}
	if (self.csqcprojectile_clientanimate) {
		sf &= ~4;
		sf |= 128; // client animated, not interpolated
		if (self.movetype == MOVETYPE_BOUNCEMISSILE || self.movetype == MOVETYPE_BOUNCE)
			sf |= 8;
	} else if(!self.csqcprojectile_sendangles) {
		sf &= ~4;
	}
	if (self.flags & FL_ONGROUND) {
		sf |= 64;
	}
	if (self.team <= 0) {
		sf &= ~16;
	}
	net_write_byte(MSG_ENTITY, NET_CSQC_PROJECTILE);
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		net_write_coord(MSG_ENTITY, self.origin_x);
		net_write_coord(MSG_ENTITY, self.origin_y);
		net_write_coord(MSG_ENTITY, self.origin_z);
		if (sf & 128) {
			net_write_coord(MSG_ENTITY, self.velocity_x);
			net_write_coord(MSG_ENTITY, self.velocity_y);
			net_write_coord(MSG_ENTITY, self.velocity_z);
			net_write_coord(MSG_ENTITY, self.gravity);
		} else if (sf & 32) {
			net_write_coord(MSG_ENTITY, self.teleport_time);
			net_write_coord(MSG_ENTITY, self.oldorigin_x);
			net_write_coord(MSG_ENTITY, self.oldorigin_y);
			net_write_coord(MSG_ENTITY, self.oldorigin_z);
		}
	}
	if (sf & 2) {
		net_write_byte(MSG_ENTITY, self.csqcprojectile_type); // TODO maybe put this into sf?
		if (sf & 16)
			net_write_char(MSG_ENTITY, self.team);
	}
	if(sf & 4) {
		net_write_coord(MSG_ENTITY, self.angles_x);
		net_write_coord(MSG_ENTITY, self.angles_y);
		net_write_coord(MSG_ENTITY, self.angles_z);
	}
	return 1;
}

.vector csqcprojectile_oldorigin;
.vector csqcprojectile_oldangles;
void(void) projectile_check {
	entity e;
	for (e = world; (e = findflags(e, flags, FL_PROJECTILE)); ) {
		if (!e.csqcprojectile_clientanimate || (e.flags & FL_ONGROUND)) {
			if (e.origin != e.csqcprojectile_oldorigin)
				projectile_update(e);
		} else if (e.movetype == MOVETYPE_FOLLOW) {
			if (e.angles != e.csqcprojectile_oldangles) {
				projectile_update_angles(e);
				e.csqcprojectile_oldangles = e.angles;
			}
			if (!e.aiment || wasfreed(e.aiment)) {
				e.aiment = world;
				e.movetype = MOVETYPE_TOSS;
				setorigin(e, e.csqcprojectile_oldorigin);
				projectile_update(e);
			}
		}
		e.csqcprojectile_oldorigin = e.origin;
	}
}

void(float csqcid, vector sizes) projectile_register_auto {
	float type;
	if (sizes_x == 0 && sizes_y == sizes_z) {
		if (sizes == '0 0 0') {
			type = PROJECTILE_INFO_TYPE_POINT_000;
		} else if (sizes == '0 -3 -3') {
			type = PROJECTILE_INFO_TYPE_POINT_00n3;
		} else {
			type = PROJECTILE_INFO_TYPE_POINT;
		}
	} else if (sizes_y == sizes_z * -1) {
		type = PROJECTILE_INFO_TYPE_CENTERED;
	} else {
		type = PROJECTILE_INFO_TYPE_UNCENTERED;
	}
	projectile_register(csqcid, type, sizes);
}

void(float type) projectile_init {
	vector sizes;
	CVAR_CACHE(sv_projectile_tracecull);
	CVAR_CACHE(g_projectile_use_clipgroup);
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
	case PROJECTILE_RM_FLAK_BOMB:
		sizes = '1 -1 1';
		break;
	case PROJECTILE_RM_PRYAXE:
		sizes = '16 -4 4';
		break;
	}
	projectile_register_auto(type, sizes);
}

entity(float clientanimate, float type, float docull, entity _owner) projectile {
	entity e = spawn();
	if not(sv_projectile_tracecull)
		e.culltracemode = CULLTRACEMODE_NONE;

	if (g_projectile_use_clipgroup)
		e.clipgroup = _owner.clipgroup;

	e.realowner = e.owner = akimbo_owner(_owner);
	e.team = e.owner.team;
	projectile_set_size(e, type);
	net_link_entity(e, docull, 0, projectile_send);
	e.csqcprojectile_clientanimate = clientanimate;
	e.csqcprojectile_type = type;
	e.flags = FL_PROJECTILE;
	e.classname = "projectile";
	if (entity_per_player_entities && _owner) {
		if (clienttype(_owner) == CLIENTTYPE_NOTACLIENT)
			e.existsonlyfor = _owner.existsonlyfor;
		else
			e.existsonlyfor = _owner;
	}
	e.reset = stdproc_remove;
	e.solid = SOLID_SLIDEBOX;
	e.dphitcontentsmask = (DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE);
	return e;
}

void(entity e, vector _origin, float impacttype, float deathtype, float _dmg, float _dmg_edge, float _dmg_radius, float _force, float _gravity, float _movetype) projectile_setup {
	e.projectiledeathtype = deathtype;
	e.species = impacttype;
	e.movetype = _movetype;
	if (_gravity) {
		e.gravity = _gravity;
		if (e.movetype == MOVETYPE_FLY)
			e.movetype = MOVETYPE_TOSS;
		else if (e.movetype == MOVETYPE_BOUNCEMISSILE)
			e.movetype = MOVETYPE_BOUNCE;
	} else {
		if (e.movetype == MOVETYPE_TOSS || e.movetype == MOVETYPE_BOUNCE)
			e.gravity = 1;
	}
	if (e.owner && e.owner.solid != SOLID_BSP) {
		if (e.mins != e.maxs || e.mins != '0 0 0') {
			vector v = (e.mins + e.maxs) * 0.5;
			trace_box((e.owner.absmax + e.owner.absmin) * 0.5 - v, e.mins, e.maxs, _origin - v, TRACE_MOVE_NOMONSTERS, NULL);
			setorigin(e, trace_endpos);
		} else {
			setorigin(e, _origin);
		}
	} else
		setorigin(e, _origin);

	e.csqcprojectile_oldorigin = e.origin;
	e.dmg = _dmg;
	e.dmg_force = _force;
	e.dmg_radius = _dmg_radius;
	e.dmg_edge = _dmg_edge;
	e.bot_dodge = TRUE;
	e.bot_dodgerating = _dmg;
}

void(entity e) projectile_update {
	if (e.SendEntity == projectile_send) {
		// send new origin data
		e.SendFlags |= 1;
	}
}

void(entity e, float t) projectile_update_with_type {
	if (e.SendEntity == projectile_send) {
		// send new origin data
		e.csqcprojectile_type = t;
		e.SendFlags |= 3;
	}
}

void(entity e) projectile_update_angles {
	if (e.SendEntity == projectile_send) {
		// send new angles data (does nothing in predictive mode)
		e.SendFlags |= 4;
		e.csqcprojectile_sendangles = TRUE;
	}
}

void(entity e) projectile_update_after_teleport {
	if (e.SendEntity == projectile_send) {
		// send new origin data and mark as teleported
		e.SendFlags |= 1;
		e.teleport_time = time;
		e.oldorigin = e.origin - normalize(e.velocity);
	}
}

.void(void) csqcprojectile_oldthink;
.float csqcprojectile_oldnextthink;

void() projectile_update_think {
	projectile_update(self);
	self.think = self.csqcprojectile_oldthink;
	if (self.csqcprojectile_oldnextthink && self.csqcprojectile_oldnextthink < time) {
		self.nextthink = 0;
		self.think();
		return;
	}
	self.nextthink = max(time, self.csqcprojectile_oldnextthink);
}

void(entity e) projectile_update_next_frame {
	if (e.SendEntity == projectile_send)
	if (e.think != projectile_update_think) {
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
	self.event_damage = NULL;
	self.takedamage = DAMAGE_NO;
	damage_radius(self, self.realowner, self.dmg, self.dmg_edge, self.dmg_radius, world, self.dmg_force, self.species, self.projectiledeathtype, other);
	stdproc_remove();
}

void(void) projectile_touch_explode {
	PROJECTILE_TOUCH;
	projectile_explode();
}

void(entity e, entity to, vector a) projectile_stick {
	if (to.solid == SOLID_TRIGGER || e.movetype == MOVETYPE_FOLLOW || e.movetype == MOVETYPE_NONE)
		return;

	e.angles = a;
	if (to) {
		e.aiment = to;
		e.movetype = MOVETYPE_FOLLOW;
		e.v_angle = e.angles;
		e.v_angle_y -= to.angles_y;
		e.punchangle = -to.angles;
		e.punchangle_y *= -1;
		e.view_ofs = e.origin - to.origin;
		e.flags &= ~FL_ONGROUND;
		e.solid = SOLID_CORPSE;
	} else
		e.movetype = MOVETYPE_NONE;

	e.velocity = '0 0 0';
	e.csqcprojectile_clientanimate = FALSE;
	projectile_update(e);
	projectile_update_angles(e);
}

void(entity proj, float delta) projectile_premove {
	float g = 0;
	if (proj.movetype == MOVETYPE_TOSS || proj.movetype == MOVETYPE_BOUNCE) {
		g = (proj.gravity ? proj.gravity : 1) * sv_gravity;
		proj.velocity_z -= 0.5 * g * delta;
	}
	vector v = proj.origin + proj.velocity * delta;
	trace_box(proj.origin, proj.mins, proj.maxs, v, TRACE_MOVE_NOMONSTERS, proj);
	setorigin(proj, trace_endpos);
	if (trace_fraction < 1) { //check if we "inside" a surface
		trace_box(proj.origin, proj.mins, proj.maxs, v, TRACE_MOVE_NOMONSTERS, proj);
		if (trace_endpos != proj.origin) //move back to prevent projectile fall trough surfaces
			setorigin(proj, proj.origin - 0.125 * normalize(proj.velocity));
	}
	if (g) {
		proj.velocity_z -= 0.5 * g * delta;
	}
}

void(void) projectile_info_send {
	float i;
	net_write_byte(MSG_ENTITY, projectile_info_highest_registered);
	for(i = 0; i < projectile_info_highest_registered; ++i) {
		float type = projectile_info_type[i];
		net_write_byte(MSG_ENTITY, type);
		switch (type) {
		case PROJECTILE_INFO_TYPE_UNREGISTERED:
		case PROJECTILE_INFO_TYPE_POINT_000:
		case PROJECTILE_INFO_TYPE_POINT_00n3:
			break;
		case PROJECTILE_INFO_TYPE_UNCENTERED:
		case PROJECTILE_INFO_TYPE_POINT:
		case PROJECTILE_INFO_TYPE_CENTERED:
			net_write_coord(MSG_ENTITY, projectile_info_sizes[i]);
			break;
		default:
			error(strcat("Invalid projectile info type ", ftos(type)));
		}
	}
}
