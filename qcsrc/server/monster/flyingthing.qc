//compatibility with old save files
#define monster_flyingthing_idle flyingthing_idle
#define monster_flyingthing_walk flyingthing_walk
#define monster_flyingthing_hunt flyingthing_hunt
#define monster_flyingthing_spawn flyingthing_spawn

void() monster_flyingthing_walk;

void() monster_flyingthing_idle {
	self.movetype = MOVETYPE_FLY;
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	monster_move_fly_idle(100, 5);
}

void() monster_flyingthing_hunt {
	self.movetype = MOVETYPE_WALK;
	self.nextthink = time;
	if (monster_check_target(monster_flyingthing_walk, monster_flyingthing_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		self.angles_x = v_x;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16 - '0 0 24';
		sound (self, CHAN_WEAPON, "weapons/electro_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren = monster_projectile(TRUE, PROJECTILE_ELECTRO_BEAM, TRUE, self);
		projectile_setup(gren,_shotorg, EFFECT_IMPACT_PLASMA, WEAPON_ELECTRO, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
		gren.nextthink = time + 5;
		gren.think = projectile_think2use;
		gren.use = projectile_explode;
		gren.touch = projectile_touch_explode;
		gren.velocity = normalize(_shotdir) * 2400;
		weapon_setup_projectile_velocity(gren);
		self.attack_finished_single = time + 1 + random();
	} else {
		v = monster_move_fly(450, 5);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
		self.angles_x = approach_angle(self.angles_x, v_x, 360 * frametime);
	}
}

void() monster_flyingthing_walk {
	self.movetype = MOVETYPE_WALK;
	self.nextthink = time;
	if (monster_look_for_player(3000, 500, 0, 1, 1)) {
		return;
	}
	if (monster_walk_finished(monster_flyingthing_idle, 100))
		return;

	//self.velocity = normalize(v) * 400;
	vector v = monster_move_fly(300, 5);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
	self.angles_x = approach_angle(self.angles_x, v_x, 90 * frametime);
}

void(void) monster_flyingthing_die {
	vector o = ENTITY_CENTER(self);
	float i;
	entity gren;
	for (i = 0; i < 4; i++) {
		gren = monster_projectile(TRUE, PROJECTILE_ELECTRO_BEAM, TRUE, NULL);
		projectile_setup(gren,o, EFFECT_IMPACT_PLASMA, WEAPON_ELECTRO, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_TOSS);
		gren.nextthink = time + 5;
		gren.think = projectile_think2use;
		gren.use = projectile_explode;
		gren.touch = projectile_touch_explode;
		gren.velocity = randomvec() * 500;
	}
}

void() monster_flyingthing_spawn {
	self.movetype = MOVETYPE_FLY;
	self.species = SPECIES_ROBOT_SOLID;
	self.netname = "Flying Thing";
	monster_set_fly();
	monster_prepare(monster_flyingthing_hunt, monster_flyingthing_walk, monster_flyingthing_idle);
	setmodel(self, "models/turrets/walker_mghead.md3");
	self.colormod = '2 3 1';
	//self.effects = EFFECT_FULLBRIGHT;
	self.solid = SOLID_BBOX;
	self.gravity = 0.01;
	self.takedamage = DAMAGE_AIM;
	self.view_ofs = '0 0 -16';
	self.damageforcescale = 1;
	self.ammo_cells = 10;
	self.use = monster_flyingthing_die;
}

void(void) monster_flyingthing_init {
	precache_sound("weapons/electro_fire.wav");
	precache_model("models/turrets/walker_mghead.md3");
	projectile_init(PROJECTILE_ELECTRO_BEAM);
}

void(void) spawnfunc_monster_flyingthing_spawn {
	setsize(self, '-16 -16 -48', '16 16 0');
	monster_init(monster_flyingthing_init);
	monster_prepare_spawn(monster_flyingthing_spawn, spawnfunc_monster_flyingthing_spawn);
}

#undef monster_flyingthing_idle
#undef monster_flyingthing_walk
#undef monster_flyingthing_hunt
#undef monster_flyingthing_spawn
