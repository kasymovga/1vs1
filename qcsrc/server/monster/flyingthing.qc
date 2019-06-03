void flyingthing_walk();

void flyingthing_idle() {
	self.movetype = MOVETYPE_FLY;
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	monster_move_fly_idle(100, 5);
}

void flyingthing_hunt() {
	self.movetype = MOVETYPE_WALK;
	self.nextthink = time;
	if (monster_check_target(flyingthing_walk, flyingthing_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		movelib_beak_simple(100 * frametime);
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		self.angles_x = v_x;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16 - '0 0 24';
		sound (self, CHAN_WEAPON, "weapons/electro_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren = projectile(TRUE, PROJECTILE_ELECTRO_BEAM, TRUE, self);
		gren.dmg_edge = self.dmg_edge;
		gren.dmg_radius = self.dmg_radius;
		gren.dmg_force = self.dmg_force;
		gren.classname = "grenade";
		gren.movetype = MOVETYPE_FLY;
		PROJECTILE_MAKETRIGGER(gren);
		gren.projectiledeathtype = WEP_ELECTRO;
		setorigin(gren, _shotorg);

		gren.nextthink = time + 5;
		gren.think = projectile_think2use;
		gren.use = monster_proj_explode;
		gren.touch = monster_proj_touch;
		gren.velocity = normalize(_shotdir) * 2400;
		weapon_setup_projectile_velocity(gren);

		gren.angles = vectoangles (gren.velocity);

		self.attack_finished_single = time + 1 + random();
	} else {
		v = monster_move_fly(450, 5);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
		self.angles_x = approach_angle(self.angles_x, v_x, 360 * frametime);
	}
}

void flyingthing_walk() {
	self.movetype = MOVETYPE_WALK;
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
	self.movetype = MOVETYPE_FLY;
	self.species = SPECIES_ROBOT_SOLID;
	self.netname = "Flying Thing";
	monster_set_fly();
	monster_prepare(flyingthing_hunt, flyingthing_walk, flyingthing_idle);
	setmodel(self, "models/turrets/walker_mghead.md3");
	self.solid = SOLID_BBOX;
	self.gravity = 0.01;
	self.takedamage = DAMAGE_AIM;
	self.view_ofs = '0 0 -16';
	self.damageforcescale = 1;
}

void flyingthing_init() {
	precache_sound("weapons/electro_fire.wav");
	precache_model("models/turrets/walker_mghead.md3");
	projectile_init(PROJECTILE_ELECTRO_BEAM);
}

void spawnfunc_monster_flyingthing_spawn() {
	setsize(self, '-16 -16 -48', '16 16 0');
	monster_init(flyingthing_init);
	monster_prepare_spawn(flyingthing_spawn, spawnfunc_monster_flyingthing_spawn);
}
