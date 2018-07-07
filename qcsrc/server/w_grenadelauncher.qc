float g_balance_grenadelauncher_primary_ammo;
float g_balance_grenadelauncher_primary_animtime;
float g_balance_grenadelauncher_primary_bounce;
float g_balance_grenadelauncher_primary_damage;
float g_balance_grenadelauncher_primary_edgedamage;
float g_balance_grenadelauncher_primary_force;
float g_balance_grenadelauncher_primary_lifetime;
float g_balance_grenadelauncher_primary_radius;
float g_balance_grenadelauncher_primary_refire;
float g_balance_grenadelauncher_primary_speed;
float g_balance_grenadelauncher_primary_speed_up;
float g_balance_grenadelauncher_secondary_ammo;
float g_balance_grenadelauncher_secondary_animtime;
float g_balance_grenadelauncher_secondary_damage;
float g_balance_grenadelauncher_secondary_damageforcescale;
float g_balance_grenadelauncher_secondary_edgedamage;
float g_balance_grenadelauncher_secondary_force;
float g_balance_grenadelauncher_secondary_health;
float g_balance_grenadelauncher_secondary_lifetime;
float g_balance_grenadelauncher_secondary_radius;
float g_balance_grenadelauncher_secondary_refire;
float g_balance_grenadelauncher_secondary_speed;
float g_balance_grenadelauncher_secondary_speed_up;
float g_balance_grenadelauncher_secondary;

var .float gl_buttonatck1 = BUTTON_ATCK;
var .float gl_buttonatck2 = BUTTON_ATCK2;

void W_Grenade_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						announce(self.owner, "announcer/male/airshot.wav");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, g_balance_grenadelauncher_primary_damage, g_balance_grenadelauncher_primary_edgedamage, g_balance_grenadelauncher_primary_radius, world, g_balance_grenadelauncher_primary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Grenade_Explode2 (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(IsFlying(other))
					announce(self.owner, "announcer/male/airshot.wav");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, g_balance_grenadelauncher_secondary_damage, g_balance_grenadelauncher_secondary_edgedamage, g_balance_grenadelauncher_secondary_radius, world, g_balance_grenadelauncher_secondary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Grenade_Touch1 (void)
{
	PROJECTILE_TOUCH;
	W_Grenade_Explode ();
}

void W_Grenade_Touch2 (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
	{
		self.use ();
	}
	else
	{
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

void W_Grenade_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
	self.health = self.health - damage;
	if (self.health <= 0)
	{
		W_PrepareExplosionByDamage(attacker, self.think);
	}
}

void W_Grenade_Attack (void)
{
	local entity gren;
	float bounce = (g_balance_grenadelauncher_primary_bounce ? TRUE : FALSE);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_grenadelauncher_primary_ammo;
	W_SetupShot(self, 4, "weapons/grenade_fire.wav", 1);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = CSQCProjectile(TRUE, (bounce ? PROJECTILE_GRENADE_BOUNCING : PROJECTILE_GRENADE), TRUE);
	gren.gravity = 1;
	gren.owner = Akimbo_Owner(self);
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = g_balance_grenadelauncher_primary_damage;
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_GRENADE_LAUNCHER;
	setorigin(gren, w_shotorg);

	gren.nextthink = time + g_balance_grenadelauncher_primary_lifetime;
	gren.think = adaptor_think2use;
	gren.use = W_Grenade_Explode;
	gren.touch = (bounce ? W_Grenade_Touch2 : W_Grenade_Touch1);
	gren.velocity = w_shotdir * g_balance_grenadelauncher_primary_speed + v_up * g_balance_grenadelauncher_primary_speed_up;
	W_SetupProjectileVelocity(gren);

	gren.angles = vectoangles (gren.velocity);
}

void W_Grenade_Attack2 (void)
{
	local entity gren;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_grenadelauncher_secondary_ammo;
	W_SetupShot(self, 4, "weapons/grenade_fire.wav", 1);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = CSQCProjectile(TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);
	gren.gravity = 1;
	gren.owner = Akimbo_Owner(self);
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = g_balance_grenadelauncher_secondary_damage;
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_GRENADE_LAUNCHER | HITTYPE_SECONDARY;
	setorigin(gren, w_shotorg);

	gren.nextthink = time + g_balance_grenadelauncher_secondary_lifetime;
	gren.think = adaptor_think2use;
	gren.use = W_Grenade_Explode2;
	gren.touch = W_Grenade_Touch2;
	gren.takedamage = DAMAGE_YES;
	gren.health = g_balance_grenadelauncher_secondary_health;
	gren.damageforcescale = g_balance_grenadelauncher_secondary_damageforcescale;
	gren.event_damage = W_Grenade_Damage;
	gren.velocity = w_shotdir * g_balance_grenadelauncher_secondary_speed + v_up * g_balance_grenadelauncher_secondary_speed_up;
	W_SetupProjectileVelocity(gren);

	gren.angles = vectoangles (gren.velocity);
}

void spawnfunc_weapon_grenadelauncher (void)
{
	weapon_defaultspawnfunc(WEP_GRENADE_LAUNCHER);
}

.float bot_secondary_grenademooth;
float w_glauncher(float req)
{
	if (req == WR_AIM)
	{
		self.gl_buttonatck1 = FALSE;
		self.gl_buttonatck2 = FALSE;
		if (self.bot_secondary_grenademooth == 0 || !g_balance_grenadelauncher_secondary)
		{
			if(bot_aim(g_balance_grenadelauncher_primary_speed, g_balance_grenadelauncher_primary_speed_up, g_balance_grenadelauncher_primary_lifetime, TRUE))
			{
				self.gl_buttonatck1 = TRUE;
				if(random() < 0.01) self.bot_secondary_grenademooth = 1;
			}
		}
		else
		{
			if(bot_aim(g_balance_grenadelauncher_secondary_speed, g_balance_grenadelauncher_secondary_speed_up, g_balance_grenadelauncher_secondary_lifetime, TRUE))
			{
				self.gl_buttonatck2 = TRUE;
				if(random() < 0.02) self.bot_secondary_grenademooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if (self.gl_buttonatck1)
		if (weapon_prepareattack(0, g_balance_grenadelauncher_primary_refire))
		{
			W_Grenade_Attack();
			weapon_thinkf(WFRAME_FIRE1, g_balance_grenadelauncher_primary_animtime, w_ready);
		}
		if (self.gl_buttonatck2)
		if (g_balance_grenadelauncher_secondary)
		if (weapon_prepareattack(1, g_balance_grenadelauncher_secondary_refire))
		{
			W_Grenade_Attack2();
			weapon_thinkf(WFRAME_FIRE2, g_balance_grenadelauncher_secondary_animtime, w_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/grenade_bounce1.wav");
		precache_sound ("weapons/grenade_bounce2.wav");
		precache_sound ("weapons/grenade_bounce3.wav");
		precache_sound ("weapons/grenade_bounce4.wav");
		precache_sound ("weapons/grenade_bounce5.wav");
		precache_sound ("weapons/grenade_bounce6.wav");
		precache_sound ("weapons/grenade_fire.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_GRENADE_LAUNCHER);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_rockets >= g_balance_grenadelauncher_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_rockets >= g_balance_grenadelauncher_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "tried out his own grenade";
		else
			w_deathtypestring = "detonated";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SPLASH)
			if(w_deathtype & HITTYPE_BOUNCE) // (must be secondary then)
				w_deathtypestring = "didn't see #'s grenade";
			else // unchecked: SECONDARY
				w_deathtypestring = "almost dodged #'s grenade";
		else // unchecked: SECONDARY, BOUNCE
			w_deathtypestring = "ate #'s grenade";
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_grenadelauncher_primary_ammo);
		CACHE_CVAR(g_balance_grenadelauncher_primary_animtime);
		CACHE_CVAR(g_balance_grenadelauncher_primary_bounce);
		CACHE_CVAR(g_balance_grenadelauncher_primary_damage);
		CACHE_CVAR(g_balance_grenadelauncher_primary_edgedamage);
		CACHE_CVAR(g_balance_grenadelauncher_primary_force);
		CACHE_CVAR(g_balance_grenadelauncher_primary_lifetime);
		CACHE_CVAR(g_balance_grenadelauncher_primary_radius);
		CACHE_CVAR(g_balance_grenadelauncher_primary_refire);
		CACHE_CVAR(g_balance_grenadelauncher_primary_speed);
		CACHE_CVAR(g_balance_grenadelauncher_primary_speed_up);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_ammo);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_animtime);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_damage);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_damageforcescale);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_edgedamage);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_force);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_health);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_lifetime);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_radius);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_refire);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_speed);
		CACHE_CVAR(g_balance_grenadelauncher_secondary_speed_up);
		CACHE_CVAR(g_balance_grenadelauncher_secondary);
		CSQCProjectile_Init(PROJECTILE_GRENADE);
		CSQCProjectile_Init(PROJECTILE_GRENADE_BOUNCING);
		if (cvar("g_balance_grenadelauncher_swap_buttons")) {
			gl_buttonatck1 = BUTTON_ATCK2;
			gl_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
};
