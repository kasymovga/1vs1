// leilei's fancy muzzleflash stuff
void W_Uzi_Flash_Go() {
	if (self.frame > 10){
		SUB_Remove();
		return;
	}
	self.frame = self.frame + 2;
	self.alpha = self.alpha - 0.2;
	self.think = W_Uzi_Flash_Go;
	self.nextthink = time + 0.02;
};

float g_balance_uzi_bulletconstant;
float g_balance_uzi_first;
float g_balance_uzi_first_ammo;
float g_balance_uzi_first_damage;
float g_balance_uzi_first_force;
float g_balance_uzi_first_gravityfactor;
float g_balance_uzi_first_refire;
float g_balance_uzi_first_spread;
float g_balance_uzi_speed;
float g_balance_uzi_sustained_ammo;
float g_balance_uzi_sustained_damage;
float g_balance_uzi_sustained_force;
float g_balance_uzi_sustained_gravityfactor;
float g_balance_uzi_sustained_refire;
float g_balance_uzi_sustained_spread;

.float uzi_bulletcounter;
void W_Uzi_Attack (float deathtype)
{
	local entity flash;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if (self.uzi_bulletcounter == 1)
			self.ammo_nails = self.ammo_nails - g_balance_uzi_first_ammo;
		else
			self.ammo_nails = self.ammo_nails - g_balance_uzi_sustained_ammo;
	}
	W_SetupShot (self, g_antilag_bullets && g_balance_uzi_speed >= g_antilag_bullets, 0, "weapons/uzi_fire.wav", g_balance_uzi_first_damage);
	if (!g_norecoil)
	{
		self.punchangle_x = random () - 0.5;
		self.punchangle_y = random () - 0.5;
	}

	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(self) = time + g_balance_uzi_first_refire * W_WeaponRateFactor();

	if (self.uzi_bulletcounter == 1)
		fireBallisticBullet(w_shotorg, w_shotdir, g_balance_uzi_first_spread, g_balance_uzi_speed, 5, g_balance_uzi_first_damage, 0, g_balance_uzi_first_force, deathtype, 0, g_balance_uzi_first_gravityfactor, g_balance_uzi_bulletconstant);
	else
		fireBallisticBullet(w_shotorg, w_shotdir, g_balance_uzi_sustained_spread, g_balance_uzi_speed, 5, g_balance_uzi_sustained_damage, 0, g_balance_uzi_sustained_force, deathtype, 0, g_balance_uzi_sustained_gravityfactor, g_balance_uzi_bulletconstant);
	endFireBallisticBullet();

	pointparticles(particleeffectnum("uzi_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	//SUB_SetFade(flash, time + 0.06, 0);
	flash.think = W_Uzi_Flash_Go;
	flash.nextthink = time + 0.02;
	flash.frame = 2;
	flash.alpha = 1;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');

	// casing code
	if (g_casings >= 2)
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);
}

// weapon frames
void uzi_fire1_02()
{
	if(self.weapon != self.switchweapon) // abort immediately if switching
	{
		w_ready();
		return;
	}
	if (self.BUTTON_ATCK)
	{
		if (!weapon_action(self.weapon, WR_CHECKAMMO2))
		{
			W_SwitchWeapon_Force(self, w_getbestweapon(self));
			w_ready();
			return;
		}
		self.uzi_bulletcounter = self.uzi_bulletcounter + 1;
		W_Uzi_Attack(WEP_UZI);
		weapon_thinkf(WFRAME_FIRE1, g_balance_uzi_sustained_refire, uzi_fire1_02);
	}
	else
		weapon_thinkf(WFRAME_FIRE1, g_balance_uzi_sustained_refire, w_ready);
};

float w_uzi(float req)
{
	if (req == WR_AIM)
		if(vlen(self.origin-self.enemy.origin) < 3000 - bound(0, skill, 10) * 200 || !g_balance_uzi_first)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
		else
		{
			self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
		}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, 0))
		{
			self.uzi_bulletcounter = 1;
			W_Uzi_Attack(WEP_UZI); // sets attack_finished
			weapon_thinkf(WFRAME_FIRE1, g_balance_uzi_sustained_refire, uzi_fire1_02);
		}
		if (self.BUTTON_ATCK2)
		if (g_balance_uzi_first)
		if (weapon_prepareattack(1, 0))
		{
			self.uzi_bulletcounter = 1;
			W_Uzi_Attack(WEP_UZI | HITTYPE_SECONDARY); // sets attack_finished
			weapon_thinkf(WFRAME_FIRE2, g_balance_uzi_first_refire, w_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/uziflash.md3");
		precache_sound ("weapons/uzi_fire.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_UZI);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_nails >= g_balance_uzi_first_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_nails >= g_balance_uzi_first_ammo;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "was sniped by";
		else
			w_deathtypestring = "was riddled full of holes by";
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_uzi_bulletconstant);
		CACHE_CVAR(g_balance_uzi_first);
		CACHE_CVAR(g_balance_uzi_first_ammo);
		CACHE_CVAR(g_balance_uzi_first_damage);
		CACHE_CVAR(g_balance_uzi_first_force);
		CACHE_CVAR(g_balance_uzi_first_gravityfactor);
		CACHE_CVAR(g_balance_uzi_first_refire);
		CACHE_CVAR(g_balance_uzi_first_spread);
		CACHE_CVAR(g_balance_uzi_speed);
		CACHE_CVAR(g_balance_uzi_sustained_ammo);
		CACHE_CVAR(g_balance_uzi_sustained_damage);
		CACHE_CVAR(g_balance_uzi_sustained_force);
		CACHE_CVAR(g_balance_uzi_sustained_gravityfactor);
		CACHE_CVAR(g_balance_uzi_sustained_refire);
		CACHE_CVAR(g_balance_uzi_sustained_spread);
	}
	return TRUE;
};
