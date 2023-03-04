#define MONSTER_SOLDIER_MOVE_ANIM_LEGS_WALK '128 11 11'
#define MONSTER_SOLDIER_MOVE_ANIM_LEGS_IDLE '194 6 6'
#define MONSTER_SOLDIER_MOVE_ANIM_TORSO_STAND '155 9 9'
#define MONSTER_SOLDIER_MOVE_ANIM_TORSO_ATTACK '132 6 15'
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
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = normalize(monster_look_to_end - self.origin);
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/shotgun_fire.wav", VOL_BASE, ATTN_NORM);
		float sc;
		bullet_begin(1000);
		for (sc = 0; sc < 5; sc++)
			bullet(_shotorg, _shotdir, self.dmg_radius, 1000, 5, self.dmg_edge, 0, self.dmg_force, EFFECT_IMPACT_PELLET, WEAPON_SHOTGUN, particleeffectnum("tr_bullet"), 0, 1);

		bullet_end();
		pointparticles(particleeffectnum("shotgun_muzzleflash"), _shotorg, _shotdir * 1000, g_balance_shotgun_primary_ammo);
		// casing code
		casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);
		self.attack_finished_single = time + 4 + random();
		self.bulletcounter = time + 0.5;
	}
	if (time > self.bulletcounter) {
		v = monster_move_walk(300, 25, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		monster_common_composite_anim(MONSTER_SOLDIER_MOVE_ANIM_LEGS_WALK, MONSTER_SOLDIER_MOVE_ANIM_TORSO_STAND, '13 1 1');
	} else {
		movelib_beak_simple(2000 * frametime);
		monster_common_composite_anim(MONSTER_SOLDIER_MOVE_ANIM_LEGS_IDLE, MONSTER_SOLDIER_MOVE_ANIM_TORSO_ATTACK, '13 1 1');
	}
}

void soldier_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_SOLDIER_MOVE_ANIM_LEGS_IDLE, MONSTER_SOLDIER_MOVE_ANIM_TORSO_STAND, '7 1 1');
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
	if (monster_walk_finished(soldier_idle, 40))
		return;

	monster_common_composite_anim(MONSTER_SOLDIER_MOVE_ANIM_LEGS_WALK, MONSTER_SOLDIER_MOVE_ANIM_TORSO_STAND, '13 1 1');
	vector v = monster_move_walk(200, 25, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	anim_update(self);
}

void soldier_remove() {
	monster_common_on_remove();
}

void soldier_spawn() {
	monster_prepare(soldier_hunt, soldier_walk, soldier_idle);
	monster_common_composite_setup("soldier", "shotgun");
	self.damageforcescale = 1;
	self.netname = "Soldier";
	self.ammo_shells = 10;
	self.view_ofs = '0 0 27';
}

void soldier_init() {
	dlc_require("monsters");
	monster_common_composite_precache("soldier", "shotgun");
	precache_sound("weapons/shotgun_fire.wav");
}

void spawnfunc_monster_soldier_spawn() {
	monster_common_setup_spawn_size('-16 -16 -24', '16 16 45', '0 0 8');
	monster_init(soldier_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(soldier_spawn, spawnfunc_monster_soldier_spawn);
}

#undef MONSTER_SOLDIER_MOVE_ANIM_LEGS_IDLE
#undef MONSTER_SOLDIER_MOVE_ANIM_TORSO_STAND
#undef MONSTER_SOLDIER_MOVE_ANIM_TORSO_ATTACK
#undef MONSTER_SOLDIER_MODEL_ORIGIN_ADJUST
