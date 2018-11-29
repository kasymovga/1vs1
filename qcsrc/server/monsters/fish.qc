void fish_walk();

void fish_idle() {
	updateanim(self);
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 1)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
}

void fish_hunt() {
	updateanim(self);
	self.nextthink = time;
	if (monster_check_target(fish_walk, fish_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (vlen(self.origin - self.enemy.origin) < self.dmg_radius) {
		dofire = TRUE;
	}
	if (dofire) {
		traceline(self.origin, self.enemy.origin, MOVE_NORMAL, self);
		if (trace_ent) {
			Damage(trace_ent, self, self, self.dmg_edge * frametime, WEP_MELEE, trace_endpos, v_forward);
		}
		setanim(self, '1 18 18', TRUE, TRUE, FALSE);
		movelib_beak_simple(50 * frametime);
	} else {
		setanim(self, '40 18 18', TRUE, TRUE, FALSE);
		v = monster_move_swim(450, 5);
		if (v != '0 0 0') {
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
			self.angles_x = approach_angle(self.angles_x, v_x, 360 * frametime);
		}
	}
}

void fish_walk() {
	updateanim(self);
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 1)) {
		return;
	}
	if (monster_walk_finished(fish_idle, 100))
		return;

	vector v = monster_move_swim(300, 5);
	if (v != '0 0 0') {
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
		self.angles_x = approach_angle(self.angles_x, v_x, 90 * frametime);
	}
}

void fish_spawn() {
	self.movetype = MOVETYPE_WALK;
	self.species = SPECIES_ALIEN;
	self.netname = "Acid Fish";
	monster_prepare(fish_hunt, fish_walk, fish_idle);
	setmodel(self, "models/oq/fish.mdl");
	self.solid = SOLID_BBOX;
	self.scale = 1.6;
	self.gravity = 0.01;
	self.takedamage = DAMAGE_AIM;
	self.flags = MONSTER_IGNOREDROWN;
	setanim(self, '40 18 18', TRUE, TRUE, FALSE);
}

void fish_init() {
	precache_model("models/oq/fish.mdl");
	dlc_require("oqmodels");
}

void spawnfunc_monster_fish_spawn() {
	setsize(self, '-24 -24 -32', '24 24 16');
	monster_init(fish_init);
	monster_prepare_spawn(fish_spawn, spawnfunc_monster_fish_spawn);
}

