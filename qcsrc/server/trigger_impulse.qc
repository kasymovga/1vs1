// tZorks trigger impulse / gravity
.float falloff;
.float strength;

float trigger_impulse_frametime;
float (entity e) trigger_impulse_affected {
	if not(e.iscreature)
	if not(e.flags & FL_PROJECTILE)
	if (e.movetype != MOVETYPE_TOSS)
		return FALSE;

	if (e.deadflag && e.iscreature)
		return FALSE;

	if (clienttype(other) == CLIENTTYPE_REAL ||
			(other.owner && player_entity(other.owner) == other &&
			clienttype(other.owner) == CLIENTTYPE_REAL)) { // real player or vehicle with real player
		trigger_impulse_frametime = (physics_current_player ? physics_frametime : 0);
	} else
		trigger_impulse_frametime = frametime;

	return trigger_impulse_frametime > 0;
}

// targeted (directional) mode
void(void) trigger_impulse_touch1 {
	if not(trigger_impulse_affected(other))
		return;

	TRIGGER_EXACT_TOUCH;
	other.velocity = other.velocity + normalize(self.enemy.origin - self.origin) * self.strength * trigger_impulse_frametime;
	other.flags &= ~FL_ONGROUND;
}

// Directionless (accelerator/decelerator) mode
void(void) trigger_impulse_touch2 {
	if not(trigger_impulse_affected(other))
		return;

	TRIGGER_EXACT_TOUCH;
	// div0: ticrate independent, 1 = identity (not 20)
	other.velocity = other.velocity * pow(self.strength, trigger_impulse_frametime);
}

// Spherical (gravity/repulsor) mode
void(void) trigger_impulse_touch3 {
	float str;
	if not(trigger_impulse_affected(other))
		return;

	vector o = ENTITY_CENTER(other);
	TRIGGER_EXACT_TOUCH;
	setsize(self, '-1 -1 -1' * self.radius,'1 1 1' * self.radius);
	str = min(self.radius, vlen(self.origin - o));
	if (self.falloff == 1)
		str = (1 - str / self.radius) * self.strength; // 1 in the inside
	else if (self.falloff == 2)
		str = (str / self.radius) * self.strength; // 0 in the inside
	else
		str = self.strength;

	other.velocity = other.velocity + normalize(o - self.origin) * str * trigger_impulse_frametime;
}

float(entity to, float sf) trigger_impulse_prediction_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_TRIGGER_IMPULSE_PREDICTION);
	net_write_coord(MSG_ENTITY, self.modelindex);
	net_write_coord(MSG_ENTITY, self.origin_x);
	net_write_coord(MSG_ENTITY, self.origin_y);
	net_write_coord(MSG_ENTITY, self.origin_z);
	net_write_coord(MSG_ENTITY, self.mins_x);
	net_write_coord(MSG_ENTITY, self.mins_y);
	net_write_coord(MSG_ENTITY, self.mins_z);
	net_write_coord(MSG_ENTITY, self.maxs_x);
	net_write_coord(MSG_ENTITY, self.maxs_y);
	net_write_coord(MSG_ENTITY, self.maxs_z);
	if (self.touch == trigger_impulse_touch1) {
		net_write_byte(MSG_ENTITY, 1);
		net_write_coord(MSG_ENTITY, self.enemy.origin_x);
		net_write_coord(MSG_ENTITY, self.enemy.origin_y);
		net_write_coord(MSG_ENTITY, self.enemy.origin_z);
	} else if (self.touch == trigger_impulse_touch2) {
		net_write_byte(MSG_ENTITY, 2);
	} else {
		net_write_byte(MSG_ENTITY, 3);
		net_write_coord(MSG_ENTITY, self.radius);
		net_write_coord(MSG_ENTITY, self.falloff);
	}
	net_write_coord(MSG_ENTITY, self.strength);
	return TRUE;
}

void(void) trigger_impulse_finalize {
	if (cvar("g_trigger_impulse_prediction")) {
		net_link_entity(self, TRUE, 0, trigger_impulse_prediction_send);
	}
}

void(void) trigger_impulse_find_target {
	self.enemy = find(NULL, targetname, self.target);
	if not(self.enemy) {
		entity_abort("trigger_impulse: target entity not found");
		return;
	}
	self.touch = trigger_impulse_touch1;
	trigger_impulse_finalize();
}

/*QUAKED spawnfunc_trigger_impulse (.5 .5 .5) ?
-------- KEYS --------
target : If this is set, this points to the spawnfunc_target_position to which the player will get pushed.
         If not, this trigger acts like a damper/accelerator field.

strength : This is how mutch force to add in the direction of .target each second
           when .target is set. If not, this is hoe mutch to slow down/accelerate
           someting cought inside this trigger. (1=no change, 0,5 half speed rougthly each tic, 2 = doubble)

radius   : If set, act as a spherical device rather then a liniar one.

falloff : 0 = none, 1 = liniar, 2 = inverted liniar

-------- NOTES --------
Use a brush textured with common/origin in the trigger entity to determine the origin of the force
in directional and sperical mode. For damper/accelerator mode this is not nessesary (and has no effect).
*/
void(void) spawnfunc_trigger_impulse {
	trigger_solid_brush_init();
	if (self.target != "") {
		if (!self.strength) self.strength = 950 * cvar("g_triggerimpulse_directional_multiplier");
		entity_initialize(self, trigger_impulse_find_target, INITPRIO_FINDTARGET);
	} else {
		if (self.radius) {
			if (!self.strength) self.strength = 2000 * cvar("g_triggerimpulse_radial_multiplier");
			setorigin(self, self.origin);
			setsize(self, '-1 -1 -1' * self.radius,'1 1 1' * self.radius);
			self.touch = trigger_impulse_touch3;
			trigger_impulse_finalize();
		} else {
			if (!self.strength) self.strength = 0.9;
			self.strength = pow(self.strength, cvar("g_triggerimpulse_accel_power")) * cvar("g_triggerimpulse_accel_multiplier");
			self.touch = trigger_impulse_touch2;
			trigger_impulse_finalize();
		}
	}
}

