.float nadget_count;
.float nadget_hold;
float g_nadgets_count_start;
float g_balance_nadget_grenade_damage;
float g_balance_nadget_grenade_damageforcescale;
float g_balance_nadget_grenade_edgedamage;
float g_balance_nadget_grenade_force;
float g_balance_nadget_grenade_health;
float g_balance_nadget_grenade_lifetime;
float g_balance_nadget_grenade_radius;
float g_balance_nadget_grenade_speed;
float g_balance_nadget_grenade_speed_up;
float g_balance_nadget_throw_speedfactor_min;
float g_balance_nadget_throw_holdtime;
#if 0
.float nadget_type;
#define NADGET_GRENADE 1
#define NADGET_MOLOTOV 2
#define NADGET_PLASMA 4
#define NADGET_LAST 4

float Nadget_CodeByName(string name) {
	if (name == "grenade") {
		return NADGET_GRENADE;

	if (name == "molotov") {
		return NADGET_MOLOTOV;

	if (name == "plasma") {
		return NADGET_PLASMA;
}

string Nadget_NameByCode(float f) {
	switch (f) {
		case NADGET_GRENADE:
			return "grenade";
		case NADGET_GRENADE:
			return "molotov";
		case NADGET_GRENADE:
			return "plasma";
	}
}
#endif

void Nadget_SpawnHook() {
	self.nadget_count = g_nadgets_count_start;
	self.nadget_hold = 0;
}

void Nadget_Init() {
	CACHE_CVAR(g_nadgets);
	CACHE_CVAR(g_nadgets_count_start);
	CACHE_CVAR(g_balance_nadget_grenade_damage);
	CACHE_CVAR(g_balance_nadget_grenade_damageforcescale);
	CACHE_CVAR(g_balance_nadget_grenade_edgedamage);
	CACHE_CVAR(g_balance_nadget_grenade_force);
	CACHE_CVAR(g_balance_nadget_grenade_health);
	CACHE_CVAR(g_balance_nadget_grenade_lifetime);
	CACHE_CVAR(g_balance_nadget_grenade_speed);
	CACHE_CVAR(g_balance_nadget_grenade_speed_up);
	CACHE_CVAR(g_balance_nadget_grenade_radius);
	CACHE_CVAR(g_balance_nadget_throw_speedfactor_min);
	CACHE_CVAR(g_balance_nadget_throw_holdtime);
#if 0
	float n, i;
	n = tokenizebyseparator(cvar_string("g_nadgets"), " ");
	for (i = 0; i < n; i++) {
		g_nadgets |= Nadget_CodeByName(argv(i));
	}
#endif
}

void Nadget_Grenade_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(IsFlying(other))
					announce(self.owner, "announcer/male/airshot.wav");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, g_balance_nadget_grenade_damage, g_balance_nadget_grenade_edgedamage, g_balance_nadget_grenade_radius, world, g_balance_nadget_grenade_force, self.projectiledeathtype, other);

	remove (self);
}

void Nadget_Grenade_Throw(float speedfactor) {
	local entity gren;

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 4, "weapons/grenade_fire.wav", g_balance_grenadelauncher_secondary_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = Akimbo_Owner(self);
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = g_balance_nadget_grenade_damage;
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_GRENADE_LAUNCHER | HITTYPE_SECONDARY;
	setsize(gren, '0 0 -3', '0 0 -3');
	setorigin(gren, w_shotorg);

	gren.nextthink = time + g_balance_nadget_grenade_lifetime;
	gren.think = adaptor_think2use;
	gren.use = Nadget_Grenade_Explode;
	gren.touch = W_Grenade_Touch2;
	gren.takedamage = DAMAGE_YES;
	gren.health = g_balance_nadget_grenade_health;
	gren.damageforcescale = g_balance_nadget_grenade_damageforcescale;
	gren.event_damage = W_Grenade_Damage;
	gren.velocity = (w_shotdir * g_balance_nadget_grenade_speed + v_up * g_balance_nadget_grenade_speed_up) * speedfactor;
	W_SetupProjectileVelocity(gren);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);
}

void Nadget_Frame() {
	if (self.nadget_count <= 0)
		return;

	if not(self.deadflag == DEAD_NO)
		return;

	if not(self.BUTTON_HOOK)
	if (self.nadget_hold < 0) {
		self.nadget_hold = 0;
		return;
	}
	if (self.BUTTON_HOOK && self.nadget_hold >= 0) {
		if (g_balance_nadget_throw_holdtime > 0)
			self.nadget_hold += frametime / g_balance_nadget_throw_holdtime;
		else
			self.nadget_hold = 1;
	}
	if (self.nadget_hold && (!self.BUTTON_HOOK || self.nadget_hold >= 1)) {
		Nadget_Grenade_Throw(bound(0, g_balance_nadget_throw_speedfactor_min + (1 - g_balance_nadget_throw_speedfactor_min) * self.nadget_hold, 1));
		self.nadget_count -= 1;
		if (self.BUTTON_HOOK)
			self.nadget_hold = -1;
		else
			self.nadget_hold = 0;
	}
}
