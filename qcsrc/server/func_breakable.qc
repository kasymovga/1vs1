.entity sprite;

.float napalm_count;
.float napalm_color;

.string mdl_dead; // or "" to hide when broken
// other fields:
//   mdl = particle effect name
//   count = particle effect multiplier
//   targetname = target to trigger to unbreak the model
//   target = targets to trigger when broken
//   health = amount of damage it can take
//   spawnflags:
//     1 = start disabled (needs to be triggered to activate)
//     2 = indicate damage
// notes:
//   for mdl_dead to work, origin must be set (using a common/origin brush).
//   Otherwise mdl_dead will be displayed at the map origin, and nobody would
//   want that!

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) func_breakable_damage;

void(void) func_breakable_colormod {
	float h;
	if not(self.spawnflags & 2)
		return;

	h = self.health / self.max_health;
	if (h < 0.25)
		self.colormod = '1 0 0';
	else if (h <= 0.75)
		self.colormod = '1 0 0' + '0 1 0' * (2 * h - 0.5);
	else
		self.colormod = '1 1 1';
}

void(void) func_breakable_look_destroyed {
	float floor_z;
	if (self.mdl_dead == "")
		self.model = "";
	else {
		vector _mins = self.mins, _maxs = self.maxs;
		setmodel(self, self.mdl_dead);
		setsize(self, _mins, _maxs);
		if (self.origin == '0 0 0') { // probably no origin brush, so don't spawn in the middle of the map..
			floor_z = self.absmin_z;
			setorigin(self, ((self.absmax + self.absmin) * 0.5));
			self.origin_z = floor_z;
		}
	}
	self.solid = SOLID_NOT;
}

void(void) func_breakable_look_restore {
	vector _mins = self.mins, _maxs = self.maxs;
	setmodel(self, self.mdl);
	setsize(self, _mins, _maxs);
	self.solid = self.oldsolid;
}

void(void) func_breakable_behave_destroyed {
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	self.event_damage = NULL;
	self.state = 1;
	func_breakable_colormod();
}

void(void) func_breakable_behave_restore {
	self.owner = world;
	self.health = self.max_health;
	self.takedamage = DAMAGE_YES;
	self.event_damage = func_breakable_damage;
	self.state = 0;
	func_breakable_colormod();
	setorigin(self, self.spawnorigin);
}

void(void) func_breakable_destroyed {
	func_breakable_look_destroyed();
	func_breakable_behave_destroyed();
}

void(void) func_breakable_restore {
	self.nextthink = 0;
	func_breakable_look_restore();
	func_breakable_behave_restore();
}

void(void) func_breakable_launch_napalm {
	// yes, this is a lazy hack
	float nc = self.napalm_count;
	if (nc <= 0)
		return;

	float saveteam = self.owner.team;
	self.owner.team = team_from_index(self.napalm_color);
	float c;
	entity e;
	for(c = 0; c < nc; ++c) {
		e = Napalm_Spawn(self.owner, self.origin, 3, 0.15, DEATH_HURTTRIGGER, 180, 80, 20, 1.5);
		e.velocity = random_spread_vector(70, 300, 300, 10);
	}
	self.owner.team = saveteam;
}

vector func_breakable_debrisforce; // global, set before calling this
void(void) func_breakable_destroy {
	string oldmsg;
	activator = self.owner;
	// now throw around the debris
	debris_throw(func_breakable_debrisforce);
	func_breakable_launch_napalm();
	func_breakable_destroyed();
	if (self.noise)
		sound (self, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NORM);

	if (self.dmg)
		damage_radius(self, activator, self.dmg, self.dmg_edge, self.dmg_radius, self, self.dmg_force, 0, DEATH_HURTTRIGGER, world);

	if (self.cnt)
		pointparticles(self.cnt, self.absmin * 0.5 + self.absmax * 0.5, '0 0 0', self.count);

	if (self.respawntime) {
		self.think = func_breakable_restore;
		self.nextthink = time + self.respawntime + random_2() * self.respawntimejitter;
	}
	oldmsg = self.message;
	self.message = "";
	other = self;
	trigger_use_targets();
	self.message = oldmsg;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) func_breakable_damage {
	if (self.state == 1)
		return;

	if (self.team)
		if (attacker.team == self.team)
			return;

	if (self.sprite)
		WaypointSprite_Ping(self.sprite);

	self.health = self.health - _damage;
	func_breakable_colormod();
	if (self.health <= 0) {
		func_breakable_debrisforce = force;
		damage_prepare_explosion(attacker, func_breakable_destroy);
	}
}

void(void) func_breakable_reset {
	self.team = self.team_saved;
	func_breakable_look_restore();
	if (self.spawnflags & 1)
		func_breakable_behave_destroyed();
	else
		func_breakable_behave_restore();
}

float func_breakable_init_done;
void(void) func_breakable_init {
	if (func_breakable_init_done)
		return;
}

// destructible walls that can be used to trigger target_objective_decrease
void(void) spawnfunc_func_breakable {
	func_breakable_init();
	model_movable_init();
	debris_init();
	if not(self.health)
		self.health = 100;

	if not(self.solid)
		self.solid = SOLID_BSP;

	self.oldsolid = self.solid;
	self.max_health = self.health;
	// yes, I know, MOVETYPE_NONE is not available here, not that one would want it here anyway
	if (self.mdl != "")
		self.cnt = particleeffectnum(self.mdl);

	if (self.count == 0)
		self.count = 1;

	if not(self.message)
		self.message = "got too close to an explosion";

	if not(self.message2)
		self.message2 = "was pushed into an explosion by";

	if not(self.dmg_radius)
		self.dmg_radius = 150;

	if not(self.dmg_force)
		self.dmg_force = 200;

	self.mdl = self.model;
	model_setup();
	self.use = func_breakable_restore;
	// precache all the models
	if (self.mdl_dead)
		precache_model(self.mdl_dead);

	if (self.noise)
		precache_sound(self.noise);

	self.team_saved = self.team;
	self.reset = func_breakable_reset;
	self.spawnorigin = self.origin;
	func_breakable_reset();
	if (self.napalm_count > 0) {
		Napalm_Init();
	}
}
