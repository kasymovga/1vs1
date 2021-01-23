#define PUSH_ONCE 1
#define PUSH_SILENT 2

.float height;

void() trigger_use_targets;

float trigger_push_calculatevelocity_flighttime;
float g_trigger_push_use_trigger_origin;

void(void) trigger_push_use {
	if(team_mode)
		self.team = activator.team;
}

/*
	trigger_push_calculatevelocity

	Arguments:
	  org - origin of the object which is to be pushed
	  tgt - target entity (can be either a point or a model entity; if it is
	        the latter, its midpoint is used)
	  ht  - jump height, measured from the higher one of org and tgt's midpoint

	Returns: velocity for the jump
	the global trigger_push_calculatevelocity_flighttime is set to the total
	jump time
 */

vector(vector org, entity tgt, float ht) trigger_push_calculatevelocity {
	float grav, sdist, zdist, vs, vz, jumpheight;
	vector sdir, torg;
	torg = tgt.origin + (tgt.mins + tgt.maxs) * 0.5;
	grav = sv_gravity;
	zdist = torg_z - org_z;
	sdist = vlen(torg - org - zdist * '0 0 1');
	sdir = normalize(torg - org - zdist * '0 0 1');
	// how high do we need to push the player?
	jumpheight = fabs(ht);
	if (zdist > 0)
		jumpheight = jumpheight + zdist;

	/*
		STOP.
		You will not understand the following equations anyway...
		But here is what I did to get them.
		I used the functions
		  s(t) = t * vs
		  z(t) = t * vz - 1/2 grav t^2
		and solved for:
		  s(ti) = sdist
		  z(ti) = zdist
		  max(z, ti) = jumpheight
		From these three equations, you will find the three parameters vs, vz
		and ti.
	 */
	// push him so high...
	vz = sqrt(2 * grav * jumpheight); // NOTE: sqrt(positive)!
	// we start with downwards velocity only if it's a downjump and the jump apex should be outside the jump!
	if (ht < 0)
		if (zdist < 0)
			vz = -vz;

	vector solution;
	solution = math_solve_quadratic(0.5 * grav, -vz, zdist); // equation "z(ti) = zdist"
	// ALWAYS solvable because jumpheight >= zdist
	if (!solution_z)
		solution_y = solution_x; // just in case it is not solvable due to roundoff errors, assume two equal solutions at their center (this is mainly for the usual case with ht == 0)

	if (zdist == 0)
		solution_x = solution_y; // solution_x is 0 in this case, so don't use it, but rather use solution_y (which will be sqrt(0.5 * jumpheight / grav), actually)

	if (zdist < 0) {
		// down-jump
		if (ht < 0) {
			// almost straight line type
			// jump apex is before the jump
			// we must take the larger one
			trigger_push_calculatevelocity_flighttime = solution_y;
		} else {
			// regular jump
			// jump apex is during the jump
			// we must take the larger one too
			trigger_push_calculatevelocity_flighttime = solution_y;
		}
	} else {
		// up-jump
		if(ht < 0) {
			// almost straight line type
			// jump apex is after the jump
			// we must take the smaller one
			trigger_push_calculatevelocity_flighttime = solution_x;
		} else {
			// regular jump
			// jump apex is during the jump
			// we must take the larger one
			trigger_push_calculatevelocity_flighttime = solution_y;
		}
	}
	vs = sdist / trigger_push_calculatevelocity_flighttime;
	// finally calculate the velocity
	return sdir * vs + '0 0 1' * vz;
}

void(void) trigger_push_touch {
	// FIXME: add a .float for whether an entity should be tossed by jumppads
	if not(other.iscreature)
	if (other.classname != "body")
	if (other.classname != "droppedweapon")
	if (!(other.flags & FL_PROJECTILE) || other.classname == "bullet")
		return;

	if (other.deadflag && other.deadflag != DEAD_FREEZE && other.iscreature)
		return;

	if (self.team)
		if ((self.spawnflags & 4 == 0) == (self.team != other.team))
			return;

	EXACTTRIGGER_TOUCH;
	if(self.target)
		self.movedir = trigger_push_calculatevelocity((g_trigger_push_use_trigger_origin ? (self.origin + (self.mins + self.maxs) * 0.5) : other.origin), self.enemy, self.height);

	other.flags &~= FL_ONGROUND;
	other.velocity = self.movedir;
	if (other.iscreature) {
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		other.oldvelocity = other.velocity;
		if (self.pushltime < time) { // prevent "snorring" sound when a player hits the jumppad more than once
			// flash when activated
			pointparticles(particleeffectnum("jumppad_activate"), other.origin, other.velocity, 1);
			sound (other, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NORM);
			self.pushltime = time + 0.2;
		}
		float ct;
		ct = clienttype(other);
		if (ct == CLIENTTYPE_BOT)
			other.lastteleporttime = time;

		// reset tracking of who pushed you into a hazard (for kill credit)
		other.pushltime = 0;
	}
	if (self.enemy.target) {
		entity oldself;
		oldself = self;
		activator = other;
		self = self.enemy;
		trigger_use_targets();
		self = oldself;
	}
	if (other.flags & FL_PROJECTILE) {
		other.angles = vectoangles (other.velocity);
		switch(other.movetype) {
			case MOVETYPE_FLY:
				other.movetype = MOVETYPE_TOSS;
				other.gravity = 1;
				break;
			case MOVETYPE_BOUNCEMISSILE:
				other.movetype = MOVETYPE_BOUNCE;
				other.gravity = 1;
				break;
		}
		projectile_update(other);
	}
	other.lastpushtime = time;
	if (self.spawnflags & PUSH_ONCE) {
		self.touch = stdproc_nothing;
		self.think = stdproc_remove;
		self.nextthink = time;
	}
}

.vector dest;
void(void) trigger_push_findtarget {
	entity e;
	vector org;
	float flighttime;
	// first calculate a typical start point for the jump
	org = (self.absmin + self.absmax) * 0.5;
	org_z = self.absmax_z - PL_MIN_z;
	if (self.target) {
		// find the target
		self.enemy = find(world, targetname, self.target);
		if not(self.enemy) {
			entity_abort("trigger_push: target not found\n");
			remove(self);
			return;
		}
		self.enemy.origin = self.enemy.origin + '0 0 1' * cvar("sv_jumppads_target_adjust_height");
		self.movedir = trigger_push_calculatevelocity(org, self.enemy, self.height);
		flighttime = trigger_push_calculatevelocity_flighttime;
	} else
		flighttime = 0;

	// calculate the destination and spawn a teleporter spawnfunc_waypoint
	e = spawn();
	setorigin(e, org);
	setsize(e, PL_MIN, PL_MAX);
	e.velocity = self.movedir;
	builtin_tracetoss(e, e);
	self.dest = trace_endpos;
	remove(e);
	waypoint_spawnforteleporter(self, self.dest, flighttime);
}

/*
 * ENTITY PARAMETERS:
 *
 *   target:  target of jump
 *   height:  the absolute value is the height of the highest point of the jump
 *            trajectory above the higher one of the player and the target.
 *            the sign indicates whether the highest point is INSIDE (positive)
 *            or OUTSIDE (negative) of the jump trajectory. General rule: use
 *            positive values for targets mounted on the floor, and use negative
 *            values to target a point on the ceiling.
 *   movedir: if target is not set, this * speed * 10 is the velocity to be reached.
 */

float trigger_push_init_done;
void(void) spawnfunc_trigger_push {
	if not(trigger_push_init_done) {
		CACHE_CVAR(g_trigger_push_use_trigger_origin);
		trigger_push_init_done = 1;
	}
	if (self.speed)
		entity_movedir_setup();

	EXACTTRIGGER_INIT;
	self.use = trigger_push_use;
	self.touch = trigger_push_touch;
	// normal push setup
	if (!self.speed)
		self.speed = 1000;

	self.movedir = self.movedir * self.speed * 10;
	if not(self.noise)
		self.noise = "misc/jumppad.wav";

	precache_sound (self.noise);
	// this must be called to spawn the teleport waypoints for bots
	entity_initialize(self, trigger_push_findtarget, INITPRIO_FINDTARGET);
}

#define TRIGGER_PUSH_VELOCITY_PLAYERDIR_XY 1
#define TRIGGER_PUSH_VELOCITY_ADD_XY 2
#define TRIGGER_PUSH_VELOCITY_PLAYERDIR_Z 4
#define TRIGGER_PUSH_VELOCITY_ADD_Z 8

void(void) trigger_push_velocity_touch {
	if (other.classname != "player")
		return;

	if not(self.enemy)
		return;

	vector v1, v2;
	if (self.spawnflags & TRIGGER_PUSH_VELOCITY_PLAYERDIR_XY) {
		v1 = other.velocity;
		v1_z = 0;
		v1 = self.speed * normalize(v1);
	} else {
		v1 = trigger_push_calculatevelocity((g_trigger_push_use_trigger_origin ? (self.origin + (self.mins + self.maxs) * 0.5) : other.origin), self.enemy, self.height);
	}
	v2_x = v1_x;
	v2_y = v1_y;
	if (self.spawnflags & TRIGGER_PUSH_VELOCITY_PLAYERDIR_Z) {
		v1 = self.count * '0 0 1';
	} else {
		v1 = trigger_push_calculatevelocity((g_trigger_push_use_trigger_origin ? (self.origin + (self.mins + self.maxs) * 0.5) : other.origin), self.enemy, self.height);
	}
	v2_z = v1_z;
	if (self.spawnflags & TRIGGER_PUSH_VELOCITY_ADD_XY) {
		other.velocity_x = other.velocity_x + v2_x * (frametime / sys_ticrate);
		other.velocity_y = other.velocity_y + v2_y * (frametime / sys_ticrate);
	} else {
		other.velocity_x = v2_x;
		other.velocity_y = v2_y;
	}
	if (self.spawnflags & TRIGGER_PUSH_VELOCITY_ADD_Z) {
		other.velocity_z = other.velocity_z + v2_z * (frametime / sys_ticrate);
	} else {
		other.velocity_z = v2_z;
	}
}

void(void) spawnfunc_trigger_push_velocity {
	EXACTTRIGGER_INIT;
	self.touch = trigger_push_velocity_touch;
	entity_initialize(self, trigger_push_findtarget, INITPRIO_FINDTARGET);
}
