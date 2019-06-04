void boss2_idle();
void boss2_guard();
void boss2_walk();

void boss2_pellet_touch()
{
	PROJECTILE_TOUCH;
	if(other.solid == SOLID_BSP)
		damage_info(self.origin, self.dmg_edge, 0, 0, normalize(self.velocity), self.projectiledeathtype, self);

	if (other && other.takedamage)
	{
		entity o = self.realowner;
		damage(other, self, o, self.dmg_edge, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity));
		self.cnt = 0;
	}
	if not(self.cnt)
	{
		remove(self);
		return;
	}
	self.cnt = self.cnt - 1;
	self.owner = world;
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void boss2_pellet(vector start, vector dir)
{
	entity proj;
	proj = projectile(TRUE, PROJECTILE_BULLET_BIG, TRUE, self);
	proj.classname = "bullet";
	proj.realowner = proj.owner;
	PROJECTILE_MAKETRIGGER(proj);
	proj.movetype = MOVETYPE_BOUNCEMISSILE;
	proj.think = stdproc_remove;
	proj.nextthink = time + 10;
	proj.velocity = normalize(dir + randomvec() * 0.1) * 2000;
	weapon_setup_projectile_velocity(proj);
	proj.angles = vectoangles(proj.velocity);
	setorigin(proj, start);
	proj.touch = boss2_pellet_touch;
	proj.dmg_edge = self.dmg_edge;
	proj.dmg_force = self.dmg_force;
	proj.projectiledeathtype = WEP_SUPERSHOTGUN;
	proj.oldvelocity = proj.velocity;
	proj.cnt = 3;
}



void boss2_hunt() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_check_target(boss2_walk, boss2_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	if (dofire) {
		v = vectoangles(monster_look_to_end - self.origin);
		self.angles_y = v_y;
		movelib_beak_simple(100 * frametime);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = normalize(monster_look_to_end - self.origin);
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/shotgun_fire.wav", VOL_BASE, ATTN_NORM);
		float sc;
		for (sc = 0; sc < 16; sc ++)
			boss2_pellet(_shotorg, _shotdir);

		pointparticles(particleeffectnum("shotgun_muzzleflash"), _shotorg, _shotdir * 1000, g_balance_shotgun_primary_ammo);

		self.attack_finished_single = time + 1 + random();
		self.bulletcounter = time + 0.5;
	} else {
		v = monster_move_walk(800, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter)
		anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	else
		anim_set(self, '11 1 1', TRUE, TRUE, FALSE);
}

void boss2_idle() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	anim_set(self, '7 1 1', TRUE, TRUE, FALSE);
}

void boss2_guard() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	boss2_idle();
}

void boss2_walk() {
	WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, self.health);
	self.nextthink = time;
	if (monster_look_for_player(1500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(boss2_idle, 100))
		return;

	anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
	vector v = monster_move_walk(600, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void boss2_remove() {
	WaypointSprite_DetachCarrier(self);
	remove(self.exteriorweaponentity);
}

void boss2_spawn() {
	monster_prepare(boss2_hunt, boss2_walk, boss2_idle);
	setmodel(self, "models/player/shock.zym");
	self.movetype = MOVETYPE_WALK;
	self.entremove = boss2_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 17;

	self.exteriorweaponentity = spawn();
	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_shotgun.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.netname = "Big Soldier";
	self.scale = 3;
	self.damageforcescale = 0.01;
	self.anim_die1 = '0 1 0.5';
	self.frags = 10;
	self.view_ofs = '0 0 105';
	entity e = WaypointSprite_Spawn("danger", 0, 0, self, '0 0 192', world, 0, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateMaxHealth(e, self.health);
	WaypointSprite_UpdateHealth(e, self.health);
	WaypointSprite_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
}

void boss2_init() {
	precache_model("models/player/shock.zym");
	precache_model("models/weapons/v_shotgun.md3");
	precache_sound("weapons/shotgun_fire.wav");
}

void spawnfunc_monster_boss2_spawn() {
	setsize(self, '-48 -48 -72', '64 64 135');
	monster_init(boss2_init);
	self.noise1 = "player/torus/incoming.ogg";
	self.noise2 = "player/torus/death.ogg";
	self.noise3 = "player/torus/pain50.ogg";
	monster_prepare_spawn(boss2_spawn, spawnfunc_monster_boss2_spawn);
}
