// tZorks trigger impulse / gravity
.float falloff;
.float strength;

float (entity e) trigger_impulse_affected {
	if not(other.iscreature)
	if not(other.flags & FL_PROJECTILE)
	if (other.movetype != MOVETYPE_TOSS)
		return FALSE;

	return TRUE;
}

// targeted (directional) mode
void(void) trigger_impulse_touch1 {
	float pushdeltatime;
	float str = 0;
	// FIXME: Better checking for what to push and not.
	if not(trigger_impulse_affected(other))
		return;

	if (other.deadflag && other.iscreature)
		return;

	TRIGGER_EXACT_TOUCH;
	if (self.falloff == 1)
		str = (str / self.radius) * self.strength;
	else if (self.falloff == 2)
		str = (1 - (str / self.radius)) * self.strength;
	else
		str = self.strength;

	pushdeltatime = time - other.lastpushtime;
	if (pushdeltatime > 0.15) pushdeltatime = 0;
	other.lastpushtime = time;
	if (!pushdeltatime) return;
	other.velocity = other.velocity + normalize(self.enemy.origin - self.origin) * str * pushdeltatime;
	other.flags &= ~FL_ONGROUND;
}

// Directionless (accelerator/decelerator) mode
void(void) trigger_impulse_touch2 {
	float pushdeltatime;
	// FIXME: Better checking for what to push and not.
	if not(trigger_impulse_affected(other))
		return;

	if (other.deadflag && other.iscreature)
		return;

	TRIGGER_EXACT_TOUCH;
	pushdeltatime = time - other.lastpushtime;
	if (pushdeltatime > 0.15) pushdeltatime = 0;
	other.lastpushtime = time;
	if (!pushdeltatime) return;
	// div0: ticrate independent, 1 = identity (not 20)
	other.velocity = other.velocity * pow(self.strength, pushdeltatime);
}

// Spherical (gravity/repulsor) mode
void(void) trigger_impulse_touch3 {
	float pushdeltatime;
	float str;
	// FIXME: Better checking for what to push and not.
	if not(trigger_impulse_affected(other))
		return;

	if (other.deadflag && other.iscreature)
		return;

	TRIGGER_EXACT_TOUCH;
	pushdeltatime = time - other.lastpushtime;
	if (pushdeltatime > 0.15) pushdeltatime = 0;
	other.lastpushtime = time;
	if (!pushdeltatime) return;
	setsize(self, '-1 -1 -1' * self.radius,'1 1 1' * self.radius);
	str = min(self.radius, vlen(self.origin - other.origin));
	if (self.falloff == 1)
		str = (1 - str / self.radius) * self.strength; // 1 in the inside
	else if (self.falloff == 2)
		str = (str / self.radius) * self.strength; // 0 in the inside
	else
		str = self.strength;

	other.velocity = other.velocity + normalize(other.origin - self.origin) * str * pushdeltatime;
}

void(void) trigger_impulse_find_target {
	self.enemy = find(NULL, targetname, self.target);
	if not(self.enemy) {
		entity_abort("trigger_impulse: target entity not found");
		return;
	}
	self.touch = trigger_impulse_touch1;
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
	if (self.radius) {
		if (!self.strength) self.strength = 2000 * cvar("g_triggerimpulse_radial_multiplier");
		setorigin(self, self.origin);
		setsize(self, '-1 -1 -1' * self.radius,'1 1 1' * self.radius);
		self.touch = trigger_impulse_touch3;
	} else {
		if (self.target != "") {
			if (!self.strength) self.strength = 950 * cvar("g_triggerimpulse_directional_multiplier");
			entity_initialize(self, trigger_impulse_find_target, INITPRIO_FINDTARGET);
		} else {
			if (!self.strength) self.strength = 0.9;
			self.strength = pow(self.strength, cvar("g_triggerimpulse_accel_power")) * cvar("g_triggerimpulse_accel_multiplier");
			self.touch = trigger_impulse_touch2;
		}
	}
}

