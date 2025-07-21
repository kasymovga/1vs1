void(string t) func_boss_controller_switch_target {
	entity boss = self.enemy;
	self.aiment = find(NULL, targetname, t);
	if (self.aiment) {
		entity_angles_normalize(boss, self.aiment.angles);
		self.speed = (self.aiment.speed ? self.aiment.speed : boss.speed);
	} else
		self.speed = boss.speed;
}

void(void) func_boss_controller_think {
	entity e;
	self.nextthink = time;
	entity boss = self.enemy;
	if not(boss.state)
		return;

	if not(self.aiment) {
		func_boss_controller_switch_target(boss.target);
	}
	if not(self.aiment) {
		return;
	}
	if (boss.speed) {
		vector d = self.aiment.origin - boss.origin;
		vector step = normalize(d) * boss.speed * frametime;
		float dl = vlen(d);
		float stepl = vlen(step);
		if (stepl >= dl) {
			setorigin(boss, self.aiment.origin);
			boss.angles = self.aiment.angles;
			func_boss_controller_switch_target(self.aiment.target);
		} else {
			setorigin(boss, boss.origin + step);
			float f = stepl / dl;
			boss.angles = self.aiment.angles * f + boss.angles * (1 - f);
		}
	}
	if (boss.targetname != "") {
		for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
			if (e.classname != "func_boss_part" && e.classname != "func_boss_shooter") continue;
			makevectors(boss.angles);
			e.angles = boss.angles;
			setorigin(e, boss.origin + v_forward * e.pos1_x - v_right * e.pos1_y + v_up * e.pos1_z);
		}
	}
}

void(void) func_boss_init_delayed {
	entity e;
	e = spawn();
	self.enemy = e;
	e.enemy = self;
	e.classname = "func_boss_controller";
	e.think = func_boss_controller_think;
	e.nextthink = time;
	if (self.targetname != "") {
		for (e = find(NULL, target, self.targetname); e; e = find(e, target, self.targetname)) {
			if (e.classname != "func_boss_part" && e.classname != "func_boss_shooter") continue;
			e.owner = self;
			e.pos1 = e.origin - self.origin;
		}
	}
}

void(void) func_boss_move_next {
	entity e, t, oldself;
	if (self.target == "") return;
	t = find(NULL, targetname, self.target);
	if not(t) return;
	float spd = (t.speed ? t.speed : self.speed);
	self.target = t.target;
}

void(void) func_boss_use {
	self.state = 1;
}

void(void) spawnfunc_func_boss {
	model_init(SOLID_BSP);
	entity_initialize(self, func_boss_init_delayed, INITPRIO_FINDTARGET);
	self.use = func_boss_use;
	self.state = 0;
	if (self.speed <= 0) self.speed = 1000;
}

void(void) spawnfunc_func_boss_part {
	model_init(SOLID_BSP);
}

void(void) spawnfunc_func_boss_shooter {
	model_init(SOLID_BSP);
}
