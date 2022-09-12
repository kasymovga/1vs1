void boss3_idle();
void boss3_guard();
void boss3_walk();

void boss3_hunt() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	self.colormod = '1 1 1' + '0.125 -0.125 0.125' * sin(time);
	if (monster_check_target(boss3_walk, boss3_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/electro_fire.wav", VOL_BASE, ATTN_NORM);
		float i;
		for (i = 0; i < 6; i++) {
			entity proj = projectile(TRUE, PROJECTILE_ELECTRO, TRUE, self);
			projectile_setup(proj, _shotorg, EFFECT_IMPACT_PLASMA, WEP_ELECTRO, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
			proj.touch = projectile_touch_explode;
			proj.velocity = normalize(normalize(_shotdir) + randomvec() * 0.1) * 1600;
			proj.pushltime = time + 10;
			weapon_setup_projectile_velocity(proj);
		}
		self.attack_finished_single = time + 3 + random();
		self.bulletcounter = time + 0.5;
	}
	if (time > self.bulletcounter) {
		v = monster_move_walk(1200, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
		anim_set(self, '16 1 1', TRUE, TRUE, FALSE);
	} else {
		movelib_beak_simple(2000 * frametime);
		anim_set(self, '8 1 1', TRUE, TRUE, FALSE);
	}
}

void boss3_idle() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.colormod = '1 1 1' + '-0.125 0.125 0.125' * sin(time);
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	anim_set(self, '23 1 1', TRUE, TRUE, FALSE);
}

void boss3_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	boss3_idle();
}

void boss3_walk() {
	self.nextthink = time;
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.colormod = '1 1 1' + '0.125 0.125 -0.125' * sin(time);
	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(boss3_idle, 100))
		return;

	anim_set(self, '15 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(600, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);

}

void boss3_remove() {
	WaypointSprite_DetachCarrier(self);
	remove(self.exteriorweaponentity);
}

void boss3_spawn() {
	monster_prepare(boss3_hunt, boss3_walk, boss3_idle);
	setmodel(self, "models/arachna/arachna.md3");
	self.movetype = MOVETYPE_WALK;
	self.species = SPECIES_ALIEN;
	self.exteriorweaponentity = spawn();
	self.entremove = boss3_remove;
	self.scale = 3;
	self.exteriorweaponentity.scale = 0.6;
	setattachment(self.exteriorweaponentity, self, "tag_weapon");
	setmodel(self.exteriorweaponentity, "models/weapons/v_electro.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 0.1;
	self.netname = "Giant Arachna";
	self.frags = 10;
	self.anim_die1 = '1 1 1';
	self.view_ofs = '0 0 48';
	entity e = WaypointSprite_Spawn("danger", 0, 0, self, '0 0 0', world, 0, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateMaxHealth(e, self.health);
	WaypointSprite_UpdateHealth(e, self.health);
	WaypointSprite_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
}

void boss3_init() {
	precache_model("models/arachna/arachna.md3");
	precache_model("models/weapons/v_electro.md3");
	precache_sound("weapons/electro_fire.wav");
	dlc_require("arachna");
}

void spawnfunc_monster_boss3_spawn() {
	setsize(self, '-32 -32 -72', '32 32 96');
	monster_init(boss3_init);
	self.noise1 = "player/pyria-skadi/coms/incoming.ogg";
	self.noise3 = "player/pyria-skadi/player/pain50.ogg";
	monster_prepare_spawn(boss3_spawn, spawnfunc_monster_boss3_spawn);
}

