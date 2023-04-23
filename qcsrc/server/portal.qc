#define SAFENUDGE '1 1 1'
#define SAFERNUDGE '8 8 8'

.vector portal_transform;
.vector portal_safe_origin;
.float portal_wants_to_vanish;
.float portal_activatetime;

float(entity p, vector v) portal_player_edge_distance {
	vector vbest;
	if(v_x < 0) vbest_x = p.mins_x; else vbest_x = p.maxs_x;
	if(v_y < 0) vbest_y = p.mins_y; else vbest_y = p.maxs_y;
	if(v_z < 0) vbest_z = p.mins_z; else vbest_z = p.maxs_z;
	return vbest * v;
}

.vector right_vector;
float(entity teleporter, entity player) portal_teleport_player {
	vector from, to, safe, step, transform, ang, newvel;
	vector new_forward, new_up;
	vector old_forward, old_up;
	vector new_yawforward;
	vector old_yawforward;
	float planeshift, s, t;
	if not(teleporter.enemy) {
		backtrace("portal_teleport_player called without other portal being set. Stop.");
		return 0;
	}
	from = teleporter.origin;
	transform = teleporter.portal_transform;
	to = teleporter.enemy.origin;
	to = to + anglestransform_apply(teleporter.portal_transform, player.origin - from);
	newvel = anglestransform_apply(transform, player.velocity);
	// this now is INSIDE the plane... can't use that
	// shift it out
	makevectors(teleporter.enemy.angles);
	// first shift it ON the plane if needed
	planeshift = ((teleporter.enemy.origin - to) * v_forward) + portal_player_edge_distance(player, v_forward) + 1;
	/*
	if(planeshift > 0 && (newvel * v_forward) > vlen(newvel) * 0.01)
		// if we can't, let us not do the planeshift and do somewhat incorrect transformation in the end
		to += newvel * (planeshift / (newvel * v_forward));
	else
	*/
		to += v_forward * planeshift;

	s = (to - teleporter.enemy.origin) * v_right;
	t = (to - teleporter.enemy.origin) * v_up;
	s = bound(-48, s, 48);
	t = bound(-48, t, 48);
	to = teleporter.enemy.origin
	   + ((to - teleporter.enemy.origin) * v_forward) * v_forward
	   +     s                                        * v_right
	   +     t                                        * v_up;

	safe = teleporter.enemy.portal_safe_origin; // a valid player origin
	step = to + ((safe - to) * v_forward) * v_forward;
	trace_box(safe, player.mins - SAFENUDGE, player.maxs + SAFENUDGE, step, TRACE_MOVE_NOMONSTERS, player);
	if (trace_startsolid) {
		print("'safe' teleport location is not safe!\n");
		// FAIL TODO why does this happen?
		return 0;
	}
	safe = trace_endpos + normalize(safe - trace_endpos) * 0;
	trace_box(safe, player.mins - SAFENUDGE, player.maxs + SAFENUDGE, to, TRACE_MOVE_NOMONSTERS, player);
	if (trace_startsolid) {
		print("trace_endpos in solid, this can't be!\n");
		// FAIL TODO why does this happen? (reported by MrBougo)
		return 0;
	}
	to = trace_endpos + normalize(safe - trace_endpos) * 0;
	//print(vtos(to), "\n");
	// ang_x stuff works around weird quake angles
	if (player.classname == "player") {
		ang = anglestransform_apply_to_vangles(transform, player.v_angle);
		ang_z = 0;
	} else {
		ang = anglestransform_multiply(transform, player.angles);
	}
	// factor -1 allows chaining portals, but may be weird
	player.right_vector = -1 * anglestransform_apply(transform, player.right_vector);
	if (plugin_player_is_carrier(player))
		plugin_player_drop_carried(player);

	if not(teleporter.enemy) {
		backtrace("portal_teleport_player ended up without other portal being set BEFORE TeleportPlayer. Stop.");
		return 0;
	}
	teleport_death_hit = 0;
	teleport(teleporter, player, to, ang, newvel, teleporter.enemy.absmin, teleporter.enemy.absmax, 10000);
	if(teleport_death_hit) {
		// telefrag within 1 second of portal creation = amazing
		if (time < teleporter.teleport_time + 1)
			announce(player, "announcer/male/amazing.wav", "^5Amazing");
	}
	if not(teleporter.enemy) {
		backtrace("portal_teleport_player ended up without other portal being set AFTER TeleportPlayer. Stop.");
		return 0;
	}
	// reset fade counter
	teleporter.portal_wants_to_vanish = 0;
	teleporter.nextthink = time + cvar("g_balance_portal_lifetime");
	teleporter.health = cvar("g_balance_portal_health");
	teleporter.enemy.health = cvar("g_balance_portal_health");
	return 1;
}

float(entity portal) portal_find_save_origin {
	vector o;
	o = portal.origin;
	portal.mins = PL_MIN - SAFERNUDGE;
	portal.maxs = PL_MAX + SAFERNUDGE;
	portal.angles_x = - portal.angles_x;
	makevectors(portal.angles);
	portal.angles_x = - portal.angles_x;
	portal.origin += 16 * v_forward;
	if(!entity_move_out_of_solid(portal)) {
#ifdef DEBUG
		print("NO SAFE ORIGIN\n");
#endif
		return 0;
	}
	portal.portal_safe_origin = portal.origin;
	setorigin(portal, o);
	return 1;
}

float(vector eorg, vector emins, vector emaxs, vector evel, vector porg, vector pnorm, float psize) portal_will_hit_plane {
	float dist, distpersec, delta;
	vector v;
	dist = (eorg - porg) * pnorm;
	dist += min(emins_x * pnorm_x, emaxs_x * pnorm_x);
	dist += min(emins_y * pnorm_y, emaxs_y * pnorm_y);
	dist += min(emins_z * pnorm_z, emaxs_z * pnorm_z);
	if(dist < -1) // other side?
		return 0;

	return 1;
}

void(void) portal_touch {
	vector g;
	if (plugin_portal_forbidden_for(other))
		return; // never portal these

	if (!self.enemy)
		error("portal_touch called for a broken portal\n");

	if(other.portal_id == self.portal_id)
		return;

	if (time < self.portal_activatetime)
		if(other == self.aiment) {
			self.portal_activatetime = time + 0.1;
			return;
		}
	if (other != self.aiment)
		if(other.classname == "player")
			if(PLAYER_IS_INDEPENDENT(other) || PLAYER_IS_INDEPENDENT(self.aiment))
				return; // cannot go through someone else's portal

	if (other.aiment != self.aiment)
		if(other.aiment.classname == "player")
			if(PLAYER_IS_INDEPENDENT(other.aiment) || PLAYER_IS_INDEPENDENT(self.aiment))
				return; // cannot go through someone else's portal

	self.angles_x = -self.angles_x;
	makevectors(self.angles);
	self.angles_x = -self.angles_x;
	g = frametime * '0 0 -1' * cvar("sv_gravity");
	if (!portal_will_hit_plane(other.origin, other.mins, other.maxs, other.velocity + g, self.origin, v_forward, self.maxs_x))
		return;

	portal_teleport_player(self, other);
}

void(entity portal) portal_make_broken_portal {
	portal.skin = 2;
	portal.solid = SOLID_NOT;
	portal.touch = stdproc_nothing;
	portal.think = stdproc_nothing;
	portal.effects = 0;
	portal.nextthink = 0;
	portal.takedamage = DAMAGE_NO;
}

void(entity portal) portal_make_waiting_portal {
	portal.skin = 2;
	portal.solid = SOLID_NOT;
	portal.touch = stdproc_nothing;
	portal.think = stdproc_nothing;
	portal.effects = EFFECT_ADDITIVE;
	portal.nextthink = 0;
	portal.takedamage = DAMAGE_YES;
}

void(void) portal_think;
void(entity portal) portal_make_in_portal {
	portal.skin = 0;
	portal.solid = SOLID_NOT; // this is done when connecting them!
	portal.touch = portal_touch;
	portal.think = portal_think;
	portal.effects = EFFECT_RED;
	portal.nextthink = time;
	portal.takedamage = DAMAGE_NO;
}

void(entity portal) portal_make_out_portal {
	portal.skin = 1;
	portal.solid = SOLID_NOT;
	portal.touch = stdproc_nothing;
	portal.think = stdproc_nothing;
	portal.effects = EFFECT_STARDUST | EFFECT_BLUE;
	portal.nextthink = 0;
	portal.takedamage = DAMAGE_YES;
}

void(entity teleporter, entity destination) portal_disconnect {
	teleporter.enemy = world;
	destination.enemy = world;
	portal_make_broken_portal(teleporter);
	portal_make_broken_portal(destination);
}

float portal_counter;
void(entity teleporter, entity destination) portal_connect {
	vector a = destination.angles + '0 180 0';
	teleporter.angles_x = -teleporter.angles_x;
	teleporter.portal_transform = anglestransform_multiply(a, anglestransform_invert(teleporter.angles));
	teleporter.angles_x = -teleporter.angles_x;
	teleporter.enemy = destination;
	destination.enemy = teleporter;
	portal_make_in_portal(teleporter);
	portal_make_out_portal(destination);
	if (portal_counter > 1000000) portal_counter = 0;
	portal_counter = teleporter.portal_id = destination.portal_id = portal_counter + 1;
	teleporter.nextthink = time + cvar("g_balance_portal_lifetime");
	destination.nextthink = teleporter.nextthink;
	teleporter.portal_wants_to_vanish = 0;
	destination.portal_wants_to_vanish = 0;
	teleporter.teleport_time = time;
	teleporter.solid = SOLID_TRIGGER;
}

void(entity portal, float killed) portal_remove {
	entity e;
	e = portal.enemy;
	if (e) {
		portal_disconnect(portal, e);
		portal_remove(e, killed);
	}
	if (portal == portal.aiment.portal_in)
		portal.aiment.portal_in = world;

	if (portal == portal.aiment.portal_out)
		portal.aiment.portal_out = world;

	//portal.aiment = world;
	// makes the portal vanish
	if (killed) {
		makevectors(portal.angles);
		sound(portal, CHAN_PROJECTILE, "porto/explode.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("rocket_explode"), portal.origin + v_forward * 16, v_forward * 1024, 4);
		remove(portal);
	} else {
		portal_make_broken_portal(portal);
		sound(portal, CHAN_PROJECTILE, "porto/expire.wav", VOL_BASE, ATTN_NORM);
		entity_fade_setup(portal, time, 0.5);
	}
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) portal_damage {
	if (deathtype == WEAPON_PORTO)
		return;

	if (attacker != self.aiment)
		if(PLAYER_IS_INDEPENDENT(attacker) || PLAYER_IS_INDEPENDENT(self.aiment))
			return;

	self.health -= _damage;
	if (self.health < 0)
		portal_remove(self, 1);
}

void(void) portal_think {
	portal_remove(self, 0);
}

float(void) portal_customize {
	if (other.classname == "spectator")
		other = other.enemy;

	if (other == self.aiment) {
		self.modelindex = self.modelindex_lod0;
	} else if (PLAYER_IS_INDEPENDENT(other) || PLAYER_IS_INDEPENDENT(self.aiment)) {
		self.modelindex = 0;
	} else {
		self.modelindex = self.modelindex_lod0;
	}
	return TRUE;
}

// cleanup:
//   when creating in-portal:
//     disconnect
//     clear existing in-portal
//     set as in-portal
//     connect
//   when creating out-portal:
//     disconnect
//     clear existing out-portal
//     set as out-portal
//   when player dies:
//     disconnect portals
//     clear both portals
//   after timeout of in-portal:
//     disconnect portals
//     clear both portals
//   TODO: ensure only one portal shot at once
float(entity own, entity portal) portal_set_in_portal {
	if (own.portal_in) {
		if (own.portal_out)
			portal_disconnect(own.portal_in, own.portal_out);

		portal_remove(own.portal_in, 0);
	}
	own.portal_in = portal;
	if (own.portal_out) {
		portal_connect(own.portal_in, own.portal_out);
	}
	return 2;
}

float(entity own, entity portal) portal_set_out_portal {
	if (own.portal_out) {
		if (own.portal_in)
			portal_disconnect(own.portal_in, own.portal_out);

		portal_remove(own.portal_out, 0);
	}
	own.portal_out = portal;
	if (own.portal_in) {
		portal_connect(own.portal_in, own.portal_out);
	}
	return 1;
}
void(entity own) portal_clear_all_portals_only {
	if (own.portal_in)
		portal_remove(own.portal_in, 0);

	if (own.portal_out)
		portal_remove(own.portal_out, 0);
}

void(entity own) portal_clear_all {
	portal_clear_all_portals_only(own);
}

void(void) portal_remove_later_think {
	portal_remove(self, self.cnt);
}

void(entity portal, float kill) portal_remove_later {
	portal_make_broken_portal(portal);
	portal.cnt = kill;
	portal.think = portal_remove_later_think;
	portal.nextthink = time;
}

void(entity own) portal_clear_all_later_portals_only {
	if(own.portal_in)
		portal_remove_later(own.portal_in, 0);
	if(own.portal_out)
		portal_remove_later(own.portal_out, 0);
}
void(entity own) portal_clear_all_later {
	portal_clear_all_later_portals_only(own);
}

entity(entity own, vector org, vector ang) portal_spawn {
	entity portal;
	ang_x = -ang_x;
	makevectors(ang);
	ang_x = -ang_x;
	if (!portal_check_wire_frame_box(own, org - 48 * v_right - 48 * v_up + 16 * v_forward, 96 * v_right, 96 * v_up, 96 * v_forward))
		return world;

	portal = spawn();
	portal.classname = "portal";
	portal.aiment = own;
	setorigin(portal, org);
	portal.angles = ang;
	portal.think = portal_think;
	portal.nextthink = 0;
	portal.portal_activatetime = time + 0.1;
	portal.takedamage = DAMAGE_AIM;
	portal.event_damage = portal_damage;
	portal.nextthink = time + cvar("g_balance_portal_lifetime");
	portal.health = cvar("g_balance_portal_health");
	setmodel(portal, "models/portal.md3");
	portal.modelindex_lod0 = portal.modelindex;
	portal.customizeentityforclient = portal_customize;
	if (!portal_find_save_origin(portal)) {
		remove(portal);
		return world;
	}
	setsize(portal, '-48 -48 -48', '48 48 48');
	portal_make_waiting_portal(portal);
	return portal;
}

float(entity own, vector dir) portal_spawn_in_portal_at_trace {
	entity portal;
	vector ang;
	vector org;
	org = trace_endpos;
	ang = vectoangles(trace_plane_normal, dir);
	portal = portal_spawn(own, org, ang);
	if (!portal)
		return 0;

	portal_set_in_portal(own, portal);
	return 1;
}

float(entity own, vector dir) portal_spawn_out_portal_at_trace {
	entity portal;
	vector ang;
	vector org;
	org = trace_endpos;
	ang = vectoangles(trace_plane_normal, dir);
	portal = portal_spawn(own, org, ang);
	if (!portal) {
		portal_clear_all_portals_only(own);

		return 0;
	}
	portal_set_out_portal(own, portal);
	return 1;
}
