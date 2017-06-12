void soldier_idle();
void soldier_guard();
void soldier_walk();

void soldier_hunt() {
	self.nextthink = time;
	if (monster_check_target(soldier_walk, soldier_guard))
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
		v = vectoangles(self.enemy.origin - self.origin);
		self.angles_y = v_y;
		movelib_beak_simple(100 * frametime);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = normalize(self.enemy.origin - self.origin);
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/shotgun_fire.wav", VOL_BASE, ATTN_NORM);
		float sc;
		for (sc = 0; sc < 5; sc++)
			fireBallisticBullet(_shotorg, _shotdir, 0.1, 1000, 5, 10, 0, 20, WEP_SHOTGUN, 0, 0, 0);
		endFireBallisticBullet();
		pointparticles(particleeffectnum("shotgun_muzzleflash"), _shotorg, _shotdir * 1000, g_balance_shotgun_primary_ammo);
		// casing code
		if (g_casings >= 1)
			SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

		self.attack_finished_single = time + 4 + random();
		self.bulletcounter = time + 0.5;
	} else {
		v = monster_move_walk(300, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter)
		setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	else
		setanim(self, '7 1 1', TRUE, TRUE, FALSE);
}

void soldier_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	setanim(self, '7 1 1', TRUE, TRUE, FALSE);
}

void soldier_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	soldier_idle();
}

void soldier_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(soldier_idle, 100))
		return;

	setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	vector v = monster_move_walk(200, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void soldier_remove() {
	remove(self.exteriorweaponentity);
}

void soldier_spawn() {
	monster_prepare(soldier_hunt, soldier_walk, soldier_idle);
	setmodel(self, "models/player/shock.zym");
	self.movetype = MOVETYPE_WALK;
	self.entremove = soldier_remove;
	self.colormap = 1024 + 17;
	self.exteriorweaponentity = spawn();
	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_shotgun.md3");
	setsize(self, '-32 -32 -32', '32 32 32');
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.health = 50;
	self.damageforcescale = 1;
	self.netname = "Soldier";
}

void soldier_init() {
	precache_model("models/player/shock.zym");
	precache_model("models/weapons/v_shotgun.md3");
	precache_sound("weapons/shotgun_fire.wav");
}

void spawnfunc_soldier_spawn() {
	monster_init(soldier_init);
	monster_prepare_spawn(soldier_spawn, spawnfunc_soldier_spawn);
}
