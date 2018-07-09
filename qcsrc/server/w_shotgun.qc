float g_balance_shotgun_primary_ammo;
float g_balance_shotgun_primary_animtime;
float g_balance_shotgun_primary_bulletconstant;
float g_balance_shotgun_primary_bullets;
float g_balance_shotgun_primary_damage;
float g_balance_shotgun_primary_force;
float g_balance_shotgun_primary_gravityfactor;
float g_balance_shotgun_primary_refire;
float g_balance_shotgun_primary_speed;
float g_balance_shotgun_primary_spread;
float g_balance_shotgun_secondary;
float g_balance_shotgun_secondary_ammo;
float g_balance_shotgun_secondary_animtime;
float g_balance_shotgun_secondary_bulletconstant;
float g_balance_shotgun_secondary_bullets;
float g_balance_shotgun_secondary_damage;
float g_balance_shotgun_secondary_force;
float g_balance_shotgun_secondary_gravityfactor;
float g_balance_shotgun_secondary_refire;
float g_balance_shotgun_secondary_speed;
float g_balance_shotgun_secondary_spread;
var .float sg_buttonatck1 = BUTTON_ATCK;
var .float sg_buttonatck2 = BUTTON_ATCK2;

void W_Shotgun_Attack (void)
{
	float	sc;
	local entity flash;

	beginFireBallisticBullet(g_balance_shotgun_primary_speed);
	W_SetupShot (self, 5, "weapons/shotgun_fire.wav", g_balance_shotgun_primary_bullets);

	for (sc = 0;sc < g_balance_shotgun_primary_bullets;sc = sc + 1)
		fireBallisticBullet(w_shotorg, w_shotdir, g_balance_shotgun_primary_spread, g_balance_shotgun_primary_speed, 5,
				g_balance_shotgun_primary_damage, 0, g_balance_shotgun_primary_force,
				WEP_SHOTGUN, particleeffectnum("tr_bullet"), g_balance_shotgun_primary_gravityfactor, g_balance_shotgun_primary_bulletconstant);
	endFireBallisticBullet();
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - g_balance_shotgun_primary_ammo;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, g_balance_shotgun_primary_ammo);

	// casing code
	if (g_casings >= 1)
		for (sc = 0; sc < g_balance_shotgun_primary_ammo; sc = sc + 1)
			SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');

}

void W_Shotgun_Attack2 (void)
{
	float	sc;
	local entity flash;

	beginFireBallisticBullet(g_balance_shotgun_secondary_speed);
	W_SetupShot (self, 5, "weapons/shotgun_fire.wav", g_balance_shotgun_secondary_bullets);
	for (sc = 0; sc < g_balance_shotgun_secondary_bullets; sc = sc + 1)
		fireBallisticBullet(w_shotorg, w_shotdir, g_balance_shotgun_secondary_spread, g_balance_shotgun_secondary_speed, 5,
				g_balance_shotgun_secondary_damage, 0, g_balance_shotgun_secondary_force,
				WEP_SHOTGUN | HITTYPE_SECONDARY, particleeffectnum("tr_bullet"), g_balance_shotgun_secondary_gravityfactor,
				g_balance_shotgun_secondary_bulletconstant);
	endFireBallisticBullet();
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - g_balance_shotgun_secondary_ammo;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, g_balance_shotgun_secondary_ammo);

	// casing code
	if (g_casings >= 1)
		for (sc = 0; sc < g_balance_shotgun_secondary_ammo; sc = sc + 1)
			SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.scale = 1.2;
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');
}

// weapon frames
void shotgun_fire2_03()
{
	W_Shotgun_Attack2();
	weapon_thinkf(WFRAME_FIRE2, g_balance_shotgun_secondary_animtime, w_ready);
}
void shotgun_fire2_02()
{
	W_Shotgun_Attack2();
	weapon_thinkf(WFRAME_FIRE2, g_balance_shotgun_secondary_animtime, shotgun_fire2_03);
}

void spawnfunc_weapon_shotgun(); // defined in t_items.qc

float w_shotgun(float req)
{
	if (req == WR_AIM)
		if(vlen(self.origin-self.enemy.origin)>200 || !g_balance_shotgun_secondary)
			self.sg_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.sg_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
	else if (req == WR_THINK)
	{
		if (self.sg_buttonatck1)
		if (weapon_prepareattack(0, g_balance_shotgun_primary_refire))
		{
			W_Shotgun_Attack();
			weapon_thinkf(WFRAME_FIRE1, g_balance_shotgun_primary_animtime, w_ready);
		}
		if (self.sg_buttonatck2)
		if (g_balance_shotgun_secondary)
		if (weapon_prepareattack(1, g_balance_shotgun_secondary_refire))
		{
			W_Shotgun_Attack2();
			weapon_thinkf(WFRAME_FIRE2, g_balance_shotgun_secondary_animtime, shotgun_fire2_02);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/uziflash.md3");
		precache_sound ("misc/itempickup.wav");
		precache_sound ("weapons/shotgun_fire.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_SHOTGUN);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_shells >= g_balance_shotgun_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_shells >= g_balance_shotgun_secondary_ammo * 3;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
	{
		w_deathtypestring = "was gunned by"; // unchecked: SECONDARY
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_shotgun_primary_ammo);
		CACHE_CVAR(g_balance_shotgun_primary_animtime);
		CACHE_CVAR(g_balance_shotgun_primary_bulletconstant);
		CACHE_CVAR(g_balance_shotgun_primary_bullets);
		CACHE_CVAR(g_balance_shotgun_primary_damage);
		CACHE_CVAR(g_balance_shotgun_primary_force);
		CACHE_CVAR(g_balance_shotgun_primary_gravityfactor);
		CACHE_CVAR(g_balance_shotgun_primary_refire);
		CACHE_CVAR(g_balance_shotgun_primary_speed);
		CACHE_CVAR(g_balance_shotgun_primary_spread);
		CACHE_CVAR(g_balance_shotgun_secondary);
		CACHE_CVAR(g_balance_shotgun_secondary_ammo);
		CACHE_CVAR(g_balance_shotgun_secondary_animtime);
		CACHE_CVAR(g_balance_shotgun_secondary_bulletconstant);
		CACHE_CVAR(g_balance_shotgun_secondary_bullets);
		CACHE_CVAR(g_balance_shotgun_secondary_damage);
		CACHE_CVAR(g_balance_shotgun_secondary_force);
		CACHE_CVAR(g_balance_shotgun_secondary_gravityfactor);
		CACHE_CVAR(g_balance_shotgun_secondary_refire);
		CACHE_CVAR(g_balance_shotgun_secondary_speed);
		CACHE_CVAR(g_balance_shotgun_secondary_spread);
		if (cvar("g_balance_shotgun_swap_buttons")) {
			sg_buttonatck1 = BUTTON_ATCK2;
			sg_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
};
