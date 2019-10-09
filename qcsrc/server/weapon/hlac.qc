float g_balance_hlac_primary_ammo;
float g_balance_hlac_primary_animtime;
float g_balance_hlac_primary_damage;
float g_balance_hlac_primary_edgedamage;
float g_balance_hlac_primary_force;
float g_balance_hlac_primary_lifetime;
float g_balance_hlac_primary_radius;
float g_balance_hlac_primary_refire;
float g_balance_hlac_primary_speed;
float g_balance_hlac_primary_spread_add;
float g_balance_hlac_primary_spread_crouchmod;
float g_balance_hlac_primary_spread_max;
float g_balance_hlac_primary_spread_min;
float g_balance_hlac_secondary;
float g_balance_hlac_secondary_ammo;
float g_balance_hlac_secondary_animtime;
float g_balance_hlac_secondary_damage;
float g_balance_hlac_secondary_edgedamage;
float g_balance_hlac_secondary_force;
float g_balance_hlac_secondary_lifetime;
float g_balance_hlac_secondary_radius;
float g_balance_hlac_secondary_refire;
float g_balance_hlac_secondary_shots;
float g_balance_hlac_secondary_speed;
float g_balance_hlac_secondary_spread;
float g_balance_hlac_secondary_spread_crouchmod;

var .float hlac_buttonatck1 = BUTTON_ATCK;
var .float hlac_buttonatck2 = BUTTON_ATCK2;

.float HLAC_bulletcounter;

void(void) weapon_hlac_attack {
	entity missile;
    float spread;
    if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
        self.ammo_cells = self.ammo_cells - g_balance_hlac_primary_ammo;
    }
    spread = g_balance_hlac_primary_spread_min + (g_balance_hlac_primary_spread_add * self.HLAC_bulletcounter);
    spread = min(spread,g_balance_hlac_primary_spread_max);
    if(self.crouch)
        spread = spread * g_balance_hlac_primary_spread_crouchmod;

	weapon_setup_shot (self, 3, "weapons/lasergun_fire.wav", 1);
	weapon_shake(1);
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);
	missile = projectile(TRUE, PROJECTILE_HLAC, TRUE, self);
	projectile_setup(missile, w_shotorg, WEP_HLAC, g_balance_hlac_primary_damage,
			g_balance_hlac_primary_edgedamage, g_balance_hlac_primary_radius, g_balance_hlac_primary_force);

	missile.movetype = MOVETYPE_FLY;
    missile.velocity = (w_shotdir + randomvec() * spread) * g_balance_hlac_primary_speed;
	weapon_setup_projectile_velocity(missile);
	missile.touch = projectile_touch_explode;
	missile.think = stdproc_remove;
    missile.nextthink = time + g_balance_hlac_primary_lifetime;
}

void(void) weapon_hlac_attack2f {
	entity missile;
    float spread;
    spread = g_balance_hlac_secondary_spread;
    if(self.crouch)
        spread = spread * g_balance_hlac_secondary_spread_crouchmod;

	missile = projectile(TRUE, PROJECTILE_HLAC, TRUE, self);
	projectile_setup(missile, w_shotorg, WEP_HLAC | HITTYPE_SECONDARY, g_balance_hlac_primary_damage,
			g_balance_hlac_primary_edgedamage, g_balance_hlac_primary_radius, g_balance_hlac_primary_force);

	missile.movetype = MOVETYPE_FLY;
    missile.velocity = (w_shotdir + randomvec() * spread) * g_balance_hlac_secondary_speed;
	weapon_setup_projectile_velocity(missile);
	missile.touch = projectile_touch_explode;
	missile.think = stdproc_remove;
    missile.nextthink = time + g_balance_hlac_secondary_lifetime;
}

void(void) weapon_hlac_attack2 {
    float i;
    if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
        self.ammo_cells = self.ammo_cells - g_balance_hlac_secondary_ammo;
    }
	weapon_setup_shot(self, 3, "weapons/lasergun_fire.wav", 1);
	weapon_shake(1);
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);
    for(i = g_balance_hlac_secondary_shots; i > 0; --i)
        weapon_hlac_attack2f();
}

// weapon frames
void weapon_hlack_fire1_02()
{
	if(self.weapon != self.switchweapon || !player_can_fire(self, TRUE))
	{
		weapon_ready();
		return;
	}

	if (self.hlac_buttonatck1)
	{
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		if not(weapon_action(self.weapon, WR_CHECKAMMO1))
		{
			weapon_switch_force(self, weapon_best(self));
			weapon_ready();
			return;
		}

		ATTACK_FINISHED(self) = time + g_balance_hlac_primary_refire * weapon_rate_factor();
		weapon_hlac_attack();
		self.HLAC_bulletcounter = self.HLAC_bulletcounter + 1;
        weapon_thinkf(WFRAME_FIRE1, g_balance_hlac_primary_refire, weapon_hlack_fire1_02);
	}
	else
	{
		weapon_thinkf(WFRAME_FIRE1, g_balance_hlac_primary_animtime, weapon_ready);
	}
}

void spawnfunc_weapon_hlac (void)
{
	weapon_defaultspawnfunc(WEP_HLAC);
}

float weapon_hlac(float req)
{
	if (req == WR_AIM)
        self.hlac_buttonatck1 = bot_aim(g_balance_hlac_primary_speed, 0, g_balance_hlac_primary_lifetime, FALSE);
	else if (req == WR_THINK)
	{
		if (self.hlac_buttonatck1)
		if (weapon_prepareattack(0, g_balance_hlac_primary_refire))
		{
			self.HLAC_bulletcounter = 0;
			weapon_hlac_attack();
			weapon_thinkf(WFRAME_FIRE1, g_balance_hlac_primary_refire, weapon_hlack_fire1_02);
		}

		if (self.hlac_buttonatck2)
		if (g_balance_hlac_secondary)
		if (weapon_prepareattack(1, g_balance_hlac_secondary_refire))
		{
			weapon_hlac_attack2();
			weapon_thinkf(WFRAME_FIRE2, g_balance_hlac_secondary_animtime, weapon_ready);
		}

	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/lasergun_fire.wav");

	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_HLAC);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= g_balance_hlac_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_cells >= g_balance_hlac_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "should have used a smaller gun";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "was cut down by";
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_hlac_primary_ammo);
		CACHE_CVAR(g_balance_hlac_primary_animtime);
		CACHE_CVAR(g_balance_hlac_primary_damage);
		CACHE_CVAR(g_balance_hlac_primary_edgedamage);
		CACHE_CVAR(g_balance_hlac_primary_force);
		CACHE_CVAR(g_balance_hlac_primary_lifetime);
		CACHE_CVAR(g_balance_hlac_primary_radius);
		CACHE_CVAR(g_balance_hlac_primary_refire);
		CACHE_CVAR(g_balance_hlac_primary_speed);
		CACHE_CVAR(g_balance_hlac_primary_spread_add);
		CACHE_CVAR(g_balance_hlac_primary_spread_crouchmod);
		CACHE_CVAR(g_balance_hlac_primary_spread_max);
		CACHE_CVAR(g_balance_hlac_primary_spread_min);
		CACHE_CVAR(g_balance_hlac_secondary);
		CACHE_CVAR(g_balance_hlac_secondary_ammo);
		CACHE_CVAR(g_balance_hlac_secondary_animtime);
		CACHE_CVAR(g_balance_hlac_secondary_damage);
		CACHE_CVAR(g_balance_hlac_secondary_edgedamage);
		CACHE_CVAR(g_balance_hlac_secondary_force);
		CACHE_CVAR(g_balance_hlac_secondary_lifetime);
		CACHE_CVAR(g_balance_hlac_secondary_radius);
		CACHE_CVAR(g_balance_hlac_secondary_refire);
		CACHE_CVAR(g_balance_hlac_secondary_shots);
		CACHE_CVAR(g_balance_hlac_secondary_speed);
		CACHE_CVAR(g_balance_hlac_secondary_spread);
		CACHE_CVAR(g_balance_hlac_secondary_spread_crouchmod);
		projectile_init(PROJECTILE_HLAC);
		if (cvar("g_balance_hlac_swap_buttons")) {
			hlac_buttonatck1 = BUTTON_ATCK2;
			hlac_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}
