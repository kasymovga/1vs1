float g_balance_hlac_primary_ammo;
float g_balance_hlac_primary_animtime;
float g_balance_hlac_primary_damage;
float g_balance_hlac_primary_edgedamage;
float g_balance_hlac_primary_force;
float g_balance_hlac_primary_lifetime;
float g_balance_hlac_primary_premove;
float g_balance_hlac_primary_radius;
float g_balance_hlac_primary_recoil;
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
float g_balance_hlac_secondary_recoil;
float g_balance_hlac_secondary_refire;
float g_balance_hlac_secondary_shots;
float g_balance_hlac_secondary_speed;
float g_balance_hlac_secondary_spread;
float g_balance_hlac_secondary_spread_crouchmod;
float g_balance_hlac_magazinecapacity;
float g_balance_hlac_reloadtime;

var .float hlac_buttonatck1 = BUTTON_ATCK;
var .float hlac_buttonatck2 = BUTTON_ATCK2;

.float hlac_ammoclip;

void(void) weapon_hlac_attack {
	entity missile;
	float spread;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
		self.ammo_cells = self.ammo_cells - g_balance_hlac_primary_ammo;
	}
	spread = g_balance_hlac_primary_spread_min + (g_balance_hlac_primary_spread_add * self.bulletcounter);
	spread = min(spread,g_balance_hlac_primary_spread_max);
	if (self.crouch)
	if (self.flags & FL_ONGROUND_OR_SLICK)
		spread = spread * g_balance_hlac_primary_spread_crouchmod;

	weapon_setup_shot (self, g_balance_hlac_primary_recoil, "weapons/lasergun_fire.wav", 1);
	weapon_shake(1);
	pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	missile = projectile(TRUE, PROJECTILE_HLAC, TRUE, self);
	projectile_setup(missile, weapon_shotorg, EFFECT_IMPACT_LASER, WEAPON_HLAC, g_balance_hlac_primary_damage,
			g_balance_hlac_primary_edgedamage, g_balance_hlac_primary_radius, g_balance_hlac_primary_force, 0, MOVETYPE_FLY);
	missile.velocity = (weapon_shotdir + randomvec() * spread) * g_balance_hlac_primary_speed;
	weapon_setup_projectile_velocity(missile);
	missile.touch = projectile_touch_explode;
	missile.think = stdproc_remove;
	missile.nextthink = time + g_balance_hlac_primary_lifetime;
	if (g_balance_hlac_primary_premove) projectile_premove(missile, g_balance_hlac_primary_premove);
}

void(void) weapon_hlac_attack2f {
	entity missile;
	float spread;
	spread = g_balance_hlac_secondary_spread;
	if (self.crouch)
	if (self.flags & FL_ONGROUND_OR_SLICK)
		spread = spread * g_balance_hlac_secondary_spread_crouchmod;

	missile = projectile(TRUE, PROJECTILE_HLAC, TRUE, self);
	projectile_setup(missile, weapon_shotorg, EFFECT_IMPACT_LASER, WEAPON_HLAC | HITTYPE_SECONDARY, g_balance_hlac_secondary_damage,
			g_balance_hlac_secondary_edgedamage, g_balance_hlac_secondary_radius, g_balance_hlac_secondary_force, 0, MOVETYPE_FLY);
	missile.velocity = (weapon_shotdir + randomvec() * spread) * g_balance_hlac_secondary_speed;
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
	float n;
	if (g_balance_hlac_magazinecapacity) {
		n = min(g_balance_hlac_secondary_shots, self.hlac_ammoclip);
		self.hlac_ammoclip -= n;
	} else
		n = g_balance_hlac_secondary_shots;

	weapon_setup_shot(self, g_balance_hlac_secondary_recoil, "weapons/lasergun_fire.wav", n);
	weapon_shake(1);
	pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	for (i = n; i > 0; --i)
		weapon_hlac_attack2f();
}

// weapon frames
void(void) weapon_hlack_fire1_02 {
	if (self.weapon != self.switchweapon || !player_can_fire(self, TRUE)) {
		weapon_ready();
		return;
	}
	if (g_balance_hlac_magazinecapacity) {
		if (self.hlac_ammoclip <= 0) {
			weapon_ready();
			return;
		}
		self.hlac_ammoclip -= 1;
	}
	if (self.hlac_buttonatck1) {
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		if (self.ammo_cells < g_balance_hlac_primary_ammo) {
			weapon_switch_force(self, weapon_best(self));
			weapon_ready();
			return;
		}
		WEAPON_ATTACK_FINISHED(self) = time + g_balance_hlac_primary_refire * weapon_rate_factor();
		weapon_hlac_attack();
		self.bulletcounter += 1;
		weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_hlac_primary_refire, weapon_hlack_fire1_02);
	} else {
		weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_hlac_primary_animtime, weapon_ready);
	}
}

void(void) spawnfunc_weapon_hlac {
	weapon_defaultspawnfunc(WEAPON_HLAC);
}

void(void) weapon_hlac_reloadandready {
	weapon_clip_reloadandready(ammo_cells, hlac_ammoclip,
			g_balance_hlac_primary_ammo, g_balance_hlac_secondary_ammo, g_balance_hlac_reloadtime);
}

void(void) weapon_hlac_reload {
	weapon_clip_reload(ammo_cells, hlac_ammoclip, g_balance_hlac_primary_ammo,
			g_balance_hlac_secondary_ammo, "weapons/campingrifle_reload.wav", g_balance_hlac_reloadtime,
			weapon_hlac_reloadandready);
}

float(float req) weapon_hlac {
	if (req == WEAPON_REQUEST_AIM)
		self.hlac_buttonatck1 = bot_aim(g_balance_hlac_primary_speed, 0, g_balance_hlac_primary_lifetime, FALSE);
	else if (req == WEAPON_REQUEST_THINK) {
		if (g_balance_hlac_magazinecapacity && (self.hlac_ammoclip < 0 || (!self.hlac_ammoclip && (self.hlac_buttonatck1 || self.hlac_buttonatck2)))) { // forced reload (e.g. because interrupted)
			if (self.switchweapon == self.weapon)
			if (self.weaponentity.state == WEAPON_STATE_READY)
				weapon_hlac_reload();
		} else if (!g_balance_hlac_magazinecapacity || self.hlac_ammoclip > 0) {
			if (self.hlac_buttonatck1)
			if (weapon_prepareattack(0, g_balance_hlac_primary_refire)) {
				self.bulletcounter = 0;
				weapon_hlac_attack();
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_hlac_primary_refire, weapon_hlack_fire1_02);
			}
			if (self.hlac_buttonatck2)
			if (g_balance_hlac_secondary)
			if (weapon_prepareattack(1, g_balance_hlac_secondary_refire)) {
				weapon_hlac_attack2();
				weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_hlac_secondary_animtime, weapon_ready);
			}
		}
		if (g_balance_hlac_magazinecapacity) {
			self.ammoclip = self.hlac_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_sound("weapons/lasergun_fire.wav");
	} else if (req == WEAPON_REQUEST_RELOAD) {
		weapon_hlac_reload();
	} else if (req == WEAPON_REQUEST_SETUP) {
		weapon_clip_setup(g_balance_hlac_magazinecapacity, ammo_cells, hlac_ammoclip, g_balance_hlac_primary_ammo, g_balance_hlac_secondary_ammo);
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		weapon_clip_reset(g_balance_hlac_magazinecapacity, hlac_ammoclip);
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "should have used a smaller gun";
	else if (req == WEAPON_REQUEST_KILLMESSAGE)
		weapon_deathtypestring = "was cut down by";
	else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_hlac_primary_ammo);
		CVAR_CACHE(g_balance_hlac_primary_animtime);
		CVAR_CACHE(g_balance_hlac_primary_damage);
		CVAR_CACHE(g_balance_hlac_primary_edgedamage);
		CVAR_CACHE(g_balance_hlac_primary_force);
		CVAR_CACHE(g_balance_hlac_primary_lifetime);
		CVAR_CACHE(g_balance_hlac_primary_premove);
		CVAR_CACHE(g_balance_hlac_primary_radius);
		CVAR_CACHE(g_balance_hlac_primary_recoil);
		CVAR_CACHE(g_balance_hlac_primary_refire);
		CVAR_CACHE(g_balance_hlac_primary_speed);
		CVAR_CACHE(g_balance_hlac_primary_spread_add);
		CVAR_CACHE(g_balance_hlac_primary_spread_crouchmod);
		CVAR_CACHE(g_balance_hlac_primary_spread_max);
		CVAR_CACHE(g_balance_hlac_primary_spread_min);
		CVAR_CACHE(g_balance_hlac_secondary);
		CVAR_CACHE(g_balance_hlac_secondary_ammo);
		CVAR_CACHE(g_balance_hlac_secondary_animtime);
		CVAR_CACHE(g_balance_hlac_secondary_damage);
		CVAR_CACHE(g_balance_hlac_secondary_edgedamage);
		CVAR_CACHE(g_balance_hlac_secondary_force);
		CVAR_CACHE(g_balance_hlac_secondary_lifetime);
		CVAR_CACHE(g_balance_hlac_secondary_radius);
		CVAR_CACHE(g_balance_hlac_secondary_recoil);
		CVAR_CACHE(g_balance_hlac_secondary_refire);
		CVAR_CACHE(g_balance_hlac_secondary_shots);
		CVAR_CACHE(g_balance_hlac_secondary_speed);
		CVAR_CACHE(g_balance_hlac_secondary_spread);
		CVAR_CACHE(g_balance_hlac_secondary_spread_crouchmod);
		CVAR_CACHE(g_balance_hlac_magazinecapacity);
		CVAR_CACHE(g_balance_hlac_reloadtime);
		projectile_init(PROJECTILE_HLAC);
		if (cvar("g_balance_hlac_swap_buttons")) {
			hlac_buttonatck1 = BUTTON_ATCK2;
			hlac_buttonatck2 = BUTTON_ATCK;
		}
		weapon_ammo_limits(WEAPON_HLAC, g_balance_hlac_primary_ammo, g_balance_hlac_secondary_ammo);
	}
	return TRUE;
}
