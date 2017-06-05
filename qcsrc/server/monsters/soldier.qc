void soldier_idle();
void soldier_guard();

void soldier_hunt() {
	self.nextthink = time;
	vector v;
	v = monster_get_direction_to(self.enemy);
	if (self.enemy.health < 1) {
		self.think = soldier_guard;
		soldier_guard();
		return;
	}
	if (self.attack_finished_single > time) {
		setanim(self, '13 1 1', TRUE, TRUE, FALSE);
		monster_move_walk(v, 300, 5);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	} else {
		movelib_beak_simple(100 * frametime);
		v = vectoangles(v);
		self.angles_y = v_y;
		setanim(self, '7 1 1', TRUE, TRUE, FALSE);
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1) {
			makevectors(self.angles);
			vector _shotdir = self.enemy.origin - self.origin;
			vector _shotorg = self.origin + v_forward * 16;
			sound (self, CHAN_WEAPON, "weapons/shotgun_fire.wav", VOL_BASE, ATTN_NORM);
			float sc;
			for (sc = 0; sc < 5; sc++)
				fireBallisticBullet(_shotorg, _shotdir, 1, 1000, 5, 10, 0, 20, WEP_SHOTGUN, 0, 0, 0);
			endFireBallisticBullet();
			pointparticles(particleeffectnum("shotgun_muzzleflash"), _shotorg, _shotdir * 1000, g_balance_shotgun_primary_ammo);
			// casing code
			if (g_casings >= 1)
				SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

			self.attack_finished_single = time + 2;
		}
	}
}

void soldier_idle() {
	self.nextthink = time;
	movelib_beak_simple(100 * frametime);
	setanim(self, '7 1 1', TRUE, TRUE, FALSE);
	entity e;
	if ((e = monster_look_for_player(2500, 0))) {
		self.enemy = e;
		self.think = soldier_hunt;
	}
}

void soldier_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	soldier_idle();
}

void soldier_walk() {
	self.nextthink = time;
	setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	entity e;
	if ((e = monster_look_for_player(1500, 0))) {
		self.enemy = e;
		self.think = soldier_hunt;
		self.attack_finished_single = time + random() * 3 + 1;
		return;
	}
	vector v, v1;
	v1 = monster_get_direction_to(self.enemy);
	v = self.enemy.origin - self.origin;
	if (vlen(v) < frametime * 2 * (vlen(self.velocity)) + 32) {
		if (self.enemy.target)
			self.enemy = find(world, targetname, self.enemy.target);
		else
			self.enemy = world;

		if not(self.enemy)
			self.think = soldier_idle;

		return;
	}
	//self.velocity = normalize(v) * 400;
	monster_move_walk(v1, 200, 5);
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
	self.exteriorweaponentity = spawn();
	self.entremove = soldier_remove;
	self.colormap = 1024 + 17;
	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_shotgun.md3");
	setsize(self, '-32 -32 -32', '32 32 32');
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.health = 50;
	self.damageforcescale = 1;
}

void spawnfunc_soldier_spawn() {
	monster_prepare_spawn(soldier_spawn, spawnfunc_soldier_spawn);
}
