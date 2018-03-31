void ugandaknuckles_idle();
void ugandaknuckles_guard();
void ugandaknuckles_walk();

void ugandaknuckles_hunt() {
	float dofire;
	self.nextthink = time;
	if (monster_check_target(ugandaknuckles_walk, ugandaknuckles_guard))
		return;

	if (self.attack_finished_single < time)
	if (vlen(self.enemy.origin - self.origin) <= self.dmg_radius)
	{
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1) {
			dofire = TRUE;
			self.lastshot_time = time;
		}
	}
	vector v;
	if (dofire) {
		self.attack_finished_single = time + 3 + random(2);
		float f = random(5);
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
		movelib_beak_simple(500 * frametime);
		if (time - self.lastshot_time < 1) {
			setanim(self, '7 2 4', TRUE, TRUE, FALSE);
			updateanim(self);
		} else {
			self.frame = 0;
		}

		v = self.enemy.origin - self.origin;
	} else {
		setanim(self, '1 6 12', TRUE, TRUE, FALSE);
		updateanim(self);
		v = monster_move_walk(500, 5, 0);
	}
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
}

void ugandaknuckles_idle() {
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	movelib_beak_simple(100 * frametime);
	self.frame = 1;
}

void ugandaknuckles_guard() {
	self.angles_y = self.angles_y + frametime * 15;
	ugandaknuckles_idle();
	self.frame = 1;
}

void ugandaknuckles_walk() {
	self.nextthink = time;
	if(monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	if (monster_walk_finished(ugandaknuckles_idle, 100))
		return;

	setanim(self, '1 6 12', TRUE, TRUE, FALSE);
	updateanim(self);
	vector v = monster_move_walk(300, 5, 0);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void ugandaknuckles_spawn() {
	monster_prepare(ugandaknuckles_hunt, ugandaknuckles_walk, ugandaknuckles_idle);
	setmodel(self, "models/knuckles.md3");
	self.movetype = MOVETYPE_WALK;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Uganda Knuckles";
}

void ugandaknuckles_init() {
	precache_model("models/knuckles.md3");
	precache_sound("douknowdawae.ogg");
	precache_sound("myqueenyoulook.ogg");
	precache_sound("quenisok.ogg");
	precache_sound("isthisdawae.ogg");
	precache_sound("youdunnodawae.ogg");
	dlc_require("uganda");
}

void spawnfunc_monster_ugandaknuckles_spawn() {
	setsize(self, '-16 -16 0', '16 16 40');
	monster_init(ugandaknuckles_init);
	monster_prepare_spawn(ugandaknuckles_spawn, spawnfunc_monster_ugandaknuckles_spawn);
}
