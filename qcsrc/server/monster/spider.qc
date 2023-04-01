void spider_idle();
void spider_guard();
void spider_walk();

void spider_hunt() {
	self.nextthink = time;
	if (monster_check_target(spider_walk, spider_guard))
		return;

	vector v = entity_nearest_point_on_box(self.enemy, self.origin) - self.origin;
	float f = vlen(v);
	if (f < 60) {
		self.enemy = self;
		self.classname = "explode";
		self.event_damage(self, self, self.health + 1, DEATH_HURTTRIGGER, (self.absmin + self.absmax) * 0.5, '0 0 0');
		return;
	}
	float dofire;
	if (self.flags & FL_ONGROUND) {
		dofire = FALSE;
		if (self.attack_finished_single < time)
		if (f < 400)
		{
			trace_line(self.origin, self.enemy.origin, TRACE_MOVE_WORLDONLY, self);
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
			self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		}
	}
	if (time > self.bulletcounter) {
		self.frame = 0; //walk forward
	} else {
		self.frame = 4; //jump
	}
}

void spider_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
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

	self.frame = 0; //walk forward
	if (self.flags & FL_ONGROUND) {
		vector v = monster_move_walk(400, 5, 0);
		//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	}

}

void spider_remove() {
	damage_radius (self, self, self.dmg_edge, 0, self.dmg_radius, world, self.dmg_force, EFFECT_IMPACT_GRENADE, WEAPON_GRENADE_LAUNCHER, world);
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
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Explosive Spider";
	self.weaponentity.colormod = self.colormod;
}

void(void) monster_spider_init {
	precache_model("models/spiderbot/spiderbot.dpm");
	precache_model("models/grenademodel.md3");
}

void(void) spawnfunc_monster_spider_spawn {
	setsize(self, '-16 -16 0', '16 16 24');
	monster_init(monster_spider_init);
	monster_prepare_spawn(spider_spawn, spawnfunc_monster_spider_spawn);
}
