void spearguy_idle();
void spearguy_guard();
void spearguy_walk();

void spearguy_hunt() {
	self.nextthink = time;
	if (monster_check_target(spearguy_walk, spearguy_guard)) {
		sound_stop(self, CHAN_WEAPON);
		self.lip = FALSE;
		return;
	}
	vector v;
	v = entity_nearest_point_on_box(self.enemy, self.origin);
	if (vlen(v - self.origin) > self.dmg_radius) {
		anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
		v = monster_move_walk(600, 5, 500);
		if (self.lip) {
			sound_stop(self, CHAN_WEAPON);
			self.lip = FALSE;
		}
	} else {
		movelib_beak_simple(100 * frametime);
		anim_set(self, '11 1 1', TRUE, TRUE, FALSE);
		trace_line(self.origin, v, TRACE_MOVE_WORLDONLY, self);
		if (trace_fraction == 1) {
			if not(self.lip) {
				sound(self, CHAN_WEAPON, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
				self.lip = TRUE;
			}
			vector o = gettaginfo(self.exteriorweaponentity, gettagindex(self.exteriorweaponentity, ""));
			//te_lightning1(world, o + v_forward * 20, self.enemy.origin);
			pointparticles(particleeffectnum("sparks"), o + v_forward * 50, v_forward, 1);
			damage(self.enemy, self, self, self.dmg_edge * frametime, WEP_MELEE, self.enemy.origin, v_forward);
		}
		v = self.enemy.origin - self.origin;
	}
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
}

void spearguy_idle() {
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	movelib_beak_simple(100 * frametime);
	anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
}

void spearguy_guard() {
	self.angles_y = self.angles_y + frametime * 15;
	spearguy_idle();
}

void spearguy_walk() {
	self.nextthink = time;
	if(monster_look_for_player(1500, 500, 0, 0, 0))
		return;

	if (monster_walk_finished(spearguy_idle, 100))
		return;

	anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(400, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void spearguy_remove() {
	remove(self.exteriorweaponentity);
	sound_stop(self, CHAN_WEAPON);
	self.lip = FALSE;
}

void spearguy_spawn() {
	monster_prepare(spearguy_hunt, spearguy_walk, spearguy_idle);
	setmodel(self, "models/player/lurk.zym");
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_rspear.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.entremove = spearguy_remove;
	self.netname = "Spearguy";
	self.ammo_cells = 10;
	self.view_ofs = '0 0 35';
}

void spearguy_init() {
	dlc_require("rspear");
	precache_model("models/player/lurk.zym");
	precache_model("models/weapons/v_rspear.md3");
	precache_sound("weapons/electro_fly.wav");
}

void spawnfunc_monster_spearguy_spawn() {
	setsize(self, '-16 -16 -24', '16 16 45');
	monster_init(spearguy_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(spearguy_spawn, spawnfunc_monster_spearguy_spawn);
}
