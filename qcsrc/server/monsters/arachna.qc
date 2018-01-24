void arachna_idle();
void arachna_guard();
void arachna_walk();

void arachna_grenade_explode (void)
{
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, self.dmg_edge, 0, self.dmg_radius, world, self.dmg_force, self.projectiledeathtype, other);

	remove (self);
}

void arachna_grenade_touch (void)
{
	PROJECTILE_TOUCH;
	arachna_grenade_explode();
}

void arachna_mine_touch(void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
	if(Fire_AddDamage(other, self.realowner, self.dmg_edge, 2, self.projectiledeathtype | HITTYPE_HEADSHOT) >= 0)
	{
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void arachna_mine_think()
{
	if(time > self.pushltime)
	{
		remove(self);
		return;
	}

	// make it "hot" once it leaves its owner
	if(self.owner)
	{
		if(vlen(self.origin - self.owner.origin - self.owner.view_ofs) > self.dmg_radius)
		{
			self.cnt += 1;
			if(self.cnt == 3)
				self.owner = world;
		}
		else
			self.cnt = 0;
	}

	W_Fireball_LaserPlay(0.1, self.dmg_radius, self.dmg_edge, 0, 4);

	self.nextthink = time + 0.1;
}


void arachna_hunt() {
	self.nextthink = time;
	if (monster_check_target(arachna_walk, arachna_guard))
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
		sound (self, CHAN_WEAPON, "weapons/fireball_fire.wav", VOL_BASE, ATTN_NORM);

		entity proj = CSQCProjectile(TRUE, PROJECTILE_FIREMINE, TRUE);
		proj.owner = proj.realowner = self;
		proj.classname = "grenade";
		proj.bot_dodge = TRUE;
		proj.bot_dodgerating = self.dmg_edge;
		proj.dmg_edge = self.dmg_edge;
		proj.dmg_radius = self.dmg_radius;
		proj.dmg_force = self.dmg_force;
		proj.movetype = MOVETYPE_BOUNCE;
		proj.projectiledeathtype = WEP_FIREBALL;
		proj.touch = arachna_mine_touch;
		PROJECTILE_MAKETRIGGER(proj);
		setorigin(proj, _shotorg);
		proj.think = arachna_mine_think;
		proj.nextthink = time;
		proj.damageforcescale = g_balance_fireball_primary_damageforcescale;
		proj.velocity = _shotdir * 500 + v_up * 50;
		proj.pushltime = time + g_balance_fireball_primary_lifetime;
		W_SetupProjectileVelocity(proj);
		proj.angles = vectoangles(proj.velocity);

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

void arachna_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	setanim(self, '7 1 1', TRUE, TRUE, FALSE);
}

void arachna_guard() {
	self.angles_y = self.angles_y + frametime * 45 * random();
	if (self.angles_y > 360)
		self.angles_y = self.angles_y - 360;
	arachna_idle();
}

void arachna_walk() {
	self.nextthink = time;
	if (monster_look_for_player(1000, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(arachna_idle, 100))
		return;

	setanim(self, '13 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(150, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void arachna_remove() {
	remove(self.exteriorweaponentity);
}

void arachna_spawn() {
	monster_prepare(arachna_hunt, arachna_walk, arachna_idle);
	setmodel(self, "models/player/arachna.md3");
	self.movetype = MOVETYPE_WALK;
	self.exteriorweaponentity = spawn();
	self.entremove = arachna_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 68;

	setattachment(self.exteriorweaponentity, self, "bip01 r hand");
	setmodel(self.exteriorweaponentity, "models/weapons/v_fireball.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "FireGuy";
}

void arachna_init() {
	precache_model("models/player/arachna.md3");
	precache_model("models/weapons/v_rl.md3");
	dlc_require("arachna");
	CSQCProjectile_Init(PROJECTILE_ROCKET);
}

void spawnfunc_arachna_spawn() {
	setsize(self, '-16 -16 -24', '16 16 16');
	monster_init(arachna_init);
	monster_prepare_spawn(arachna_spawn, spawnfunc_arachna_spawn);
}
