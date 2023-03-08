#define MONSTER_BOSS2_ANIM_DIE '0 29 15'
#define MONSTER_BOSS2_ANIM_LEGS_WALK '128 11 11'
#define MONSTER_BOSS2_ANIM_LEGS_IDLE '194 6 6'
#define MONSTER_BOSS2_ANIM_TORSO_STAND '155 9 9'
#define MONSTER_BOSS2_ANIM_TORSO_ATTACK '132 6 15'

void boss2_idle();
void boss2_guard();
void boss2_walk();

void boss2_pellet_touch()
{
	PROJECTILE_TOUCH;
	if(other.solid == SOLID_BSP)
		effect_impact(self.origin, self.dmg, 0, 0, normalize(self.velocity), EFFECT_IMPACT_PELLET, self);

	if (other && other.takedamage) {
		entity o = self.realowner;
		damage(other, self, o, self.dmg_edge, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity));
		self.cnt = 0;
	}
	if not(self.cnt) {
		remove(self);
		return;
	}
	self.cnt = self.cnt - 1;
	self.owner = world;
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void(vector start, vector dir) boss2_pellet {
	entity proj;
	proj = projectile(TRUE, PROJECTILE_BULLET_BIG, TRUE, self);
	projectile_setup(proj, start, EFFECT_IMPACT_PELLET, PROJECTILE_BULLET_BIG, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
	proj.movetype = MOVETYPE_BOUNCEMISSILE;
	proj.think = stdproc_remove;
	proj.nextthink = time + 10;
	proj.velocity = normalize(dir + randomvec() * 0.1) * 2000;
	weapon_setup_projectile_velocity(proj);
	proj.touch = boss2_pellet_touch;
	proj.oldvelocity = proj.velocity;
	proj.cnt = 3;
}

void boss2_hunt() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_check_target(boss2_walk, boss2_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		vector _shotorg = self.origin + self.maxs_z * '0 0 1' - '0 0 45';
		v = vectoangles(monster_look_to_end - _shotorg);
		self.angles_y = v_y;
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = normalize(monster_look_to_end - _shotorg);
		_shotorg = _shotorg + v_forward * self.maxs_x;
		sound (self, CHAN_WEAPON, "weapons/shotgun_fire.wav", VOL_BASE, ATTN_NORM);
		float sc;
		for (sc = 0; sc < 16; sc ++)
			boss2_pellet(_shotorg, _shotdir);

		pointparticles(particleeffectnum("shotgun_muzzleflash"), _shotorg, _shotdir * 1000, g_balance_shotgun_primary_ammo);
		self.attack_finished_single = time + 1 + random();
		self.bulletcounter = time + 0.5;
	}
	if (time > self.bulletcounter) {
		v = monster_move_walk(800, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		monster_common_composite_anim(MONSTER_BOSS2_ANIM_LEGS_WALK, MONSTER_BOSS2_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	} else {
		movelib_beak_simple(2000 * frametime);
		monster_common_composite_anim(MONSTER_BOSS2_ANIM_LEGS_IDLE, MONSTER_BOSS2_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
	}
}

void boss2_idle() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_BOSS2_ANIM_LEGS_IDLE, MONSTER_BOSS2_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
}

void boss2_guard() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;

	boss2_idle();
}

void boss2_walk() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(boss2_idle, 100))
		return;

	monster_common_composite_anim(MONSTER_BOSS2_ANIM_LEGS_WALK, MONSTER_BOSS2_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	vector v = monster_move_walk(600, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void boss2_remove() {
	WaypointSprite_DetachCarrier(self);
	remove(self.exteriorweaponentity);
}

void boss2_spawn() {
	monster_prepare(boss2_hunt, boss2_walk, boss2_idle);
	if (self.colormod != '0 0 0')
		self.colormod *= 0.25;
	else
		self.colormod = '0.75 0.5 0.25';

	monster_common_composite_setup("soldier", "shotgun");
	self.entremove = boss1_remove;
	self.scale = 3.75;
	self.max_health = self.health;
	self.damageforcescale = 0.01;
	self.netname = "Big Soldier";
	self.anim_die1 = MONSTER_BOSS2_ANIM_DIE;
	self.frags = 10;
	self.view_ofs = '0 0 81';
	entity e = WaypointSprite_Spawn("danger", 0, 0, self, '0 0 0', world, 0, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateMaxHealth(e, self.health);
	WaypointSprite_UpdateHealth(e, self.health);
	WaypointSprite_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
}

void boss2_init() {
	dlc_require("monsters");
	monster_common_composite_precache("heavysoldier", "gl");
	precache_sound("weapons/shotgun_fire.wav");
	projectile_init(PROJECTILE_BULLET_BIG);
}

void spawnfunc_monster_boss2_spawn() {
	monster_common_setup_spawn_size('-48 -48 -72', '64 64 135', '0 0 24');
	monster_init(boss2_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise2 = "player/torus/death.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	self.atten = 0.1;
	monster_prepare_spawn(boss2_spawn, spawnfunc_monster_boss2_spawn);
}

#undef MONSTER_BOSS2_ANIM_DIE
#undef MONSTER_BOSS2_ANIM_LEGS_IDLE
#undef MONSTER_BOSS2_ANIM_TORSO_STAND
#undef MONSTER_BOSS2_ANIM_TORSO_ATTACK
#undef MONSTER_BOSS2_MODEL_ORIGIN_ADJUST
