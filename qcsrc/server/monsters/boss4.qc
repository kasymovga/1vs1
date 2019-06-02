void boss4_idle();
void boss4_guard();
void boss4_walk();

float boss4_prethink_skip(void) {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	if (self.owner.spawnflags & MONSTER_SPAWN_SHIELDED)
	if not(self.spawnflags & MONSTER_SPAWN_SHIELDED) {
		anim_set(self, '9 1 1', TRUE, TRUE, FALSE);
		return TRUE;
	}
	return FALSE;
}

void boss4_mine_think()
{
	if(time > self.pushltime)
	{
		remove(self);
		return;
	}
	if (self.waterlevel > 0) {
		remove(self);
		return;
	}
	weapon_fireball_laser_play(0.1, self.dmg_radius, self.dmg_edge * 0.25, 0, 4);
	self.nextthink = time + 0.1;
}


void boss4_hunt() {
	self.nextthink = time;
	if (boss4_prethink_skip())
		return;

	if (monster_check_target(boss4_walk, boss4_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	float stay = self.owner.spawnflags & MONSTER_SPAWN_STAYSTILL;
	if (dofire) {
		movelib_beak_simple(100 * frametime);
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = monster_look_to_end - self.origin;
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/fireball_fire.wav", VOL_BASE, ATTN_NORM);

		entity proj = projectile(TRUE, PROJECTILE_FIREBALL, TRUE, self);
		proj.classname = "grenade";
		proj.bot_dodge = TRUE;
		proj.bot_dodgerating = self.dmg_edge;
		proj.dmg_edge = self.dmg_edge;
		proj.dmg_radius = self.dmg_radius;
		proj.dmg_force = self.dmg_force;
		proj.movetype = MOVETYPE_FLY;
		proj.projectiledeathtype = WEP_ROCKET_LAUNCHER;
		proj.touch = monster_proj_touch;
		PROJECTILE_MAKETRIGGER(proj);
		setorigin(proj, _shotorg);
		proj.think = boss4_mine_think;
		proj.nextthink = time;
		proj.damageforcescale = g_balance_fireball_primary_damageforcescale;
		proj.velocity = normalize(_shotdir) * 1000;
		proj.pushltime = time + 20;
		weapon_setup_projectile_velocity(proj);
		proj.angles = vectoangles(proj.velocity);

		self.attack_finished_single = time + 1 + random();
		self.bulletcounter = time + 0.5;
	} else if (stay) {
		movelib_beak_simple(1000 * frametime);
		v = vectoangles(normalize(self.enemy.origin - self.origin));
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	} else {
		v = monster_move_walk(750, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter) {
		if (stay)
			anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
		else
			anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	} else
		anim_set(self, '11 1 1', TRUE, TRUE, FALSE);
}

void boss4_idle() {
	self.nextthink = time;
	if (boss4_prethink_skip())
		return;

	if (monster_look_for_player(2000, 500, 0, 1, 3))
		return;

	movelib_beak_simple(100 * frametime);
	anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
}

void boss4_guard() {
	if (boss4_prethink_skip()) {
		self.nextthink = time;
		return;
	}
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	boss4_idle();
}

void boss4_walk() {
	self.nextthink = time;
	if (boss4_prethink_skip())
		return;

	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(boss4_idle, 100))
		return;

	anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(450, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void boss4_remove() {
	remove(self.exteriorweaponentity);
	remove(self.fire_burner);
	WaypointSprite_DetachCarrier(self);
}

void boss4_spawn() {
	monster_prepare(boss4_hunt, boss4_walk, boss4_idle);
	setmodel(self, "models/player/lycanthrope.zym");
	self.scale = 3;
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	self.entremove = boss4_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 68;

	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_fireball.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Big FireGuy";
	self.max_health = self.health;
	self.damageforcescale = 0.01;
	self.ammo_rockets = 10;
	self.flags = MONSTER_IGNOREFIRE;
	self.anim_die1 = '0 1 0.5';
	self.view_ofs = '0 0 105';
	self.fire_burner = spawn();
	setattachment(self.fire_burner, self, "Bip01 Head");
	self.fire_burner.effects = EF_FLAME;
	entity e = WaypointSprite_Spawn("danger", 0, 0, self, '0 0 192', world, 0, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateMaxHealth(e, self.health);
	WaypointSprite_UpdateHealth(e, self.health);
	WaypointSprite_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
}

void boss4_init() {
	precache_model("models/player/lycanthrope.zym");
	precache_model("models/weapons/v_fireball.md3");
	precache_sound("weapons/fireball_fire.wav");
	projectile_init(PROJECTILE_FIREBALL);
}

void spawnfunc_monster_boss4_spawn() {
	setsize(self, '-48 -48 -72', '64 64 135');
	monster_init(boss4_init);
	self.noise1 = "player/carni-lycan/coms/incoming.ogg";
	self.noise2 = "player/carni-lycan/player/death2.ogg";
	self.noise3 = "player/carni-lycan/player/pain50.ogg";
	monster_prepare_spawn(boss4_spawn, spawnfunc_monster_boss4_spawn);
}
