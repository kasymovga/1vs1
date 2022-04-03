void rlgirl_idle();
void rlgirl_guard();
void rlgirl_walk();

void rlgirl_hunt() {
	self.nextthink = time;
	if (monster_check_target(rlgirl_walk, rlgirl_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		v = vectoangles(monster_look_to_end - self.origin - '0 0 20');
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/rocket_fire.wav", VOL_BASE, ATTN_NORM);
		entity missile = projectile(TRUE, PROJECTILE_ROCKET, TRUE, self);
		projectile_setup(missile,_shotorg, WEP_ROCKET_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
		missile.nextthink = time + 5;
		missile.think = projectile_think2use;
		missile.use = projectile_explode;
		missile.touch = projectile_touch_explode;
		missile.velocity = normalize(_shotdir) * 800;
		weapon_setup_projectile_velocity(missile);
		self.attack_finished_single = time + 3 + random();
		self.bulletcounter = time + 0.5;
	} else {
	}
	if (time > self.bulletcounter) {
		v = monster_move_walk(400, 25, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
		anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	} else {
		movelib_beak_simple(2000 * frametime);
		anim_set(self, '11 1 1', TRUE, TRUE, FALSE);
	}
}

void rlgirl_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
}

void rlgirl_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	rlgirl_idle();
}

void rlgirl_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(rlgirl_idle, 40))
		return;

	anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(300, 25, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);

}

void rlgirl_remove() {
	remove(self.exteriorweaponentity);
}

void rlgirl_spawn() {
	monster_prepare(rlgirl_hunt, rlgirl_walk, rlgirl_idle);
	setmodel(self, "models/player/pyria.zym");
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	self.entremove = rlgirl_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 34;

	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_rl.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Rocket Girl";
	self.ammo_rockets = 10;
	self.view_ofs = '0 0 35';
}

void rlgirl_init() {
	precache_model("models/player/pyria.zym");
	precache_model("models/weapons/v_rl.md3");
	precache_sound("weapons/rocket_fire.wav");
}

void spawnfunc_monster_rlgirl_spawn() {
	setsize(self, '-16 -16 -24', '16 16 45');
	monster_init(rlgirl_init);
	self.noise1 = "player/pyria-skadi/coms/incoming.ogg";
	self.noise3 = "player/pyria-skadi/player/pain50.ogg";
	monster_prepare_spawn(rlgirl_spawn, spawnfunc_monster_rlgirl_spawn);
}
