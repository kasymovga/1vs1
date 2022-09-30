float g_balance_electro_combo_comboradius;
float g_balance_electro_combo_damage;
float g_balance_electro_combo_edgedamage;
float g_balance_electro_combo_force;
float g_balance_electro_combo_radius;
float g_balance_electro_combo_speed;
float g_balance_electro_primary_ammo;
float g_balance_electro_primary_animtime;
float g_balance_electro_primary_comboradius;
float g_balance_electro_primary_damage;
float g_balance_electro_primary_edgedamage;
float g_balance_electro_primary_force;
float g_balance_electro_primary_lifetime;
float g_balance_electro_primary_lightning;
float g_balance_electro_primary_lightning_length;
float g_balance_electro_primary_radius;
float g_balance_electro_primary_refire;
float g_balance_electro_primary_recoil;
float g_balance_electro_primary_speed;
float g_balance_electro_secondary;
float g_balance_electro_secondary_ammo;
float g_balance_electro_secondary_animtime;
float g_balance_electro_secondary_count;
float g_balance_electro_secondary_damage;
float g_balance_electro_secondary_damageforcescale;
float g_balance_electro_secondary_edgedamage;
float g_balance_electro_secondary_force;
float g_balance_electro_secondary_health;
float g_balance_electro_secondary_lifetime;
float g_balance_electro_secondary_radius;
float g_balance_electro_secondary_recoil;
float g_balance_electro_secondary_refire;
float g_balance_electro_secondary_refire2;
float g_balance_electro_secondary_speed;
float g_balance_electro_secondary_speed_up;
float g_balance_electro_secondary_spread;

.float electro_count;
.float electro_secondarytime;
var .float electro_buttonatck1 = BUTTON_ATCK;
var .float electro_buttonatck2 = BUTTON_ATCK2;

void(void) weapon_electro_explode_combo;

void(entity e, entity own, float _delay) weapon_electro_combo_prepare {
	e.realowner = e.owner = own;
	e.takedamage = DAMAGE_NO;
	e.classname = "plasma_chain";
	e.think = weapon_electro_explode_combo;
	e.dmg = g_balance_electro_combo_damage;
	e.dmg_edge = g_balance_electro_combo_edgedamage;
	e.dmg_force = g_balance_electro_combo_force;
	e.dmg_radius = g_balance_electro_combo_radius;
	e.species = EFFECT_IMPACT_PLASMA_COMBO;
	e.projectiledeathtype = (WEP_ELECTRO | HITTYPE_BOUNCE);
	e.nextthink = time + _delay;
}

void(vector org, float rad, entity own) weapon_electro_trigger_combo {
	entity e;
	e = findradius(org, rad);
	while (e) {
		if (e.classname == "plasma") {
			// see if there is line of sight to the combo ball
			trace_line(org, e.origin, TRACE_MOVE_NORMAL, e);
			if (trace_fraction == 1 || trace_ent == e) {
				// change owner to whoever caused the combo explosion
				weapon_electro_combo_prepare(e, own, vlen(e.origin - org) / g_balance_electro_combo_speed);
			}
		}
		e = e.chain;
	}
}

void(void) weapon_electro_explode {
	if (other.takedamage == DAMAGE_AIM)
	if (other.classname == "player")
	if (team_is_different_teams(self.owner, other))
	if (other.deadflag == DEAD_NO)
	if (physics_is_flying(other))
		announce(self.owner, "announcer/male/electrobitch.wav", "^5Air^5Shot");

	if not(self.projectiledeathtype & HITTYPE_SECONDARY)
		weapon_electro_trigger_combo(self.origin, g_balance_electro_primary_comboradius, self.owner);

	projectile_explode();
}

void(void) weapon_electro_explode_combo {
	weapon_electro_trigger_combo(self.origin, g_balance_electro_combo_comboradius, self.owner);
	projectile_explode();
}

void(void) weapon_electro_touch {
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM) {
		weapon_electro_explode ();
	} else {
		sound_spam (self, CHAN_PROJECTILE, "weapons/electro_bounce.wav", VOL_BASE, ATTN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void(void) weapon_electro_touch_explode {
	PROJECTILE_TOUCH;
	weapon_electro_explode ();
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) weapon_electro_damage {
	if (self.health <= 0)
		return;

	self.health = self.health - _damage;
	if (self.health <= 0) {
		if (inflictor.classname == "plasma_chain" || inflictor.classname == "plasma_prim") {
			// change owner to whoever caused the combo explosion
			weapon_electro_combo_prepare(self, inflictor.owner, 0);
		} else {
			self.nextthink = time;
			self.takedamage = DAMAGE_NO;
			self.use = weapon_electro_explode;
			self.think = projectile_think2use;
		}
	}
}

void(void) weapon_electro_attack {
	entity proj;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_electro_primary_ammo;

	weapon_setup_shot(self, g_balance_electro_primary_recoil, "weapons/electro_fire.wav", 1);
	pointparticles(particleeffectnum("electro_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	proj = projectile(TRUE, PROJECTILE_ELECTRO_BEAM, TRUE, self);
	projectile_setup(proj, weapon_shotorg, EFFECT_IMPACT_PLASMA, WEP_ELECTRO, g_balance_electro_primary_damage,
			g_balance_electro_primary_edgedamage, g_balance_electro_primary_radius, g_balance_electro_primary_force, 0, MOVETYPE_FLY);
	proj.classname = "plasma_prim";
	proj.use = weapon_electro_explode;
	proj.think = projectile_think2use;
	proj.nextthink = time + g_balance_electro_primary_lifetime;
	proj.velocity = weapon_shotdir * g_balance_electro_primary_speed;
	weapon_setup_projectile_velocity(proj);
	proj.touch = weapon_electro_touch_explode;
}

void(void) weapon_electro_attack2 {
	entity proj;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_electro_secondary_ammo;

	weapon_setup_shot(self, g_balance_electro_secondary_recoil, "weapons/electro_fire2.wav", 1);
	weapon_shotdir = v_forward; // no TrueAim for grenades please
	pointparticles(particleeffectnum("electro_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	proj = projectile(TRUE, PROJECTILE_ELECTRO, FALSE, self); // no culling, it has sound
	projectile_setup(proj, weapon_shotorg, EFFECT_IMPACT_PLASMA_BALL, WEP_ELECTRO | HITTYPE_SECONDARY, g_balance_electro_secondary_damage,
			g_balance_electro_secondary_edgedamage, g_balance_electro_secondary_radius, g_balance_electro_secondary_force, 1, MOVETYPE_BOUNCE);
	proj.classname = "plasma";
	proj.use = weapon_electro_explode;
	proj.think = projectile_think2use;
	proj.nextthink = time + g_balance_electro_secondary_lifetime;
	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.velocity = (weapon_shotdir + randomvec() * g_balance_electro_secondary_spread) * g_balance_electro_secondary_speed + v_up * g_balance_electro_secondary_speed_up;
	weapon_setup_projectile_velocity(proj);
	proj.touch = weapon_electro_touch;
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = g_balance_electro_secondary_damageforcescale;
	proj.health = g_balance_electro_secondary_health;
	proj.event_damage = weapon_electro_damage;
}

void(void) spawnfunc_weapon_electro {
	weapon_defaultspawnfunc(WEP_ELECTRO);
}

void(void) weapon_electro_checkattack {
	if (self.electro_count > 1)
	if (self.electro_buttonatck2)
	if (weapon_prepareattack(1, -1)) {
		weapon_electro_attack2();
		self.electro_count -= 1;
		weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_electro_secondary_animtime, weapon_electro_checkattack);
		return;
	}
	weapon_ready();
}

.float bot_secondary_electromooth;
float(float req) weapon_electro {
	if (req == WEAPON_REQUEST_AIM) {
		self.electro_buttonatck1=FALSE;
		self.electro_buttonatck2=FALSE;
		if (vlen(self.origin-self.enemy.origin) > g_balance_electro_secondary_speed)
			self.bot_secondary_electromooth = 0;

		if (self.bot_secondary_electromooth == 0) {
			float aim_electro_speed;
			float aim_electro_lifetime;
			if (g_balance_electro_primary_lightning) {
				aim_electro_speed = g_balance_electro_primary_lightning_length * 100;
				aim_electro_lifetime = 0.01;
			} else {
				aim_electro_speed = g_balance_electro_primary_speed;
				aim_electro_lifetime = g_balance_electro_primary_lifetime;
			}
			if (bot_aim(aim_electro_speed, 0, aim_electro_lifetime, FALSE)) {
				self.electro_buttonatck1 = TRUE;
				if (g_balance_electro_secondary && random() < sys_ticrate)
					self.bot_secondary_electromooth = 1;
			}
		} else {
			if (bot_aim(g_balance_electro_secondary_speed, g_balance_electro_secondary_speed_up, g_balance_electro_secondary_lifetime, TRUE)) {
				self.electro_buttonatck2 = TRUE;
				if (random() < sys_ticrate * 3) self.bot_secondary_electromooth = 0;
			}
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.electro_buttonatck1)
		if (weapon_prepareattack(0, g_balance_electro_primary_refire)) {
			weapon_electro_attack();
			weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_electro_primary_animtime, weapon_ready);
		}
		if (self.electro_buttonatck2)
		if (time >= self.electro_secondarytime)
		if (g_balance_electro_secondary)
		if (weapon_prepareattack(1, g_balance_electro_secondary_refire)) {
			weapon_electro_attack2();
			self.electro_count = g_balance_electro_secondary_count;
			weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_electro_secondary_animtime, weapon_electro_checkattack);
			self.electro_secondarytime = time + g_balance_electro_secondary_refire2;
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_sound("weapons/electro_bounce.wav");
		precache_sound("weapons/electro_fire.wav");
		precache_sound("weapons/electro_fire2.wav");
		precache_sound("weapons/electro_impact.wav");
		precache_sound("weapons/electro_impact_combo.wav");
		precache_sound("weapons/electro_fly.wav");
		hint_add("Spam secondary electro balls and explode them with primary fire to create a powerful explosion.");
	} else if (req == WEAPON_REQUEST_SETUP) {
	} else if (req == WEAPON_REQUEST_CHECKAMMO1)
		return self.ammo_cells >= g_balance_electro_primary_ammo;
	else if (req == WEAPON_REQUEST_CHECKAMMO2)
		return self.ammo_cells >= g_balance_electro_secondary_ammo;
	else if (req == WEAPON_REQUEST_SUICIDEMESSAGE) {
		if (weapon_deathtype & HITTYPE_SECONDARY)
			weapon_deathtypestring = "could not remember where he put plasma";
		else
			weapon_deathtypestring = "played with plasma";
	} else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		if (weapon_deathtype & HITTYPE_SECONDARY) {
			if (weapon_deathtype & HITTYPE_SPLASH) // unchecked: BOUNCE
				weapon_deathtypestring = "just noticed #'s blue ball";
			else // unchecked: BOUNCE
				weapon_deathtypestring = "got in touch with #'s blue ball";
		} else {
			if (weapon_deathtype & HITTYPE_BOUNCE) // combo
				weapon_deathtypestring = "felt the electrifying air of #'s combo";
			else if (weapon_deathtype & HITTYPE_SPLASH)
				weapon_deathtypestring = "got too close to #'s blue beam";
			else
				weapon_deathtypestring = "was blasted by #'s blue beam";
		}
	} else if (req == WEAPON_REQUEST_RESETPLAYER)
		self.electro_secondarytime = time;
	else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_electro_combo_comboradius);
		CVAR_CACHE(g_balance_electro_combo_damage);
		CVAR_CACHE(g_balance_electro_combo_edgedamage);
		CVAR_CACHE(g_balance_electro_combo_force);
		CVAR_CACHE(g_balance_electro_combo_radius);
		CVAR_CACHE(g_balance_electro_combo_speed);
		CVAR_CACHE(g_balance_electro_primary_ammo);
		CVAR_CACHE(g_balance_electro_primary_animtime);
		CVAR_CACHE(g_balance_electro_primary_comboradius);
		CVAR_CACHE(g_balance_electro_primary_damage);
		CVAR_CACHE(g_balance_electro_primary_edgedamage);
		CVAR_CACHE(g_balance_electro_primary_force);
		CVAR_CACHE(g_balance_electro_primary_lifetime);
		CVAR_CACHE(g_balance_electro_primary_lightning);
		CVAR_CACHE(g_balance_electro_primary_lightning_length);
		CVAR_CACHE(g_balance_electro_primary_radius);
		CVAR_CACHE(g_balance_electro_primary_recoil);
		CVAR_CACHE(g_balance_electro_primary_refire);
		CVAR_CACHE(g_balance_electro_primary_speed);
		CVAR_CACHE(g_balance_electro_secondary);
		CVAR_CACHE(g_balance_electro_secondary_ammo);
		CVAR_CACHE(g_balance_electro_secondary_animtime);
		CVAR_CACHE(g_balance_electro_secondary_count);
		CVAR_CACHE(g_balance_electro_secondary_damage);
		CVAR_CACHE(g_balance_electro_secondary_damageforcescale);
		CVAR_CACHE(g_balance_electro_secondary_edgedamage);
		CVAR_CACHE(g_balance_electro_secondary_force);
		CVAR_CACHE(g_balance_electro_secondary_health);
		CVAR_CACHE(g_balance_electro_secondary_lifetime);
		CVAR_CACHE(g_balance_electro_secondary_radius);
		CVAR_CACHE(g_balance_electro_secondary_recoil);
		CVAR_CACHE(g_balance_electro_secondary_refire);
		CVAR_CACHE(g_balance_electro_secondary_refire2);
		CVAR_CACHE(g_balance_electro_secondary_speed);
		CVAR_CACHE(g_balance_electro_secondary_speed_up);
		CVAR_CACHE(g_balance_electro_secondary_spread);
		projectile_init(PROJECTILE_ELECTRO);
		projectile_init(PROJECTILE_ELECTRO_BEAM);
		if (cvar("g_balance_electro_swap_buttons")) {
			electro_buttonatck1 = BUTTON_ATCK2;
			electro_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}
