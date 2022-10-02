float g_balance_chainsaw_primary_damage;
float g_balance_chainsaw_primary_force;
float g_balance_chainsaw_primary_refire;
float g_balance_chainsaw_secondary;
float g_balance_chainsaw_secondary_damage;
float g_balance_chainsaw_noise;

void(void) spawnfunc_weapon_chainsaw {
	if (g_balance_melee && g_balance_melee != 2)
		weapon_defaultspawnfunc(WEAPON_MELEE);
	else
		remove(self);
}

void(void) weapon_chainsaw_ready {
	if (g_balance_chainsaw_noise)
		player_sound(self, CHAN_WEAPON, "weapons/chainsaw_idle_1.wav", VOL_BASE, ATTN_NORM);
	else
		player_sound(self, CHAN_WEAPON, "misc/null.wav", VOL_BASE, ATTN_NORM);

	weapon_ready();
}

.float chainsaw_last_hit;
void(void) weapon_chainsaw_attack {
	if (!self.BUTTON_ATCK || self.weapon != self.switchweapon || !player_can_fire(self, TRUE)) {
		weapon_chainsaw_ready();
		return;
	}
	antilag_begin(self);
	weapon_setup_shot(self, 0, "", (self.dmg ? 1 : 0));
	warpzone_trace_line(weapon_shotorg - (weapon_shotdir * 20), weapon_shotorg + weapon_shotdir * g_balance_melee_distance, TRACE_MOVE_NORMAL, self);
	antilag_end();
	if (trace_fraction < 1)
	if (trace_ent)
	if (trace_ent.takedamage)
	if (self.chainsaw_last_hit <= time) {
		self.chainsaw_last_hit = time + g_balance_chainsaw_primary_refire;
		damage_record_hits(self, trace_ent, WEAPON_MELEE, 1, g_balance_chainsaw_primary_damage);
		damage(trace_ent, self, self, g_balance_chainsaw_primary_damage,
				WEAPON_MELEE, trace_endpos, warpzone_transform_velocity(warpzone_trace_transform, weapon_shotdir) * g_balance_chainsaw_primary_force);
	}
	weapon_thinkf(WEAPON_FRAME_FIRE1, 0.05, weapon_chainsaw_attack);
}

float(float req) weapon_chainsaw {
	if (req == WEAPON_REQUEST_AIM) {
		if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
		if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE)) {
			if (g_balance_chainsaw_secondary) {
				if (random() > 0.5)
					self.BUTTON_ATCK = TRUE;
				else
					self.BUTTON_ATCK2 = TRUE;
			} else
				self.BUTTON_ATCK = TRUE;
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.BUTTON_ATCK) {
			if (weapon_prepareattack(0, 0)) {
				player_sound(self, CHAN_WEAPON, "weapons/chainsaw_active_1.wav", VOL_BASE, ATTN_NORM);
				weapon_chainsaw_attack();
			}
		} else if (self.BUTTON_ATCK2 && g_balance_chainsaw_secondary) {
			if (weapon_prepareattack(0, g_balance_melee_refire)) {
				player_sound(self, CHAN_WEAPON, "weapons/chainsaw_active_1.wav", VOL_BASE, ATTN_NORM);
				weapon_melee_attack(1, g_balance_chainsaw_secondary_damage, "");
				weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_melee_animtime, weapon_chainsaw_ready);
			}
		}
	} else if (req == WEAPON_REQUEST_RELOAD) { //same as attack2
		if (g_balance_chainsaw_secondary)
		if (g_balance_melee != 2)
		if (weapon_prepareattack(0, g_balance_melee_refire)) {
			player_sound(self, CHAN_WEAPON, "weapons/chainsaw_active_1.wav", VOL_BASE, ATTN_NORM);
			weapon_melee_attack(1, g_balance_chainsaw_secondary_damage, "");
			weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_melee_animtime, weapon_ready);
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		dlc_require("chainsaw_v2");
		dlc_precache_sound("weapons/chainsaw_idle_1.wav");
		dlc_precache_sound("weapons/chainsaw_active_1.wav");
	} else if (req == WEAPON_REQUEST_SETUP) {
		//weapon_setup(WEAPON_MELEE);
		if (g_balance_chainsaw_noise)
			player_sound(self, CHAN_WEAPON, "weapons/chainsaw_idle_1.wav", VOL_BASE, ATTN_NORM);
	} else if (req == WEAPON_REQUEST_CLEAR) {
		player_sound_stop(self, CHAN_WEAPON);
	} else if (req == WEAPON_REQUEST_CHECKAMMO1)
		return TRUE;
	else if (req == WEAPON_REQUEST_CHECKAMMO2)
		return TRUE;
	else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "rekt himself";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_fragprefix = "^xF80MELEE";
		weapon_deathtypestring = "was butchered by";
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_chainsaw_primary_damage);
		CVAR_CACHE(g_balance_chainsaw_primary_force);
		CVAR_CACHE(g_balance_chainsaw_primary_refire);
		CVAR_CACHE(g_balance_chainsaw_secondary);
		CVAR_CACHE(g_balance_chainsaw_secondary_damage);
		CVAR_CACHE(g_balance_chainsaw_noise);
		weapon_melee_init();
	}
	return TRUE;
}
