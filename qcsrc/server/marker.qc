..entity owned_by_field;

.float(entity) waypointsprite_visible_for_player;

void(entity e, string m1, string m2, string m3) marker_UpdateSprites {
	if (m1 != e.target) {
		e.target = m1;
		e.SendFlags |= 2;
	}
	if (m2 != e.target2) {
		e.target2 = m2;
		e.SendFlags |= 4;
	}
	if (m3 != e.target3) {
		e.target3 = m3;
		e.SendFlags |= 8;
	}
}

void(entity e, float f) marker_UpdateHealth {
	f = bound(0, f, e.max_health);
	if (f != e.health || e.pain_finished) {
		e.health = f;
		e.pain_finished = 0;
		e.SendFlags |= 0x80;
	}
}

void(entity e, float f) marker_UpdateMaxHealth {
	if (f != e.max_health || e.pain_finished) {
		e.max_health = f;
		e.pain_finished = 0;
		e.SendFlags |= 0x80;
	}
}

void(entity e, float f) marker_UpdateBuildFinished {
	if (f != e.pain_finished || e.max_health) {
		e.max_health = 0;
		e.pain_finished = f;
		e.SendFlags |= 0x80;
	}
}

void(entity e, vector o) marker_UpdateOrigin {
	if (o != e.origin) {
		setorigin(e, o);
		e.SendFlags |= 64;
	}
}

void(entity e, float t) marker_UpdateRule {
	// no check, as this is never called without doing an actual change (usually only once)
	e.team = t;
	e.SendFlags |= 1;
}

void(entity e, float icon, vector col) marker_UpdateTeamRadar {
	// no check, as this is never called without doing an actual change (usually only once)
	e.cnt = (icon & 0xFF);
	e.colormod = col;
	e.SendFlags |= 32;
}

void(entity e) marker_Ping {
	// ALWAYS sends (this causes a radar circle), thus no check
	e.cnt |= 0x80;
	e.SendFlags |= 32;
}

void(entity e, float t) marker_FadeOutIn {
	if (!e.fade_time) {
		e.fade_time = t;
		e.teleport_time = time + t;
	} else if (t < (e.teleport_time - time)) {
		// accelerate the waypoint's dying
		// ensure:
		//   (e.teleport_time - time) / wp.fade_time stays
		//   e.teleport_time = time + fadetime
		float current_fadetime;
		current_fadetime = e.teleport_time - time;
		e.teleport_time = time + t;
		e.fade_time = e.fade_time * t / current_fadetime;
	}
	e.SendFlags |= 16;
}

float waypointsprite_limitedrange, waypointsprite_deployed_lifetime, waypointsprite_deadlifetime;
void(void) marker_Init {
	waypointsprite_limitedrange = cvar("g_waypointsprite_limitedrange");
	waypointsprite_deployed_lifetime = cvar("g_waypointsprite_deployed_lifetime");
	waypointsprite_deadlifetime = cvar("g_waypointsprite_deadlifetime");
}

void(entity wp) marker_Kill {
	if (!wp)
		return;

	if (wp.owner)
		wp.owner.(wp.owned_by_field) = world;

	remove(wp);
}

void(entity wp, float fadetime) marker_Disown {
	if (!wp)
		return;

	if (wp.owner) {
		if (wp.exteriormodeltoclient == wp.owner)
			wp.exteriormodeltoclient = world;

		wp.owner.(wp.owned_by_field) = world;
		wp.owner = world;
		marker_FadeOutIn(wp, fadetime);
	}
}

void() marker_Think {
	float doremove;
	doremove = FALSE;
	if (self.fade_time) {
		if (time >= self.teleport_time)
			doremove = TRUE;
	}
	if (self.exteriormodeltoclient) {
		entity e = player_entity(self.exteriormodeltoclient);
		vector v = '0 0 1' * e.maxs_z + e.origin;
		marker_UpdateOrigin(self, v + self.view_ofs);
	}
	if (doremove)
		marker_Kill(self);
	else
		self.nextthink = time; // WHY?!?
}

float(entity e) marker_visible_for_player {
	// personal waypoints
	if (self.enemy)
		if (self.enemy != other)
			return FALSE;

	// team waypoints
	if (self.team) {
		if (e.classname == "observer" && e.team <= 0) {
			if (self.target3 == "") {
				return FALSE;
			}
		} else {
			if (self.team != e.team && self.target == "" && (self.color == '0 0 0' || self.target3 == "")) {
				return FALSE;
			} else if (self.team == e.team && self.target2 == "" && (self.color == '0 0 0' || self.target3 == "")) {
				return FALSE;
			}
		}
	}
	return TRUE;
}

float(void) marker_Customize {
	// this is not in SendEntity because it shall run every frame, not just every update
	// make spectators see what the player would see
	entity e;
	e = other;
	if (e.classname == "spectator")
		e = e.enemy;

	return self.waypointsprite_visible_for_player(e);
}

float(entity to, float sendflags) marker_SendEntity {
	float dt;
	net_write_byte(MSG_ENTITY, NET_CSQC_WAYPOINT);
	sendflags = sendflags & 0x7F;
	if (self.max_health || (self.pain_finished && (time < self.pain_finished + 0.25)))
		sendflags |= 0x80;

	net_write_byte(MSG_ENTITY, sendflags);
	if (sendflags & 0x80) {
		if (self.max_health) {
			net_write_byte(MSG_ENTITY, (self.health / self.max_health) * 191.0);
		} else {
			dt = self.pain_finished - time;
			dt = bound(0, dt * 32, 16383);
			net_write_byte(MSG_ENTITY, (dt & 0xFF00) / 256 + 192);
			net_write_byte(MSG_ENTITY, (dt & 0x00FF));
		}
	}
	if (sendflags & 64) {
		net_write_coord(MSG_ENTITY, self.origin_x);
		net_write_coord(MSG_ENTITY, self.origin_y);
		net_write_coord(MSG_ENTITY, self.origin_z);
	}
	if (sendflags & 1) {
		net_write_byte(MSG_ENTITY, self.team);
	}
	if (sendflags & 2)
		net_write_string(MSG_ENTITY, self.target);

	if (sendflags & 4)
		net_write_string(MSG_ENTITY, self.target2);

	if (sendflags & 8)
		net_write_string(MSG_ENTITY, self.target3);

	if (sendflags & 16) {
		net_write_coord(MSG_ENTITY, self.fade_time);
		net_write_coord(MSG_ENTITY, self.teleport_time);
		net_write_short(MSG_ENTITY, self.fade_rate); // maxdist
		float f;
		f = 0;
		if (self.currentammo)
			f |= 1; // hideable

		if (self.exteriormodeltoclient == to)
			f |= 2; // my own

		net_write_byte(MSG_ENTITY, f);
	}
	if (sendflags & 32) {
		net_write_byte(MSG_ENTITY, self.cnt); // icon on radar
		net_write_color(MSG_ENTITY, self.colormod);
		net_write_color(MSG_ENTITY, self.color);
		net_write_color(MSG_ENTITY, self.pos1);
		net_write_color(MSG_ENTITY, self.pos2);
	}
	return TRUE;
}

void(void) marker_Reset {
	// if a WP wants to time out, let it time out immediately; other WPs ought to be reset/killed by their owners
	if (self.fade_time) // there was there before: || g_keyhunt, do we really need this?
		marker_Kill(self);
}

entity(
	string spr, // sprite
	float lifetime, float maxdistance, // lifetime, max distance
	entity ref, vector ofs, // position
	entity showto, float t, // show to whom? Use a flag to indicate a team
	entity own, .entity ownfield, // remove when own gets killed
	float hideable // true when it should be controlled by cl_hidewaypoints
) marker_Spawn {
	entity wp;
	wp = spawn();
	wp.classname = "sprite_waypoint";
	wp.teleport_time = time + lifetime;
	wp.fade_time = lifetime;
	wp.exteriormodeltoclient = ref;
	if (ref) {
		wp.view_ofs = ofs;
		setorigin(wp, ref.origin + ofs);
	} else
		setorigin(wp, ofs);

	wp.enemy = showto;
	wp.team = t;
	wp.owner = own;
	wp.currentammo = hideable;
	if (own) {
		if (own.ownfield)
			remove(own.ownfield);

		own.ownfield = wp;
		wp.owned_by_field = ownfield;
	}
	wp.fade_rate = maxdistance;
	wp.think = marker_Think;
	wp.nextthink = time;
	if (t)
		wp.target2 = spr;
	else
		wp.target = spr;

	wp.customizeentityforclient = marker_Customize;
	wp.waypointsprite_visible_for_player = marker_visible_for_player;
	wp.reset2 = marker_Reset;
	net_link_entity(wp, FALSE, 0, marker_SendEntity);
	return wp;
}

entity(
	string spr,
	vector ofs,
	entity own,
	.entity ownfield
) marker_SpawnFixed {
	return marker_Spawn(spr, 0, 0, world, ofs, world, 0, own, ownfield, TRUE);
}

.entity waypointsprite_deployed_fixed;
entity(
	string spr,
	float limited_range,
	vector ofs
) marker_DeployFixed {
	float t, maxdistance;
	if (team_mode)
		t = self.team;
	else
		t = 0;

	if (limited_range)
		maxdistance = waypointsprite_limitedrange;
	else
		maxdistance = 0;

	return marker_Spawn(spr, waypointsprite_deployed_lifetime, maxdistance, world, ofs, world, t, self, waypointsprite_deployed_fixed, FALSE);
}

.entity waypointsprite_deployed_personal;
entity(
	string spr,
	vector ofs
) marker_DeployPersonal {
	return marker_Spawn(spr, 0, 0, world, ofs, world, 0, self, waypointsprite_deployed_personal, FALSE);
}

.entity waypointsprite_attached;
.entity waypointsprite_attachedforcarrier;
entity(
	string spr,
	float limited_range
) marker_Attach {
	float t, maxdistance;
	if (self.waypointsprite_attachedforcarrier)
		return world; // can't attach to FC

	if (team_mode)
		t = self.team;
	else
		t = 0;

	if (limited_range)
		maxdistance = waypointsprite_limitedrange;
	else
		maxdistance = 0;

	return marker_Spawn(spr, waypointsprite_deployed_lifetime, maxdistance, self, '0 0 1' * self.maxs_z, world, t, self, waypointsprite_attached, FALSE);
}

entity(
	string spr,
	entity carrier
) marker_AttachCarrier {
	entity e;
	marker_Kill(carrier.waypointsprite_attached); // FC overrides attached
	e = marker_Spawn(spr, 0, 0, carrier, '0 0 1' * self.maxs_z, world, carrier.team, carrier, waypointsprite_attachedforcarrier, FALSE);
	return e;
}

void(entity carrier) marker_DetachCarrier {
	marker_Disown(carrier.waypointsprite_attachedforcarrier, waypointsprite_deadlifetime);
}

void(void) marker_ClearPersonal {
	marker_Kill(self.waypointsprite_deployed_personal);
}

void(void) marker_ClearOwned {
	marker_Kill(self.waypointsprite_deployed_fixed);
	marker_Kill(self.waypointsprite_deployed_personal);
	marker_Kill(self.waypointsprite_attached);
}

void(void) marker_PlayerDead {
	marker_Disown(self.waypointsprite_attached, waypointsprite_deadlifetime);
	marker_DetachCarrier(self);
}

void(void) marker_PlayerGone {
	marker_Disown(self.waypointsprite_deployed_fixed, waypointsprite_deadlifetime);
	marker_Kill(self.waypointsprite_deployed_personal);
	marker_Disown(self.waypointsprite_attached, waypointsprite_deadlifetime);
	marker_DetachCarrier(self);
}

void(float imp) marker_impulse {
	entity wp;
	switch (imp) {
	case 30:
		wp = marker_DeployPersonal("waypoint", self.origin);
		if (wp) {
			marker_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
			marker_Ping(wp);
		}
		sprint(self, "personal waypoint spawned at location\n");
		break;
	case 31:
		wp = marker_DeployPersonal("waypoint", self.cursor_trace_endpos);
		if (wp) {
			marker_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
			marker_Ping(wp);
		}
		break;
	case 32:
		if (vlen(self.death_origin)) {
			wp = marker_DeployPersonal("waypoint", self.death_origin);
			if (wp) {
				marker_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
				marker_Ping(wp);
			}
			sprint(self, "personal waypoint spawned at death location\n");
		}
		break;
	case 33:
		if (self.deadflag == DEAD_NO && team_mode) {
			wp = marker_Attach("helpme", TRUE);
			if (wp)
				marker_UpdateTeamRadar(wp, RADARICON_HELPME, '1 0.5 0'); // TODO choose better color

			if (!wp)
				wp = self.waypointsprite_attachedforcarrier; // flag sprite?

			if (wp)
				marker_Ping(wp);

			sprint(self, "HELP ME attached\n");
		}
		break;
	case 34:
		wp = marker_DeployFixed("here", FALSE, self.origin);
		if (wp) {
			marker_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
			marker_Ping(wp);
		}
		sprint(self, "HERE spawned at location\n");
		break;
	case 35:
		wp = marker_DeployFixed("here", FALSE, self.cursor_trace_endpos);
		if (wp) {
			marker_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
			marker_Ping(wp);
		}
		break;
	case 36:
		if (vlen(self.death_origin)) {
			wp = marker_DeployFixed("here", FALSE, self.death_origin);
			if (wp) {
				marker_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
				marker_Ping(wp);
			}
			sprint(self, "HERE spawned at death location\n");
		}
		break;
	case 37:
		wp = marker_DeployFixed("danger", FALSE, self.origin);
		if (wp) {
			marker_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
			marker_Ping(wp);
		}
		sprint(self, "DANGER spawned at location\n");
		break;
	case 38:
		wp = marker_DeployFixed("danger", FALSE, self.cursor_trace_endpos);
		if (wp) {
			marker_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
			marker_Ping(wp);
		}
		break;
	case 39:
		if (vlen(self.death_origin)) {
			wp = marker_DeployFixed("danger", FALSE, self.death_origin);
			if (wp) {
				marker_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
				marker_Ping(wp);
			}
			sprint(self, "DANGER spawned at death location\n");
		}
		break;
	case 47:
		marker_ClearPersonal();
		sprint(self, "personal waypoint cleared\n");
		break;
	case 48:
		marker_ClearOwned();
		sprint(self, "all waypoints cleared\n");
		break;
	}
}

void(entity m, vector clr1, vector clr2, vector clr3) marker_text_update {
	if (m.color != clr1 || m.pos1 != clr2 || m.pos2 != clr3) {
		m.color = clr1;
		m.pos1 = clr2;
		m.pos2 = clr3;
		m.SendFlags |= 32;
	}
}
