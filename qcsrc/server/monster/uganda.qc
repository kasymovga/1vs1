void(void) monster_ugandaknuckles_idle;
void(void) monster_ugandaknuckles_guard;
void(void) monster_ugandaknuckles_walk;

void(void) monster_ugandaknuckles_hunt {
	float dofire = FALSE;
	self.nextthink = time;
	if (monster_check_target(monster_ugandaknuckles_walk, monster_ugandaknuckles_guard))
		return;

	if (self.attack_finished_single < time)
	if (vlen(self.enemy.origin - self.origin) <= self.dmg_radius)
	{
		trace_line(self.origin, self.enemy.origin, TRACE_MOVE_WORLDONLY, self);
		if (trace_fraction == 1) {
			dofire = TRUE;
			self.lastshot_time = time;
		}
	}
	vector v;
	if (dofire) {
		self.attack_finished_single = time + 3 + 2 * random();
		float f = random() * 5;
		if (f > 4)
			sound(self, CHAN_WEAPON, "myqueenyoulook.ogg", VOL_BASE, ATTN_NORM);
		else if (f > 3)
			sound(self, CHAN_WEAPON, "quenisok.ogg", VOL_BASE, ATTN_NORM);
		else if (f > 2)
			sound(self, CHAN_WEAPON, "douknowdawae.ogg", VOL_BASE, ATTN_NORM);
		else if (f > 1)
			sound(self, CHAN_WEAPON, "isthisdawae.ogg", VOL_BASE, ATTN_NORM);
		else
			sound(self, CHAN_WEAPON, "youdunnodawae.ogg", VOL_BASE, ATTN_NORM);
	}
	if (self.attack_finished_single >= time) {
		move_beak_simple(500 * frametime);
		if (time - self.lastshot_time < 1) {
			anim_set(self, '7 2 4', TRUE, TRUE, FALSE);
			anim_update(self);
		} else {
			self.frame = 0;
		}

		v = self.enemy.origin - self.origin;
	} else {
		anim_set(self, '1 6 12', TRUE, TRUE, FALSE);
		anim_update(self);
		v = monster_move_walk(500, 5, 0);
	}
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
}

void(void) monster_ugandaknuckles_idle {
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	move_beak_simple(100 * frametime);
	self.frame = 1;
}

void(void) monster_ugandaknuckles_guard {
	self.angles_y = self.angles_y + frametime * 15;
	monster_ugandaknuckles_idle();
	self.frame = 1;
}

void(void) monster_ugandaknuckles_walk {
	self.nextthink = time;
	if(monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	if (monster_walk_finished(monster_ugandaknuckles_idle, 100))
		return;

	anim_set(self, '1 6 12', TRUE, TRUE, FALSE);
	anim_update(self);
	vector v = monster_move_walk(300, 5, 0);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void(void) monster_ugandaknuckles_spawn {
	monster_prepare(monster_ugandaknuckles_hunt, monster_ugandaknuckles_walk, monster_ugandaknuckles_idle);
	setmodel(self, "models/knuckles.md3");
	self.movetype = MOVETYPE_WALK;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Uganda Knuckles";
}

void(void) monster_ugandaknuckles_init {
	precache_model("models/knuckles.md3");
	dlc_require("uganda");
	dlc_precache_sound("douknowdawae.ogg");
	dlc_precache_sound("myqueenyoulook.ogg");
	dlc_precache_sound("quenisok.ogg");
	dlc_precache_sound("isthisdawae.ogg");
	dlc_precache_sound("youdunnodawae.ogg");
}

void(void) spawnfunc_monster_ugandaknuckles_spawn {
	setsize(self, '-16 -16 0', '16 16 40');
	monster_init(monster_ugandaknuckles_init);
	monster_prepare_spawn(monster_ugandaknuckles_spawn, spawnfunc_monster_ugandaknuckles_spawn);
}
