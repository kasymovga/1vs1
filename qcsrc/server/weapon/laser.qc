float g_balance_laser_primary_animtime;
float g_balance_laser_primary_damage;
float g_balance_laser_primary_edgedamage;
float g_balance_laser_primary_force;
float g_balance_laser_primary_lifetime;
float g_balance_laser_primary_radius;
float g_balance_laser_primary_refire;
float g_balance_laser_primary_shotangle;
float g_balance_laser_primary_speed;
float g_balance_laser_secondary;
float g_balance_laser_secondary_animtime;
float g_balance_laser_secondary_damage;
float g_balance_laser_secondary_edgedamage;
float g_balance_laser_secondary_force;
float g_balance_laser_secondary_lifetime;
float g_balance_laser_secondary_radius;
float g_balance_laser_secondary_refire;
float g_balance_laser_secondary_shotangle;
float g_balance_laser_secondary_speed;

void(float issecondary) weapon_laser_attack {
	vector s_forward;
	float a;
	if (issecondary)
		a = g_balance_laser_secondary_shotangle;
	else
		a = g_balance_laser_primary_shotangle;

	s_forward = v_forward * cos(a * DEG2RAD) + v_up * sin(a * DEG2RAD);
	weapon_setup_shotdir (self, s_forward, 3, "weapons/lasergun_fire.wav", 1);
	pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	if (issecondary)
		laser_projectile(weapon_shotdir, g_balance_laser_secondary_speed,
				g_balance_laser_secondary_damage, g_balance_laser_secondary_edgedamage,
				g_balance_laser_secondary_radius, g_balance_laser_secondary_force,
				FALSE, TRUE, g_balance_laser_secondary_lifetime);
	else
		laser_projectile(weapon_shotdir, g_balance_laser_primary_speed,
				g_balance_laser_primary_damage, g_balance_laser_primary_edgedamage,
				g_balance_laser_primary_radius, g_balance_laser_primary_force,
				FALSE, TRUE, g_balance_laser_primary_lifetime);
}

void spawnfunc_weapon_laser (void)
{
	weapon_defaultspawnfunc(WEP_LASER);
}

float weapon_laser(float req)
{
	if (req == WR_AIM)
		self.BUTTON_ATCK = bot_aim(g_balance_laser_primary_speed, 0, g_balance_laser_primary_lifetime, FALSE);
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, g_balance_laser_primary_refire))
			{
				weapon_laser_attack(FALSE);
				weapon_thinkf(WFRAME_FIRE1, g_balance_laser_primary_animtime, weapon_ready);
			}
		}
		if (self.BUTTON_ATCK2)
		{
			if(g_balance_laser_secondary)
			{
				if (weapon_prepareattack(0, g_balance_laser_secondary_refire))
				{
					weapon_laser_attack(TRUE);
					weapon_thinkf(WFRAME_FIRE2, g_balance_laser_secondary_animtime, weapon_ready);
				}
			}
			else
			{
				if(self.switchweapon == WEP_LASER) // don't do this if already switching
					weapon_switch(self.cnt);
			}
		}
	}
	else if (req == WR_PRECACHE) {
		precache_sound ("weapons/lasergun_fire.wav");
	} else if (req == WR_SETUP)
		weapon_setup(WEP_LASER);
	else if (req == WR_CHECKAMMO1)
		return TRUE;
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		weapon_deathtypestring = "lasered himself to hell";
	else if (req == WR_KILLMESSAGE)
		weapon_deathtypestring = "was lasered to death by"; // unchecked: SPLASH
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_laser_primary_animtime);
		CACHE_CVAR(g_balance_laser_primary_damage);
		CACHE_CVAR(g_balance_laser_primary_edgedamage);
		CACHE_CVAR(g_balance_laser_primary_force);
		CACHE_CVAR(g_balance_laser_primary_lifetime);
		CACHE_CVAR(g_balance_laser_primary_radius);
		CACHE_CVAR(g_balance_laser_primary_refire);
		CACHE_CVAR(g_balance_laser_primary_shotangle);
		CACHE_CVAR(g_balance_laser_primary_speed);
		CACHE_CVAR(g_balance_laser_secondary);
		CACHE_CVAR(g_balance_laser_secondary_animtime);
		CACHE_CVAR(g_balance_laser_secondary_damage);
		CACHE_CVAR(g_balance_laser_secondary_edgedamage);
		CACHE_CVAR(g_balance_laser_secondary_force);
		CACHE_CVAR(g_balance_laser_secondary_lifetime);
		CACHE_CVAR(g_balance_laser_secondary_radius);
		CACHE_CVAR(g_balance_laser_secondary_refire);
		CACHE_CVAR(g_balance_laser_secondary_shotangle);
		CACHE_CVAR(g_balance_laser_secondary_speed);
		projectile_init(PROJECTILE_LASER);
	}
	return TRUE;
};
