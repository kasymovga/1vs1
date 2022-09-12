void bat_walk();

void bat_idle() {
	self.movetype = MOVETYPE_FLY;
	anim_update(self);
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	monster_move_fly_idle(100, 5);
}

void bat_hunt() {
	self.movetype = MOVETYPE_WALK;
	anim_update(self);
	self.nextthink = time;
	if (monster_check_target(bat_walk, bat_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time) {
		if (vlen(self.origin - self.enemy.origin) < 500)
			dofire = monster_look_to(self.enemy);
	}
	if (dofire) {
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		self.angles_x = v_x;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16 - '0 0 24';
		sound (self, CHAN_WEAPON, "weapons/crylink_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren = projectile(TRUE, PROJECTILE_CRYLINK, TRUE, self);
		projectile_setup(gren,_shotorg, EFFECT_IMPACT_CRYLINK_BIG, WEP_CRYLINK, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
		gren.nextthink = time + 5;
		gren.think = projectile_think2use;
		gren.use = projectile_explode;
		gren.touch = projectile_touch_explode;
		gren.velocity = normalize(_shotdir) * 2400;
		weapon_setup_projectile_velocity(gren);
		self.attack_finished_single = time + 1 + random();
	} else {
		v = monster_move_fly(450, 5);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
		self.angles_x = approach_angle(self.angles_x, v_x, 360 * frametime);
	}
}

void bat_walk() {
	self.movetype = MOVETYPE_WALK;
	anim_update(self);
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
	self.movetype = MOVETYPE_FLY;
	self.species = SPECIES_ALIEN;
	self.netname = "Hell Bat";
	monster_set_fly();
	monster_prepare(bat_hunt, bat_walk, bat_idle);
	setmodel(self, "models/bat.md3");
	self.colormod = '3 2 1';
	self.solid = SOLID_BBOX;
	self.scale = 2;
	self.gravity = 0.01;
	self.takedamage = DAMAGE_AIM;
	anim_set(self, '0 7 7', TRUE, TRUE, FALSE);
	self.damageforcescale = 1;
}

void bat_init() {
	precache_sound("weapons/crylink_fire.wav");
	precache_model("models/bat.md3");
	dlc_require("bat");
}

void spawnfunc_monster_bat_spawn() {
	setsize(self, '-32 -32 -32', '32 32 32');
	monster_init(bat_init);
	monster_prepare_spawn(bat_spawn, spawnfunc_monster_bat_spawn);
}
