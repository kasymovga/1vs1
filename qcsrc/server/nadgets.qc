.float nadget_hold;
.entity nadget_pb;
float g_balance_nadget_grenade_ammo;
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
	self.nadget_hold = 0;
}

void Nadget_Init() {
	CACHE_CVAR(g_nadgets);
	CACHE_CVAR(g_balance_nadget_grenade_ammo);
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
	precache_sound("weapons/grenade_bounce1.wav");
	precache_sound("weapons/grenade_bounce2.wav");
	precache_sound("weapons/grenade_bounce3.wav");
	precache_sound("weapons/grenade_bounce4.wav");
	precache_sound("weapons/grenade_bounce5.wav");
	precache_sound("weapons/grenade_bounce6.wav");
	precache_sound("weapons/grenade_fire.wav");
#if 0
	float n, i;
	n = tokenizebyseparator(cvar_string("g_nadgets"), " ");
	for (i = 0; i < n; i++) {
		g_nadgets |= Nadget_CodeByName(argv(i));
	}
#endif
}

void Nadget_Grenade_Touch (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
		self.use();
	else {
		if (self.owner)
			self.owner = world;

		float r;
		r = random() * 6;
		if(r < 1)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			spamsound (self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void Nadget_Grenade_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.realowner, other))
				if(IsFlying(other))
					announce(self.realowner, "announcer/male/airshot.wav");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.realowner, g_balance_nadget_grenade_damage, g_balance_nadget_grenade_edgedamage, g_balance_nadget_grenade_radius, world, g_balance_nadget_grenade_force, self.projectiledeathtype, other);

	remove (self);
}

void Nadget_Grenade_Throw(float holdtime) {
	local entity gren;

	if (self.ammo_rockets < g_balance_nadget_grenade_ammo)
		return;

	if (self.deadflag)
		makevectors(randomvec());
	else
		makevectors(self.v_angle);
	sound(self, CHAN_WEAPON, "weapons/grenade_fire.wav", VOL_BASE, ATTN_NORM);
	w_shotorg = self.origin;
	traceline(w_shotorg, w_shotorg + v_forward * 21, MOVE_NOMONSTERS, self);
	w_shotorg = w_shotorg + (trace_fraction * 20 * v_forward);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = gren.realowner = Akimbo_Owner(self);
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = g_balance_nadget_grenade_damage;
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_NADGET_GRENADE;
	setsize(gren, '0 0 -3', '0 0 -3');
	setorigin(gren, w_shotorg);

	gren.nextthink = time + g_balance_nadget_grenade_lifetime - g_balance_nadget_throw_holdtime * holdtime;
	gren.think = adaptor_think2use;
	gren.use = Nadget_Grenade_Explode;
	gren.touch = Nadget_Grenade_Touch;
	gren.takedamage = DAMAGE_YES;
	gren.health = g_balance_nadget_grenade_health;
	gren.damageforcescale = g_balance_nadget_grenade_damageforcescale;
	gren.event_damage = W_Grenade_Damage;
	gren.velocity = (w_shotdir * g_balance_nadget_grenade_speed + v_up * g_balance_nadget_grenade_speed_up) *
			bound(0, g_balance_nadget_throw_speedfactor_min + (1 - g_balance_nadget_throw_speedfactor_min) * self.nadget_hold, 1);
	W_SetupProjectileVelocity(gren);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);
	self.ammo_rockets -= g_balance_nadget_grenade_ammo;
}

void Nadget_Clear() {
	if (self.nadget_pb) {
		remove(self.nadget_pb);
		self.nadget_pb = world;
	}
	if (self.nadget_hold > 0) {
		Nadget_Grenade_Throw(self.nadget_hold);

		self.nadget_hold = 0;
	}
}

void Nadget_Frame() {
	if not(self.deadflag == DEAD_NO) {
		Nadget_Clear();
		return;
	}
	if not(self.BUTTON_HOOK) {
		if (self.nadget_hold < 0) {
			self.nadget_hold = 0;
			return;
		}
	}
	if (self.BUTTON_HOOK && self.nadget_hold >= 0) {
		if (self.ammo_rockets < g_balance_nadget_grenade_ammo) {
			Nadget_Clear();
		} else if (g_balance_nadget_throw_holdtime > 0) {
			self.nadget_hold += frametime / g_balance_nadget_throw_holdtime;
			if not(self.nadget_pb)
				self.nadget_pb = ProgressBar_Create("Throw power", self);

			ProgressBar_SetValue(self.nadget_pb, self.nadget_hold);
		} else
			self.nadget_hold = 1;
	}
	if (self.nadget_hold && (!self.BUTTON_HOOK || self.nadget_hold >= 1)) {
		Nadget_Grenade_Throw(self.nadget_hold);
		if (self.BUTTON_HOOK)
			self.nadget_hold = -1;
		else
			self.nadget_hold = 0;

		Nadget_Clear();
	}
}
