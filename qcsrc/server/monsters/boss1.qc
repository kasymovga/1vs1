void boss1_idle();
void boss1_guard();
void boss1_walk();

void boss1_grenade_explode (void)
{
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, 50, 0, 100, world, 100, self.projectiledeathtype, other);

	remove (self);
}

void boss1_grenade_touch (void)
{
	PROJECTILE_TOUCH;
	boss1_grenade_explode();
}


void boss1_hunt() {
	self.nextthink = time;
	if (monster_check_target(boss1_walk, boss1_guard))
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
		float i;
		for (i = 0; i < 8; i++) {
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
			gren.use = boss1_grenade_explode;
			gren.touch = boss1_grenade_touch;
			gren.velocity = normalize(_shotdir + randomvec() * 0.05 * vlen(_shotdir)) * 3200;
			W_SetupProjectileVelocity(gren);

			gren.angles = vectoangles (gren.velocity);
			gren.flags = FL_PROJECTILE;

			CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
		}

		self.attack_finished_single = time + 1 + random();
		self.bulletcounter = time + 0.5;
	} else {
		v = monster_move_walk(450, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter)
		setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	else
		setanim(self, '7 1 1', TRUE, TRUE, FALSE);
}

void boss1_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	setanim(self, '7 1 1', TRUE, TRUE, FALSE);
}

void boss1_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	boss1_idle();
}

void boss1_walk() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 1000, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(boss1_idle, 100))
		return;

	setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(350, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void boss1_remove() {
	remove(self.exteriorweaponentity);
}

void boss1_spawn() {
	monster_prepare(boss1_hunt, boss1_walk, boss1_idle);
	setmodel(self, "models/player/grunt.zym");
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	self.entremove = boss1_remove;
	self.colormap = 1024 + 17;
	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_gl.md3");
	self.scale = 3;
	setsize(self, '-64 -64 -48', '64 64 96');
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.health = 3000;
	self.damageforcescale = 0.01;
	self.netname = "Big Soldier";
}

void boss1_init() {
	precache_model("models/player/grunt.zym");
	precache_model("models/weapons/v_gl.md3");
	precache_sound("weapons/grenade_fire.wav");
}

void spawnfunc_boss1_spawn() {
	monster_init(boss1_init);
	monster_prepare_spawn(boss1_spawn, spawnfunc_boss1_spawn);
}
