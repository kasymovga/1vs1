void heavysoldier_idle();
void heavysoldier_guard();
void heavysoldier_walk();

void heavysoldier_grenade_explode (void)
{
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, 50, 0, 100, world, 100, self.projectiledeathtype, other);

	remove (self);
}

void heavysoldier_grenade_touch (void)
{
	PROJECTILE_TOUCH;
	heavysoldier_grenade_explode();
}


void heavysoldier_hunt() {
	self.nextthink = time;
	if (monster_check_target(heavysoldier_walk, heavysoldier_guard))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time) {
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1)
			dofire = TRUE;
	}
	if (dofire) {
		movelib_beak_simple(100 * frametime);
		v = vectoangles(self.enemy.origin - self.origin);
		self.angles_y = v_y;
		makevectors(self.angles);
		vector _shotdir = self.enemy.origin - self.origin;
		vector _shotorg = self.origin + v_forward * 16;
		sound (self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);
		entity gren = spawn();
		gren.owner = self;
		gren.classname = "grenade";
		gren.movetype = MOVETYPE_BOUNCE;
		gren.gravity = 0.01;
		PROJECTILE_MAKETRIGGER(gren);
		gren.projectiledeathtype = WEP_GRENADE_LAUNCHER;
		setorigin(gren, _shotorg);
		setsize(gren, '0 0 -3', '0 0 -3');

		gren.nextthink = time + 5;
		gren.think = adaptor_think2use;
		gren.use = heavysoldier_grenade_explode;
		gren.touch = heavysoldier_grenade_touch;
		gren.velocity = normalize(_shotdir) * 3200;
		W_SetupProjectileVelocity(gren);

		gren.angles = vectoangles (gren.velocity);
		gren.flags = FL_PROJECTILE;

		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);

		self.attack_finished_single = time + 3 + random();
		self.bulletcounter = time + 0.5;
	} else {
		v = monster_move_walk(250, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter)
		setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	else
		setanim(self, '7 1 1', TRUE, TRUE, FALSE);
}

void heavysoldier_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	setanim(self, '7 1 1', TRUE, TRUE, FALSE);
}

void heavysoldier_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	heavysoldier_idle();
}

void heavysoldier_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(heavysoldier_idle, 100))
		return;

	setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(150, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void heavysoldier_remove() {
	remove(self.exteriorweaponentity);
}

void heavysoldier_spawn() {
	monster_prepare(heavysoldier_hunt, heavysoldier_walk, heavysoldier_idle);
	setmodel(self, "models/player/grunt.zym");
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	self.entremove = heavysoldier_remove;
	self.colormap = 1024 + 34;
	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_gl.md3");
	setsize(self, '-16 -16 -24', '16 16 45');
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.health = 200;
	self.damageforcescale = 1;
	self.netname = "Heavy Soldier";
}

void heavysoldier_init() {
	precache_model("models/player/grunt.zym");
	precache_model("models/weapons/v_gl.md3");
	precache_sound("weapons/grenade_fire.wav");
}

void spawnfunc_heavysoldier_spawn() {
	monster_init(heavysoldier_init);
	monster_prepare_spawn(heavysoldier_spawn, spawnfunc_heavysoldier_spawn);
}
