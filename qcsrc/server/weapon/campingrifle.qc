//Camping rifle Primary mode: manually operated bolt*, Secondary: full automatic**
//* Manually operating the bolt means that all the power of the gas is used to propell the bullet. In this mode the bolt is prevented from moving backwards in response to the firing of the bullet.
//** In fully automatic mode some of the gas is used to extract and reload the next cartrige, thus there is less power and range.

float g_balance_campingrifle_auto_reload_after_changing_weapons;
float g_balance_campingrifle_bursttime;
float g_balance_campingrifle_magazinecapacity;
float g_balance_campingrifle_primary_ammo;
float g_balance_campingrifle_primary_animtime;
float g_balance_campingrifle_primary_bulletconstant;
float g_balance_campingrifle_primary_burstcost;
float g_balance_campingrifle_primary_damage;
float g_balance_campingrifle_primary_force;
float g_balance_campingrifle_primary_gravityfactor;
float g_balance_campingrifle_primary_headshotaddeddamage;
float g_balance_campingrifle_primary_lifetime;
float g_balance_campingrifle_primary_recoil;
float g_balance_campingrifle_primary_refire;
float g_balance_campingrifle_primary_speed;
float g_balance_campingrifle_primary_spread;
float g_balance_campingrifle_secondary_ammo;
float g_balance_campingrifle_secondary_animtime;
float g_balance_campingrifle_secondary_bulletconstant;
float g_balance_campingrifle_secondary_burstcost;
float g_balance_campingrifle_secondary_damage;
float g_balance_campingrifle_secondary_force;
float g_balance_campingrifle_secondary_gravityfactor;
float g_balance_campingrifle_secondary_headshotaddeddamage;
float g_balance_campingrifle_secondary_lifetime;
float g_balance_campingrifle_secondary_recoil;
float g_balance_campingrifle_secondary_refire;
float g_balance_campingrifle_secondary_speed;
float g_balance_campingrifle_secondary_spread;
float g_balance_campingrifle_hotreload;

.float campingrifle_ammoclip;
var .float cr_buttonatck1 = BUTTON_ATCK;
var .float cr_buttonatck2 = BUTTON_ATCK2;
.float campingrifle_accumulator;
.float campingrifle_hotreloadtime;

float(void) weapon_campingrifle_checkmaxbullets {
	return weapon_clip_checkmaxbullets(g_balance_campingrifle_magazinecapacity, ammo_nails, campingrifle_ammoclip, g_balance_campingrifle_primary_ammo, g_balance_campingrifle_secondary_ammo);
}

void(void) weapon_campingrifle_hotreload {
	if (time < self.campingrifle_hotreloadtime)
		return;

	if (self.campingrifle_ammoclip >= g_balance_campingrifle_magazinecapacity)
		return;

	if (self.weaponentity.state != WEAPON_STATE_READY)
		return;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (self.ammo_nails < min(g_balance_campingrifle_primary_ammo, g_balance_campingrifle_secondary_ammo) * (self.campingrifle_ammoclip + 1))
		return;

	self.campingrifle_ammoclip++;
	self.campingrifle_hotreloadtime += g_balance_campingrifle_reloadtime;
}

void(void) weapon_campingrifle_reloadandready {
	weapon_clip_reloadandready(g_balance_campingrifle_magazinecapacity, ammo_nails, campingrifle_ammoclip,
			g_balance_campingrifle_primary_ammo, g_balance_campingrifle_secondary_ammo, g_balance_campingrifle_reloadtime);
}

void(void) weapon_campingrifle_reload {
	weapon_clip_reload(g_balance_campingrifle_magazinecapacity, ammo_nails, campingrifle_ammoclip, g_balance_campingrifle_primary_ammo,
			g_balance_campingrifle_secondary_ammo, "weapons/campingrifle_reload.wav", g_balance_campingrifle_reloadtime,
			weapon_campingrifle_reloadandready);
}

void(void) weapon_campingrifle_checkreloadandready {
	weapon_ready();
	if (g_balance_campingrifle_hotreload) {
		self.campingrifle_hotreloadtime = time + g_balance_campingrifle_reloadtime;
		return;
	}
	if (self.campingrifle_ammoclip <= 0)
		weapon_campingrifle_reload();
	else
		weapon_ready();
}

void(float pSpread, float pDamage, float pHeadshotAddedDamage, float pForce, float pSpeed, float pLifetime, float pAmmo, float deathtype, float pBulletConstant) weapon_campingrifle_fire {
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_nails -= pAmmo;

	bullet_begin(pSpeed);
	if (deathtype & HITTYPE_SECONDARY)
		weapon_setup_shot (self, g_balance_campingrifle_secondary_recoil, "weapons/campingrifle_fire2.wav", 1);
	else
		weapon_setup_shot (self, g_balance_campingrifle_primary_recoil, "weapons/campingrifle_fire.wav", 1);

	pointparticles(particleeffectnum("shotgun_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 2000, 1);
	if (self.BUTTON_ZOOM) { // if zoomed, shoot from the eye
		weapon_shotdir = v_forward;
		weapon_shotorg = self.origin + self.view_ofs + ((weapon_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;
	}
	bullet(weapon_shotorg, weapon_shotdir, pSpread, pSpeed, pLifetime, pDamage, pHeadshotAddedDamage / pDamage, pForce, EFFECT_IMPACT_BULLET, deathtype, particleeffectnum("tr_rifle"), ((deathtype & HITTYPE_SECONDARY) ? g_balance_campingrifle_primary_gravityfactor : g_balance_campingrifle_primary_gravityfactor), pBulletConstant);
	bullet_end();
	casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 2, self);
	self.campingrifle_ammoclip = self.campingrifle_ammoclip - 1;
	weapon_campingrifle_checkmaxbullets();
}

void(void) weapon_campingrifle_attack {
	weapon_campingrifle_fire(g_balance_campingrifle_primary_spread, g_balance_campingrifle_primary_damage, g_balance_campingrifle_primary_headshotaddeddamage, g_balance_campingrifle_primary_force, g_balance_campingrifle_primary_speed, g_balance_campingrifle_primary_lifetime, g_balance_campingrifle_primary_ammo, WEP_CAMPINGRIFLE, g_balance_campingrifle_primary_bulletconstant);
}

void(void) weapon_campingrifle_attack2 {
	weapon_campingrifle_fire(g_balance_campingrifle_secondary_spread, g_balance_campingrifle_secondary_damage, g_balance_campingrifle_secondary_headshotaddeddamage, g_balance_campingrifle_secondary_force, g_balance_campingrifle_secondary_speed, g_balance_campingrifle_secondary_lifetime, g_balance_campingrifle_secondary_ammo, WEP_CAMPINGRIFLE | HITTYPE_SECONDARY, g_balance_campingrifle_secondary_bulletconstant);
}

void(void) spawnfunc_weapon_campingrifle {
	weapon_defaultspawnfunc(WEP_CAMPINGRIFLE);
}

.float bot_secondary_campingriflemooth;
float(float req) weapon_campingrifle {
	float full;
	if (req == WEAPON_REQUEST_AIM) {
		self.cr_buttonatck1=FALSE;
		self.cr_buttonatck2=FALSE;
		if (vlen(self.origin-self.enemy.origin) > 1000)
			self.bot_secondary_campingriflemooth = 0;

		if (self.bot_secondary_campingriflemooth == 0) {
			if (bot_aim(g_balance_campingrifle_primary_speed, 0, g_balance_campingrifle_primary_lifetime, TRUE)) {
				self.cr_buttonatck1 = TRUE;
				if (random() < 0.01) self.bot_secondary_campingriflemooth = 1;
			}
		} else {
			if (bot_aim(g_balance_campingrifle_secondary_speed, 0, g_balance_campingrifle_secondary_lifetime, TRUE)) {
				self.cr_buttonatck2 = TRUE;
				if (random() < 0.03) self.bot_secondary_campingriflemooth = 0;
			}
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.campingrifle_ammoclip < 0 || (!self.campingrifle_ammoclip && (self.cr_buttonatck1 || self.cr_buttonatck2))) { // forced reload (e.g. because interrupted)
			if not(g_balance_campingrifle_hotreload)
			if (self.switchweapon == self.weapon)
			if (self.weaponentity.state == WEAPON_STATE_READY)
				weapon_campingrifle_reload();
		} else if (self.campingrifle_ammoclip > 0) {
			self.campingrifle_accumulator = bound(time - g_balance_campingrifle_bursttime, self.campingrifle_accumulator, time);
			if (self.cr_buttonatck1)
			if (time >= self.campingrifle_accumulator + g_balance_campingrifle_primary_burstcost)
			if (weapon_prepareattack(0, g_balance_campingrifle_primary_refire)) {
				weapon_campingrifle_attack();
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_campingrifle_primary_animtime, weapon_campingrifle_checkreloadandready);
				self.campingrifle_accumulator += g_balance_campingrifle_primary_burstcost;
			}
			if (self.cr_buttonatck2)
			if (time >= self.campingrifle_accumulator + g_balance_campingrifle_secondary_burstcost)
			if (weapon_prepareattack(1, g_balance_campingrifle_secondary_refire)) {
				weapon_campingrifle_attack2();
				weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_campingrifle_secondary_animtime, weapon_campingrifle_checkreloadandready);
				self.campingrifle_accumulator += g_balance_campingrifle_secondary_burstcost;
			}
		}
		if (g_balance_campingrifle_hotreload)
			weapon_campingrifle_hotreload();
		else {
			self.ammoclip = self.campingrifle_ammoclip;
			if (self.ammoclip <= 0)
				self.ammoclip = 0;
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_sound("weapons/campingrifle_reload.wav");
		precache_sound("weapons/campingrifle_fire.wav");
		precache_sound("weapons/campingrifle_fire2.wav");
	} else if (req == WEAPON_REQUEST_SETUP) {
		//weapon_setup(WEP_CAMPINGRIFLE);
		full = weapon_campingrifle_checkmaxbullets();
		if (g_balance_campingrifle_auto_reload_after_changing_weapons)
			if (!full)
				self.campingrifle_ammoclip = -1;

		if not(self.campingrifle_ammoclip)
			self.campingrifle_ammoclip = -1;

		self.campingrifle_hotreloadtime = time + g_balance_campingrifle_reloadtime;
	} else if (req == WEAPON_REQUEST_CHECKAMMO1)
		return self.ammo_nails >= g_balance_campingrifle_primary_ammo;
	else if (req == WEAPON_REQUEST_CHECKAMMO2)
		return self.ammo_nails >= g_balance_campingrifle_secondary_ammo;
	else if (req == WEAPON_REQUEST_SUICIDEMESSAGE) {
		if (weapon_deathtype & HITTYPE_SECONDARY)
			weapon_deathtypestring = "shot himself automatically";
		else
			weapon_deathtypestring = "sniped himself somehow";
	} else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		if (weapon_deathtype & HITTYPE_SECONDARY) {
			if (weapon_deathtype & HITTYPE_BOUNCE)
				weapon_deathtypestring = "failed to hide from #'s bullet hail";
			else
				weapon_deathtypestring = "died in #'s bullet hail";
		} else {
			if (weapon_deathtype & HITTYPE_BOUNCE) {
				// TODO special headshot message here too?
				weapon_deathtypestring = "failed to hide from #'s rifle";
			} else {
				if (weapon_deathtype & HITTYPE_HEADSHOT)
					weapon_deathtypestring = "got hit in the head by #";
				else
					weapon_deathtypestring = "was sniped by #";
			}
		}
	} else if (req == WEAPON_REQUEST_RELOAD) {
		if not(g_balance_campingrifle_hotreload)
			weapon_campingrifle_reload();
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		self.campingrifle_accumulator = time - g_balance_campingrifle_bursttime;
		self.campingrifle_ammoclip = g_balance_campingrifle_magazinecapacity;
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_campingrifle_auto_reload_after_changing_weapons);
		CVAR_CACHE(g_balance_campingrifle_bursttime);
		CVAR_CACHE(g_balance_campingrifle_magazinecapacity);
		if (g_balance_campingrifle_magazinecapacity < 0)
			g_balance_campingrifle_magazinecapacity = 8;

		CVAR_CACHE(g_balance_campingrifle_primary_ammo);
		CVAR_CACHE(g_balance_campingrifle_primary_animtime);
		CVAR_CACHE(g_balance_campingrifle_primary_bulletconstant);
		CVAR_CACHE(g_balance_campingrifle_primary_burstcost);
		CVAR_CACHE(g_balance_campingrifle_primary_damage);
		CVAR_CACHE(g_balance_campingrifle_primary_force);
		CVAR_CACHE(g_balance_campingrifle_primary_gravityfactor);
		CVAR_CACHE(g_balance_campingrifle_primary_headshotaddeddamage);
		CVAR_CACHE(g_balance_campingrifle_primary_lifetime);
		CVAR_CACHE(g_balance_campingrifle_primary_recoil);
		CVAR_CACHE(g_balance_campingrifle_primary_refire);
		CVAR_CACHE(g_balance_campingrifle_primary_speed);
		CVAR_CACHE(g_balance_campingrifle_primary_spread);
		CVAR_CACHE(g_balance_campingrifle_reloadtime);
		CVAR_CACHE(g_balance_campingrifle_secondary_ammo);
		CVAR_CACHE(g_balance_campingrifle_secondary_animtime);
		CVAR_CACHE(g_balance_campingrifle_secondary_bulletconstant);
		CVAR_CACHE(g_balance_campingrifle_secondary_burstcost);
		CVAR_CACHE(g_balance_campingrifle_secondary_damage);
		CVAR_CACHE(g_balance_campingrifle_secondary_force);
		CVAR_CACHE(g_balance_campingrifle_secondary_gravityfactor);
		CVAR_CACHE(g_balance_campingrifle_secondary_headshotaddeddamage);
		CVAR_CACHE(g_balance_campingrifle_secondary_lifetime);
		CVAR_CACHE(g_balance_campingrifle_secondary_recoil);
		CVAR_CACHE(g_balance_campingrifle_secondary_refire);
		CVAR_CACHE(g_balance_campingrifle_secondary_speed);
		CVAR_CACHE(g_balance_campingrifle_secondary_spread);
		CVAR_CACHE(g_balance_campingrifle_hotreload);
		if (cvar("g_balance_campingrifle_swap_buttons")) {
			cr_buttonatck1 = BUTTON_ATCK2;
			cr_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}
