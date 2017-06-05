void heavysoldier_idle();
void heavysoldier_guard();

void heavysoldier_grenade_explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						announce(self.owner, "announcer/male/airshot.wav");

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
	vector v;
	v = monster_get_direction_to(self.enemy);
	if (self.enemy.health < 1) {
		self.think = heavysoldier_guard;
		heavysoldier_guard();
		return;
	}
	if (self.attack_finished_single > time) {
		setanim(self, '13 1 1', TRUE, TRUE, FALSE);
		monster_move_walk(v, 250, 5);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	} else {
		movelib_beak_simple(100 * frametime);
		v = vectoangles(v);
		self.angles_y = v_y;
		setanim(self, '7 1 1', TRUE, TRUE, FALSE);
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1) {
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
			gren.use = W_Grenade_Explode;
			gren.touch = heavysoldier_grenade_touch;
			gren.velocity = normalize(_shotdir) * 1600;
			W_SetupProjectileVelocity(gren);

			gren.angles = vectoangles (gren.velocity);
			gren.flags = FL_PROJECTILE;

			CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);

			self.attack_finished_single = time + 3;
		}
	}
}

void heavysoldier_idle() {
	self.nextthink = time;
	movelib_beak_simple(100 * frametime);
	setanim(self, '7 1 1', TRUE, TRUE, FALSE);
	entity e;
	if ((e = monster_look_for_player(2000, 0))) {
		self.enemy = e;
		self.think = heavysoldier_hunt;
	}
}

void heavysoldier_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	heavysoldier_idle();
}

void heavysoldier_walk() {
	self.nextthink = time;
	setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	entity e;
	if ((e = monster_look_for_player(1000, 0))) {
		self.enemy = e;
		self.think = heavysoldier_hunt;
		self.attack_finished_single = time + random() * 3 + 1;
		return;
	}
	vector v, v1;
	v1 = monster_get_direction_to(self.enemy);
	v = self.enemy.origin - self.origin;
	if (vlen(v) < frametime * 2 * (vlen(self.velocity)) + 32) {
		if (self.enemy.target)
			self.enemy = find(world, targetname, self.enemy.target);
		else
			self.enemy = world;

		if not(self.enemy)
			self.think = heavysoldier_idle;

		return;
	}
	//self.velocity = normalize(v) * 400;
	monster_move_walk(v1, 150, 5);
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
	setsize(self, '-32 -32 -32', '32 32 32');
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.health = 200;
	self.damageforcescale = 1;
}

void spawnfunc_heavysoldier_spawn() {
	monster_prepare_spawn(heavysoldier_spawn, spawnfunc_heavysoldier_spawn);
}
