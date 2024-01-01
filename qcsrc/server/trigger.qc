float g_trigger_collisions_exact;
float g_trigger_collisions_exact_extend;
vector trigger_exact_hit_mins;
vector trigger_exact_hit_maxs;
float(void) trigger_exact_hit_recurse {
	float s;
	entity se;
	float f;
	trace_box('0 0 0', trigger_exact_hit_mins, trigger_exact_hit_maxs, '0 0 0', TRACE_MOVE_NORMAL, other);
	if not(trace_ent)
		return 0;

	if (trace_ent == self)
		return 1;

	se = trace_ent;
	s = se.solid;
	se.solid = SOLID_NOT;
	f = trigger_exact_hit_recurse();
	se.solid = s;
	return f;
}

float(void) trigger_exact_hit {
	float f, s;
	if not(self.modelindex)
		return 1;

	s = self.solid;
	self.solid = SOLID_BSP;
	trigger_exact_hit_mins = other.mins + other.origin + (g_trigger_collisions_exact_extend ? '-1 -1 -1' : '0 0 0');
	trigger_exact_hit_maxs = other.maxs + other.origin + (g_trigger_collisions_exact_extend ? '1 1 1' : '0 0 0');
	if (g_trigger_collisions_exact > 1) {
		string dir = cvar_string("collision_triangle_directional");
		cvar_set("collision_triangle_directional", "0");
		f = trigger_exact_hit_recurse();
		cvar_set("collision_triangle_directional", dir);
	} else
		f = trigger_exact_hit_recurse();

	self.solid = s;
	return f;
}

float trigger_solid_brush_init_done;
void(void) trigger_solid_brush_init {
	if not(trigger_solid_brush_init_done) {
		trigger_solid_brush_init_done = TRUE;
		CVAR_CACHE(g_trigger_collisions_exact);
		CVAR_CACHE(g_trigger_collisions_exact_extend);
	}
	// trigger angles are used for one-way touches.  An angle of 0 is assumed
	// to mean no restrictions, so use a yaw of 360 instead.
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		entity_movedir_setup();

	model_setup();
	self.movetype = MOVETYPE_NONE; // why was this PUSH? -div0
	if (!g_trigger_collisions_exact || self.solid < 0)
		self.modelindex = 0;

	self.model = "";
	self.solid = SOLID_TRIGGER;
}

void() trigger_dont_use_targets { }

void(void) trigger_delay_think {
	activator = self.enemy;
	trigger_use_targets();
	remove(self);
}

float trigger_foreachtarget_callid;
.float targethandled;

void(entity s, float(entity, float, vector, string, entity) cback, float recursive, float fdata, vector vdata, string sdata, entity edata) trigger_for_each_target_recurse {
	float i;
	string targname = "";
	entity targ;
	if (trigger_foreachtarget_callid < 1)
		trigger_foreachtarget_callid = 1;

	for (i = 0; i < 4; ++i) {
		switch (i) {
			case 0: targname = s.target ; break;
			case 1: targname = s.target2; break;
			case 2: targname = s.target3; break;
			case 3: targname = s.target4; break;
		}

		if (targname != "") {
			for (targ = world; (targ = find(targ, targetname, targname));)
			if (targ && targ.targethandled != trigger_foreachtarget_callid) {
				if (cback(targ, fdata, vdata, sdata, edata))
					return;

				targ.targethandled = trigger_foreachtarget_callid;

				if (recursive)
					trigger_for_each_target_recurse(targ, cback, recursive, fdata, vdata, sdata, edata);
			}
		}
	}
}

void trigger_for_each_target(entity s, float(entity, float, vector, string, entity) cback, float recursive, float fdata, vector vdata, string sdata, entity edata) {
	trigger_foreachtarget_callid++;
	trigger_for_each_target_recurse(s, cback, recursive, fdata, vdata, sdata, edata);
}

entity trigger_linktargets_ent;
entity trigger_linktargets_first;
var .entity linktargets_fld;
float(entity targ, float _f, vector _v, string _s, entity _e) trigger_link_targets_add {
	if (trigger_linktargets_ent)
		trigger_linktargets_ent.linktargets_fld = targ;
	else
		trigger_linktargets_first = targ;

	trigger_linktargets_ent = targ;
	return FALSE;
}

entity(entity ent, .entity fld, float recursive) trigger_link_targets {
	trigger_linktargets_ent = world;
	trigger_linktargets_first = world;
	linktargets_fld = fld;
	trigger_for_each_target(ent, trigger_link_targets_add, recursive, NULL, NULL, NULL, NULL);
	if (trigger_linktargets_ent)
		trigger_linktargets_ent.fld = world;

	return trigger_linktargets_first;
}

/*
==============================
trigger_use_targets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the trigger_use_targets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/

.float sub_target_used;

void(float preventReuse) trigger_use_targets_ex {
	entity t, stemp, otemp, act;
	string s;
	float i;
	//
	// check for a delay
	//
	if (self.delay) {
		// create a temp object to fire at a later time
		t = spawn();
		t.classname = "DelayedUse";
		t.nextthink = time + self.delay;
		t.think = trigger_delay_think;
		t.enemy = activator;
		t.message = self.message;
		t.killtarget = self.killtarget;
		t.target = self.target;
		t.target2 = self.target2;
		t.target3 = self.target3;
		t.target4 = self.target4;
		if (entity_per_player_entities) {
			if (clienttype(activator) != CLIENTTYPE_NOTACLIENT) {
				t.existsonlyfor = activator;
			} else
				t.existsonlyfor = self.existsonlyfor;
		}
		t.reset = stdproc_remove;
		return;
	}
	//
	// print the message
	//
	if (activator.classname == "player" && self.message != "") {
		if (clienttype(activator) == CLIENTTYPE_REAL) {
			centerprint (activator, self.message);
			if (!self.noise)
				sound_play2(activator, "misc/talk.wav");
		}
	}
	//
	// kill the killtagets
	//
	s = self.killtarget;
	if (s != "") {
		for (t = world; (t = find(t, targetname, s)); )
			remove(t);
	}
	//
	// fire targets
	//
	act = activator;
	stemp = self;
	otemp = other;
	for (i = 0; i < 4; ++i) {
		switch (i) {
		default:
		case 0: s = stemp.target; break;
		case 1: s = stemp.target2; break;
		case 2: s = stemp.target3; break;
		case 3: s = stemp.target4; break;
		}
		if (s != "") {
			for (t = world; (t = find(t, targetname, s)); ) {
				if (t.existsonlyfor) {
					if (stemp.existsonlyfor && t.existsonlyfor != stemp.existsonlyfor) continue;
					if (act != t.existsonlyfor) continue;
				}
				if (t.use && (t.sub_target_used != time || !preventReuse)) {
					self = t;
					other = otemp;
					activator = act;
					//print(act.classname, "#", ftos(num_for_edict(act)), ": ");
					//print(stemp.classname, "/", stemp.targetname, " -> ", t.classname, "/", t.targetname, "\n");
					self.use();
					if (preventReuse) {
						self.sub_target_used = time;
					}
				}
			}
		}
	}
	activator = act;
	self = stemp;
	other = otemp;
}

float trigger_use_targets_depth;
void(void) trigger_use_targets {
	if (trigger_use_targets_depth > 32) {
		print("------------------------------------------------------\n");
		print("trigger_use_targets: too much recursive calls, aborted\n");
		print("    self.classname=", self.classname ,"\n");
		print("    self.netname=", self.netname ,"\n");
		print("    self.targetname=", self.targetname ,"\n");
		print("    self.target=", self.target ,"\n");
		print("    other.classname=", other.classname ,"\n");
		print("    other.netname=", other.netname ,"\n");
		print("    other.targetname=", other.targetname ,"\n");
		print("    other.target=", other.target ,"\n");
		print("    activator.classname=", other.classname ,"\n");
		print("    activator.netname=", other.netname ,"\n");
		print("    activator.targetname=", other.targetname ,"\n");
		print("    activator.target=", other.target ,"\n");
		print("------------------------------------------------------\n");
		return;
	}
	trigger_use_targets_depth++;
	trigger_use_targets_ex(FALSE);
	trigger_use_targets_depth--;
}

void trigger_use_targets_prevent_reuse() {
	trigger_use_targets_ex(TRUE);
}

float TRIGGER_SPAWNFLAG_NOMESSAGE = 1;
float TRIGGER_SPAWNFLAG_NOTOUCH = 1;
float TRIGGER_SPAWNFLAG_NOCREATUREONLY = 2;
float TRIGGER_SPAWNFLAG_PLAYERONLY = 4;

// the wait time has passed, so set back up for another activation
void(void) trigger_multiple_wait {
	if (self.max_health) {
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
}

// the trigger was just touched/killed/used
// self.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void(void) trigger_multiple_fire {
	if (self.nextthink > time) {
		return; // allready been triggered
	}
	if (self.noise != "")
		sound(self.enemy, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NORM);

	// don't trigger again until reset
	self.takedamage = DAMAGE_NO;
	activator = self.enemy;
	other = self.goalentity;
	trigger_use_targets();
	if (self.wait > 0) {
		self.think = trigger_multiple_wait;
		self.nextthink = time + self.wait;
	} else if not(self.classname == "trigger_multiple") {
		self.touch = stdproc_nothing;
		self.use = stdproc_nothing;
	}
}

void(void) trigger_multiple_use {
	self.goalentity = other;
	self.enemy = activator;
	trigger_multiple_fire();
}

void(void) trigger_multiple_touch {
	if (self.spawnflags & TRIGGER_SPAWNFLAG_PLAYERONLY || !(self.spawnflags & TRIGGER_SPAWNFLAG_NOCREATUREONLY)) {
		if not(self.spawnflags & TRIGGER_SPAWNFLAG_NOCREATUREONLY) {
			if not(other.iscreature)
				return;

			if (self.team)
			if (self.team == other.team)
				return;
		}
		if (self.spawnflags & TRIGGER_SPAWNFLAG_PLAYERONLY)
		if (other.classname != "player")
			return;

		if (other.health < 1)
			return;
	}
	// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0') {
		makevectors (other.angles);
		if (v_forward * self.movedir < 0)
			return;		// not facing the right way
	}
	TRIGGER_EXACT_TOUCH;
	self.enemy = other;
	self.goalentity = other;
	trigger_multiple_fire ();
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) trigger_multiple_eventdamage {
	if (!self.takedamage)
		return;

	self.health = self.health - _damage;
	if (self.health <= 0) {
		self.enemy = attacker;
		self.goalentity = inflictor;
		trigger_multiple_fire();
	}
}

void(void) trigger_multiple_reset {
	if (!(self.spawnflags & TRIGGER_SPAWNFLAG_NOTOUCH))
		self.touch = trigger_multiple_touch;

	if (self.max_health) {
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
	self.think = stdproc_nothing;
	self.use = trigger_multiple_use;
	self.team = self.team_saved;
	self.nextthink = 0;
}

/*QUAKED spawnfunc_trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by spawnfunc_trigger_relay!
sounds
1) secret
2) beep beep
3) large switch
4)
set "message" to text string
*/
void(void) spawnfunc_trigger_multiple {
	self.reset = trigger_multiple_reset;
	if (self.noise == "") {
		if (self.sounds == 1) {
			self.noise = "misc/strength_respawn.wav";
		} else if (self.sounds == 2) {
			self.noise = "misc/talk.wav";
		} else if (self.sounds == 3) {
			self.noise = "misc/menu1.wav";
		}
	}
	if (self.noise != "")
		precache_sound(self.noise);

	if (!self.wait)
		self.wait = cvar("g_trigger_wait_default");

	if (self.wait < 0 && cvar("g_trigger_negative_wait_is_never"))
		self.wait = 999999;

	self.use = trigger_multiple_use;
	trigger_solid_brush_init();
	self.team_saved = self.team;
	if (self.health) {
		if (self.spawnflags & TRIGGER_SPAWNFLAG_NOTOUCH) {
			entity_abort("health and notouch don't make sense\n");
			return;
		}
		self.max_health = self.health;
		self.event_damage = trigger_multiple_eventdamage;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin (self, self.origin);	// make sure it links into the world
	} else {
		if (!(self.spawnflags & TRIGGER_SPAWNFLAG_NOTOUCH)) {
			self.touch = trigger_multiple_touch;
			setorigin (self, self.origin);	// make sure it links into the world
		}
	}
}


/*QUAKED spawnfunc_trigger_once (.5 .5 .5) ? notouch
Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
"targetname".  If "health" is set, the trigger must be killed to activate.
If notouch is set, the trigger is only fired by other entities, not by touching.
if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
sounds
1) secret
2) beep beep
3) large switch
4)
set "message" to text string
*/
void(void) spawnfunc_trigger_once {
	self.wait = -1;
	spawnfunc_trigger_multiple();
}

//=============================================================================

/*QUAKED spawnfunc_trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
void(void) spawnfunc_trigger_relay {
	self.use = trigger_use_targets;
}

void(void) spawnfunc_trigger_delay {
	if (!self.wait)
		self.wait = 1;

	self.delay = self.wait;
	self.wait = 0;
	self.use = trigger_use_targets;
}

void(void) trigger_counter_use {
	ENTITY_PER_PLAYER_FORCE();
	self.count = self.count - 1;
	if (self.count < 0)
		return;

	if (self.count != 0) {
		if (activator.classname == "player"
				&& (self.spawnflags & TRIGGER_SPAWNFLAG_NOMESSAGE) == 0) {
			if (self.count >= 4)
				centerprint (activator, "There are more to go...");
			else if (self.count == 3)
				centerprint (activator, "Only 3 more to go...");
			else if (self.count == 2)
				centerprint (activator, "Only 2 more to go...");
			else
				centerprint (activator, "Only 1 more to go...");
		}
		return;
	}
	if (activator.classname == "player"
	&& (self.spawnflags & TRIGGER_SPAWNFLAG_NOMESSAGE) == 0)
		centerprint(activator, "Sequence completed!");

	self.enemy = activator;
	trigger_multiple_fire ();
}

void(void) trigger_counter_reset {
	self.count = self.cnt;
	trigger_multiple_reset();
}

/*QUAKED spawnfunc_trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/
void(void) spawnfunc_trigger_counter {
	self.wait = -1;
	if (!self.count)
		self.count = 2;
	self.cnt = self.count;

	self.use = trigger_counter_use;
	self.reset = trigger_counter_reset;
}

float g_trigger_hurt_interval;
.float triggerhurttime;
void(void) trigger_hurt_touch {
	// only do the TRIGGER_EXACT_TOUCH checks when really needed (saves some cpu)
	if (other.takedamage)
	if not(other.flags & FL_PROJECTILE)
	if (other.triggerhurttime < time) {
		TRIGGER_EXACT_TOUCH;
		other.triggerhurttime = time + g_trigger_hurt_interval;
		damage(other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');
	}
	return;
}

/*QUAKED spawnfunc_trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
defalt dmg = 5
*/
.entity trigger_hurt_next;
entity trigger_hurt_last;
entity trigger_hurt_first;
void(void) spawnfunc_trigger_hurt {
	ENTITY_NOT_PER_PLAYER();
	trigger_solid_brush_init();
	self.touch = trigger_hurt_touch;
	if (!self.dmg)
		self.dmg = 1000;

	if (!self.message)
		self.message = "was in the wrong place";

	if (!self.message2)
		self.message2 = "was thrown into a world of hurt by";

	if (!trigger_hurt_first)
		trigger_hurt_first = self;

	if (trigger_hurt_last)
		trigger_hurt_last.trigger_hurt_next = self;

	CVAR_CACHE(g_trigger_hurt_interval);
	trigger_hurt_last = self;
}

float(vector start, vector mi, vector ma, vector end) trigger_tracebox_hits_hurt {
	entity th;
	for (th = trigger_hurt_first; th; th = th.trigger_hurt_next)
		if (trace_box_hits_box(start, mi, ma, end, th.absmin, th.absmax))
			return TRUE;

	return FALSE;
}

.float triggerhealtime;
void(void) trigger_heal_touch {
	// only do the TRIGGER_EXACT_TOUCH checks when really needed (saves some cpu)
	if (other.iscreature) {
		if (other.takedamage)
		if (other.triggerhealtime < time) {
			TRIGGER_EXACT_TOUCH;
			other.triggerhealtime = time + 1;
			if (other.health < self.max_health) {
				other.health = min(other.health + self.health, self.max_health);
				other.pauserothealth_finished = max(other.pauserothealth_finished, time + g_balance_pause_health_rot);
				sound (other, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NORM);
			}
		}
	}
}

void(void) spawnfunc_trigger_heal {
	trigger_solid_brush_init();
	self.touch = trigger_heal_touch;
	if (!self.health)
		self.health = 10;

	if (!self.max_health)
		self.max_health = 200; //Max health topoff for field

	if (self.noise == "")
		self.noise = "misc/mediumhealth.wav";

	precache_sound(self.noise);
}

// tZorks trigger impulse / gravity
.float radius;
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
	entity targ;
	float pushdeltatime;
	float str = 0;
	// FIXME: Better checking for what to push and not.
	if not(trigger_impulse_affected(other))
		return;

	if (other.deadflag && other.iscreature)
		return;

	TRIGGER_EXACT_TOUCH;
	targ = find(world, targetname, self.target);
	if (!targ) {
		entity_abort("trigger_force without a (valid) .target!\n");
		return;
	}
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
	other.velocity = other.velocity + normalize(targ.origin - self.origin) * str * pushdeltatime;
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
		if (self.target) {
			if (!self.strength) self.strength = 950 * cvar("g_triggerimpulse_directional_multiplier");
			self.touch = trigger_impulse_touch1;
		} else {
			if (!self.strength) self.strength = 0.9;
			self.strength = pow(self.strength, cvar("g_triggerimpulse_accel_power")) * cvar("g_triggerimpulse_accel_multiplier");
			self.touch = trigger_impulse_touch2;
		}
	}
}

/*QUAKED spawnfunc_trigger_flipflop (.5 .5 .5) (-8 -8 -8) (8 8 8) START_ENABLED
"Flip-flop" trigger gate... lets only every second trigger event through
*/
void(void) trigger_flipflop_use {
	self.state = !self.state;
	if (self.state)
		trigger_use_targets();
}

void(void) spawnfunc_trigger_flipflop {
	if (self.spawnflags & 1)
		self.state = 1;

	self.use = trigger_flipflop_use;
	self.reset = spawnfunc_trigger_flipflop; // perfect resetter
}

/*QUAKED spawnfunc_trigger_monoflop (.5 .5 .5) (-8 -8 -8) (8 8 8)
"Mono-flop" trigger gate... turns one trigger event into one "on" and one "off" event, separated by a delay of "wait"
*/
void(void) trigger_monoflop_use {
	self.nextthink = time + self.wait;
	self.enemy = activator;
	if (self.state)
		return;
	self.state = 1;
	trigger_use_targets();
}

void(void) trigger_monoflop_fixed_use {
	if (self.state)
		return;

	self.nextthink = time + self.wait;
	self.state = 1;
	self.enemy = activator;
	trigger_use_targets();
}

void(void) trigger_monoflop_think {
	self.state = 0;
	activator = self.enemy;
	trigger_use_targets();
}

void(void) trigger_monoflop_reset {
	self.state = 0;
	self.nextthink = 0;
}

void(void) spawnfunc_trigger_monoflop {
	if (!self.wait)
		self.wait = 1;

	if (self.spawnflags & 1)
		self.use = trigger_monoflop_fixed_use;
	else
		self.use = trigger_monoflop_use;

	self.think = trigger_monoflop_think;
	self.state = 0;
	self.reset = trigger_monoflop_reset;
}

void(void) trigger_multivibrator_send {
	float newstate;
	float cyclestart;
	cyclestart = floor((time + self.phase) / (self.wait + self.respawntime)) * (self.wait + self.respawntime) - self.phase;
	newstate = (time < cyclestart + self.wait);
	activator = self;
	if (self.state != newstate)
		trigger_use_targets();

	self.state = newstate;
	if (self.state)
		self.nextthink = cyclestart + self.wait + 0.01;
	else
		self.nextthink = cyclestart + self.wait + self.respawntime + 0.01;
}

void(void) trigger_multivibrator_toggle {
	if (self.nextthink == 0) {
		trigger_multivibrator_send();
	} else {
		if (self.state) {
			trigger_use_targets();
			self.state = 0;
		}
		self.nextthink = 0;
	}
}

void(void) trigger_multivibrator_reset {
	if (!(self.spawnflags & 1))
		self.nextthink = 0; // wait for a trigger event
	else
		self.nextthink = max(1, time);
}

/*QUAKED trigger_multivibrator (.5 .5 .5) (-8 -8 -8) (8 8 8) START_ON
"Multivibrator" trigger gate... repeatedly sends trigger events. When triggered, turns on or off.
-------- KEYS --------
target: trigger all entities with this targetname when it goes off
targetname: name that identifies this entity so it can be triggered; when off, it always uses the OFF state
phase: offset of the timing
wait: "on" cycle time (default: 1)
respawntime: "off" cycle time (default: same as wait)
-------- SPAWNFLAGS --------
START_ON: assume it is already turned on (when targeted)
*/
void(void) spawnfunc_trigger_multivibrator {
	if (!self.wait)
		self.wait = 1;

	if (!self.respawntime)
		self.respawntime = self.wait;

	self.state = 0;
	self.use = trigger_multivibrator_toggle;
	self.think = trigger_multivibrator_send;
	self.nextthink = time;
	IFTARGETED
		trigger_multivibrator_reset();
}


void(void) trigger_gamestart_use {
	activator = self;
	trigger_use_targets();
	remove(self);
}

void(void) spawnfunc_trigger_gamestart {
	self.use = trigger_gamestart_use;
	self.reset2 = spawnfunc_trigger_gamestart;
	if (self.wait) {
		self.think = self.use;
		self.nextthink = map_starttime + self.wait;
	} else
		entity_initialize(self, trigger_gamestart_use, INITPRIO_FINDTARGET);
}

void(void) trigger_relay_teamcheck_use {
	if (activator.team) {
		if (self.spawnflags & 2) {
			if (activator.team != self.team)
				trigger_use_targets();
		} else {
			if (activator.team == self.team)
				trigger_use_targets();
		}
	} else {
		if (self.spawnflags & 1)
			trigger_use_targets();
	}
}

void(void) trigger_relay_teamcheck_reset {
	self.team = self.team_saved;
}

void(void) spawnfunc_trigger_relay_teamcheck {
	self.team_saved = self.team;
	self.use = trigger_relay_teamcheck_use;
	self.reset = trigger_relay_teamcheck_reset;
}



void(void) trigger_disablerelay_use {
	entity e;
	float a, b;
	a = b = 0;
	for (e = world; (e = find(e, targetname, self.target)); ) {
		if (e.use == trigger_use_targets) {
			e.use = trigger_dont_use_targets;
			++a;
		} else if (e.use == trigger_dont_use_targets) {
			e.use = trigger_use_targets;
			++b;
		}
	}
	if ((!a) == (!b))
		print("Invalid use of trigger_disablerelay: ", ftos(a), " relays were on, ", ftos(b), " relays were off!\n");
}

void(void) spawnfunc_trigger_disablerelay {
	self.use = trigger_disablerelay_use;
}

float magicear_matched;
string(entity ear, entity source, float teamsay, entity privatesay, string msgin) trigger_magicear_processmessage {
	float domatch, dotrigger, matchstart, l;
	string s, msg;
	entity oldself;
	magicear_matched = FALSE;
	dotrigger = ((self.classname == "player") && ((ear.radius == 0) || (vlen(source.origin - ear.origin) <= ear.radius)));
	domatch = ((ear.spawnflags & 32) || dotrigger);
	if not(domatch)
		return msgin;

	if (privatesay) {
		if (ear.spawnflags & 4)
			return msgin;
	} else {
		if (!teamsay)
			if (ear.spawnflags & 1)
				return msgin;

		if (teamsay > 0)
			if (ear.spawnflags & 2)
				return msgin;

		if (teamsay < 0)
			if (ear.spawnflags & 8)
				return msgin;
	}
	matchstart = -1;
	l = strlen(ear.message);
	if (self.spawnflags & 128)
		msg = msgin;
	else
		msg = strdecolorize(msgin);

	if (substring(ear.message, 0, 1) == "*") {
		if (substring(ear.message, -1, 1) == "*") {
			// two wildcards
			// as we need multi-replacement here...
			s = substring(ear.message, 1, -2);
			l -= 2;
			if (strstrofs(msg, s, 0) >= 0)
				matchstart = -2; // we use strreplace on s
		} else {
			// match at start
			s = substring(ear.message, 1, -1);
			l -= 1;
			if (substring(msg, -l, l) == s)
				matchstart = strlen(msg) - l;
		}
	} else {
		if (substring(ear.message, -1, 1) == "*") {
			// match at end
			s = substring(ear.message, 0, -2);
			l -= 1;
			if (substring(msg, 0, l) == s)
				matchstart = 0;
		} else {
			// full match
			s = ear.message;
			if (msg == ear.message)
				matchstart = 0;
		}
	}
	if (matchstart == -1) // no match
		return msgin;

	magicear_matched = TRUE;
	if (dotrigger) {
		oldself = activator = self;
		self = ear;
		trigger_use_targets();
		self = oldself;
	}
	if (ear.spawnflags & 16) {
		return ear.netname;
	} else if (ear.netname != "") {
		if (matchstart < 0)
			return strreplace(s, ear.netname, msg);
		else
			return strcat(
				substring(msg, 0, matchstart),
				ear.netname,
				substring(msg, matchstart + l, -1)
			);
	}
	else
		return msgin;
}

entity trigger_magicears;
string(entity source, float teamsay, entity privatesay, string msgin) trigger_magicear_processmessage_forallears {
	entity ear;
	string msgout;
	for (ear = trigger_magicears; ear; ear = ear.enemy) {
		msgout = trigger_magicear_processmessage(ear, source, teamsay, privatesay, msgin);
		if not(ear.spawnflags & 64)
			if (magicear_matched)
				return msgout;

		msgin = msgout;
	}
	return msgin;
}

void(void) spawnfunc_trigger_magicear {
	self.enemy = trigger_magicears;
	trigger_magicears = self;
	// actually handled in "say" processing
	// spawnflags:
	//   1 = ignore say
	//   2 = ignore teamsay
	//   4 = ignore tell
	//   8 = ignore tell to unknown player
	//   16 = let netname replace the whole message (otherwise, netname is a word replacement if set)
	//   32 = perform the replacement even if outside the radius
	//   64 = continue replacing/triggering even if this one matched
	// message: either
	//   *pattern*
	// or
	//   *pattern
	// or
	//   pattern*
	// or
	//   pattern
	// netname:
	//   if set, replacement for the matched text
	// radius:
	//   "hearing distance"
	// target:
	//   what to trigger
}

void(void) trigger_always_init {
	self.nextthink = time;
	self.think = trigger_use_targets;
}

void(void) spawnfunc_trigger_always {
	ENTITY_PER_PLAYER_FORCE();
	self.reset = trigger_always_init;
	if not(entity_per_player_entities)
		entity_initialize(self, trigger_always_init, INITPRIO_LAST);
}

.string chaintarget;
string(string curtarget) trigger_cycle_find_next_target {
	entity e = NULL;
	while((e = find(e, targetname, curtarget)))
		if (e.chaintarget)
			return e.chaintarget;

	error("trigger_cycle: broken chain");
	return NULL;
}

void(void) trigger_cycle_reset {
	self.target = self.netname;
}

void(void) trigger_cycle_use {
	trigger_use_targets_prevent_reuse();
	self.target = trigger_cycle_find_next_target(self.target);
	trigger_use_targets_prevent_reuse();
}

void(void) spawnfunc_trigger_cycle {
	self.netname = self.target;
	self.use = trigger_cycle_use;
	self.reset = trigger_cycle_reset;
}

/*
 * killcredit
 */

void(void) trigger_killcredit_use {
	self.enemy = activator;
	self.solid = SOLID_TRIGGER;
	self.think = self.reset;
	self.nextthink = time + self.wait;
}

void(void) trigger_killcredit_reset {
	self.enemy = world;
	self.solid = SOLID_NOT;
	self.think = stdproc_nothing;
}

void(void) trigger_killcredit_touch {
	if (!other.iscreature)
		return;

	other.pushltime = time + g_maxpushtime;
	other.pusher = self.enemy;
}

void(void) spawnfunc_trigger_killcredit {
	trigger_solid_brush_init();
	if (self.wait <= 0)
		self.wait = 3;

	self.use = trigger_killcredit_use;
	self.reset = trigger_killcredit_reset;
	self.touch = trigger_killcredit_touch;
	self.reset();
}

void(void) trigger_relay_chance_use {
	if (random() < self.cnt)
		trigger_use_targets();
}

void(void) spawnfunc_trigger_relay_chance {
	self.classname = "trigger_relay";
	if (!self.cnt)
		self.cnt = 0.5;

	self.use = trigger_relay_chance_use;
	self.reset = spawnfunc_trigger_relay_chance;
}

float(entity e, float _f, vector _v, string _s, entity _e) trigger_relay_random_use_target {
	e.sub_target_used = time;
	random_selection_add(e, 0, NULL, 1, 1);
	return FALSE;
}

void(void) trigger_relay_random_use {
	random_selection_init();
	trigger_for_each_target(self, trigger_relay_random_use_target, FALSE, NULL, NULL, NULL, NULL);
	if (random_selection_chosen_ent) {
		random_selection_chosen_ent.sub_target_used = -1;
		trigger_use_targets_prevent_reuse();
	}
}

void(void) spawnfunc_trigger_relay_random {
	self.classname = "trigger_relay";
	self.use = trigger_relay_random_use;
	self.reset = spawnfunc_trigger_relay_random;
}

void(void) trigger_relay_foreachplayer_use {
	entity activatorold = activator;
	FOR_EACH_PLAYER(activator)
		trigger_use_targets();

	activator = activatorold;
}

void(void) spawnfunc_trigger_relay_foreachplayer {
	self.classname = "trigger_relay";
	self.use = trigger_relay_foreachplayer_use;
	self.reset = spawnfunc_trigger_relay_foreachplayer;
}

enum {
	TSTATE_ENABLED = 1,
	TSTATE_USE_ON = 2,
	TSTATE_USE_OFF = 4,
};

enum {
	TSTATE_NOT = 1,
};

typedef float(void) statefunc_t;
typedef float(entity, .entity) statefunc_aggr_t;

.statefunc_t statefunc;
.statefunc_t statefunc2;

const float STATECHAIN_STACK_MAX = 16;
.entity statechain_stack[STATECHAIN_STACK_MAX];
float statechain_stack_ptr;
var .entity statechain_next;

void(void) statechain_push {
	if (statechain_stack_ptr >= STATECHAIN_STACK_MAX)
		error("statechain stack overflow");

	statechain_next = statechain_stack[statechain_stack_ptr];
	++statechain_stack_ptr;
}

void(void) statechain_pop {
	--statechain_stack_ptr;
	if (statechain_stack_ptr < 0)
		error("statechain stack underflow");

	statechain_next = statechain_stack[statechain_stack_ptr];
}

float(entity e) compute_state {
	entity oldself = self;
	self = e;
	float r = e.statefunc();
	self = oldself;
	return r;
}

float(entity e, .entity next) aggregate_and {
	do {
		if (e.statefunc)
		if (!compute_state(e))
			return FALSE;
	} while((e = e.next));
	return TRUE;
}

float(entity e, .entity next) aggregate_or {
	do {
		if (e.statefunc)
		if (compute_state(e))
			return TRUE;
	} while((e = e.next));
	return FALSE;
}

float(statefunc_aggr_t aggr) statefunc_aggregate_targets {
	statechain_push();
	float s = aggr(trigger_link_targets(self, statechain_next, FALSE), statechain_next);
	statechain_pop();
	return s;
}

float(void) statefunc_invertible {
	float s = self.statefunc2();
	if (self.spawnflags & TSTATE_NOT)
		return !s;

	return s;
}

float(void) statefunc_self {
	return self.state;
}

float(void) statefunc_or {
	return statefunc_aggregate_targets(aggregate_or);
}

float(void) statefunc_and {
	return statefunc_aggregate_targets(aggregate_and);
}

void(void(void) reset_f, statefunc_t state_f) trigger_state_init {
	self.classname = "trigger_state";
	self.reset = reset_f;
	self.statefunc = statefunc_invertible;
	self.statefunc2 = state_f;
	self.use = stdproc_nothing; // dummy default to ensure that ForEachTarget works on it
}

void(void) trigger_state_use {
	self.state = !(self.state);
	if ((self.state && self.spawnflags & TSTATE_USE_ON) || (!self.state && self.spawnflags & TSTATE_USE_OFF))
		trigger_use_targets();
}

void(void) spawnfunc_trigger_state {
	trigger_state_init(spawnfunc_trigger_state, statefunc_self);
	self.statefunc = self.statefunc2;
	self.state = (self.spawnflags & TSTATE_ENABLED);

	self.use = trigger_state_use;
}

void(void) spawnfunc_trigger_state_and {
	trigger_state_init(spawnfunc_trigger_state_and, statefunc_and);
}

void(void) spawnfunc_trigger_state_or {
	trigger_state_init(spawnfunc_trigger_state_or, statefunc_or);
}

float(void) trigger_state_activatoralive_check {
	return !PLAYER_DEAD(activator);
}

void(void) spawnfunc_trigger_state_activatoralive {
	trigger_state_init(spawnfunc_trigger_state_activatoralive, trigger_state_activatoralive_check);
}

void(void) trigger_relay_ifstate_use {
	float s = compute_state(self.enemy);
	if (self.spawnflags & TSTATE_NOT)
		s = !s;

	if (s > 0) // XXX: why is this necessary?
		trigger_use_targets();
}

void(void) trigger_relay_ifstate_init {
	entity e = NULL;
	while((e = find(e, targetname, self.killtarget))) {
		if (e.statefunc) {
			self.killtarget = NULL;
			self.enemy = e;
			break;
		}
	}
	if (!self.enemy) {
		entity_abort("trigger_relay_ifstate does not point to a valid state entity");
		return;
	}
}

void(void) spawnfunc_trigger_relay_ifstate {
	self.classname = "trigger_relay";
	self.use = trigger_relay_ifstate_use;
	entity_initialize(self, trigger_relay_ifstate_init, INITPRIO_FINDTARGET);
}

void(void) trigger_roundstate_warmup_init {
	activator = self;
	trigger_use_targets();
}

void(void) trigger_roundstate_warmup {
	self.reset2 = trigger_roundstate_warmup;
	entity_initialize(self, trigger_roundstate_warmup_init, INITPRIO_FINDTARGET);
}

void(void) spawnfunc_trigger_roundstate {
	self.classname = "trigger_roundstate";
	self.reset2 = spawnfunc_trigger_roundstate;
	self.use = trigger_use_targets;
	if (self.cnt == 0 /*ROUNDSTATE_GAMEINIT*/) {
		entity_initialize(self, trigger_gamestart_use, INITPRIO_FINDTARGET);
	} else if (self.cnt == 4 /*ROUNDSTATE_WARMUP*/) {
		self.reset2 = trigger_roundstate_warmup;
	} else {
		print("trigger_roundstate: roundstate ", self.cnt, " is not supported\n");
	}
}

.entity trigger_gravity_check;
void(entity own) trigger_gravity_remove {
	if (own.trigger_gravity_check.owner == own) {
		projectile_update(own);
		own.gravity = own.trigger_gravity_check.gravity;
		remove(own.trigger_gravity_check);
	} else
		backtrace("Removing a trigger_gravity_check with no valid owner");

	own.trigger_gravity_check = world;
}

void(void) trigger_gravity_check_think {
	// This spawns when a player enters the gravity zone and checks if he left.
	// Each frame, self.count is set to 2 by trigger_gravity_touch() and decreased by 1 here.
	// It the player has left the gravity trigger, this will be allowed to reach 0 and indicate that.
	if (self.count <= 0) {
		if (self.owner.trigger_gravity_check == self)
			trigger_gravity_remove(self.owner);
		else
			remove(self);

		return;
	} else {
		self.count -= 1;
		self.nextthink = time;
	}
}

void(void) trigger_gravity_use {
	self.state = !self.state;
}

void(void) trigger_gravity_touch {
	float g;
	if (self.state != TRUE)
		return;

	TRIGGER_EXACT_TOUCH;
	g = self.gravity;
	if not(self.spawnflags & 1) {
		if (other.trigger_gravity_check) {
			if (self == other.trigger_gravity_check.enemy) {
				// same?
				other.trigger_gravity_check.count = 2; // gravity one more frame...
				return;
			}
			// compare prio
			if (self.cnt > other.trigger_gravity_check.enemy.cnt)
				trigger_gravity_remove(other);
			else
				return;
		}
		other.trigger_gravity_check = spawn();
		other.trigger_gravity_check.enemy = self;
		other.trigger_gravity_check.owner = other;
		other.trigger_gravity_check.gravity = other.gravity;
		other.trigger_gravity_check.think = trigger_gravity_check_think;
		other.trigger_gravity_check.nextthink = time;
		other.trigger_gravity_check.count = 2;
		if (other.gravity)
			g *= other.gravity;
	}
	if (other.gravity != g) {
		other.gravity = g;
		if (self.noise != "")
			sound (other, CHAN_TRIGGER, self.noise, VOL_BASE, ATTN_NORM);
		projectile_update(other);
	}
}

void(void) spawnfunc_trigger_gravity {
	trigger_solid_brush_init();
	self.touch = trigger_gravity_touch;
	if (self.noise != "")
		precache_sound(self.noise);

	self.state = TRUE;
	IFTARGETED {
		self.use = trigger_gravity_use;
		if (self.spawnflags & 2)
			self.state = FALSE;
	}
}

void(void) spawnfunc_trigger_teleport {
	teleport_setup();
}

.float swamp_interval; //Hurt players in swamp with this interval
.float swamp_slowdown; //Players in swamp get slowd down by this mutch 0-1 is slowdown 1-~ is speedup (!?)
.entity swampslug;
var float() trigger_swamp_physics_max_speed_mod_next;
float() trigger_swamp_physics_max_speed_mod {
	float f = 1;
	if (self.swampslug) {
		entity oldother = other, oldself = self;
		other = self;
		self = self.swampslug;
		if (trigger_exact_hit())
			f = self.swamp_slowdown;
		else
			other.swampslug = world;

		other = oldother;
		self = oldself;
	}
	return f * trigger_swamp_physics_max_speed_mod_next();
}

void(void) trigger_swamp_touch {
	if ((other.classname != "player") || (other.deadflag != DEAD_NO))
		return;

	TRIGGER_EXACT_TOUCH;
	if (other.swamp_interval < time) {
		other.swamp_interval = time + self.swamp_interval;
		damage(other, self, self, self.dmg, DEATH_SLIME, other.origin, '0 0 0');
	}
	other.swampslug = self;
}

/*QUAKED spawnfunc_trigger_swamp (.5 .5 .5) ?
Players gettin into the swamp will
get slowd down and damaged
*/
float trigger_swamp_init_done;
void(void) spawnfunc_trigger_swamp {
	trigger_solid_brush_init();
	self.touch = trigger_swamp_touch;
	if (self.dmg <= 0)
		self.dmg = 5;

	if (self.swamp_interval <= 0)
		self.swamp_interval = 1;

	if (self.swamp_slowdown <= 0)
		self.swamp_slowdown = 0.5;

	if not(trigger_swamp_init_done) {
		trigger_swamp_init_done = TRUE;
		trigger_swamp_physics_max_speed_mod_next = plugin_chain_physics_max_speed_mod;
		plugin_chain_physics_max_speed_mod = trigger_swamp_physics_max_speed_mod;
	}
}

void(void) trigger_door_check_use {
	entity e;
	float state_to_check;
	if (self.spawnflags & 1)
		state_to_check = FUNC_STATE_BOTTOM;
	else
		state_to_check = FUNC_STATE_TOP;

	float total, correct;
	total = correct = 0;
	string t = self.target;
	for (e = find(world, targetname, t); e; e = find(e, targetname, t)) {
		total++;
		if (e.state == state_to_check)
			correct++;
	}
	self.target = "";
	self.state = FUNC_STATE_BOTTOM;
	if (self.spawnflags & 2) { //OR check (at least one door in needed state)
		if (correct > 0) {
			trigger_use_targets();
			self.state = FUNC_STATE_TOP;
		}
	} else { //AND check (all doors in needed state)
		if (total == correct) {
			trigger_use_targets();
			self.state = FUNC_STATE_TOP;
		}
	}
	self.target = t;
}

void(void) spawnfunc_trigger_door_check {
	self.use = trigger_door_check_use;
}

void(void) trigger_relay_if_use {
	float n;
	n = self.count;
	// TODO make this generic AND faster than nextent()ing through all, if somehow possible
	n = (cvar_string(self.netname) == cvar_string(self.message));
	if (self.spawnflags & 1)
		n = !n;

	if (n)
		trigger_use_targets();
}

void(void) spawnfunc_trigger_relay_if {
	self.use = trigger_relay_if_use;
}
