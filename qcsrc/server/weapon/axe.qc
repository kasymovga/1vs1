float g_balance_axe_damage;

void(void) spawnfunc_weapon_axe {
	if (g_balance_melee && g_balance_melee != 2)
		weapon_defaultspawnfunc(WEP_MELEE);
	else
		remove(self);
}

float(float req) weapon_axe {
	if (req == WR_AIM) {
		if (random() < bot_melee_love)
		if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
		if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE))
			self.BUTTON_ATCK = TRUE;
	} else if (req == WR_THINK) {
		if (self.BUTTON_ATCK || self.BUTTON_ATCK2)
		if (weapon_prepareattack(0, g_balance_melee_refire))
		{
			weapon_melee_attack(1, g_balance_axe_damage);
			weapon_thinkf(WFRAME_FIRE1, g_balance_melee_animtime, weapon_ready);
		}
	}
	else if (req == WR_PRECACHE) {
		dlc_require("axe_v2");
	} else if (req == WR_SETUP)
		weapon_setup(WEP_MELEE);
	else if (req == WR_CHECKAMMO1)
		return TRUE;
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "rekt himself";
	else if (req == WR_KILLMESSAGE) {
		w_fragprefix = "^xF80MELEE";
		w_deathtypestring = "was smashed by";
	} else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_axe_damage);
		weapon_melee_init();
	}
	return TRUE;
}
