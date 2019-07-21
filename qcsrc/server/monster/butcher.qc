void butcher_idle();
void butcher_guard();
void butcher_walk();

void butcher_hunt() {
	anim_update(self);
	self.nextthink = time;
	if (monster_check_target(butcher_walk, butcher_guard))
		return;

	vector v;
	float dofire;
	if (self.attack_finished_single < time) {
		if (vlen(self.enemy.origin - self.origin) <= self.dmg_radius) {
			self.attack_finished_single = time + 0.5;
			self.lastshot_time = FALSE;
			dofire = TRUE;
		} else
			dofire = FALSE;
	} else if (self.attack_finished_single + 0.5 > time)
		dofire = TRUE;
	else
		dofire = FALSE;

	if (dofire) {
		if not(self.lastshot_time) {
			v = entity_nearest_point_on_box(self.enemy, self.origin);
			if (vlen(v - self.origin) <= self.dmg_radius)
			if (self.attack_finished_single - time < 0.25) {
				traceline(self.origin, v, MOVE_NORMAL, self);
				if (trace_ent) {
					damage(trace_ent, self, self, self.dmg_edge, WEP_MELEE, trace_endpos, v_forward);
					self.lastshot_time = time;
				}
			}
		}
		v = self.enemy.origin - self.origin;
		movelib_beak_simple(200 * frametime);
		anim_set(self, '55 15 15', TRUE, TRUE, FALSE);
	} else {
		anim_set(self, '22 6 6', TRUE, TRUE, FALSE);
		v = monster_move_walk(500, 5, 500);
	}
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
}

void butcher_idle() {
	anim_update(self);
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	movelib_beak_simple(100 * frametime);
	anim_set(self, '1 12 12', TRUE, TRUE, FALSE);
}

void butcher_guard() {
	self.angles_y = self.angles_y + frametime * 15;
	butcher_idle();
}

void butcher_walk() {
	anim_update(self);
	self.nextthink = time;
	if(monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	if (monster_walk_finished(butcher_idle, 100))
		return;

	anim_set(self, '14 8 8', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(300, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);

}

void butcher_spawn() {
	monster_prepare(butcher_hunt, butcher_walk, butcher_idle);
	setmodel(self, "models/oq/demon.mdl");
	self.movetype = MOVETYPE_WALK;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Crazy Butcher";
	self.scale = 2;
	self.view_ofs = '0 0 35';
}

void butcher_init() {
	precache_model("models/oq/demon.mdl");
	dlc_require("oqmodels");
}

void spawnfunc_monster_butcher_spawn() {
	setsize(self, '-20 -20 -45', '20 20 40');
	monster_init(butcher_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(butcher_spawn, spawnfunc_monster_butcher_spawn);
}

