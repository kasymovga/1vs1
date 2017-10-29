void bat_walk();

void bat_grenade_explode (void)
{
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, self.dmg_edge, 0, self.dmg_radius, world, -self.dmg_force, self.projectiledeathtype, other);
	remove (self);
}

void bat_grenade_touch (void)
{
	PROJECTILE_TOUCH;
	bat_grenade_explode();
}


void bat_idle() {
	updateanim(self);
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
}

void bat_hunt() {
	updateanim(self);
	self.nextthink = time;
	if (monster_check_target(bat_walk, bat_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time) {
		if (vlen(self.origin - self.enemy.origin) < 500) {
			traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
			if (trace_fraction == 1)
				dofire = TRUE;
		}
	}
	if (dofire) {
		movelib_beak_simple(100 * frametime);
		v = vectoangles(self.enemy.origin - self.origin);
		self.angles_y = v_y;
		self.angles_x = v_x;
		makevectors(self.angles);
		vector _shotdir = self.enemy.origin - self.origin;
		vector _shotorg = self.origin + v_forward * 16 - '0 0 24';
		sound (self, CHAN_WEAPON, "weapons/crylink_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren = spawn();
		gren.owner = self;
		gren.dmg_edge = self.dmg_edge;
		gren.dmg_radius = self.dmg_radius;
		gren.dmg_force = self.dmg_force;
		gren.classname = "grenade";
		gren.movetype = MOVETYPE_FLY;
		PROJECTILE_MAKETRIGGER(gren);
		gren.projectiledeathtype = WEP_CRYLINK;
		setorigin(gren, _shotorg);
		setsize(gren, '0 0 0', '0 0 0');

		gren.nextthink = time + 5;
		gren.think = adaptor_think2use;
		gren.use = bat_grenade_explode;
		gren.touch = bat_grenade_touch;
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

void bat_walk() {
	updateanim(self);
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	if (monster_walk_finished(bat_idle, 100))
		return;

	//self.velocity = normalize(v) * 400;
	vector v = monster_move_fly(300, 5);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
	self.angles_x = approach_angle(self.angles_x, v_x, 90 * frametime);
}

void bat_spawn() {
	self.movetype = MOVETYPE_WALK;
	self.species = SPECIES_ALIEN;
	self.netname = "Hell Bat";
	monster_set_fly();
	monster_prepare(bat_hunt, bat_walk, bat_idle);
	setmodel(self, "models/bat.md3");
	self.solid = SOLID_BBOX;
	self.scale = 2;
	self.gravity = 0.01;
	self.takedamage = DAMAGE_AIM;
	setanim(self, '0 7 7', TRUE, TRUE, FALSE);
}

void bat_init() {
	precache_sound("weapons/crylink_fire.wav");
	precache_model("models/bat.md3");
	dlc_require("bat");
}

void spawnfunc_bat_spawn() {
	setsize(self, '-32 -32 -32', '32 32 32');
	monster_init(bat_init);
	monster_prepare_spawn(bat_spawn, spawnfunc_bat_spawn);
}
