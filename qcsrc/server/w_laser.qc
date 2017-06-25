void(float imp) W_SwitchWeapon;

float g_balance_laser_primary_animtime;
float g_balance_laser_primary_damage;
float g_balance_laser_primary_edgedamage;
float g_balance_laser_primary_force;
//float g_balance_laser_primary_melee; //defined in defs.qh
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
//float g_balance_laser_secondary_melee; //defined in defs.qh
float g_balance_laser_secondary_lifetime;
float g_balance_laser_secondary_radius;
float g_balance_laser_secondary_refire;
float g_balance_laser_secondary_shotangle;
float g_balance_laser_secondary_speed;

void W_Laser_Touch (void)
{
	PROJECTILE_TOUCH;

	self.event_damage = SUB_Null;
	if (self.dmg)
		RadiusDamage (self, self.owner, g_balance_laser_secondary_damage, g_balance_laser_secondary_edgedamage, g_balance_laser_secondary_radius, world, g_balance_laser_secondary_force, self.projectiledeathtype, other);
	else
		RadiusDamage (self, self.owner, g_balance_laser_primary_damage, g_balance_laser_primary_edgedamage, g_balance_laser_primary_radius, world, g_balance_laser_primary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Laser_Attack (float issecondary)
{
	local entity missile;
	vector s_forward;
	float a;

	if (issecondary)
		a = g_balance_laser_secondary_shotangle;
	else
		a = g_balance_laser_primary_shotangle;
	s_forward = v_forward * cos(a * DEG2RAD) + v_up * sin(a * DEG2RAD);

	if(issecondary)
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", g_balance_laser_secondary_damage);
	else
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", g_balance_laser_primary_damage);
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = Akimbo_Owner(self);
	missile.classname = "laserbolt";
	missile.dmg = issecondary;
	missile.bot_dodge = TRUE;
	if (issecondary)
		missile.bot_dodgerating = g_balance_laser_secondary_damage;
	else
		missile.bot_dodgerating = g_balance_laser_primary_damage;

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_LASER;
	if(issecondary)
		missile.projectiledeathtype |= HITTYPE_SECONDARY;

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	if (issecondary)
		missile.velocity = w_shotdir * g_balance_laser_secondary_speed;
	else
		missile.velocity = w_shotdir * g_balance_laser_primary_speed;
	W_SetupProjectileVelocity(missile);
	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = W_Laser_Touch;
	missile.think = SUB_Remove;
	if (issecondary)
		missile.nextthink = time + g_balance_laser_secondary_lifetime;
	else
		missile.nextthink = time + g_balance_laser_primary_lifetime;

	missile.flags = FL_PROJECTILE;

	CSQCProjectile(missile, TRUE, PROJECTILE_LASER, TRUE);
}

void spawnfunc_weapon_laser (void)
{
	weapon_defaultspawnfunc(WEP_LASER);
}

float w_laser(float req)
{
	if (req == WR_AIM)
		self.BUTTON_ATCK = bot_aim(g_balance_laser_primary_speed, 0, g_balance_laser_primary_lifetime, FALSE);
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if (g_balance_laser_primary_melee)
				W_Melee_Attack_Check();
			else if (weapon_prepareattack(0, g_balance_laser_primary_refire))
			{
				W_Laser_Attack(FALSE);
				weapon_thinkf(WFRAME_FIRE1, g_balance_laser_primary_animtime, w_ready);
			}
		}
		if (self.BUTTON_ATCK2)
		{
			if(g_balance_laser_secondary)
			{
				if (g_balance_laser_secondary_melee)
					W_Melee_Attack_Check();
				else if (weapon_prepareattack(0, g_balance_laser_secondary_refire))
				{
					W_Laser_Attack(TRUE);
					weapon_thinkf(WFRAME_FIRE2, g_balance_laser_secondary_animtime, w_ready);
				}
			}
			else
			{
				if(self.switchweapon == WEP_LASER) // don't do this if already switching
					W_SwitchWeapon (self.cnt);
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
		w_deathtypestring = "lasered himself to hell";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "was lasered to death by"; // unchecked: SPLASH
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_laser_primary_animtime);
		CACHE_CVAR(g_balance_laser_primary_damage);
		CACHE_CVAR(g_balance_laser_primary_edgedamage);
		CACHE_CVAR(g_balance_laser_primary_force);
		CACHE_CVAR(g_balance_laser_primary_melee);
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
		CACHE_CVAR(g_balance_laser_secondary_melee);
		CACHE_CVAR(g_balance_laser_secondary_lifetime);
		CACHE_CVAR(g_balance_laser_secondary_radius);
		CACHE_CVAR(g_balance_laser_secondary_refire);
		CACHE_CVAR(g_balance_laser_secondary_shotangle);
		CACHE_CVAR(g_balance_laser_secondary_speed);

		ProjInfo_RegisterAuto(PROJECTILE_LASER, '0 0 0', '0 0 0');
	}
	return TRUE;
};
