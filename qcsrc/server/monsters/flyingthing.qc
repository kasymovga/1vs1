void flyingthing_walk();

void flyingthing_grenade_explode (void)
{
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, 50, 0, 100, world, 100, self.projectiledeathtype, other);
	remove (self);
}

void flyingthing_grenade_touch (void)
{
	PROJECTILE_TOUCH;
	flyingthing_grenade_explode();
}


void flyingthing_idle() {
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
}

void flyingthing_hunt() {
	self.nextthink = time;
	if (monster_check_target(flyingthing_walk, flyingthing_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time) {
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1)
			dofire = TRUE;
	}
	if (dofire) {
		movelib_beak_simple(100 * frametime);
		v = vectoangles(self.enemy.origin - self.origin);
		self.angles_y = v_y;
		self.angles_x = v_x;
		makevectors(self.angles);
		vector _shotdir = self.enemy.origin - self.origin;
		vector _shotorg = self.origin + v_forward * 16 - '0 0 24';
		sound (self, CHAN_WEAPON, "weapons/electro_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren = spawn();
		gren.owner = self;
		gren.classname = "grenade";
		gren.movetype = MOVETYPE_FLY;
		PROJECTILE_MAKETRIGGER(gren);
		gren.projectiledeathtype = WEP_ELECTRO;
		setorigin(gren, _shotorg);
		setsize(gren, '0 0 -3', '0 0 -3');

		gren.nextthink = time + 5;
		gren.think = adaptor_think2use;
		gren.use = flyingthing_grenade_explode;
		gren.touch = flyingthing_grenade_touch;
		gren.velocity = normalize(_shotdir) * 2400;
		W_SetupProjectileVelocity(gren);

		gren.angles = vectoangles (gren.velocity);
		gren.flags = FL_PROJECTILE;

		CSQCProjectile(gren, TRUE, PROJECTILE_ELECTRO_BEAM, TRUE);

		self.attack_finished_single = time + 1 + random();
	} else {
		v = monster_move_fly(450, 5);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
		self.angles_x = approach_angle(self.angles_x, v_x, 360 * frametime);
	}
}

void flyingthing_walk() {
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	if (monster_walk_finished(flyingthing_idle, 100))
		return;

	//self.velocity = normalize(v) * 400;
	vector v = monster_move_fly(300, 5);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
	self.angles_x = approach_angle(self.angles_x, v_x, 90 * frametime);
}

void flyingthing_spawn() {
	self.movetype = MOVETYPE_WALK;
	self.species = SPECIES_ROBOT_SOLID;
	monster_set_fly();
	monster_prepare(flyingthing_hunt, flyingthing_walk, flyingthing_idle);
	setmodel(self, "models/turrets/walker_mghead.md3");
	self.solid = SOLID_BBOX;
	setsize(self, '-16 -16 -48', '16 16 0');
	self.gravity = 0.01;
	self.takedamage = DAMAGE_AIM;
}

void flyingthing_init() {
	precache_sound("weapons/electro_fire.wav");
	precache_model("models/turrets/walker_mghead.md3");
}

void spawnfunc_flyingthing_spawn() {
	monster_init(flyingthing_init);
	monster_prepare_spawn(flyingthing_spawn, spawnfunc_flyingthing_spawn);
}
