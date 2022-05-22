float g_balance_laser_primary_animtime;
float g_balance_laser_primary_damage;
float g_balance_laser_primary_edgedamage;
float g_balance_laser_primary_force;
float g_balance_laser_primary_lifetime;
float g_balance_laser_primary_radius;
float g_balance_laser_primary_refire;
float g_balance_laser_primary_shotangle;
float g_balance_laser_primary_speed;
float g_balance_laser_recoil;
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

	s_forward = v_forward * cos(a * MATH_DEG2RAD) + v_up * sin(a * MATH_DEG2RAD);
	weapon_setup_shotdir (self, s_forward, g_balance_laser_recoil, "weapons/lasergun_fire.wav", 1);
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

void(void) spawnfunc_weapon_laser {
	weapon_defaultspawnfunc(WEP_LASER);
}

float(float req) weapon_laser {
	if (req == WR_AIM)
		self.BUTTON_ATCK = bot_aim(g_balance_laser_primary_speed, 0, g_balance_laser_primary_lifetime, FALSE);
	else if (req == WR_THINK) {
		if (self.BUTTON_ATCK) {
			if (weapon_prepareattack(0, g_balance_laser_primary_refire)) {
				weapon_laser_attack(FALSE);
				weapon_thinkf(WFRAME_FIRE1, g_balance_laser_primary_animtime, weapon_ready);
			}
		}
		if (self.BUTTON_ATCK2) {
			if(g_balance_laser_secondary) {
				if (weapon_prepareattack(0, g_balance_laser_secondary_refire)) {
					weapon_laser_attack(TRUE);
					weapon_thinkf(WFRAME_FIRE2, g_balance_laser_secondary_animtime, weapon_ready);
				}
			} else {
				if(self.switchweapon == WEP_LASER) // don't do this if already switching
					weapon_switch(self.cnt);
			}
		}
	}
	else if (req == WR_PRECACHE) {
		precache_sound("weapons/lasergun_fire.wav");
		if (cvar("g_balance_laser_primary_force") > 0)
			hint_add("You can use Laser for high jumps or accelerating. Just shoot under your legs or near walls.");
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
	else if (req == WR_CVAR_CACHE) {
		CVAR_CACHE(g_balance_laser_primary_animtime);
		CVAR_CACHE(g_balance_laser_primary_damage);
		CVAR_CACHE(g_balance_laser_primary_edgedamage);
		CVAR_CACHE(g_balance_laser_primary_force);
		CVAR_CACHE(g_balance_laser_primary_lifetime);
		CVAR_CACHE(g_balance_laser_primary_radius);
		CVAR_CACHE(g_balance_laser_primary_refire);
		CVAR_CACHE(g_balance_laser_primary_shotangle);
		CVAR_CACHE(g_balance_laser_primary_speed);
		CVAR_CACHE(g_balance_laser_recoil);
		CVAR_CACHE(g_balance_laser_secondary);
		CVAR_CACHE(g_balance_laser_secondary_animtime);
		CVAR_CACHE(g_balance_laser_secondary_damage);
		CVAR_CACHE(g_balance_laser_secondary_edgedamage);
		CVAR_CACHE(g_balance_laser_secondary_force);
		CVAR_CACHE(g_balance_laser_secondary_lifetime);
		CVAR_CACHE(g_balance_laser_secondary_radius);
		CVAR_CACHE(g_balance_laser_secondary_refire);
		CVAR_CACHE(g_balance_laser_secondary_shotangle);
		CVAR_CACHE(g_balance_laser_secondary_speed);
		projectile_init(PROJECTILE_LASER);
	}
	return TRUE;
}
