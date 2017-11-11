float g_balance_hagar_primary_ammo;
float g_balance_hagar_primary_damage;
float g_balance_hagar_primary_edgedamage;
float g_balance_hagar_primary_force;
float g_balance_hagar_primary_lifetime;
float g_balance_hagar_primary_radius;
float g_balance_hagar_primary_refire;
float g_balance_hagar_primary_speed;
float g_balance_hagar_primary_spread;
float g_balance_hagar_secondary_ammo;
float g_balance_hagar_secondary_damage;
float g_balance_hagar_secondary_edgedamage;
float g_balance_hagar_secondary_force;
float g_balance_hagar_secondary_lifetime_min;
float g_balance_hagar_secondary_lifetime_rand;
float g_balance_hagar_secondary_radius;
float g_balance_hagar_secondary_refire;
float g_balance_hagar_secondary_speed;
float g_balance_hagar_secondary_spread;

// NO bounce protection, as bounces are limited!
void W_Hagar_Explode (void)
{
	self.event_damage = SUB_Null;
	RadiusDamage (self, self.realowner, g_balance_hagar_primary_damage, g_balance_hagar_primary_edgedamage, g_balance_hagar_primary_radius, world, g_balance_hagar_primary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Hagar_Explode2 (void)
{
	self.event_damage = SUB_Null;
	RadiusDamage (self, self.realowner, g_balance_hagar_secondary_damage, g_balance_hagar_secondary_edgedamage, g_balance_hagar_secondary_radius, world, g_balance_hagar_secondary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Hagar_Touch (void)
{
	PROJECTILE_TOUCH;
	self.use ();
}

void W_Hagar_Touch2 (void)
{
	PROJECTILE_TOUCH;

	if(self.cnt > 0 || other.takedamage == DAMAGE_AIM) {
		self.use();
	} else {
		self.cnt++;
		pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);
		self.angles = vectoangles (self.velocity);
		self.owner = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Hagar_Attack (void)
{
	local entity missile;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_hagar_primary_ammo;
	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", g_balance_hagar_primary_damage);

	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = CSQCProjectile(TRUE, PROJECTILE_HAGAR, TRUE);
	missile.owner = missile.realowner = Akimbo_Owner(self);
	missile.classname = "missile";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = g_balance_hagar_primary_damage;
	missile.touch = W_Hagar_Touch;
	missile.use = W_Hagar_Explode;
	missile.think = adaptor_think2use;
	missile.nextthink = time + g_balance_hagar_primary_lifetime;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR;
	setorigin (missile, w_shotorg);

	missile.movetype = MOVETYPE_FLY;
	missile.velocity = (w_shotdir + randomvec() * g_balance_hagar_primary_spread) * g_balance_hagar_primary_speed;
	W_SetupProjectileVelocity(missile);

	missile.angles = vectoangles (missile.velocity);
}

void W_Hagar_Attack2 (void)
{
	local entity missile;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_hagar_secondary_ammo;
	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", g_balance_hagar_secondary_damage);
	//W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav"); // TODO: move model a little to the right

	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = CSQCProjectile(TRUE, PROJECTILE_HAGAR_BOUNCING, TRUE);
	missile.owner = missile.realowner = Akimbo_Owner(self);
	missile.classname = "missile";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = g_balance_hagar_secondary_damage;
	missile.touch = W_Hagar_Touch2;
	missile.cnt = 0;
	missile.use = W_Hagar_Explode;
	missile.think = adaptor_think2use;
	missile.nextthink = time + g_balance_hagar_secondary_lifetime_min + random() * g_balance_hagar_secondary_lifetime_rand;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR | HITTYPE_SECONDARY;
	setorigin (missile, w_shotorg);

	missile.movetype = MOVETYPE_BOUNCEMISSILE;
	missile.velocity = (w_shotdir + randomvec() * g_balance_hagar_secondary_spread) * g_balance_hagar_secondary_speed;
	W_SetupProjectileVelocity(missile);
	missile.avelocity = '100 10 10';

	missile.angles = vectoangles (missile.velocity);
}

void spawnfunc_weapon_hagar (void)
{
	weapon_defaultspawnfunc(WEP_HAGAR);
}

float w_hagar(float req)
{
	if (req == WR_AIM)
		if (random()>0.15)
			self.BUTTON_ATCK = bot_aim(g_balance_hagar_primary_speed, 0, g_balance_hagar_primary_lifetime, FALSE);
		else
		{
			// not using secondary_speed since these are only 15% and should cause some ricochets without re-aiming
			self.BUTTON_ATCK2 = bot_aim(g_balance_hagar_primary_speed, 0, g_balance_hagar_primary_lifetime, FALSE);
		}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, g_balance_hagar_primary_refire))
		{
			W_Hagar_Attack();
			weapon_thinkf(WFRAME_FIRE1, g_balance_hagar_primary_refire, w_ready);
		}
		if (self.BUTTON_ATCK2)
		if (weapon_prepareattack(1, g_balance_hagar_secondary_refire))
		{
			W_Hagar_Attack2();
			weapon_thinkf(WFRAME_FIRE2, g_balance_hagar_secondary_refire, w_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/hagar_fire.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_HAGAR);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_rockets >= g_balance_hagar_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_rockets >= g_balance_hagar_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "played with tiny rockets";
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_BOUNCE) // must be secondary; unchecked: SPLASH
			w_deathtypestring = "hoped #'s missiles wouldn't bounce";
		else // unchecked: SPLASH, SECONDARY
			w_deathtypestring = "was pummeled by";
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_hagar_primary_ammo);
		CACHE_CVAR(g_balance_hagar_primary_damage);
		CACHE_CVAR(g_balance_hagar_primary_edgedamage);
		CACHE_CVAR(g_balance_hagar_primary_force);
		CACHE_CVAR(g_balance_hagar_primary_lifetime);
		CACHE_CVAR(g_balance_hagar_primary_radius);
		CACHE_CVAR(g_balance_hagar_primary_refire);
		CACHE_CVAR(g_balance_hagar_primary_speed);
		CACHE_CVAR(g_balance_hagar_primary_spread);
		CACHE_CVAR(g_balance_hagar_secondary_ammo);
		CACHE_CVAR(g_balance_hagar_secondary_damage);
		CACHE_CVAR(g_balance_hagar_secondary_edgedamage);
		CACHE_CVAR(g_balance_hagar_secondary_force);
		CACHE_CVAR(g_balance_hagar_secondary_lifetime_min);
		CACHE_CVAR(g_balance_hagar_secondary_lifetime_rand);
		CACHE_CVAR(g_balance_hagar_secondary_radius);
		CACHE_CVAR(g_balance_hagar_secondary_refire);
		CACHE_CVAR(g_balance_hagar_secondary_speed);
		CACHE_CVAR(g_balance_hagar_secondary_spread);
		CSQCProjectile_Init(PROJECTILE_HAGAR);
		CSQCProjectile_Init(PROJECTILE_HAGAR_BOUNCING);
	}
	return TRUE;
};
