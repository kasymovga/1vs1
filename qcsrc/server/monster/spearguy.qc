#define MONSTER_SPEARGUY_ANIM_LEGS_WALK '62 11 20'
#define MONSTER_SPEARGUY_ANIM_LEGS_IDLE '150 29 10'
#define MONSTER_SPEARGUY_ANIM_TORSO_STAND '141 1 15'
#define MONSTER_SPEARGUY_ANIM_TORSO_ATTACK '133 6 15'
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
		monster_common_composite_anim(MONSTER_SPEARGUY_ANIM_LEGS_WALK, MONSTER_SPEARGUY_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
		v = monster_move_walk(600, 5, 500);
		if (self.lip) {
			sound_stop(self, CHAN_WEAPON);
			self.lip = FALSE;
		}
	} else {
		move_beak_simple(100 * frametime);
		monster_common_composite_anim(MONSTER_SPEARGUY_ANIM_LEGS_IDLE, MONSTER_SPEARGUY_ANIM_TORSO_ATTACK, '11 1 1', TRUE, FALSE);
		trace_line(self.origin, v, TRACE_MOVE_WORLDONLY, self);
		if (trace_fraction == 1) {
			if not(self.lip) {
				sound(self, CHAN_WEAPON, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
				self.lip = TRUE;
			}
			vector o = gettaginfo(self.exteriorweaponentity, gettagindex(self.exteriorweaponentity, ""));
			//te_lightning1(world, o + v_forward * 20, self.enemy.origin);
			pointparticles(particleeffectnum("sparks"), o + v_forward * 50, v_forward, 1);
			damage(self.enemy, self, self, self.dmg_edge * frametime, WEAPON_MELEE, self.enemy.origin, v_forward);
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

	move_beak_simple(100 * frametime);
	monster_common_composite_anim(MONSTER_SPEARGUY_ANIM_LEGS_IDLE, MONSTER_SPEARGUY_ANIM_TORSO_STAND, '7 1 1', TRUE, TRUE);
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

	monster_common_composite_anim(MONSTER_SPEARGUY_ANIM_LEGS_WALK, MONSTER_SPEARGUY_ANIM_TORSO_STAND, '13 1 1', TRUE, TRUE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(400, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void spearguy_remove() {
	monster_common_on_remove();
	sound_stop(self, CHAN_WEAPON);
	self.lip = FALSE;
}

void spearguy_spawn() {
	monster_prepare(spearguy_hunt, spearguy_walk, spearguy_idle);
	monster_common_composite_setup("spearguy", "rspear");
	self.damageforcescale = 1;
	self.entremove = spearguy_remove;
	self.netname = "Spearguy";
	self.ammo_cells = 10;
	self.view_ofs = '0 0 27';
	self.entremove = spearguy_remove;
}

void(void) monster_spearguy_init {
	dlc_require("rspear");
	dlc_require("monsters");
	monster_common_composite_precache("spearguy", "rspear");
	precache_sound("weapons/electro_fly.wav");
}

void(void) spawnfunc_monster_spearguy_spawn {
	monster_common_setup_spawn_size('-16 -16 -24', '16 16 45', '0 0 8');
	monster_init(monster_spearguy_init);
	self.noise1 = "player/reptilian/coms/incoming.ogg";
	self.noise3 = "player/reptilian/player/pain50.ogg";
	monster_prepare_spawn(spearguy_spawn, spawnfunc_monster_spearguy_spawn);
}

#undef MONSTER_SPEARGUY_ANIM_LEGS_WALK
#undef MONSTER_SPEARGUY_ANIM_LEGS_ID
#undef MONSTER_SPEARGUY_ANIM_TORSO_STA
#undef MONSTER_SPEARGUY_ANIM_TORSO_ATTAC
