#define MONSTER_FIREGUY_ANIM_LEGS_WALK '67 11 20'
#define MONSTER_FIREGUY_ANIM_LEGS_IDLE '173 10 10'
#define MONSTER_FIREGUY_ANIM_TORSO_STAND '82 1 15'
#define MONSTER_FIREGUY_ANIM_TORSO_ATTACK '132 6 15'
void fireguy_idle();
void fireguy_guard();
void fireguy_walk();

void(void) fireguy_mine_touch {
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
	if(fire_add_damage(other, self.realowner, self.dmg_edge, 2, self.projectiledeathtype | HITTYPE_HEADSHOT) >= 0) {
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void fireguy_mine_think()
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
	weapon_fireball_laser_play(0.1, self.dmg_radius, self.dmg_edge, 0, 4);
	self.nextthink = time + 0.1;
}

void fireguy_hunt() {
	self.nextthink = time;
	if (monster_check_target(fireguy_walk, fireguy_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	float stay = self.owner.spawnflags & MONSTER_SPAWN_STAYSTILL;
	if (dofire) {
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 12;
		sound (self, CHAN_WEAPON, "weapons/fireball_fire.wav", VOL_BASE, ATTN_NORM);
		entity proj = projectile(TRUE, PROJECTILE_FIREMINE, TRUE, self);
		projectile_setup(proj, _shotorg, 0, WEAPON_FIREBALL, self.dmg_edge, self.dmg_edge, self.dmg_radius, self.dmg_force, 1, MOVETYPE_BOUNCE);
		proj.touch = fireguy_mine_touch;
		proj.think = fireguy_mine_think;
		proj.nextthink = time;
		proj.damageforcescale = 0.5;
		proj.velocity = normalize(_shotdir) * 2000 + v_up * 50;
		proj.pushltime = time + 5;
		weapon_setup_projectile_velocity(proj);
		self.attack_finished_single = time + 3 + random();
		self.bulletcounter = time + 0.5;
	} else if (stay) {
		v = vectoangles(normalize(self.enemy.origin - self.origin));
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	}
	if (time > self.bulletcounter) {
		if (stay) {
			movelib_beak_simple(2000 * frametime);
			monster_common_composite_anim(MONSTER_FIREGUY_ANIM_LEGS_IDLE, MONSTER_FIREGUY_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
		} else {
			v = monster_move_walk(250, 5, 0);
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
			monster_common_composite_anim(MONSTER_FIREGUY_ANIM_LEGS_WALK, MONSTER_FIREGUY_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
		}
	} else {
		movelib_beak_simple(2000 * frametime);
		monster_common_composite_anim(MONSTER_FIREGUY_ANIM_LEGS_IDLE, MONSTER_FIREGUY_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
	}
}

void fireguy_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_FIREGUY_ANIM_LEGS_IDLE, MONSTER_FIREGUY_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
}

void fireguy_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	fireguy_idle();
}

void fireguy_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(fireguy_idle, 40))
		return;

	monster_common_composite_anim(MONSTER_FIREGUY_ANIM_LEGS_WALK, MONSTER_FIREGUY_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(150, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void fireguy_remove() {
	monster_common_on_remove();
}

void fireguy_spawn() {
	monster_prepare(fireguy_hunt, fireguy_walk, fireguy_idle);
	monster_common_composite_setup("fireguy", "fireball");
	self.damageforcescale = 1;
	self.netname = "FireGuy";
	self.ammo_rockets = 20;
	self.flags = MONSTER_IGNOREFIRE;
	self.view_ofs = '0 0 27';
}

void(void) monster_fireguy_init {
	dlc_require("monsters");
	monster_common_composite_precache("fireguy", "fireball");
	precache_sound("weapons/fireball_fire.wav");
	projectile_init(PROJECTILE_FIREMINE);
}

void(void) spawnfunc_monster_fireguy_spawn {
	monster_common_setup_spawn_size('-16 -16 -24', '16 16 45', '0 0 8');
	monster_init(monster_fireguy_init);
	self.noise1 = "player/carni-lycan/coms/incoming.ogg";
	self.noise3 = "player/carni-lycan/player/pain50.ogg";
	monster_prepare_spawn(fireguy_spawn, spawnfunc_monster_fireguy_spawn);
}

#undef MONSTER_FIREGUY_ANIM_LEGS_WALK
#undef MONSTER_FIREGUY_ANIM_LEGS_IDLE
#undef MONSTER_FIREGUY_ANIM_TORSO_STAND
#undef MONSTER_FIREGUY_ANIM_TORSO_ATTACK
