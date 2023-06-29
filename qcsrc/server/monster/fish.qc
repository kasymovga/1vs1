//compatibility with old save files
#define monster_fish_idle fish_idle
#define monster_fish_walk fish_walk
#define monster_fish_hunt fish_hunt
#define monster_fish_spawn fish_spawn

void() monster_fish_walk;

void() monster_fish_idle {
	anim_update(self);
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 1)) {
		return;
	}
	move_beak_simple(100 * frametime);
}

void() monster_fish_hunt {
	anim_update(self);
	self.nextthink = time;
	if (monster_check_target(monster_fish_walk, monster_fish_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	v = entity_nearest_point_on_box(self.enemy, self.origin);
	if (vlen(self.origin - v) < self.dmg_radius) {
		dofire = TRUE;
	}
	if (dofire) {
		trace_line(self.origin, v, TRACE_MOVE_NORMAL, self);
		if (trace_ent) {
			damage(trace_ent, self, self, self.dmg_edge * frametime, WEAPON_MELEE, trace_endpos, v_forward);
		}
		anim_set(self, '1 18 18', TRUE, TRUE, FALSE);
		move_beak_simple(50 * frametime);
	} else {
		anim_set(self, '40 18 18', TRUE, TRUE, FALSE);
		v = monster_move_swim(450, 5);
		if (v != '0 0 0') {
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
			self.angles_x = approach_angle(self.angles_x, v_x, 360 * frametime);
		}
	}
}

void() monster_fish_walk {
	anim_update(self);
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 1)) {
		return;
	}
	if (monster_walk_finished(monster_fish_idle, 100))
		return;

	vector v = monster_move_swim(300, 5);
	if (v != '0 0 0') {
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
		self.angles_x = approach_angle(self.angles_x, v_x, 90 * frametime);
	}
}

void() monster_fish_spawn {
	self.movetype = MOVETYPE_WALK;
	self.species = SPECIES_ALIEN;
	self.netname = "Acid Fish";
	monster_prepare(monster_fish_hunt, monster_fish_walk, monster_fish_idle);
	setmodel(self, "models/oq/fish.mdl");
	self.solid = SOLID_BBOX;
	self.scale = 1.6;
	self.gravity = 0.01;
	self.takedamage = DAMAGE_AIM;
	self.flags = MONSTER_IGNOREDROWN;
	anim_set(self, '40 18 18', TRUE, TRUE, FALSE);
}

void(void) monster_fish_init {
	precache_model("models/oq/fish.mdl");
	dlc_require("oqmodels");
}

void(void) spawnfunc_monster_fish_spawn {
	setsize(self, '-24 -24 -32', '24 24 16');
	monster_init(monster_fish_init);
	monster_prepare_spawn(monster_fish_spawn, spawnfunc_monster_fish_spawn);
}

#undef monster_fish_idle
#undef monster_fish_walk
#undef monster_fish_hunt
#undef monster_fish_spawn
