#define monster_spider_idle spider_idle
#define monster_spider_guard spider_guard
#define monster_spider_walk spider_walk
#define monster_spider_hunt spider_hunt
#define monster_spider_spawn spider_spawn
#define monster_spider_remove spider_remove

void(void) monster_spider_idle;
void(void) monster_spider_guard;
void(void) monster_spider_walk;

void(void) monster_spider_hunt {
	self.nextthink = time;
	vector org = ENTITY_CENTER(self);
	if (monster_check_target(monster_spider_walk, monster_spider_guard))
		return;

	vector v = entity_nearest_point_on_box(self.enemy, org) - org;
	float f = vlen(v);
	if (f < 60 && !self.weapon) {
		self.enemy = self;
		self.classname = "explode";
		self.event_damage(self, self, self.health + 1, DEATH_HURTTRIGGER, (self.absmin + self.absmax) * 0.5, '0 0 0');
		return;
	}
	if (self.lip == 1 && f < self.dmg_radius) { //chainsaw jump
		if (normalize(v) * normalize(self.velocity) >= 0.5) {
			trace_line(org, ENTITY_CENTER(self.enemy), TRACE_MOVE_NORMAL, self);
			if (trace_ent == self.enemy) {
				damage(trace_ent, self, self, self.dmg_edge * frametime, WEAPON_MELEE, trace_endpos, normalize(v) * self.dmg_force * frametime);
			}
		}
	}
	float dofire;
	if (self.flags & FL_ONGROUND) {
		dofire = FALSE;
		if (self.attack_finished_single < time)
		if (f < 400) {
			trace_line(org, ENTITY_CENTER(self.enemy), TRACE_MOVE_WORLDONLY, self);
			if (trace_fraction == 1)
				dofire = TRUE;
		}
		if (dofire) {
			v = vectoangles(v);
			makevectors(v);
			self.velocity = self.velocity + v_up * 300 + v_forward * 500;
			if (self.weapon)
				self.attack_finished_single = time + 1 + random();
			else
				self.attack_finished_single = time + 4 + random();

			self.bulletcounter = time + 0.5;
			if (self.weapon) {
				sound(self, CHAN_WEAPON, "weapons/chainsaw_active_1.wav", VOL_BASE, ATTN_NORM);
			}
		} else if (self.flags & FL_ONGROUND) {
			v = monster_move_walk(500, 5, 0);
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
			self.lip = 1;
		}
	}
	if (time > self.bulletcounter) {
		self.frame = 0; //walk forward
		if (self.lip) {
			sound_stop(self, CHAN_WEAPON);
		}
	} else {
		self.frame = 4; //jump
	}
}

void(void) monster_spider_idle {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	self.frame = 5;
}

void(void) monster_spider_guard {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	monster_spider_idle();
}

void(void) monster_spider_walk {
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(monster_spider_idle, 100))
		return;

	self.frame = 0; //walk forward
	if (self.flags & FL_ONGROUND) {
		vector v = monster_move_walk(400, 5, 0);
		//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	}

}

void(void) monster_spider_remove {
	sound_stop(self, CHAN_WEAPON);
	if not(self.weapon)
		damage_radius (self, self, self.dmg_edge, 0, self.dmg_radius, world, self.dmg_force, EFFECT_IMPACT_GRENADE, WEAPON_GRENADE_LAUNCHER, world);

	remove(self.weaponentity);
}

void(void) monster_spider_spawn {
	monster_prepare(monster_spider_hunt, monster_spider_walk, monster_spider_idle);
    setmodel(self, "models/spiderbot/spiderbot.dpm");
	self.scale = 0.25;
	self.weaponentity = spawn();
	if (self.owner.weapon) {
		setmodel(self.weaponentity, "models/weapons/v_chainsaw.md3");
		self.weapon = 1;
	} else
		setmodel(self.weaponentity, "models/grenademodel.md3");
	
	setattachment(self.weaponentity, self, "tag_head");
	self.weaponentity.scale = 4;
	setorigin(self.weaponentity, '0 0 16');
	self.species = SPECIES_ROBOT_SOLID;
	self.movetype = MOVETYPE_WALK;
	self.entremove = monster_spider_remove;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 2;
	self.netname = "Explosive Spider";
	self.weaponentity.colormod = self.colormod;
}

void(void) monster_spider_init {
	precache_model("models/spiderbot/spiderbot.dpm");
	precache_model("models/grenademodel.md3");
}

void(void) monster_spider_chainsaw_init {
	dlc_require("chainsaw_v2");
	precache_model("models/spiderbot/spiderbot.dpm");
	precache_model("models/weapons/v_chainsaw.md3");
	precache_sound("weapons/chainsaw_active_1.wav");
}

void(void) spawnfunc_monster_spider_spawn {
	setsize(self, '-16 -16 0', '16 16 24');
	monster_init(monster_spider_init);
	monster_prepare_spawn(monster_spider_spawn, spawnfunc_monster_spider_spawn);
}

void(void) spawnfunc_monster_spider_chainsaw_spawn {
	setsize(self, '-16 -16 0', '16 16 24');
	self.weapon = 1;
	monster_init(monster_spider_chainsaw_init);
	monster_prepare_spawn(monster_spider_spawn, spawnfunc_monster_spider_spawn);
}

#undef monster_spider_idle
#undef monster_spider_guard
#undef monster_spider_walk
#undef monster_spider_hunt
#undef monster_spider_spawn
#undef monster_spider_remove
