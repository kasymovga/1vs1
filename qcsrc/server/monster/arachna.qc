//compatibility with old save files
#define monster_arachna_idle arachna_idle
#define monster_arachna_guard arachna_guard
#define monster_arachna_walk arachna_walk
#define monster_arachna_hunt arachna_hunt
#define monster_arachna_remove arachna_remove
#define monster_arachna_spawn arachna_spawn
void() monster_arachna_idle;
void() monster_arachna_guard;
void() monster_arachna_walk;

void() monster_arachna_hunt {
	self.nextthink = time;
	if (monster_check_target(monster_arachna_walk, monster_arachna_guard))
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
		if (vlen(monster_look_to_end - self.origin) < 80) {
			self.bulletcounter = time + 1;
			self.lip = TRUE;
			trace_box(self.origin, '-8 -8 -8', '8 8 8', self.origin + v_forward * 80, TRACE_MOVE_NORMAL, self);
			pointparticles(particleeffectnum("laser_impact"), self.origin + v_forward * 40, v_forward, 1);
			if (trace_ent)
			if (trace_ent.takedamage) {
				damage(trace_ent, self, self, self.dmg_edge, WEAPON_MELEE, trace_endpos, v_forward * 300 + v_up * 50);
			}
			self.attack_finished_single = time + 0.5 + random();
			self.bulletcounter = time + 0.5;
			sound(self, CHAN_WEAPON, "player/pyria-skadi/player/jump.wav", VOL_BASE, ATTN_NORM);
		} else {
			self.lip = FALSE;
			vector _shotdir = monster_look_to_end - self.origin;
			vector _shotorg = self.origin + v_forward * 16;
			sound(self, CHAN_WEAPON, "weapons/electro_fire.wav", VOL_BASE, ATTN_NORM);
			entity proj = monster_projectile(TRUE, PROJECTILE_ELECTRO, TRUE, self);
			projectile_setup(proj,_shotorg, EFFECT_IMPACT_PLASMA, WEAPON_ELECTRO, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
			proj.touch = projectile_touch_explode;
			proj.velocity = normalize(_shotdir) * 1600;
			proj.pushltime = time + 10;
			self.attack_finished_single = time + 2 + random();
			self.bulletcounter = time + 0.5;
		}
	}
	if (time > self.bulletcounter) {
		v = monster_move_walk(500, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		anim_set(self, '16 1 1', TRUE, TRUE, FALSE);
	} else {
		move_beak_simple(2000 * frametime);
		if (self.lip)
			anim_set(self, '9 1 1', TRUE, TRUE, FALSE);
		else
			anim_set(self, '8 1 1', TRUE, TRUE, FALSE);
	}
}

void() monster_arachna_idle {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	move_beak_simple(100 * frametime);
	anim_set(self, '23 1 1', TRUE, TRUE, FALSE);
}

void() monster_arachna_guard {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	monster_arachna_idle();
}

void() monster_arachna_walk {
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(monster_arachna_idle, 100))
		return;

	anim_set(self, '15 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(250, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
}

void() monster_arachna_remove {
	remove(self.exteriorweaponentity);
}

void(void) arachna_model_setup {
	if (dlc_ready("arachna")) {
		setmodel(self, "models/arachna/arachna.md3");
		setattachment(self.exteriorweaponentity, self, "tag_weapon");
	}
}

void() arachna_dlc_reset {
	vector _mins = self.mins;
	vector _maxs = self.maxs;
	arachna_model_setup();
	setsize(self, _mins, _maxs);
}

void() monster_arachna_spawn {
	monster_prepare(monster_arachna_hunt, monster_arachna_walk, monster_arachna_idle);
	self.movetype = MOVETYPE_WALK;
	self.species = SPECIES_ALIEN;
	self.exteriorweaponentity = spawn();
	self.entremove = monster_arachna_remove;
	self.exteriorweaponentity.scale = 0.6;
	setmodel(self.exteriorweaponentity, "models/weapons/v_electro.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Arachna";
	self.view_ofs = '0 0 16';
	self.dlc_reset = arachna_dlc_reset;
	arachna_model_setup();
}

void() arachna_init {
	precache_model("models/arachna/arachna.md3");
	precache_model("models/weapons/v_electro.md3");
	precache_sound("weapons/electro_fire.wav");
	precache_sound("player/pyria-skadi/player/jump.wav");
	dlc_require("arachna");
	projectile_init(PROJECTILE_ELECTRO);
}

void() spawnfunc_monster_arachna_spawn {
	setsize(self, '-16 -16 -24', '16 16 32');
	monster_init(arachna_init);
	self.noise1 = "player/pyria-skadi/coms/incoming.ogg";
	self.noise3 = "player/pyria-skadi/player/pain50.ogg";
	monster_prepare_spawn(monster_arachna_spawn, spawnfunc_monster_arachna_spawn);
}

#undef monster_arachna_idle
#undef monster_arachna_guard
#undef monster_arachna_walk
#undef monster_arachna_hunt
#undef monster_arachna_remove
#undef monster_arachna_spawn
