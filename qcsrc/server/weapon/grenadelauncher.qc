float g_balance_grenadelauncher_primary_ammo;
float g_balance_grenadelauncher_primary_animtime;
float g_balance_grenadelauncher_primary_bounce;
float g_balance_grenadelauncher_primary_damage;
float g_balance_grenadelauncher_primary_edgedamage;
float g_balance_grenadelauncher_primary_force;
float g_balance_grenadelauncher_primary_lifetime;
float g_balance_grenadelauncher_primary_radius;
float g_balance_grenadelauncher_primary_refire;
float g_balance_grenadelauncher_primary_speed;
float g_balance_grenadelauncher_primary_speed_up;
float g_balance_grenadelauncher_primary_up;
float g_balance_grenadelauncher_recoil;
float g_balance_grenadelauncher_secondary_ammo;
float g_balance_grenadelauncher_secondary_animtime;
float g_balance_grenadelauncher_secondary_damage;
float g_balance_grenadelauncher_secondary_damageforcescale;
float g_balance_grenadelauncher_secondary_edgedamage;
float g_balance_grenadelauncher_secondary_force;
float g_balance_grenadelauncher_secondary_health;
float g_balance_grenadelauncher_secondary_lifetime;
float g_balance_grenadelauncher_secondary_radius;
float g_balance_grenadelauncher_secondary_refire;
float g_balance_grenadelauncher_secondary_speed;
float g_balance_grenadelauncher_secondary_speed_up;
float g_balance_grenadelauncher_secondary_trigger_type;
float g_balance_grenadelauncher_secondary;
float g_balance_grenadelauncher_magazinecapacity;
float g_balance_grenadelauncher_reloadtime;

var .float gl_buttonatck1 = BUTTON_ATCK;
var .float gl_buttonatck2 = BUTTON_ATCK2;
.float gl_ammoclip;

void(void) weapon_grenadelauncher_explode {
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(team_is_different_teams(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(physics_is_flying(other))
						announce(self.owner, "announcer/male/airshot.wav", "^5Air^3Shot");

	projectile_explode();
}

void(void) weapon_grenadelauncher_touch1 {
	PROJECTILE_TOUCH;
	weapon_grenadelauncher_explode();
}

void(void) weapon_grenadelauncher_touch2 {
	PROJECTILE_TOUCH;
	if (other && (other.takedamage == DAMAGE_AIM || (other.takedamage == DAMAGE_YES && g_balance_grenadelauncher_secondary_trigger_type))) {
		projectile_explode();
	} else {
		float r;
		r = random() * 6;
		if(r < 1)
			sound_spam (self, CHAN_PROJECTILE, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			sound_spam (self, CHAN_PROJECTILE, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			sound_spam (self, CHAN_PROJECTILE, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			sound_spam (self, CHAN_PROJECTILE, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			sound_spam (self, CHAN_PROJECTILE, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			sound_spam (self, CHAN_PROJECTILE, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);

		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) weapon_grenadelauncher_damage {
	if (self.health <= 0)
		return;

	self.health = self.health - _damage;
	if (self.health <= 0) {
		damage_prepare_explosion(attacker, self.think);
	}
}

void(void) weapon_grenadelauncher_attack {
	entity gren;
	float bounce = (g_balance_grenadelauncher_primary_bounce ? TRUE : FALSE);
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_grenadelauncher_primary_ammo;

	if (g_balance_grenadelauncher_magazinecapacity)
		self.gl_ammoclip -= 1;

	weapon_setup_shot(self, g_balance_grenadelauncher_recoil, "weapons/grenade_fire.wav", 1);
	weapon_shotdir = v_forward; // no TrueAim for grenades please
	if (g_balance_grenadelauncher_primary_up) {
		weapon_shotdir = normalize(weapon_shotdir + '0 0 1' * g_balance_grenadelauncher_primary_up);
	}
	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	gren = projectile(TRUE, (bounce ? PROJECTILE_GRENADE_BOUNCING : PROJECTILE_GRENADE), TRUE, self);
	projectile_setup(gren, weapon_shotorg, EFFECT_IMPACT_GRENADE, WEP_GRENADE_LAUNCHER, g_balance_grenadelauncher_primary_damage,
			g_balance_grenadelauncher_primary_edgedamage, g_balance_grenadelauncher_primary_radius, g_balance_grenadelauncher_primary_force, 1, (bounce ? MOVETYPE_BOUNCE : MOVETYPE_TOSS));

	gren.nextthink = time + g_balance_grenadelauncher_primary_lifetime;
	gren.think = projectile_think2use;
	gren.use = weapon_grenadelauncher_explode;
	gren.touch = (bounce ? weapon_grenadelauncher_touch2 : weapon_grenadelauncher_touch1);
	gren.velocity = weapon_shotdir * g_balance_grenadelauncher_primary_speed + v_up * g_balance_grenadelauncher_primary_speed_up;
	weapon_setup_projectile_velocity(gren);
}

void(void) weapon_grenadelauncher_attack2 {
	entity gren;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_grenadelauncher_secondary_ammo;

	if (g_balance_grenadelauncher_magazinecapacity)
		self.gl_ammoclip -= 1;

	weapon_setup_shot(self, g_balance_grenadelauncher_recoil, "weapons/grenade_fire.wav", 1);
	weapon_shotdir = v_forward; // no TrueAim for grenades please
	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	gren = projectile(TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE, self);
	projectile_setup(gren, weapon_shotorg, EFFECT_IMPACT_GRENADE, WEP_GRENADE_LAUNCHER | HITTYPE_SECONDARY, g_balance_grenadelauncher_secondary_damage,
			g_balance_grenadelauncher_secondary_edgedamage, g_balance_grenadelauncher_secondary_radius, g_balance_grenadelauncher_secondary_force, 1, MOVETYPE_BOUNCE);
	gren.nextthink = time + g_balance_grenadelauncher_secondary_lifetime;
	gren.think = projectile_think2use;
	gren.use = weapon_grenadelauncher_explode;
	gren.touch = weapon_grenadelauncher_touch2;
	gren.takedamage = DAMAGE_YES;
	gren.health = g_balance_grenadelauncher_secondary_health;
	gren.damageforcescale = g_balance_grenadelauncher_secondary_damageforcescale;
	gren.event_damage = weapon_grenadelauncher_damage;
	gren.velocity = weapon_shotdir * g_balance_grenadelauncher_secondary_speed + v_up * g_balance_grenadelauncher_secondary_speed_up;
	weapon_setup_projectile_velocity(gren);
}

void(void) spawnfunc_weapon_grenadelauncher {
	weapon_defaultspawnfunc(WEP_GRENADE_LAUNCHER);
}

void(void) weapon_grenadelauncher_reloadandready {
	weapon_clip_reloadandready(g_balance_grenadelauncher_magazinecapacity, ammo_rockets, gl_ammoclip,
			g_balance_grenadelauncher_primary_ammo, g_balance_grenadelauncher_secondary_ammo, g_balance_grenadelauncher_reloadtime);
}

void(void) weapon_grenadelauncher_reload {
	weapon_clip_reload(g_balance_grenadelauncher_magazinecapacity, ammo_rockets, gl_ammoclip, g_balance_grenadelauncher_primary_ammo,
			g_balance_grenadelauncher_secondary_ammo, "weapons/campingrifle_reload.wav", g_balance_grenadelauncher_reloadtime,
			weapon_grenadelauncher_reloadandready);
}

.float bot_secondary_grenademooth;
float(float req) weapon_grenadelauncher {
	if (req == WR_AIM) {
		self.gl_buttonatck1 = FALSE;
		self.gl_buttonatck2 = FALSE;
		if (self.bot_secondary_grenademooth == 0 || !g_balance_grenadelauncher_secondary) {
			if (bot_aim(g_balance_grenadelauncher_primary_speed, g_balance_grenadelauncher_primary_speed_up, g_balance_grenadelauncher_primary_lifetime, TRUE)) {
				self.gl_buttonatck1 = TRUE;
				if(random() < 0.01) self.bot_secondary_grenademooth = 1;
			}
		} else {
			if (bot_aim(g_balance_grenadelauncher_secondary_speed, g_balance_grenadelauncher_secondary_speed_up, g_balance_grenadelauncher_secondary_lifetime, TRUE)) {
				self.gl_buttonatck2 = TRUE;
				if(random() < 0.02) self.bot_secondary_grenademooth = 0;
			}
		}
	} else if (req == WR_THINK) {
		if (g_balance_grenadelauncher_magazinecapacity && (self.gl_ammoclip < 0 || (!self.gl_ammoclip && (self.gl_buttonatck1 || self.gl_buttonatck2)))) { // forced reload (e.g. because interrupted)
			if (self.switchweapon == self.weapon)
			if (self.weaponentity.state == WS_READY)
				weapon_grenadelauncher_reload();
		} else if (!g_balance_grenadelauncher_magazinecapacity || self.gl_ammoclip > 0) {
			if (self.gl_buttonatck1)
			if (weapon_prepareattack(0, g_balance_grenadelauncher_primary_refire)) {
				weapon_grenadelauncher_attack();
				weapon_thinkf(WFRAME_FIRE1, g_balance_grenadelauncher_primary_animtime, weapon_ready);
			}
			if (self.gl_buttonatck2)
			if (g_balance_grenadelauncher_secondary)
			if (weapon_prepareattack(1, g_balance_grenadelauncher_secondary_refire)) {
				weapon_grenadelauncher_attack2();
				weapon_thinkf(WFRAME_FIRE2, g_balance_grenadelauncher_secondary_animtime, weapon_ready);
			}
		}
		if (g_balance_grenadelauncher_magazinecapacity) {
			self.ammoclip = self.gl_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
		}
	} else if (req == WR_PRECACHE) {
		precache_sound("weapons/grenade_bounce1.wav");
		precache_sound("weapons/grenade_bounce2.wav");
		precache_sound("weapons/grenade_bounce3.wav");
		precache_sound("weapons/grenade_bounce4.wav");
		precache_sound("weapons/grenade_bounce5.wav");
		precache_sound("weapons/grenade_bounce6.wav");
		precache_sound("weapons/grenade_fire.wav");
	} else if (req == WR_SETUP) {
		//weapon_setup(WEP_GRENADE_LAUNCHER);
		if (g_balance_grenadelauncher_magazinecapacity) {
			weapon_clip_checkmaxbullets(g_balance_grenadelauncher_magazinecapacity, ammo_rockets, gl_ammoclip, g_balance_grenadelauncher_primary_ammo, g_balance_grenadelauncher_secondary_ammo);
			if not(self.gl_ammoclip)
				self.gl_ammoclip = -1;
		}
	} else if (req == WR_CHECKAMMO1)
		return self.ammo_rockets >= g_balance_grenadelauncher_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_rockets >= g_balance_grenadelauncher_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE) {
		if(weapon_deathtype & HITTYPE_SECONDARY)
			weapon_deathtypestring = "tried out his own grenade";
		else
			weapon_deathtypestring = "detonated";
	} else if (req == WR_KILLMESSAGE) {
		if (weapon_deathtype & HITTYPE_SPLASH)
			if (weapon_deathtype & HITTYPE_BOUNCE) // (must be secondary then)
				weapon_deathtypestring = "didn't see #'s grenade";
			else // unchecked: SECONDARY
				weapon_deathtypestring = "almost dodged #'s grenade";
		else // unchecked: SECONDARY, BOUNCE
			weapon_deathtypestring = "ate #'s grenade";
	} else if (req == WR_RELOAD) {
		weapon_grenadelauncher_reload();
	} else if (req == WR_RESETPLAYER) {
		if (g_balance_grenadelauncher_magazinecapacity)
			self.gl_ammoclip = g_balance_grenadelauncher_magazinecapacity;
	} else if (req == WR_CVAR_CACHE) {
		CVAR_CACHE(g_balance_grenadelauncher_primary_ammo);
		CVAR_CACHE(g_balance_grenadelauncher_primary_animtime);
		CVAR_CACHE(g_balance_grenadelauncher_primary_bounce);
		CVAR_CACHE(g_balance_grenadelauncher_primary_damage);
		CVAR_CACHE(g_balance_grenadelauncher_primary_edgedamage);
		CVAR_CACHE(g_balance_grenadelauncher_primary_force);
		CVAR_CACHE(g_balance_grenadelauncher_primary_lifetime);
		CVAR_CACHE(g_balance_grenadelauncher_primary_radius);
		CVAR_CACHE(g_balance_grenadelauncher_primary_refire);
		CVAR_CACHE(g_balance_grenadelauncher_primary_speed);
		CVAR_CACHE(g_balance_grenadelauncher_primary_speed_up);
		CVAR_CACHE(g_balance_grenadelauncher_primary_up);
		CVAR_CACHE(g_balance_grenadelauncher_recoil);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_ammo);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_animtime);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_damage);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_damageforcescale);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_edgedamage);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_force);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_health);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_lifetime);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_radius);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_refire);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_speed);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_speed_up);
		CVAR_CACHE(g_balance_grenadelauncher_secondary);
		CVAR_CACHE(g_balance_grenadelauncher_secondary_trigger_type);
		CVAR_CACHE(g_balance_grenadelauncher_magazinecapacity);
		CVAR_CACHE(g_balance_grenadelauncher_reloadtime);
		projectile_init(PROJECTILE_GRENADE);
		projectile_init(PROJECTILE_GRENADE_BOUNCING);
		if (cvar("g_balance_grenadelauncher_swap_buttons")) {
			gl_buttonatck1 = BUTTON_ATCK2;
			gl_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}
