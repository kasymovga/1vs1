// leilei's fancy muzzleflash stuff
void weapon_uzi_flash_go() {
	if (self.frame > 10){
		stdproc_remove();
		return;
	}
	self.frame = self.frame + 2;
	self.alpha = self.alpha - 0.2;
	self.think = weapon_uzi_flash_go;
	self.nextthink = time + 0.02;
}

.float uzi_ammoclip;
float g_balance_uzi_magazinecapacity;
float g_balance_uzi_reloadtime;
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

var .float uzi_buttonatck1 = BUTTON_ATCK;
var .float uzi_buttonatck2 = BUTTON_ATCK2;
.float uzi_bulletcounter;
void(float deathtype) weapon_uzi_attack {
	entity flash;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if (self.uzi_bulletcounter == 1)
			self.ammo_nails = self.ammo_nails - g_balance_uzi_first_ammo;
		else
			self.ammo_nails = self.ammo_nails - g_balance_uzi_sustained_ammo;

	}
	if (g_balance_uzi_magazinecapacity)
		self.uzi_ammoclip -= 1;

	bullet_begin(g_balance_uzi_speed);
	weapon_setup_shot (self, 0, "weapons/uzi_fire.wav", 1);
	weapon_shake(1);
	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(self) = time + g_balance_uzi_first_refire * weapon_rate_factor();

	if (self.uzi_bulletcounter == 1)
		bullet(weapon_shotorg, weapon_shotdir, g_balance_uzi_first_spread, g_balance_uzi_speed, 5, g_balance_uzi_first_damage, 0, g_balance_uzi_first_force, deathtype, particleeffectnum("tr_bullet"), g_balance_uzi_first_gravityfactor, g_balance_uzi_bulletconstant);
	else
		bullet(weapon_shotorg, weapon_shotdir, g_balance_uzi_sustained_spread, g_balance_uzi_speed, 5, g_balance_uzi_sustained_damage, 0, g_balance_uzi_sustained_force, deathtype, particleeffectnum("tr_bullet"), g_balance_uzi_sustained_gravityfactor, g_balance_uzi_bulletconstant);
	bullet_end();

	pointparticles(particleeffectnum("uzi_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	//SUB_SetFade(flash, time + 0.06, 0);
	flash.think = weapon_uzi_flash_go;
	flash.nextthink = time + 0.02;
	flash.frame = 2;
	flash.alpha = 1;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	weapon_attach_to_shotorg(flash, '5 0 0');
	casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 2, self);
}

// weapon frames
void(void) weapon_uzi_fire1_02 {
	if(self.weapon != self.switchweapon || !player_can_fire(self, TRUE) || (g_balance_uzi_magazinecapacity && self.uzi_ammoclip <= 0)) {
		weapon_ready();
		return;
	}
	if (self.uzi_buttonatck1) {
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		if not(weapon_action(self.weapon, WR_CHECKAMMO1))
		{
			weapon_switch_force(self, weapon_best(self));
			weapon_ready();
			return;
		}
		self.uzi_bulletcounter = self.uzi_bulletcounter + 1;
		weapon_uzi_attack(WEP_UZI);
		weapon_thinkf(WFRAME_FIRE1, g_balance_uzi_sustained_refire, weapon_uzi_fire1_02);
	}
	else
		weapon_thinkf(WFRAME_FIRE1, g_balance_uzi_sustained_refire, weapon_ready);
}

void(void) weapon_uzi_reloadandready {
	weapon_clip_reloadandready(g_balance_uzi_magazinecapacity, ammo_nails, uzi_ammoclip,
			g_balance_uzi_first_ammo, g_balance_uzi_sustained_ammo, g_balance_uzi_reloadtime);
}

void(void) weapon_uzi_reload {
	weapon_clip_reload(g_balance_uzi_magazinecapacity, ammo_nails, uzi_ammoclip, g_balance_uzi_first_ammo,
			g_balance_uzi_sustained_ammo, "weapons/campingrifle_reload.wav", g_balance_uzi_reloadtime,
			weapon_uzi_reloadandready);
}

float weapon_uzi(float req)
{
	if (req == WR_AIM)
		if(vlen(self.origin-self.enemy.origin) < 3000 - bound(0, skill, 10) * 200 || !g_balance_uzi_first)
			self.uzi_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
		else
		{
			self.uzi_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
		}
	else if (req == WR_THINK) {
		if (g_balance_uzi_magazinecapacity && (self.uzi_ammoclip < 0 || (!self.uzi_ammoclip && (self.uzi_buttonatck1 || self.uzi_buttonatck2)))) { // forced reload (e.g. because interrupted)
			if(self.switchweapon == self.weapon)
			if(self.weaponentity.state == WS_READY)
				weapon_uzi_reload();
		} else if (!g_balance_uzi_magazinecapacity || self.uzi_ammoclip > 0) {
			if (self.uzi_buttonatck1)
			if (weapon_prepareattack(0, 0))
			{
				self.uzi_bulletcounter = 1;
				weapon_uzi_attack(WEP_UZI); // sets attack_finished
				weapon_thinkf(WFRAME_FIRE1, g_balance_uzi_sustained_refire, weapon_uzi_fire1_02);
			}
			if (self.uzi_buttonatck2)
			if (g_balance_uzi_first)
			if (weapon_prepareattack(1, 0))
			{
				self.uzi_bulletcounter = 1;
				weapon_uzi_attack(WEP_UZI | HITTYPE_SECONDARY); // sets attack_finished
				weapon_thinkf(WFRAME_FIRE2, g_balance_uzi_first_refire, weapon_ready);
			}
		}
		if (g_balance_uzi_magazinecapacity) {
			self.ammoclip = self.uzi_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/uziflash.md3");
		precache_sound ("weapons/uzi_fire.wav");
		precache_sound("weapons/campingrifle_reload.wav");
	} else if (req == WR_CHECKAMMO1)
		return self.ammo_nails >= g_balance_uzi_sustained_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_nails >= g_balance_uzi_first_ammo;
	else if (req == WR_RELOAD) {
		weapon_uzi_reload();
	} else if (req == WR_SETUP) {
		weapon_setup(WEP_UZI);
		if (g_balance_uzi_magazinecapacity) {
			weapon_clip_checkmaxbullets(g_balance_uzi_magazinecapacity, ammo_nails, uzi_ammoclip, g_balance_uzi_first_ammo, g_balance_uzi_sustained_ammo);
			if not(self.uzi_ammoclip)
				self.uzi_ammoclip = -1;
		}
	} else if (req == WR_RESETPLAYER) {
		if (g_balance_uzi_magazinecapacity)
			self.uzi_ammoclip = ((start_items & IT_UNLIMITED_WEAPON_AMMO) ? g_balance_uzi_magazinecapacity : -1);
	} else if (req == WR_KILLMESSAGE) {
		if(weapon_deathtype & HITTYPE_SECONDARY)
			weapon_deathtypestring = "was sniped by";
		else
			weapon_deathtypestring = "was riddled full of holes by";
	} else if (req == WR_SUICIDEMESSAGE)
		weapon_deathtypestring = "did the impossible";
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_uzi_bulletconstant);
		CACHE_CVAR(g_balance_uzi_magazinecapacity);
		CACHE_CVAR(g_balance_uzi_reloadtime);
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
		if (cvar("g_balance_uzi_swap_buttons")) {
			uzi_buttonatck1 = BUTTON_ATCK2;
			uzi_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}

void(void) spawnfunc_weapon_uzi {
	weapon_defaultspawnfunc(WEP_UZI);
}
