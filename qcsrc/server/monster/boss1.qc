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
		movelib_beak_simple(100 * frametime);
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);
		float i;
		for (i = 0; i < 4; i++) {
			entity gren = projectile(TRUE, PROJECTILE_GRENADE, TRUE, self);
			projectile_setup(gren,_shotorg, WEP_GRENADE_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0.01);
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
		movelib_beak_simple(1000 * frametime);
		v = vectoangles(normalize(self.enemy.origin - self.origin));
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	} else {
		v = monster_move_walk(450, 5, 0);
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

void boss1_idle() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
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

	anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(350, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void boss1_remove() {
	remove(self.exteriorweaponentity);
	WaypointSprite_DetachCarrier(self);
}

void boss1_spawn() {
	monster_prepare(boss1_hunt, boss1_walk, boss1_idle);
	setmodel(self, "models/player/grunt.zym");
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	self.entremove = boss1_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 17;

	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_gl.md3");
	self.scale = 3;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.max_health = self.health;
	self.damageforcescale = 0.01;
	self.netname = "Big Soldier";
	self.anim_die1 = '0 1 0.5';
	self.frags = 10;
	self.view_ofs = '0 0 105';
	entity e = WaypointSprite_Spawn("danger", 0, 0, self, '0 0 0', world, 0, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateMaxHealth(e, self.health);
	WaypointSprite_UpdateHealth(e, self.health);
	WaypointSprite_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
}

void boss1_init() {
	precache_model("models/player/grunt.zym");
	precache_model("models/weapons/v_gl.md3");
	precache_sound("weapons/grenade_fire.wav");
}

void spawnfunc_monster_boss1_spawn() {
	setsize(self, '-48 -48 -72', '64 64 135');
	monster_init(boss1_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise2 = "player/torus/death.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(boss1_spawn, spawnfunc_monster_boss1_spawn);
}
