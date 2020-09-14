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
float g_balance_hagar_secondary;

var .float hagar_buttonatck1 = BUTTON_ATCK;
var .float hagar_buttonatck2 = BUTTON_ATCK2;

void weapon_hagar_touch2 (void) {
	PROJECTILE_TOUCH;
	if(self.cnt > 0 || other.takedamage == DAMAGE_AIM) {
		projectile_explode();
	} else {
		self.cnt++;
		pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);
		self.owner = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void(void) weapon_hagar_attack {
	entity missile;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_hagar_primary_ammo;

	weapon_setup_shot (self, 2, "weapons/hagar_fire.wav", 1);
	pointparticles(particleeffectnum("hagar_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	missile = projectile(TRUE, PROJECTILE_HAGAR, TRUE, self);
	projectile_setup(missile, weapon_shotorg, WEP_HAGAR, g_balance_hagar_primary_damage,
			g_balance_hagar_primary_edgedamage, g_balance_hagar_primary_radius, g_balance_hagar_primary_force);

	missile.touch = projectile_touch_explode;
	missile.use = projectile_explode;
	missile.think = projectile_think2use;
	missile.nextthink = time + g_balance_hagar_primary_lifetime;
	missile.movetype = MOVETYPE_FLY;
	missile.velocity = (weapon_shotdir + randomvec() * g_balance_hagar_primary_spread) * g_balance_hagar_primary_speed;
	weapon_setup_projectile_velocity(missile);
}

void(void) weapon_hagar_attack2 {
	entity missile;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_hagar_secondary_ammo;

	weapon_setup_shot (self, 2, "weapons/hagar_fire.wav", 1);
	//weapon_setup_shot (self, FALSE, 2, "weapons/hagar_fire.wav"); // TODO: move model a little to the right
	pointparticles(particleeffectnum("hagar_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	missile = projectile(TRUE, PROJECTILE_HAGAR_BOUNCING, TRUE, self);
	projectile_setup(missile, weapon_shotorg, WEP_HAGAR | HITTYPE_SECONDARY, g_balance_hagar_secondary_damage,
			g_balance_hagar_secondary_edgedamage, g_balance_hagar_secondary_radius, g_balance_hagar_secondary_force);

	missile.touch = weapon_hagar_touch2;
	missile.cnt = 0;
	missile.use = projectile_explode;
	missile.think = projectile_think2use;
	missile.nextthink = time + g_balance_hagar_secondary_lifetime_min + random() * g_balance_hagar_secondary_lifetime_rand;
	missile.movetype = MOVETYPE_BOUNCEMISSILE;
	missile.velocity = (weapon_shotdir + randomvec() * g_balance_hagar_secondary_spread) * g_balance_hagar_secondary_speed;
	weapon_setup_projectile_velocity(missile);
}

void spawnfunc_weapon_hagar (void)
{
	weapon_defaultspawnfunc(WEP_HAGAR);
}

float weapon_hagar(float req)
{
	if (req == WR_AIM)
		if (!g_balance_hagar_secondary || random() > 0.15)
			self.hagar_buttonatck1 = bot_aim(g_balance_hagar_primary_speed, 0, g_balance_hagar_primary_lifetime, FALSE);
		else
		{
			// not using secondary_speed since these are only 15% and should cause some ricochets without re-aiming
			self.hagar_buttonatck2 = bot_aim(g_balance_hagar_primary_speed, 0, g_balance_hagar_primary_lifetime, FALSE);
		}
	else if (req == WR_THINK)
	{
		if (self.hagar_buttonatck1)
		if (weapon_prepareattack(0, g_balance_hagar_primary_refire))
		{
			weapon_hagar_attack();
			weapon_thinkf(WFRAME_FIRE1, g_balance_hagar_primary_refire, weapon_ready);
		}
		if (self.hagar_buttonatck2)
		if (g_balance_hagar_secondary)
		if (weapon_prepareattack(1, g_balance_hagar_secondary_refire))
		{
			weapon_hagar_attack2();
			weapon_thinkf(WFRAME_FIRE2, g_balance_hagar_secondary_refire, weapon_ready);
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
		weapon_deathtypestring = "played with tiny rockets";
	else if (req == WR_KILLMESSAGE)
	{
		if(weapon_deathtype & HITTYPE_BOUNCE) // must be secondary; unchecked: SPLASH
			weapon_deathtypestring = "hoped #'s missiles wouldn't bounce";
		else // unchecked: SPLASH, SECONDARY
			weapon_deathtypestring = "was pummeled by";
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
		CACHE_CVAR(g_balance_hagar_secondary);
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
		projectile_init(PROJECTILE_HAGAR);
		projectile_init(PROJECTILE_HAGAR_BOUNCING);
		if (cvar("g_balance_hagar_swap_buttons")) {
			hagar_buttonatck1 = BUTTON_ATCK2;
			hagar_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}
