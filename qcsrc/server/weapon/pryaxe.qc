float g_balance_pryaxe_primary_animtime;
float g_balance_pryaxe_primary_damage;
float g_balance_pryaxe_primary_delay;
float g_balance_pryaxe_primary_force;
float g_balance_pryaxe_primary_range;
float g_balance_pryaxe_primary_refire;
float g_balance_pryaxe_primary_throw;
float g_balance_pryaxe_primary_throw_damage;
float g_balance_pryaxe_primary_throw_force;
float g_balance_pryaxe_primary_throw_speed;
float g_balance_pryaxe_secondary_animtime;
float g_balance_pryaxe_secondary_damage;
float g_balance_pryaxe_secondary_delay;
float g_balance_pryaxe_secondary_force;
float g_balance_pryaxe_secondary_range;
float g_balance_pryaxe_secondary_refire;
float g_balance_pryaxe_secondary_throw;
float g_balance_pryaxe_secondary_throw_damage;
float g_balance_pryaxe_secondary_throw_force;
float g_balance_pryaxe_secondary_throw_speed;

var .float pryaxe_buttonatck1;
var .float pryaxe_buttonatck2;
.entity pryaxe_throwed;

void(void) spawnfunc_weapon_pryaxe {
	if (g_balance_melee && g_balance_melee != 2)
		weapon_defaultspawnfunc(WEAPON_MELEE);
	else
		remove(self);
}

void(void) weapon_pryaxe_flyback {
	if (self == self.realowner.pryaxe_throwed)
		self.realowner.pryaxe_throwed = NULL;

	remove(self);
}

void(void) weapon_pryaxe_touch {
	if (self == self.realowner.pryaxe_throwed)
		self.realowner.pryaxe_throwed = NULL;

	projectile_explode();
}

void(float issecondary) weapon_pryaxe_throw {
	weapon_setup_shot(self, 0, "", 1);
	entity proj = projectile(TRUE, PROJECTILE_RM_PRYAXE, TRUE, self);
	projectile_setup(proj, weapon_shotorg, EFFECT_IMPACT_RM_PRYAXE, WEAPON_MELEE, (issecondary ? g_balance_pryaxe_secondary_throw_damage : g_balance_pryaxe_primary_throw_damage),
			0, 0, (issecondary ? g_balance_pryaxe_secondary_throw_force : g_balance_pryaxe_primary_throw_force), 0, MOVETYPE_FLY);
	proj.nextthink = time + 10;
	proj.use = weapon_pryaxe_flyback;
	proj.think = projectile_think2use;
	proj.touch = weapon_pryaxe_touch;
	proj.velocity = weapon_shotdir * (issecondary ? g_balance_pryaxe_secondary_throw_speed : g_balance_pryaxe_primary_throw_speed);
	weapon_setup_projectile_velocity(proj);
	weapon_ready();
	self.pryaxe_throwed = proj;
}

void(float issecondary) weapon_pryaxe_melee {
	antilag_begin(self);
	weapon_setup_shot(self, 0, "", 1);
	warpzone_trace_line(weapon_shotorg - (weapon_shotdir * 10), weapon_shotorg + weapon_shotdir * g_balance_pryaxe_primary_range, TRACE_MOVE_NORMAL, self);
	if (trace_fraction < 1) {
		float d = (issecondary ? g_balance_pryaxe_secondary_damage : g_balance_pryaxe_primary_damage);
		float f = (issecondary ? g_balance_pryaxe_secondary_force : g_balance_pryaxe_primary_force);
		if (trace_ent && trace_ent.takedamage) {
			weapon_score_hits(self, trace_ent, WEAPON_MELEE, 1, d);
			damage(trace_ent, self, self, d,
					WEAPON_MELEE, trace_endpos, warpzone_transform_velocity(warpzone_trace_transform, weapon_shotdir) * f);
		}
		if (!trace_ent || trace_ent.solid == SOLID_BSP) {
			effect_impact(trace_endpos, d, d, 0, weapon_shotdir * f, EFFECT_IMPACT_RM_PRYAXE, self);
		}
	}
	antilag_end();
	weapon_thinkf(WEAPON_FRAME_FIRE1, (issecondary ? (g_balance_pryaxe_secondary_animtime - g_balance_pryaxe_secondary_delay) : (g_balance_pryaxe_primary_animtime - g_balance_pryaxe_primary_delay)), weapon_ready);
}

void(float issecondary) weapon_pryaxe_attack {
	float throw = (issecondary ? g_balance_pryaxe_secondary_throw : g_balance_pryaxe_primary_throw);
	if (throw) {
		if (throw & 2) {
			weapon_pryaxe_throw(issecondary);
		} else {
			if ((issecondary ? self.pryaxe_buttonatck2 : self.pryaxe_buttonatck1)) {
				if (throw & 1)
					weapon_pryaxe_melee(issecondary);
				else
					weapon_pryaxe_throw(issecondary);
			} else {
				if (throw & 1)
					weapon_pryaxe_throw(issecondary);
				else
					weapon_pryaxe_melee(issecondary);
			}
		}
	} else {
		weapon_pryaxe_melee(issecondary);
	}
}

void(void) weapon_pryaxe_attack1 {
	weapon_pryaxe_attack(FALSE);
}

void(void) weapon_pryaxe_attack2 {
	weapon_pryaxe_attack(TRUE);
}

var float(float fr) weapon_pryaxe_weapon_animation_is_melee_next;
float(float fr) weapon_pryaxe_weapon_animation_is_melee {
	if ((fr == WEAPON_FRAME_FIRE1 || fr == WEAPON_FRAME_FIRE2) && self.weapon == WEAPON_MELEE)
		return 1;

	return weapon_pryaxe_weapon_animation_is_melee_next(fr);
}

var float(float f) weapon_pryaxe_weapon_switch_mod_next;
float(float f) weapon_pryaxe_weapon_switch_mod {
	if (f == WEAPON_MELEE && self.pryaxe_throwed) {
		return 0;
	}
	return weapon_pryaxe_weapon_switch_mod_next(f);
}

float weapon_pryaxe_init_done;
float(float req) weapon_pryaxe {
	if (req == WEAPON_REQUEST_AIM) {
		if (random() < bot_melee_love)
		if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
		if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE))
			self.BUTTON_ATCK = TRUE;
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.pryaxe_buttonatck1) {
			if (weapon_prepareattack(0, g_balance_pryaxe_primary_refire)) {
				sound(self, CHAN_WEAPON, "weapons/swing.wav", VOL_BASE, ATTN_NORM);
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_pryaxe_primary_delay, weapon_pryaxe_attack1);
			}
		}
		if (self.pryaxe_buttonatck2) {
			if (weapon_prepareattack(0, g_balance_pryaxe_secondary_refire)) {
				sound(self, CHAN_WEAPON, "weapons/swing.wav", VOL_BASE, ATTN_NORM);
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_pryaxe_secondary_delay, weapon_pryaxe_attack2);
			}
		}
	} else if (req == WEAPON_REQUEST_RELOAD) {
		if (g_balance_melee != 2)
		if (weapon_prepareattack(0, g_balance_pryaxe_primary_refire)) {
			weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_pryaxe_primary_animtime, weapon_pryaxe_attack1);
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		dlc_require("pryaxe");
		dlc_precache_sound("weapons/swing.wav");
		dlc_precache_sound("weapons/pryaxe_impact1.wav");
		dlc_precache_sound("weapons/pryaxe_impact2.wav");
		dlc_precache_sound("weapons/pryaxe_impact3.wav");
	} else if (req == WEAPON_REQUEST_SETUP) {
		self.pryaxe_throwed = NULL;
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "rekt himself";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_fragprefix = "^xF80MELEE";
		weapon_deathtypestring = "was smashed by";
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_pryaxe_primary_animtime);
		CVAR_CACHE(g_balance_pryaxe_primary_damage);
		CVAR_CACHE(g_balance_pryaxe_primary_delay);
		CVAR_CACHE(g_balance_pryaxe_primary_range);
		CVAR_CACHE(g_balance_pryaxe_primary_refire);
		CVAR_CACHE(g_balance_pryaxe_primary_throw);
		CVAR_CACHE(g_balance_pryaxe_primary_throw_damage);
		CVAR_CACHE(g_balance_pryaxe_primary_throw_force);
		CVAR_CACHE(g_balance_pryaxe_primary_throw_speed);
		CVAR_CACHE(g_balance_pryaxe_secondary_animtime);
		CVAR_CACHE(g_balance_pryaxe_secondary_damage);
		CVAR_CACHE(g_balance_pryaxe_secondary_delay);
		CVAR_CACHE(g_balance_pryaxe_secondary_range);
		CVAR_CACHE(g_balance_pryaxe_secondary_refire);
		CVAR_CACHE(g_balance_pryaxe_secondary_throw);
		CVAR_CACHE(g_balance_pryaxe_secondary_throw_damage);
		CVAR_CACHE(g_balance_pryaxe_secondary_throw_force);
		CVAR_CACHE(g_balance_pryaxe_secondary_throw_speed);
		projectile_init(PROJECTILE_RM_PRYAXE);
		if (cvar("g_balance_pryaxe_swap_buttons")) {
			pryaxe_buttonatck1 = BUTTON_ATCK2;
			pryaxe_buttonatck2 = BUTTON_ATCK;
		} else {
			pryaxe_buttonatck1 = BUTTON_ATCK;
			pryaxe_buttonatck2 = BUTTON_ATCK2;
		}
		if not(weapon_pryaxe_init_done) {
			weapon_pryaxe_weapon_animation_is_melee_next = plugin_chain_weapon_animation_is_melee;
			plugin_chain_weapon_animation_is_melee = weapon_pryaxe_weapon_animation_is_melee;
			weapon_pryaxe_weapon_switch_mod_next = plugin_chain_weapon_frame_switch_mod;
			plugin_chain_weapon_frame_switch_mod = weapon_pryaxe_weapon_switch_mod;
			weapon_pryaxe_init_done = TRUE;
		}
	}
	return TRUE;
}
