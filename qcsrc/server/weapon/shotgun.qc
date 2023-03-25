float g_balance_shotgun_magazinecapacity;
float g_balance_shotgun_reloadtime;
float g_balance_shotgun_reloadtime_shell;
float g_balance_shotgun_primary_ammo;
float g_balance_shotgun_primary_animtime;
float g_balance_shotgun_primary_bulletconstant;
float g_balance_shotgun_primary_bullets;
float g_balance_shotgun_primary_damage;
float g_balance_shotgun_primary_damage_headshot;
float g_balance_shotgun_primary_force;
float g_balance_shotgun_primary_gravityfactor;
float g_balance_shotgun_primary_refire;
float g_balance_shotgun_primary_speed;
float g_balance_shotgun_primary_spread;
float g_balance_shotgun_recoil;
float g_balance_shotgun_secondary;
float g_balance_shotgun_secondary_ammo;
float g_balance_shotgun_secondary_animtime;
float g_balance_shotgun_secondary_bulletconstant;
float g_balance_shotgun_secondary_bullets;
float g_balance_shotgun_secondary_damage;
float g_balance_shotgun_secondary_damage_headshot;
float g_balance_shotgun_secondary_force;
float g_balance_shotgun_secondary_gravityfactor;
float g_balance_shotgun_secondary_refire;
float g_balance_shotgun_secondary_speed;
float g_balance_shotgun_secondary_spread;
var .float sg_buttonatck1 = BUTTON_ATCK;
var .float sg_buttonatck2 = BUTTON_ATCK2;
.float sg_ammoclip;

void(void) weapon_shotgun_attack {
	float sc;
	if (g_balance_shotgun_magazinecapacity) {
		if (self.sg_ammoclip < 1) {
			weapon_ready();
			return;
		}
		self.sg_ammoclip -= 1;
	}
	bullet_begin(g_balance_shotgun_primary_speed);
	weapon_setup_shot(self, g_balance_shotgun_recoil, "weapons/shotgun_fire.wav", g_balance_shotgun_primary_bullets);
	for (sc = 0;sc < g_balance_shotgun_primary_bullets;sc = sc + 1)
		bullet(weapon_shotorg, weapon_shotdir, g_balance_shotgun_primary_spread, g_balance_shotgun_primary_speed, 5,
				g_balance_shotgun_primary_damage, g_balance_shotgun_primary_damage_headshot, g_balance_shotgun_primary_force,
				EFFECT_IMPACT_PELLET, WEAPON_SHOTGUN, particleeffectnum("tr_bullet"), g_balance_shotgun_primary_gravityfactor, g_balance_shotgun_primary_bulletconstant);

	bullet_end();
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - g_balance_shotgun_primary_ammo;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, g_balance_shotgun_primary_ammo);
	// casing code
	casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);
	weapon_flash(WEAPON_FLASH_SHOTGUN);
}

void(void) weapon_shotgun_attack2 {
	float sc;
	if (g_balance_shotgun_magazinecapacity) {
		if (self.sg_ammoclip < 1) {
			weapon_ready();
			return;
		}
		self.sg_ammoclip -= 1;
	}
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
		if (self.ammo_shells < g_balance_shotgun_secondary_ammo) {
			weapon_ready();
			return;
		}
		self.ammo_shells = self.ammo_shells - g_balance_shotgun_secondary_ammo;
	}
	bullet_begin(g_balance_shotgun_secondary_speed);
	weapon_setup_shot (self, g_balance_shotgun_recoil, "weapons/shotgun_fire.wav", g_balance_shotgun_secondary_bullets);
	for (sc = 0; sc < g_balance_shotgun_secondary_bullets; sc = sc + 1)
		bullet(weapon_shotorg, weapon_shotdir, g_balance_shotgun_secondary_spread, g_balance_shotgun_secondary_speed, 5,
				g_balance_shotgun_secondary_damage, g_balance_shotgun_secondary_damage_headshot, g_balance_shotgun_secondary_force,
				EFFECT_IMPACT_PELLET, WEAPON_SHOTGUN | HITTYPE_SECONDARY, particleeffectnum("tr_bullet"), g_balance_shotgun_secondary_gravityfactor,
				g_balance_shotgun_secondary_bulletconstant);

	bullet_end();
	pointparticles(particleeffectnum("shotgun_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, g_balance_shotgun_secondary_ammo);
	// casing code
	casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);
	weapon_flash(WEAPON_FLASH_SHOTGUN);
}

// weapon frames
void(void) weapon_shotgun_fire2_03 {
	weapon_shotgun_attack2();
	weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_shotgun_secondary_animtime, weapon_ready);
}

void(void) weapon_shotgun_fire2_02 {
	weapon_shotgun_attack2();
	weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_shotgun_secondary_animtime, weapon_shotgun_fire2_03);
}

void(void) weapon_shotgun_reloadandready {
	if not(g_balance_shotgun_reloadtime_shell) {
		weapon_clip_reloadandready(g_balance_shotgun_magazinecapacity, ammo_shells, sg_ammoclip,
				g_balance_shotgun_primary_ammo, g_balance_shotgun_secondary_ammo, g_balance_shotgun_reloadtime);
		return;
	}
	float t;
	float tshells = min(g_balance_shotgun_magazinecapacity, max(1, self.sg_ammoclip + 1));
	self.sg_ammoclip = tshells;
	if (weapon_clip_checkmaxbullets(g_balance_shotgun_magazinecapacity, ammo_shells, sg_ammoclip, g_balance_shotgun_primary_ammo, g_balance_shotgun_secondary_ammo) || self.sg_buttonatck1 || self.sg_buttonatck2) {
		t = WEAPON_ATTACK_FINISHED(self) - g_balance_shotgun_reloadtime - 1;
		WEAPON_ATTACK_FINISHED(self) = t;
		weapon_ready();
	} else {
		weapon_thinkf(WEAPON_FRAME_RELOAD, g_balance_shotgun_reloadtime_shell, weapon_shotgun_reloadandready);
	}

}

void(void) weapon_shotgun_reload {
	float clipsave = self.sg_ammoclip;
	weapon_clip_reload(g_balance_shotgun_magazinecapacity, ammo_shells, sg_ammoclip, g_balance_shotgun_primary_ammo,
			g_balance_shotgun_secondary_ammo, "weapons/campingrifle_reload.wav", g_balance_shotgun_reloadtime,
			weapon_shotgun_reloadandready);
	if (g_balance_shotgun_reloadtime_shell)
		self.sg_ammoclip = clipsave; //shotgun not have ammo drop on reload in case of per shell reloading
}

float(float req) weapon_shotgun {
	if (req == WEAPON_REQUEST_AIM) {
		if(vlen(self.origin-self.enemy.origin)>200 || !g_balance_shotgun_secondary)
			self.sg_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.sg_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
	} else if (req == WEAPON_REQUEST_THINK) {
		if (g_balance_shotgun_magazinecapacity && (self.sg_ammoclip < 0 || (!self.sg_ammoclip && (self.sg_buttonatck1 || self.sg_buttonatck2)))) { // forced reload (e.g. because interrupted)
			if (self.switchweapon == self.weapon)
			if (self.weaponentity.state == WEAPON_STATE_READY)
				weapon_shotgun_reload();
		} else if (!g_balance_shotgun_magazinecapacity || self.sg_ammoclip > 0) {
			if (self.sg_buttonatck1)
			if (weapon_prepareattack(0, g_balance_shotgun_primary_refire)) {
				weapon_shotgun_attack();
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_shotgun_primary_animtime, weapon_ready);
			}
			if (self.sg_buttonatck2)
			if (g_balance_shotgun_secondary)
			if (weapon_prepareattack(1, g_balance_shotgun_secondary_refire)) {
				weapon_shotgun_attack2();
				weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_shotgun_secondary_animtime, weapon_shotgun_fire2_02);
			}
		}
		if (g_balance_shotgun_magazinecapacity) {
			self.ammoclip = self.sg_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		weapon_flash_precache(WEAPON_FLASH_SHOTGUN);
		precache_sound("misc/itempickup.wav");
		precache_sound("weapons/shotgun_fire.wav");
		precache_sound("weapons/campingrifle_reload.wav");
	} else if (req == WEAPON_REQUEST_CHECKAMMO1) {
		return self.ammo_shells >= g_balance_shotgun_primary_ammo;
	} else if (req == WEAPON_REQUEST_CHECKAMMO2) {
		return self.ammo_shells >= g_balance_shotgun_secondary_ammo;
	} else if (req == WEAPON_REQUEST_RELOAD) {
		weapon_shotgun_reload();
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE) {
		weapon_deathtypestring = "did the impossible";
	} else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_deathtypestring = "was gunned by"; // unchecked: SECONDARY
	} else if (req == WEAPON_REQUEST_SETUP) {
		//weapon_setup(WEAPON_SHOTGUN);
		if (g_balance_shotgun_magazinecapacity) {
			weapon_clip_checkmaxbullets(g_balance_shotgun_magazinecapacity, ammo_shells, sg_ammoclip, g_balance_shotgun_primary_ammo, g_balance_shotgun_secondary_ammo);
			if not(self.sg_ammoclip)
				self.sg_ammoclip = -1;
		}
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		if (g_balance_shotgun_magazinecapacity)
			self.sg_ammoclip = g_balance_shotgun_magazinecapacity;
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_shotgun_magazinecapacity);
		CVAR_CACHE(g_balance_shotgun_reloadtime);
		CVAR_CACHE(g_balance_shotgun_reloadtime_shell);
		CVAR_CACHE(g_balance_shotgun_primary_ammo);
		CVAR_CACHE(g_balance_shotgun_primary_animtime);
		CVAR_CACHE(g_balance_shotgun_primary_bulletconstant);
		CVAR_CACHE(g_balance_shotgun_primary_bullets);
		CVAR_CACHE(g_balance_shotgun_primary_damage);
		CVAR_CACHE(g_balance_shotgun_primary_damage_headshot);
		CVAR_CACHE(g_balance_shotgun_primary_force);
		CVAR_CACHE(g_balance_shotgun_primary_gravityfactor);
		CVAR_CACHE(g_balance_shotgun_primary_refire);
		CVAR_CACHE(g_balance_shotgun_primary_speed);
		CVAR_CACHE(g_balance_shotgun_primary_spread);
		CVAR_CACHE(g_balance_shotgun_recoil);
		CVAR_CACHE(g_balance_shotgun_secondary);
		CVAR_CACHE(g_balance_shotgun_secondary_ammo);
		CVAR_CACHE(g_balance_shotgun_secondary_animtime);
		CVAR_CACHE(g_balance_shotgun_secondary_bulletconstant);
		CVAR_CACHE(g_balance_shotgun_secondary_bullets);
		CVAR_CACHE(g_balance_shotgun_secondary_damage);
		CVAR_CACHE(g_balance_shotgun_secondary_damage_headshot);
		CVAR_CACHE(g_balance_shotgun_secondary_force);
		CVAR_CACHE(g_balance_shotgun_secondary_gravityfactor);
		CVAR_CACHE(g_balance_shotgun_secondary_refire);
		CVAR_CACHE(g_balance_shotgun_secondary_speed);
		CVAR_CACHE(g_balance_shotgun_secondary_spread);
		if (cvar("g_balance_shotgun_swap_buttons")) {
			sg_buttonatck1 = BUTTON_ATCK2;
			sg_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}

void(void) spawnfunc_weapon_shotgun {
	weapon_defaultspawnfunc(WEAPON_SHOTGUN);
}
