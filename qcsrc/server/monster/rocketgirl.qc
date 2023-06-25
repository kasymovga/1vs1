#define MONSTER_ROCKETGIRL_ANIM_LEGS_WALK '114 8 15'
#define MONSTER_ROCKETGIRL_ANIM_LEGS_IDLE '180 9 8'
#define MONSTER_ROCKETGIRL_ANIM_TORSO_STAND '165 1 5'
#define MONSTER_ROCKETGIRL_ANIM_TORSO_ATTACK '132 6 15'
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
		projectile_setup(missile,_shotorg, EFFECT_IMPACT_ROCKET, WEAPON_ROCKET_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
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
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		monster_common_composite_anim(MONSTER_ROCKETGIRL_ANIM_LEGS_WALK, MONSTER_ROCKETGIRL_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	} else {
		move_beak_simple(2000 * frametime);
		monster_common_composite_anim(MONSTER_ROCKETGIRL_ANIM_LEGS_IDLE, MONSTER_ROCKETGIRL_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
	}
}

void rlgirl_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	move_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_ROCKETGIRL_ANIM_LEGS_IDLE, MONSTER_ROCKETGIRL_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
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

	monster_common_composite_anim(MONSTER_ROCKETGIRL_ANIM_LEGS_WALK, MONSTER_ROCKETGIRL_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(300, 25, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
}

void rlgirl_remove() {
	monster_common_on_remove();
}

void rlgirl_spawn() {
	monster_prepare(rlgirl_hunt, rlgirl_walk, rlgirl_idle);
	monster_common_composite_setup("rocketgirl", "rl");
	self.damageforcescale = 1;
	self.netname = "Rocket Girl";
	self.ammo_rockets = 10;
	self.view_ofs = '0 0 27';
	self.entremove = rlgirl_remove;
}

void(void) monster_rlgirl_init {
	dlc_require("monsters");
	monster_common_composite_precache("rocketgirl", "rl");
	precache_sound("weapons/rocket_fire.wav");
	projectile_init(PROJECTILE_ROCKET);
}

void(void) spawnfunc_monster_rlgirl_spawn {
	monster_common_setup_spawn_size('-16 -16 -24', '16 16 45', '0 0 8');
	monster_init(monster_rlgirl_init);
	self.noise1 = "player/pyria-skadi/coms/incoming.ogg";
	self.noise3 = "player/pyria-skadi/player/pain50.ogg";
	monster_prepare_spawn(rlgirl_spawn, spawnfunc_monster_rlgirl_spawn);
}

#undef MONSTER_ROCKETGIRL_ANIM_LEGS_WALK
#undef MONSTER_ROCKETGIRL_ANIM_LEGS_IDLE
#undef MONSTER_ROCKETGIRL_ANIM_TORSO_STAND
#undef MONSTER_ROCKETGIRL_ANIM_TORSO_ATTACK
