//compatibility with old save files
#define monster_marine_idle marine_idle
#define monster_marine_guard marine_guard
#define monster_marine_walk marine_walk
#define monster_marine_hunt marine_hunt
#define monster_marine_remove marine_remove
#define monster_marine_spawn marine_spawn

void() monster_marine_idle;
void() monster_marine_guard;
void() monster_marine_walk;

void() monster_marine_hunt {
	if (self.body) anim_update(self.body);
	self.nextthink = time;
	if (monster_check_target(monster_marine_walk, monster_marine_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	float stay = self.owner.spawnflags & MONSTER_SPAWN_STAYSTILL;
	if (dofire) {
		if (self.cnt)
			self.cnt = self.cnt - 1;
		else
			self.cnt = 5;

		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		move_beak_simple(100 * frametime);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = normalize(normalize(monster_look_to_end - self.origin) + (3 - self.cnt) * '0 0 0.005' + randomvec() * 0.0025);
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
		bullet_begin(10000);
		bullet(_shotorg, _shotorg, _shotdir, self.dmg_radius, 10000, 5, self.dmg_edge, 0, self.dmg_force, EFFECT_IMPACT_BULLET, WEAPON_UZI, particleeffectnum("tr_bullet"), 0, 1);
		bullet_end();
		pointparticles(particleeffectnum("uzi_muzzleflash"), _shotorg, _shotdir * 1000, g_balance_shotgun_primary_ammo);
		// casing code
		casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 2, self);
		if (self.cnt)
			self.attack_finished_single = max(self.attack_finished_single, time - frametime) + 0.1;
		else
			self.attack_finished_single = time + 4 + random();

		self.bulletcounter = time + 1;
	} else if (stay) {
		v = vectoangles(normalize(self.enemy.origin - self.origin));
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
	}
	if (time > self.bulletcounter) {
		if (stay) {
			move_beak_simple(2000 * frametime);
			if (self.body)
				anim_set(self.body, '1 8 20', TRUE, TRUE, FALSE);
			else
				anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
		} else {
			v = monster_move_walk(300, 25, 0);
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
			if (self.body)
				anim_set(self.body, '74 8 20', TRUE, TRUE, FALSE);
			else
				anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
		}
	} else {
		move_beak_simple(2000 * frametime);
		if (self.body)
			anim_set(self.body, '82 9 20', FALSE, TRUE, FALSE);
		else
			anim_set(self, '11 1 1', TRUE, TRUE, FALSE);
	}
}

void() monster_marine_idle {
	if (self.body) anim_update(self.body);
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	move_beak_simple(100 * frametime);
	if (self.body)
		anim_set(self.body, '1 8 20', TRUE, TRUE, FALSE);
	else
		anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
}

void() monster_marine_guard {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;

	monster_marine_idle();
}

void() monster_marine_walk {
	if (self.body) anim_update(self.body);
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(monster_marine_idle, 40))
		return;

	if (self.body)
		anim_set(self.body, '91 24 30', TRUE, TRUE, FALSE);
	else
		anim_set(self, '13 1 1', TRUE, TRUE, FALSE);

	vector v = monster_move_walk(200, 25, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void() monster_marine_remove {
	if (self.body) remove(self.body);
	if (self.weaponentity) remove(self.weaponentity);
}

void() monster_marine_spawn {
	monster_prepare(monster_marine_hunt, monster_marine_walk, monster_marine_idle);
	self.body = spawn();
	self.body.scale = 1.25;
	self.body.colormod = self.colormod;
	setmodel(self, "null");
	setmodel(self.body, "models/oq/soldier.mdl");
	setattachment(self.body, self, "");
	setorigin(self.body, '0 0 8');
	self.movetype = MOVETYPE_WALK;
	self.entremove = monster_marine_remove;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Marine";
	self.ammo_nails = 20;
	self.view_ofs = '0 0 35';
	self.flags |= MONSTER_IGNOREDROWN;
}

void() monster_marine_init {
	dlc_require("oqmodels");
	precache_model("models/oq/soldier.mdl");
	precache_sound("weapons/uzi_fire.wav");
}

void(void) spawnfunc_monster_marine_spawn {
	setsize(self, '-16 -16 -24', '16 16 45');
	monster_init(monster_marine_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(monster_marine_spawn, spawnfunc_monster_marine_spawn);
}

#undef monster_marine_idle
#undef monster_marine_guard
#undef monster_marine_walk
#undef monster_marine_hunt
#undef monster_marine_remove
#undef monster_marine_spawn
