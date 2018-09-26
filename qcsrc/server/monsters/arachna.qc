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
		sound (self, CHAN_WEAPON, "weapons/electro_fire.wav", VOL_BASE, ATTN_NORM);

		entity proj = CSQCProjectile(TRUE, PROJECTILE_ELECTRO, TRUE);
		proj.owner = proj.realowner = self;
		proj.classname = "grenade";
		proj.bot_dodge = TRUE;
		proj.bot_dodgerating = self.dmg_edge;
		proj.dmg_edge = self.dmg_edge;
		proj.dmg_radius = self.dmg_radius;
		proj.dmg_force = self.dmg_force;
		proj.movetype = MOVETYPE_FLY;
		proj.projectiledeathtype = WEP_ELECTRO;
		proj.touch = arachna_grenade_touch;
		PROJECTILE_MAKETRIGGER(proj);
		setorigin(proj, _shotorg);
		proj.damageforcescale = g_balance_fireball_primary_damageforcescale;
		proj.velocity = normalize(_shotdir) * 1600;
		proj.pushltime = time + g_balance_fireball_primary_lifetime;
		W_SetupProjectileVelocity(proj);
		proj.angles = vectoangles(proj.velocity);

		self.attack_finished_single = time + 3 + random();
		self.bulletcounter = time + 0.5;
	} else {
		v = monster_move_walk(500, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	}
	if (time > self.bulletcounter)
		setanim(self, '16 1 1', TRUE, TRUE, FALSE);
	else
		setanim(self, '8 1 1', TRUE, TRUE, FALSE);
}

void arachna_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2000, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	setanim(self, '23 1 1', TRUE, TRUE, FALSE);
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

	setanim(self, '15 1 1', TRUE, TRUE, FALSE);
	//self.velocity = normalize(v) * 400;
	vector v = monster_move_walk(250, 5, 0);
	//pointparticles(particleeffectnum("sparks"), self.enemy.origin, '0 0 1', 1);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);

}

void arachna_remove() {
	remove(self.exteriorweaponentity);
}

void arachna_spawn() {
	monster_prepare(arachna_hunt, arachna_walk, arachna_idle);
	setmodel(self, "models/arachna/arachna.md3");
	self.movetype = MOVETYPE_WALK;
	self.species = SPECIES_ALIEN;
	self.exteriorweaponentity = spawn();
	self.entremove = arachna_remove;
	if (self.team > 0)
		self.colormap = 1024;
	else
		self.colormap = 1024 + 68;

	self.exteriorweaponentity.scale = 0.6;
	setattachment(self.exteriorweaponentity, self, "tag_weapon");
	setmodel(self.exteriorweaponentity, "models/weapons/v_electro.md3");
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Arachna";
}

void arachna_init() {
	precache_model("models/arachna/arachna.md3");
	precache_model("models/weapons/v_electro.md3");
	precache_sound("weapons/electro_fire.wav");
	dlc_require("arachna");
	CSQCProjectile_Init(PROJECTILE_ELECTRO);
}

void spawnfunc_monster_arachna_spawn() {
	setsize(self, '-16 -16 -24', '16 16 32');
	monster_init(arachna_init);
	self.noise1 = "player/pyria-skadi/coms/incoming.ogg";
	self.noise3 = "player/pyria-skadi/player/pain50.ogg";
	monster_prepare_spawn(arachna_spawn, spawnfunc_monster_arachna_spawn);
}
