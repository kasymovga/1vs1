#define MONSTER_BOSS4_ANIM_DIE '15 11 10'
#define MONSTER_BOSS4_ANIM_LEGS_WALK '67 11 20'
#define MONSTER_BOSS4_ANIM_LEGS_IDLE '173 10 10'
#define MONSTER_BOSS4_ANIM_TORSO_STAND '82 1 15'
#define MONSTER_BOSS4_ANIM_TORSO_ATTACK '132 6 15'
#define MONSTER_BOSS4_ANIM_TORSO_DROP '144 5 20'

void boss4_idle();
void boss4_guard();
void boss4_walk();

float boss4_prethink_skip(void) {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	if (self.owner.spawnflags & MONSTER_SPAWN_SHIELDED)
	if not(self.spawnflags & MONSTER_SPAWN_SHIELDED) {
		monster_common_composite_anim(MONSTER_BOSS4_ANIM_LEGS_IDLE, MONSTER_BOSS4_ANIM_TORSO_DROP, '9 1 1', TRUE, FALSE);
		self.lip = TRUE;
		return TRUE;
	}
	if (self.lip) {
		self.lip = FALSE;
		self.attack_finished_single = time + 1;
		monster_sound(self, "player/carni-lycan/coms/taunt2.ogg", TRUE);
	}
	return FALSE;
}

void boss4_mine_think()
{
	if(time > self.pushltime)
	{
		remove(self);
		return;
	}
	if (self.waterlevel > 0) {
		remove(self);
		return;
	}
	weapon_fireball_laser_play(0.1, self.dmg_radius, self.dmg * 0.25, 0, 4);
	self.nextthink = time + 0.1;
}

void boss4_hunt() {
	self.nextthink = time;
	if (boss4_prethink_skip())
		return;

	if (monster_check_target(boss4_walk, boss4_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	float stay = self.owner.spawnflags & MONSTER_SPAWN_STAYSTILL;
	if (dofire) {
		vector _shotorg = self.origin + self.maxs_z * '0 0 1' - '0 0 90';
		v = vectoangles(monster_look_to_end - _shotorg);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - _shotorg;
		_shotorg = _shotorg + v_forward * self.maxs_x;
		sound (self, CHAN_WEAPON, "weapons/fireball_fire.wav", VOL_BASE, ATTN_NORM);
		entity proj = projectile(TRUE, PROJECTILE_FIREBALL, TRUE, self);
		projectile_setup(proj, _shotorg, EFFECT_IMPACT_FIREBALL, WEAPON_FIREBALL, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
		proj.touch = projectile_touch_explode;
		proj.think = boss4_mine_think;
		proj.nextthink = time;
		proj.velocity = normalize(_shotdir) * 1000;
		proj.pushltime = time + 20;
		weapon_setup_projectile_velocity(proj);
		self.attack_finished_single = time + 1 + random();
		self.bulletcounter = time + 0.5;
	} else if (stay) {
		v = vectoangles(normalize(self.enemy.origin - self.origin));
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	}
	if (time > self.bulletcounter) {
		if (stay) {
			movelib_beak_simple(2000 * frametime);
			monster_common_composite_anim(MONSTER_BOSS4_ANIM_LEGS_IDLE, MONSTER_BOSS4_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
		} else {
			v = monster_move_walk(750, 5, 0);
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
			monster_common_composite_anim(MONSTER_BOSS4_ANIM_LEGS_WALK, MONSTER_BOSS4_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
		}
	} else {
		movelib_beak_simple(2000 * frametime);
		monster_common_composite_anim(MONSTER_BOSS4_ANIM_LEGS_IDLE, MONSTER_BOSS4_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
	}
}

void boss4_idle() {
	self.nextthink = time;
	if (boss4_prethink_skip())
		return;

	if (monster_look_for_player(2000, 500, 0, 1, 3))
		return;

	movelib_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_BOSS4_ANIM_LEGS_IDLE, MONSTER_BOSS4_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
}

void boss4_guard() {
	if (boss4_prethink_skip()) {
		self.nextthink = time;
		return;
	}
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;

	boss4_idle();
}

void boss4_walk() {
	self.nextthink = time;
	if (boss4_prethink_skip())
		return;

	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(boss4_idle, 100))
		return;

	monster_common_composite_anim(MONSTER_BOSS4_ANIM_LEGS_WALK, MONSTER_BOSS4_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(450, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void boss4_remove() {
	monster_common_on_remove();
	if (self.fire_burner)
		remove(self.fire_burner);

	WaypointSprite_DetachCarrier(self);
}

void boss4_spawn() {
	monster_prepare(boss4_hunt, boss4_walk, boss4_idle);
	if (self.colormod != '0 0 0')
		self.colormod *= 0.25;
	else
		self.colormod = '0.75 0.5 0.25';

	monster_common_composite_setup("fireguy", "fireball");
	self.scale = 3.75;
	self.entremove = boss1_remove;
	self.netname = "Big FireGuy";
	self.max_health = self.health;
	self.damageforcescale = 0.01;
	self.ammo_rockets = 10;
	self.flags = MONSTER_IGNOREFIRE;
	self.anim_die1 = MONSTER_BOSS4_ANIM_DIE;
	self.view_ofs = '0 0 81';
	self.weaponentity.weaponentity.effects = EFFECT_FLAME;
	entity e = WaypointSprite_Spawn("danger", 0, 0, self, '0 0 0', world, 0, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateMaxHealth(e, self.health);
	WaypointSprite_UpdateHealth(e, self.health);
	WaypointSprite_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
}

void(void) monster_boss4_init {
	dlc_require("monsters");
	monster_common_composite_precache("fireguy", "fireball");
	precache_sound("player/carni-lycan/coms/taunt2.ogg");
	precache_sound("weapons/fireball_fire.wav");
	projectile_init(PROJECTILE_FIREBALL);
}

void(void) spawnfunc_monster_boss4_spawn {
	setsize(self, '-48 -48 -72', '64 64 135');
	monster_init(monster_boss4_init);
	self.noise1 = "player/carni-lycan/coms/incoming.ogg";
	self.noise2 = "player/carni-lycan/player/death2.ogg";
	self.noise3 = "player/carni-lycan/player/pain50.ogg";
	self.atten = 0.1;
	monster_prepare_spawn(boss4_spawn, spawnfunc_monster_boss4_spawn);
}

#undef MONSTER_BOSS4_ANIM_DIE
#undef MONSTER_BOSS4_ANIM_LEGS_WALK
#undef MONSTER_BOSS4_ANIM_LEGS_IDLE
#undef MONSTER_BOSS4_ANIM_TORSO_STAND
#undef MONSTER_BOSS4_ANIM_TORSO_ATTACK
