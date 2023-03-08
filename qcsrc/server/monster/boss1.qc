#define MONSTER_BOSS1_ANIM_DIE '0 30 10'
#define MONSTER_BOSS1_ANIM_LEGS_WALK '110 8 8'
#define MONSTER_BOSS1_ANIM_LEGS_IDLE '171 9 9'
#define MONSTER_BOSS1_ANIM_TORSO_STAND '151 1 15'
#define MONSTER_BOSS1_ANIM_TORSO_ATTACK '130 6 15'

void boss1_idle();
void boss1_guard();
void boss1_walk();

void boss1_hunt() {
	self.nextthink = time;
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	if (monster_check_target(boss1_walk, boss1_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time) {
		dofire = monster_look_to(self.enemy);
	}
	float stay = self.owner.spawnflags & MONSTER_SPAWN_STAYSTILL;
	if (dofire) {
		vector _shotorg = self.origin + self.maxs_z * '0 0 1' - '0 0 45';
		v = vectoangles(monster_look_to_end - _shotorg);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - _shotorg;
		_shotorg = _shotorg + v_forward * self.maxs_z;
		sound (self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);
		float i;
		for (i = 0; i < 4; i++) {
			entity gren = projectile(TRUE, PROJECTILE_GRENADE, TRUE, self);
			projectile_setup(gren,_shotorg, EFFECT_IMPACT_GRENADE, WEAPON_GRENADE_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0.01, MOVETYPE_TOSS);
			gren.nextthink = time + 5;
			gren.think = projectile_think2use;
			gren.use = projectile_explode;
			gren.touch = projectile_touch_explode;
			gren.velocity = normalize(_shotdir + randomvec() * 0.05 * vlen(_shotdir)) * 3200;
			weapon_setup_projectile_velocity(gren);
			gren.angles = vectoangles (gren.velocity);
		}
		self.attack_finished_single = time + 1 + random();
		self.bulletcounter = time + 0.5;
	} else if (stay) {
		v = vectoangles(normalize(self.enemy.origin - self.origin));
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	}
	if (time > self.bulletcounter) {
		if (stay) {
			movelib_beak_simple(2000 * frametime);
			monster_common_composite_anim(MONSTER_BOSS1_ANIM_LEGS_IDLE, MONSTER_BOSS1_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
		} else {
			v = monster_move_walk(450, 5, 0);
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
			monster_common_composite_anim(MONSTER_BOSS1_ANIM_LEGS_WALK, MONSTER_BOSS1_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
		}
	} else {
		movelib_beak_simple(2000 * frametime);
		monster_common_composite_anim(MONSTER_BOSS1_ANIM_LEGS_IDLE, MONSTER_BOSS1_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
	}
}

void boss1_idle() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_BOSS1_ANIM_LEGS_IDLE, MONSTER_BOSS1_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
}

void boss1_guard() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	boss1_idle();
}

void boss1_walk() {
	self.nextthink = time;
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	if (monster_look_for_player(2000, 1000, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(boss1_idle, 100))
		return;

	monster_common_composite_anim(MONSTER_BOSS1_ANIM_LEGS_WALK, MONSTER_BOSS1_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(350, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void boss1_remove() {
	monster_common_on_remove();
	WaypointSprite_DetachCarrier(self);
}

void boss1_spawn() {
	monster_prepare(boss1_hunt, boss1_walk, boss1_idle);
	if (self.colormod != '0 0 0')
		self.colormod *= 0.25;
	else
		self.colormod = '0.75 0.5 0.25';

	monster_common_composite_setup("heavysoldier", "gl");
	self.entremove = boss1_remove;
	self.scale = 3.75;
	self.max_health = self.health;
	self.damageforcescale = 0.01;
	self.netname = "Big Heavy Soldier";
	self.anim_die1 = MONSTER_BOSS1_ANIM_DIE;
	self.frags = 10;
	self.view_ofs = '0 0 81';
	entity e = WaypointSprite_Spawn("danger", 0, 0, self, '0 0 0', world, 0, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateMaxHealth(e, self.health);
	WaypointSprite_UpdateHealth(e, self.health);
	WaypointSprite_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
}

void boss1_init() {
	dlc_require("monsters");
	monster_common_composite_precache("heavysoldier", "gl");
	precache_sound("weapons/grenade_fire.wav");
	projectile_init(PROJECTILE_GRENADE);
}

void spawnfunc_monster_boss1_spawn() {
	monster_common_setup_spawn_size('-48 -48 -72', '64 64 135', '0 0 24');
	monster_init(boss1_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise2 = "player/torus/death.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	self.atten = 0.1;
	monster_prepare_spawn(boss1_spawn, spawnfunc_monster_boss1_spawn);
}

#undef MONSTER_BOSS1_ANIM_DIE
#undef MONSTER_BOSS1_ANIM_LEGS_WALK
#undef MONSTER_BOSS1_ANIM_LEGS_IDLE
#undef MONSTER_BOSS1_ANIM_TORSO_STAND
#undef MONSTER_BOSS1_ANIM_TORSO_ATTACK
