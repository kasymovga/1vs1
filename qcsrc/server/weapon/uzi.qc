.float uzi_ammoclip;
float g_balance_uzi_magazinecapacity;
float g_balance_uzi_reloadtime;
float g_balance_uzi_bulletconstant;
float g_balance_uzi_first;
float g_balance_uzi_first_ammo;
float g_balance_uzi_first_damage;
float g_balance_uzi_first_damage_headshot;
float g_balance_uzi_first_force;
float g_balance_uzi_first_gravityfactor;
float g_balance_uzi_first_refire;
float g_balance_uzi_first_spread;
float g_balance_uzi_speed;
float g_balance_uzi_sustained_ammo;
float g_balance_uzi_sustained_damage;
float g_balance_uzi_sustained_damage_headshot;
float g_balance_uzi_sustained_force;
float g_balance_uzi_sustained_gravityfactor;
float g_balance_uzi_sustained_refire;
float g_balance_uzi_sustained_spread;
float g_balance_uzi_recoil;

var .float uzi_buttonatck1 = BUTTON_ATCK;
var .float uzi_buttonatck2 = BUTTON_ATCK2;

void(float deathtype) weapon_uzi_attack {
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
		if (self.bulletcounter == 1)
			self.ammo_nails = self.ammo_nails - g_balance_uzi_first_ammo;
		else
			self.ammo_nails = self.ammo_nails - g_balance_uzi_sustained_ammo;

	}
	if (g_balance_uzi_magazinecapacity)
		self.uzi_ammoclip -= 1;

	bullet_begin(g_balance_uzi_speed, PROJECTILE_BULLET, particleeffectnum("tr_bullet"));
	weapon_setup_shot(self, g_balance_uzi_recoil, "weapons/uzi_fire.wav", 1);
	weapon_shake(1);
	// this attack_finished just enforces a cooldown at the end of a burst
	WEAPON_ATTACK_FINISHED(self) = time + g_balance_uzi_first_refire * weapon_rate_factor();
	if (self.bulletcounter == 1) {
		entity pts = rm_buffs_meodp_hitscan_begin(self);
		bullet(weapon_shotorg, weapon_shotorg_visual, weapon_shotdir, g_balance_uzi_first_spread, g_balance_uzi_speed,
				5, g_balance_uzi_first_damage, g_balance_uzi_first_damage_headshot,
				g_balance_uzi_first_force, EFFECT_IMPACT_BULLET, deathtype, g_balance_uzi_first_gravityfactor, g_balance_uzi_bulletconstant);
		rm_buffs_meodp_hitscan_end(pts);
	} else
		bullet(weapon_shotorg, weapon_shotorg_visual, weapon_shotdir, g_balance_uzi_sustained_spread, g_balance_uzi_speed,
				5, g_balance_uzi_sustained_damage, g_balance_uzi_sustained_damage_headshot,
				g_balance_uzi_sustained_force, EFFECT_IMPACT_BULLET, deathtype, g_balance_uzi_sustained_gravityfactor, g_balance_uzi_bulletconstant);

	bullet_end();
	pointparticles(particleeffectnum("uzi_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	// muzzle flash for 1st person view
	weapon_flash(WEAPON_FLASH_UZI);
	casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 2, self);
}

// weapon frames
void(void) weapon_uzi_fire1_02 {
	if (self.weapon != self.switchweapon || !player_can_fire(self, TRUE) || (g_balance_uzi_magazinecapacity && self.uzi_ammoclip <= 0)) {
		weapon_ready();
		return;
	}
	if (self.uzi_buttonatck1) {
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		if not(self.ammo_nails >= g_balance_uzi_sustained_ammo) {
			weapon_switch_force(self, weapon_best(self));
			weapon_ready();
			return;
		}
		self.bulletcounter += 1;
		weapon_uzi_attack(WEAPON_UZI);
		weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_uzi_sustained_refire, weapon_uzi_fire1_02);
	} else
		weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_uzi_sustained_refire, weapon_ready);
}

void(void) weapon_uzi_reloadandready {
	weapon_clip_reloadandready(ammo_nails, uzi_ammoclip,
			g_balance_uzi_first_ammo, g_balance_uzi_sustained_ammo, g_balance_uzi_reloadtime);
}

void(void) weapon_uzi_reload {
	weapon_clip_reload(ammo_nails, uzi_ammoclip, g_balance_uzi_first_ammo,
			g_balance_uzi_sustained_ammo, "weapons/campingrifle_reload.wav", g_balance_uzi_reloadtime,
			weapon_uzi_reloadandready);
}

float(float req) weapon_uzi {
	if (req == WEAPON_REQUEST_AIM) {
		if (vlen(self.origin-self.enemy.origin) < 3000 - bound(0, skill, 10) * 200 || !g_balance_uzi_first)
			self.uzi_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.uzi_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
	} else if (req == WEAPON_REQUEST_THINK) {
		if (g_balance_uzi_magazinecapacity && (self.uzi_ammoclip < 0 || (!self.uzi_ammoclip && (self.uzi_buttonatck1 || self.uzi_buttonatck2)))) { // forced reload (e.g. because interrupted)
			if (self.switchweapon == self.weapon)
			if (self.weaponentity.state == WEAPON_STATE_READY)
				weapon_uzi_reload();
		} else if (!g_balance_uzi_magazinecapacity || self.uzi_ammoclip > 0) {
			if (self.uzi_buttonatck1)
			if (weapon_prepareattack(0, 0)) {
				self.bulletcounter = 1;
				weapon_uzi_attack(WEAPON_UZI); // sets attack_finished
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_uzi_sustained_refire, weapon_uzi_fire1_02);
			}
			if (self.uzi_buttonatck2)
			if (g_balance_uzi_first)
			if (weapon_prepareattack(1, 0)) {
				self.bulletcounter = 1;
				weapon_uzi_attack(WEAPON_UZI | HITTYPE_SECONDARY); // sets attack_finished
				weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_uzi_first_refire, weapon_ready);
			}
		}
		if (g_balance_uzi_magazinecapacity) {
			self.ammoclip = self.uzi_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		weapon_flash_precache(WEAPON_FLASH_UZI);
		precache_sound("weapons/uzi_fire.wav");
		precache_sound("weapons/campingrifle_reload.wav");
	} else if (req == WEAPON_REQUEST_RELOAD) {
		weapon_uzi_reload();
	} else if (req == WEAPON_REQUEST_SETUP) {
		weapon_clip_setup(g_balance_uzi_magazinecapacity, ammo_nails, uzi_ammoclip, g_balance_uzi_first_ammo, g_balance_uzi_sustained_ammo);
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		weapon_clip_reset(g_balance_uzi_magazinecapacity, uzi_ammoclip);
	} else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		if (weapon_deathtype & HITTYPE_SECONDARY)
			weapon_deathtypestring = "was sniped by";
		else
			weapon_deathtypestring = "was riddled full of holes by";
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "did the impossible";
	else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_uzi_bulletconstant);
		CVAR_CACHE(g_balance_uzi_magazinecapacity);
		CVAR_CACHE(g_balance_uzi_reloadtime);
		CVAR_CACHE(g_balance_uzi_first);
		CVAR_CACHE(g_balance_uzi_first_ammo);
		CVAR_CACHE(g_balance_uzi_first_damage);
		CVAR_CACHE(g_balance_uzi_first_damage_headshot);
		CVAR_CACHE(g_balance_uzi_first_force);
		CVAR_CACHE(g_balance_uzi_first_gravityfactor);
		CVAR_CACHE(g_balance_uzi_first_refire);
		CVAR_CACHE(g_balance_uzi_first_spread);
		CVAR_CACHE(g_balance_uzi_recoil);
		CVAR_CACHE(g_balance_uzi_speed);
		CVAR_CACHE(g_balance_uzi_sustained_ammo);
		CVAR_CACHE(g_balance_uzi_sustained_damage);
		CVAR_CACHE(g_balance_uzi_sustained_damage_headshot);
		CVAR_CACHE(g_balance_uzi_sustained_force);
		CVAR_CACHE(g_balance_uzi_sustained_gravityfactor);
		CVAR_CACHE(g_balance_uzi_sustained_refire);
		CVAR_CACHE(g_balance_uzi_sustained_spread);
		if (cvar("g_balance_uzi_swap_buttons")) {
			uzi_buttonatck1 = BUTTON_ATCK2;
			uzi_buttonatck2 = BUTTON_ATCK;
		}
		weapon_ammo_limits(WEAPON_UZI, g_balance_uzi_sustained_ammo, g_balance_uzi_first_ammo);
	}
	return TRUE;
}

void(void) spawnfunc_weapon_uzi {
	weapon_defaultspawnfunc(WEAPON_UZI);
}
