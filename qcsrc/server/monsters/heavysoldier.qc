void heavysoldier_idle();
void heavysoldier_guard();
void heavysoldier_walk();

void heavysoldier_hunt() {
	self.nextthink = time;
	if (monster_check_target(heavysoldier_walk, heavysoldier_guard))
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
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren = projectile(TRUE, PROJECTILE_GRENADE, TRUE);
		gren.owner = self;
		gren.dmg_edge = self.dmg_edge;
		gren.dmg_radius = self.dmg_radius;
		gren.dmg_force = self.dmg_force;
		gren.classname = "grenade";
		gren.movetype = MOVETYPE_TOSS;
		gren.gravity = 0.01;
		PROJECTILE_MAKETRIGGER(gren);
		gren.projectiledeathtype = WEP_GRENADE_LAUNCHER;
		setorigin(gren, _shotorg);

		gren.nextthink = time + 5;
		gren.think = adaptor_think2use;
		gren.use = monster_proj_explode;
		gren.touch = monster_proj_touch;
		gren.velocity = normalize(_shotdir) * 3200;
		weapon_setup_projectile_velocity(gren);

		gren.angles = vectoangles (gren.velocity);

		self.attack_finished_single = time + 3 + random();
		self.bulletcounter = time + 0.5;
	} else {
		v = monster_move_walk(250, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter)
		anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	else
		anim_set(self, '11 1 1', TRUE, TRUE, FALSE);
}

void heavysoldier_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
}

void heavysoldier_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	heavysoldier_idle();
}

void heavysoldier_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(heavysoldier_idle, 40))
		return;

	anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(150, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);

}

void heavysoldier_remove() {
	remove(self.exteriorweaponentity);
}

void heavysoldier_spawn() {
	monster_prepare(heavysoldier_hunt, heavysoldier_walk, heavysoldier_idle);
	setmodel(self, "models/player/grunt.zym");
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	self.entremove = heavysoldier_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 34;

	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_gl.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Heavy Soldier";
	self.ammo_rockets = 5;
	self.view_ofs = '0 0 35';
}

void heavysoldier_init() {
	precache_model("models/player/grunt.zym");
	precache_model("models/weapons/v_gl.md3");
	precache_sound("weapons/grenade_fire.wav");
	projectile_init(PROJECTILE_GRENADE);
}

void spawnfunc_monster_heavysoldier_spawn() {
	setsize(self, '-16 -16 -24', '16 16 45');
	monster_init(heavysoldier_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(heavysoldier_spawn, spawnfunc_monster_heavysoldier_spawn);
}
