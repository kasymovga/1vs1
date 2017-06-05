void spearguy_idle();
void spearguy_guard();

void spearguy_hunt() {
	self.nextthink = time;
	vector v;
	v = monster_get_direction_to(self.enemy);
	if (self.enemy.health < 1) {
		self.think = spearguy_guard;
		spearguy_guard();
		return;
	}
	if (vlen(self.enemy.origin - self.origin) > 80) {
		setanim(self, '13 1 1', TRUE, TRUE, FALSE);
		monster_move_walk(v, 500, 5);
	} else {
		movelib_beak_simple(100 * frametime);
		setanim(self, '7 1 1', TRUE, TRUE, FALSE);
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1) {
			makevectors(self.angles);
			te_lightning1(world, self.origin + normalize(v_forward) * 20, self.enemy.origin);
			Damage(self.enemy, self, self, 50 * frametime, DEATH_TURRET, self.enemy.origin, v);
		}
	}
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
}

void spearguy_idle() {
	self.nextthink = time;
	movelib_beak_simple(100 * frametime);
	setanim(self, '7 1 1', TRUE, TRUE, FALSE);
	entity e;
	if ((e = monster_look_for_player(500, 0))) {
		self.enemy = e;
		self.think = spearguy_hunt;
	}
}

void spearguy_guard() {
	self.angles_y = self.angles_y + frametime * 15;
	spearguy_idle();
}

void spearguy_walk() {
	self.nextthink = time;
	setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	entity e;
	if ((e = monster_look_for_player(500, 0))) {
		self.enemy = e;
		self.think = spearguy_hunt;
		return;
	}
	vector v, v1;
	v1 = monster_get_direction_to(self.enemy);
	v = self.enemy.origin - self.origin;
	if (vlen(v) < frametime * 2 * (vlen(self.velocity)) + 32) {
		if (self.enemy.target)
			self.enemy = find(world, targetname, self.enemy.target);
		else
			self.enemy = world;

		if not(self.enemy)
			self.think = spearguy_idle;

		return;
	}
	//self.velocity = normalize(v) * 400;
	monster_move_walk(v1, 300, 5);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void spearguy_spawn() {
	monster_prepare(spearguy_hunt, spearguy_walk, spearguy_idle);
	setmodel(self, "models/player/lurk.zym");
	self.movetype = MOVETYPE_WALK;
	setsize(self, '-32 -32 -32', '32 32 32');
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.health = 100;
	self.damageforcescale = 1;
}

void spawnfunc_spearguy_spawn() {
	monster_prepare_spawn(spearguy_spawn, spawnfunc_spearguy_spawn);
}
