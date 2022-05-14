float g_balance_chainsaw_damage;

void(void) spawnfunc_weapon_chainsaw {
	if (g_balance_melee && g_balance_melee != 2)
		weapon_defaultspawnfunc(WEP_MELEE);
	else
		remove(self);
}

float(float req) weapon_chainsaw {
	if (req == WR_AIM) {
		if (random() < bot_melee_love)
		if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
		if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE))
			self.BUTTON_ATCK = TRUE;
	} else if (req == WR_THINK) {
		if (self.BUTTON_ATCK || self.BUTTON_ATCK2)
		if (weapon_prepareattack(0, g_balance_melee_refire)) {
			weapon_melee_attack(1, g_balance_chainsaw_damage, "weapons/powersaw_spinup_spindown.ogg");
			weapon_thinkf(WFRAME_FIRE1, g_balance_melee_animtime, weapon_ready);
		}
	} else if (req == WR_RELOAD) {
		if (g_balance_melee != 2)
		if (weapon_prepareattack(0, g_balance_melee_refire)) {
			weapon_melee_attack(1, g_balance_chainsaw_damage, "weapons/powersaw_spinup_spindown.ogg");
			weapon_thinkf(WFRAME_FIRE1, g_balance_melee_animtime, weapon_ready);
		}
	} else if (req == WR_PRECACHE) {
		dlc_require("chainsaw");
		dlc_precache_sound("weapons/powersaw_spinup_spindown.ogg");
	} else if (req == WR_SETUP)
		weapon_setup(WEP_MELEE);
	else if (req == WR_CHECKAMMO1)
		return TRUE;
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		weapon_deathtypestring = "rekt himself";
	else if (req == WR_KILLMESSAGE) {
		weapon_fragprefix = "^xF80MELEE";
		weapon_deathtypestring = "was butchered by";
	} else if (req == WR_CVAR_CACHE) {
		CVAR_CACHE(g_balance_chainsaw_damage);
		weapon_melee_init();
	}
	return TRUE;
}
