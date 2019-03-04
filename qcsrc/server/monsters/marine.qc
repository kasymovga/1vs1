void marine_idle();
void marine_guard();
void marine_walk();

void marine_hunt() {
	self.nextthink = time;
	if (monster_check_target(marine_walk, marine_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time) {
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1)
			dofire = TRUE;
	}
	float stay = self.owner.spawnflags & MONSTER_SPAWN_STAYSTILL;
	if (dofire) {
		if (self.cnt)
			self.cnt = self.cnt - 1;
		else
			self.cnt = 5;

		v = vectoangles(self.enemy.origin - self.origin);
		self.angles_y = v_y;
		movelib_beak_simple(100 * frametime);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = normalize(self.enemy.origin - self.origin);
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
		beginFireBallisticBullet(1000);
		fireBallisticBullet(_shotorg, _shotdir, self.dmg_radius, 1000, 5, self.dmg_edge, 0, self.dmg_force, WEP_SHOTGUN, particleeffectnum("tr_bullet"), 0, 0);
		endFireBallisticBullet();
		pointparticles(particleeffectnum("uzi_muzzleflash"), _shotorg, _shotdir * 1000, g_balance_shotgun_primary_ammo);
		// casing code
		if (g_casings >= 1)
			SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

		if (self.cnt)
			self.attack_finished_single = max(self.attack_finished_single, time - frametime) + 0.1;
		else
			self.attack_finished_single = time + 4 + random();

		self.bulletcounter = time + 1;
	} else if (stay) {
		movelib_beak_simple(1000 * frametime);
		v = vectoangles(normalize(self.enemy.origin - self.origin));
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	} else {
		v = monster_move_walk(300, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter) {
		if (stay)
			anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
		else
			anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	} else
		anim_set(self, '11 1 1', TRUE, TRUE, FALSE);
}

void marine_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
}

void marine_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	marine_idle();
}

void marine_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(marine_idle, 100))
		return;

	anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	vector v = monster_move_walk(200, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void marine_remove() {
	remove(self.exteriorweaponentity);
}

void marine_spawn() {
	monster_prepare(marine_hunt, marine_walk, marine_idle);
	setmodel(self, "models/player/marine.zym");
	self.movetype = MOVETYPE_WALK;
	self.entremove = marine_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 17;

	self.exteriorweaponentity = spawn();
	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_uzi.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Marine";
	self.ammo_nails = 20;
	self.view_ofs = '0 0 35';
}

void marine_init() {
	precache_model("models/player/marine.zym");
	precache_model("models/weapons/v_uzi.md3");
	precache_sound("weapons/uzi_fire.wav");
}

void spawnfunc_monster_marine_spawn() {
	setsize(self, '-16 -16 -24', '16 16 45');
	monster_init(marine_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(marine_spawn, spawnfunc_monster_marine_spawn);
}
