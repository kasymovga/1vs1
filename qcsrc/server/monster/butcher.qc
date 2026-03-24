//compatibility with old save files
#define monster_butcher_idle butcher_idle
#define monster_butcher_guard butcher_guard
#define monster_butcher_walk butcher_walk
#define monster_butcher_hunt butcher_hunt
#define monster_butcher_spawn butcher_spawn

void() monster_butcher_idle;
void() monster_butcher_guard;
void() monster_butcher_walk;

void() monster_butcher_hunt {
	self.nextthink = time;
	if (monster_check_target(monster_butcher_walk, monster_butcher_guard))
		return;

	vector v = '0 0 0';
	float dofire;
	if (self.attack_finished_single < time) {
		v = entity_nearest_point_on_box(self.enemy, self.origin);
		if (vlen(v - self.origin) <= self.dmg_radius) {
			self.attack_finished_single = time + 0.5;
			self.lastshot_time = FALSE;
			dofire = TRUE;
		} else
			dofire = FALSE;
	} else if (self.attack_finished_single + 0.5 > time) {
		v = entity_nearest_point_on_box(self.enemy, self.origin);
		dofire = TRUE;
	} else
		dofire = FALSE;

	if (dofire) {
		if not(self.lastshot_time) {
			if (vlen(v - self.origin) <= self.dmg_radius)
			if (self.attack_finished_single - time < 0.25) {
				trace_line(self.origin, v, TRACE_MOVE_NORMAL, self);
				if (trace_ent) {
					damage(trace_ent, self, self, self.dmg_edge, WEAPON_MELEE, trace_endpos, v_forward);
					self.lastshot_time = time;
				}
			}
		}
		v = self.enemy.origin - self.origin;
		move_beak_simple(200 * frametime);
		anim_set(self, '55 15 15', TRUE, TRUE, FALSE);
	} else {
		anim_set(self, '22 6 6', TRUE, TRUE, FALSE);
		v = monster_move_walk(500, 5, 500);
	}
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	anim_update(self);
}

void() monster_butcher_idle {
	anim_update(self);
	monster_idle(1500, 500, 0, 0, 0, 100);
	anim_set(self, '1 12 12', TRUE, TRUE, FALSE);
}

void() monster_butcher_guard {
	self.angles_y = self.angles_y + frametime * 15;
	monster_butcher_idle();
}

void() monster_butcher_walk {
	if (monster_walk_prepare(1500, 500, 0, 0, 0, monster_butcher_idle, 100))
		return;

	anim_set(self, '14 8 8', TRUE, TRUE, FALSE);
	anim_update(self);
	monster_move_walk_rotate(300, 5, 0, 720);
}

void() monster_butcher_spawn {
	monster_prepare(monster_butcher_hunt, monster_butcher_walk, monster_butcher_idle);
	setmodel(self, "models/oq/demon.mdl");
	self.movetype = MOVETYPE_WALK;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Crazy Butcher";
	self.scale = 2;
	self.view_ofs = '0 0 35';
}

void(void) monster_butcher_init {
	precache_model("models/oq/demon.mdl");
	dlc_require("oqmodels");
}

void(void) spawnfunc_monster_butcher_spawn {
	setsize(self, '-20 -20 -45', '20 20 40');
	monster_init(monster_butcher_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(monster_butcher_spawn, spawnfunc_monster_butcher_spawn);
}

#undef monster_butcher_idle
#undef monster_butcher_guard
#undef monster_butcher_walk
#undef monster_butcher_hunt
#undef monster_butcher_spawn
