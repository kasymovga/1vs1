float g_balance_hagar_primary_ammo;
float g_balance_hagar_primary_damage;
float g_balance_hagar_primary_edgedamage;
float g_balance_hagar_primary_force;
float g_balance_hagar_primary_lifetime;
float g_balance_hagar_primary_premove;
float g_balance_hagar_primary_radius;
float g_balance_hagar_primary_refire;
float g_balance_hagar_primary_speed;
float g_balance_hagar_primary_spread;
float g_balance_hagar_recoil;
float g_balance_hagar_secondary_ammo;
float g_balance_hagar_secondary_animtime;
float g_balance_hagar_secondary_burst;
float g_balance_hagar_secondary_damage;
float g_balance_hagar_secondary_edgedamage;
float g_balance_hagar_secondary_force;
float g_balance_hagar_secondary_gravity;
float g_balance_hagar_secondary_lifetime_min;
float g_balance_hagar_secondary_lifetime_rand;
float g_balance_hagar_secondary_mode;
float g_balance_hagar_secondary_radius;
float g_balance_hagar_secondary_refire;
float g_balance_hagar_secondary_speed;
float g_balance_hagar_secondary_spread;
float g_balance_hagar_secondary_up;
float g_balance_hagar_secondary;

var .float hagar_buttonatck1 = BUTTON_ATCK;
var .float hagar_buttonatck2 = BUTTON_ATCK2;

void(void) weapon_hagar_touch2 {
	PROJECTILE_TOUCH;
	if (self.cnt > 0 || other.takedamage == DAMAGE_AIM) {
		projectile_explode();
	} else {
		self.cnt++;
		pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);
		self.owner = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void(void) weapon_hagar_touch_stick {
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
		projectile_explode();
	else {
		projectile_stick(self, other, vectoangles(self.velocity));
	}
}

void(void) weapon_hagar_attack {
	entity missile;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_hagar_primary_ammo;

	weapon_setup_shot (self, g_balance_hagar_recoil, "weapons/hagar_fire.wav", 1);
	pointparticles(particleeffectnum("hagar_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	missile = projectile(TRUE, PROJECTILE_HAGAR, TRUE, self);
	projectile_setup(missile, weapon_shotorg, EFFECT_IMPACT_HAGAR, WEAPON_HAGAR, g_balance_hagar_primary_damage,
			g_balance_hagar_primary_edgedamage, g_balance_hagar_primary_radius, g_balance_hagar_primary_force, 0, MOVETYPE_FLY);
	missile.touch = projectile_touch_explode;
	missile.use = projectile_explode;
	missile.think = projectile_think2use;
	missile.nextthink = time + g_balance_hagar_primary_lifetime;
	missile.velocity = (weapon_shotdir + randomvec() * g_balance_hagar_primary_spread) * g_balance_hagar_primary_speed;
	weapon_setup_projectile_velocity(missile);
	if (g_balance_hagar_primary_premove) projectile_premove(missile, g_balance_hagar_primary_premove);
}

void(void) weapon_hagar_attack2 {
	entity missile;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_hagar_secondary_ammo;

	weapon_setup_shot (self, g_balance_hagar_recoil, "weapons/hagar_fire.wav", 1);
	if (g_balance_hagar_secondary_mode)
		weapon_shotdir = v_forward; // no TrueAim for grenades please

	//weapon_setup_shot (self, FALSE, 2, "weapons/hagar_fire.wav"); // TODO: move model a little to the right
	pointparticles(particleeffectnum("hagar_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	missile = projectile(TRUE, (g_balance_hagar_secondary_mode ? PROJECTILE_HAGAR_STICK : PROJECTILE_HAGAR), TRUE, self);
	projectile_setup(missile, weapon_shotorg, EFFECT_IMPACT_HAGAR, WEAPON_HAGAR | HITTYPE_SECONDARY, g_balance_hagar_secondary_damage,
			g_balance_hagar_secondary_edgedamage, g_balance_hagar_secondary_radius, g_balance_hagar_secondary_force, g_balance_hagar_secondary_gravity, (g_balance_hagar_secondary_mode ? MOVETYPE_FLY : MOVETYPE_BOUNCEMISSILE));
	missile.touch = (g_balance_hagar_secondary_mode ? weapon_hagar_touch_stick : weapon_hagar_touch2);
	missile.cnt = 0;
	missile.use = projectile_explode;
	missile.think = projectile_think2use;
	missile.nextthink = time + g_balance_hagar_secondary_lifetime_min + random() * g_balance_hagar_secondary_lifetime_rand;
	missile.velocity = (weapon_shotdir + randomvec() * g_balance_hagar_secondary_spread) * g_balance_hagar_secondary_speed + '0 0 1' * g_balance_hagar_secondary_up;
	weapon_setup_projectile_velocity(missile);
}

void(void) spawnfunc_weapon_hagar {
	weapon_defaultspawnfunc(WEAPON_HAGAR);
}

void(void) weapon_hagar_burst_3 {
	if not(self.ammo_rockets >= g_balance_hagar_secondary_ammo || (self.items & IT_UNLIMITED_WEAPON_AMMO)) {
		weapon_ready();
		return;
	}
	weapon_hagar_attack2();
	weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_hagar_secondary_refire, weapon_ready);
}

void(void) weapon_hagar_burst_2 {
	if not(self.ammo_rockets >= g_balance_hagar_secondary_ammo || (self.items & IT_UNLIMITED_WEAPON_AMMO)) {
		weapon_ready();
		return;
	}
	weapon_hagar_attack2();
	weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_hagar_secondary_refire, (g_balance_hagar_secondary_burst ? weapon_hagar_burst_3 : weapon_ready));
}

float(float req) weapon_hagar {
	if (req == WEAPON_REQUEST_AIM) {
		if (!g_balance_hagar_secondary || random() > 0.15)
			self.hagar_buttonatck1 = bot_aim(g_balance_hagar_primary_speed, 0, g_balance_hagar_primary_lifetime, FALSE);
		else {
			// not using secondary_speed since these are only 15% and should cause some ricochets without re-aiming
			self.hagar_buttonatck2 = bot_aim(g_balance_hagar_primary_speed, 0, g_balance_hagar_primary_lifetime, g_balance_hagar_secondary_mode);
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.hagar_buttonatck1)
		if (weapon_prepareattack(0, g_balance_hagar_primary_refire)) {
			weapon_hagar_attack();
			weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_hagar_primary_refire, weapon_ready);
		}
		if (self.hagar_buttonatck2)
		if (g_balance_hagar_secondary)
		if (weapon_prepareattack(1, g_balance_hagar_secondary_animtime)) {
			weapon_hagar_attack2();
			weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_hagar_secondary_refire, (g_balance_hagar_secondary_burst ? weapon_hagar_burst_2 : weapon_ready));
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_sound("weapons/hagar_fire.wav");
	} else if (req == WEAPON_REQUEST_SETUP) {
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "played with tiny rockets";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		if (weapon_deathtype & HITTYPE_BOUNCE) // must be secondary; unchecked: SPLASH
			weapon_deathtypestring = "hoped #'s missiles wouldn't bounce";
		else // unchecked: SPLASH, SECONDARY
			weapon_deathtypestring = "was pummeled by";
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_hagar_primary_ammo);
		CVAR_CACHE(g_balance_hagar_primary_damage);
		CVAR_CACHE(g_balance_hagar_primary_edgedamage);
		CVAR_CACHE(g_balance_hagar_primary_force);
		CVAR_CACHE(g_balance_hagar_primary_lifetime);
		CVAR_CACHE(g_balance_hagar_primary_premove);
		CVAR_CACHE(g_balance_hagar_primary_radius);
		CVAR_CACHE(g_balance_hagar_primary_refire);
		CVAR_CACHE(g_balance_hagar_primary_speed);
		CVAR_CACHE(g_balance_hagar_primary_spread);
		CVAR_CACHE(g_balance_hagar_recoil);
		CVAR_CACHE(g_balance_hagar_secondary);
		CVAR_CACHE(g_balance_hagar_secondary_ammo);
		CVAR_CACHE(g_balance_hagar_secondary_animtime);
		CVAR_CACHE(g_balance_hagar_secondary_burst);
		CVAR_CACHE(g_balance_hagar_secondary_damage);
		CVAR_CACHE(g_balance_hagar_secondary_edgedamage);
		CVAR_CACHE(g_balance_hagar_secondary_force);
		CVAR_CACHE(g_balance_hagar_secondary_gravity);
		CVAR_CACHE(g_balance_hagar_secondary_lifetime_min);
		CVAR_CACHE(g_balance_hagar_secondary_lifetime_rand);
		CVAR_CACHE(g_balance_hagar_secondary_mode);
		CVAR_CACHE(g_balance_hagar_secondary_radius);
		CVAR_CACHE(g_balance_hagar_secondary_refire);
		CVAR_CACHE(g_balance_hagar_secondary_speed);
		CVAR_CACHE(g_balance_hagar_secondary_spread);
		CVAR_CACHE(g_balance_hagar_secondary_up);
		projectile_init(PROJECTILE_HAGAR);
		if (cvar("g_balance_hagar_swap_buttons")) {
			hagar_buttonatck1 = BUTTON_ATCK2;
			hagar_buttonatck2 = BUTTON_ATCK;
		}
		weapon_ammo_limits(WEAPON_HAGAR, g_balance_hagar_primary_ammo, g_balance_hagar_secondary_ammo);
	}
	return TRUE;
}
