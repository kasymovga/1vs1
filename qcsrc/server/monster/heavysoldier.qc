#define MONSTER_HEAVYSOLDIER_ANIM_LEGS_WALK '110 8 8'
#define MONSTER_HEAVYSOLDIER_ANIM_LEGS_IDLE '171 9 9'
#define MONSTER_HEAVYSOLDIER_ANIM_TORSO_STAND '151 1 15'
#define MONSTER_HEAVYSOLDIER_ANIM_TORSO_ATTACK '130 6 15'
void heavysoldier_idle();
void heavysoldier_guard();
void heavysoldier_walk();

void(void) monster_heavysoldier_projectile_bounce_touch {
	PROJECTILE_TOUCH;
	if (other && (other.takedamage))
		projectile_explode();
	else {
		float r;
		r = random() * 6;
		if(r < 1)
			sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			sound_spam(self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
	}
}

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
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren;
		if (random() > 0.5 || vlen(monster_look_to_end - self.origin) > 1000) {
			gren = projectile(TRUE, PROJECTILE_GRENADE, TRUE, self);
			projectile_setup(gren,_shotorg, EFFECT_IMPACT_GRENADE, WEAPON_GRENADE_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0.01, MOVETYPE_TOSS);
			gren.touch = projectile_touch_explode;
			gren.velocity = normalize(_shotdir) * 3200;
			self.attack_finished_single = time + 3 + random();
		} else {
			gren = projectile(TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE, self);
			projectile_setup(gren,_shotorg, EFFECT_IMPACT_GRENADE, WEAPON_GRENADE_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 1, MOVETYPE_BOUNCE);
			gren.touch = monster_heavysoldier_projectile_bounce_touch;
			gren.velocity = normalize(_shotdir) * 1000 + 200 * '0 0 1';
			self.attack_finished_single = time + 1 + random();
		}
		PROJECTILE_MAKETRIGGER(gren);
		gren.nextthink = time + 5;
		gren.think = projectile_think2use;
		gren.use = projectile_explode;
		weapon_setup_projectile_velocity(gren);
		self.bulletcounter = time + 0.5;
	}
	if (time > self.bulletcounter) {
		v = monster_move_walk(250, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		monster_common_composite_anim(MONSTER_HEAVYSOLDIER_ANIM_LEGS_WALK, MONSTER_HEAVYSOLDIER_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	} else {
		move_beak_simple(2000 * frametime);
		monster_common_composite_anim(MONSTER_HEAVYSOLDIER_ANIM_LEGS_IDLE, MONSTER_HEAVYSOLDIER_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
	}
}

void heavysoldier_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	move_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_HEAVYSOLDIER_ANIM_LEGS_IDLE, MONSTER_HEAVYSOLDIER_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
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

	monster_common_composite_anim(MONSTER_HEAVYSOLDIER_ANIM_LEGS_WALK, MONSTER_HEAVYSOLDIER_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(150, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void heavysoldier_remove() {
	monster_common_on_remove();
}

void heavysoldier_spawn() {
	monster_prepare(heavysoldier_hunt, heavysoldier_walk, heavysoldier_idle);
	monster_common_composite_setup("heavysoldier", "gl");
	self.damageforcescale = 1;
	self.netname = "Heavy Soldier";
	self.ammo_rockets = 10;
	self.view_ofs = '0 0 27';
}

void(void) monster_heavysoldier_init {
	dlc_require("monsters");
	monster_common_composite_precache("heavysoldier", "gl");
	precache_sound("weapons/grenade_fire.wav");
	precache_sound("weapons/grenade_bounce1.wav");
	precache_sound("weapons/grenade_bounce2.wav");
	precache_sound("weapons/grenade_bounce3.wav");
	precache_sound("weapons/grenade_bounce4.wav");
	precache_sound("weapons/grenade_bounce5.wav");
	precache_sound("weapons/grenade_bounce6.wav");
	projectile_init(PROJECTILE_GRENADE);
	projectile_init(PROJECTILE_GRENADE_BOUNCING);
}

void(void) spawnfunc_monster_heavysoldier_spawn {
	monster_common_setup_spawn_size('-16 -16 -24', '16 16 45', '0 0 8');
	monster_init(monster_heavysoldier_init);
	self.noise1 = "player/soldier/coms/incoming.ogg";
	self.noise3 = "player/soldier/player/pain50.ogg";
	monster_prepare_spawn(heavysoldier_spawn, spawnfunc_monster_heavysoldier_spawn);
}

#undef MONSTER_HEAVYSOLDIER_ANIM_LEGS_WALK
#undef MONSTER_HEAVYSOLDIER_ANIM_LEGS_IDLE
#undef MONSTER_HEAVYSOLDIER_ANIM_TORSO_STAND
#undef MONSTER_HEAVYSOLDIER_ANIM_TORSO_ATTACK
