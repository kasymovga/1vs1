void spider_idle();
void spider_guard();
void spider_walk();

void spider_hunt() {
	self.nextthink = time;
	if (monster_check_target(spider_walk, spider_guard))
		return;

	vector v = self.enemy.origin - self.origin;
	float f = vlen(v);
	if (f < 75) {
		self.enemy = self;
		monster_die();
		return;
	}
	float dofire;
	if (self.flags & FL_ONGROUND) {
		dofire = FALSE;
		if (self.attack_finished_single < time)
		if (f < 400)
		{
			traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
			if (trace_fraction == 1)
				dofire = TRUE;
		}
		if (dofire) {
			v = vectoangles(v);
			makevectors(v);
			self.velocity = self.velocity + v_up * 300 + v_forward * 500;
			self.attack_finished_single = time + 4 + random();
			self.bulletcounter = time + 0.5;
		} else if (self.flags & FL_ONGROUND) {
			v = monster_move_walk(500, 5, 0);
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
		}
	}
	if (time > self.bulletcounter) {
		self.anim_start = MODEL_SPIDERBOT_FORWARD_START;
		self.anim_end   = MODEL_SPIDERBOT_FORWARD_END;
		self.frame      = 0;
	} else {
		self.anim_start = MODEL_SPIDERBOT_JUMP_START;
		self.anim_end   = MODEL_SPIDERBOT_JUMP_END;
		self.frame      = 4;
	}
}

void spider_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	self.anim_start = 0;
	self.anim_end = 0;
	self.frame = 5;
}

void spider_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	spider_idle();
}

void spider_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(spider_idle, 100))
		return;

	self.anim_start = MODEL_SPIDERBOT_FORWARD_START;
	self.anim_end   = MODEL_SPIDERBOT_FORWARD_END;
	self.frame      = 0;
	if (self.flags & FL_ONGROUND) {
		vector v = monster_move_walk(400, 5, 0);
		//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
	}

}

void spider_remove() {
	RadiusDamage (self, self, 100, 0, 150, world, 100, WEP_GRENADE_LAUNCHER, world);
	remove(self.weaponentity);
}

void spider_spawn() {
	monster_prepare(spider_hunt, spider_walk, spider_idle);
    setmodel(self, "models/spiderbot/spiderbot.dpm");
	self.scale = 0.25;
	self.weaponentity = spawn();
	setmodel(self.weaponentity, "models/grenademodel.md3");
	setattachment(self.weaponentity, self, "tag_head");
	self.weaponentity.scale = 4;
	setorigin(self.weaponentity, '0 0 16');
	self.species = SPECIES_ROBOT_SOLID;
	self.movetype = MOVETYPE_WALK;
	self.entremove = spider_remove;
	setsize(self, '-16 -16 0', '16 16 24');
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Explosive Spider";
}

void spider_init() {
	precache_model("models/spiderbot/spiderbot.dpm");
	precache_model("models/grenademodel.md3");
}

void spawnfunc_spider_spawn() {
	monster_init(spider_init);
	monster_prepare_spawn(spider_spawn, spawnfunc_spider_spawn);
}
