void() monster_ewheel_walk;

void() monster_ewheel_idle {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	move_beak_simple(50 * frametime);
	anim_set(self, '0 0 0', TRUE, TRUE, FALSE);
	anim_update(self);
}

void() monster_ewheel_hunt {
	self.nextthink = time;
	if (monster_check_target(monster_ewheel_walk, monster_ewheel_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		makevectors(self.angles);
		if (v_forward * normalize(self.enemy.origin - self.origin) > 0.75) {
			vector _shotdir = normalize(self.enemy.origin - self.origin);
			_shotdir_x = v_forward_x;
			_shotdir_y = v_forward_y;
			vector _shotorg = self.origin + v_forward * 16;
			sound(self, CHAN_WEAPON, "weapons/lasergun_fire.wav", VOL_BASE, ATTN_NORM);
			float i;
			for (i = -1; i < 2; i += 2) {
				entity proj = monster_projectile(TRUE, PROJECTILE_LASER, TRUE, self);
				projectile_setup(proj, _shotorg + v_right * i * 16, EFFECT_IMPACT_LASER, WEAPON_LASER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
				proj.nextthink = time + 5;
				proj.think = projectile_think2use;
				proj.use = projectile_explode;
				proj.touch = projectile_touch_explode;
				proj.velocity = normalize(_shotdir) * 3200;
				weapon_setup_projectile_velocity(proj);
				self.attack_finished_single = time + 2 + random();
			}
		}
	}
	v = monster_move_walk(500, 1, 0);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	self.frame = 2;
}

void() monster_ewheel_walk {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(monster_ewheel_idle, 100))
		return;

	self.frame = 1;
	if (self.flags & FL_ONGROUND) {
		vector v = monster_move_walk(400, 1, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	}
}

void() monster_ewheel_remove {
	remove(self.weaponentity);
}

void() monster_ewheel_spawn {
	monster_prepare(monster_ewheel_hunt, monster_ewheel_walk, monster_ewheel_idle);
	setmodel(self, "models/turrets/ewheel-base2.md3");
	self.weaponentity = spawn();
	setmodel(self.weaponentity, "models/turrets/ewheel-gun1.md3");
    setattachment(self.weaponentity, self, "tag_head");
	self.species = SPECIES_ROBOT_SOLID;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Magic Wheel";
	self.movetype = MOVETYPE_WALK;
	self.entremove = monster_ewheel_remove;
	self.takedamage = DAMAGE_AIM;
	self.weaponentity.colormod = self.colormod;
	self.ammo_cells = 10;
}

void(void) monster_ewheel_init {
	precache_model ("models/turrets/ewheel-base2.md3");
	precache_model ("models/turrets/ewheel-gun1.md3");
	precache_sound("weapons/uzi_fire.wav");
	projectile_init(PROJECTILE_LASER);
}

void(void) spawnfunc_monster_ewheel_spawn {
    setsize(self,'-32 -32 0','32 32 48');
	monster_init(monster_ewheel_init);
	monster_prepare_spawn(monster_ewheel_spawn, spawnfunc_monster_ewheel_spawn);
}
