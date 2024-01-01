float g_balance_pryaxe_primary_animtime;
float g_balance_pryaxe_primary_damage;
float g_balance_pryaxe_primary_refire;
float g_balance_pryaxe_secondary_animtime;
float g_balance_pryaxe_secondary_damage;
float g_balance_pryaxe_secondary_refire;

var .float pryaxe_buttonatck1;
var .float pryaxe_buttonatck2;

void(void) spawnfunc_weapon_pryaxe {
	if (g_balance_melee && g_balance_melee != 2)
		weapon_defaultspawnfunc(WEAPON_MELEE);
	else
		remove(self);
}

float(float req) weapon_pryaxe {
	if (req == WEAPON_REQUEST_AIM) {
		if (random() < bot_melee_love)
		if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
		if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE))
			self.BUTTON_ATCK = TRUE;
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.pryaxe_buttonatck1) {
			if (weapon_prepareattack(0, g_balance_pryaxe_primary_refire)) {
				weapon_melee_attack(1, g_balance_pryaxe_primary_damage, "nexball/shoot2.wav");
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_pryaxe_primary_animtime, weapon_ready);
			}
		}
		if (self.pryaxe_buttonatck2) {
			if (weapon_prepareattack(0, g_balance_pryaxe_secondary_refire)) {
				weapon_melee_attack(1, g_balance_pryaxe_secondary_damage, "nexball/shoot2.wav");
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_pryaxe_secondary_animtime, weapon_ready);
			}
		}
	} else if (req == WEAPON_REQUEST_RELOAD) {
		if (g_balance_melee != 2)
		if (weapon_prepareattack(0, g_balance_pryaxe_primary_refire)) {
			weapon_melee_attack(1, g_balance_pryaxe_primary_damage, "nexball/shoot2.wav");
			weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_pryaxe_primary_animtime, weapon_ready);
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_sound("nexball/shoot2.wav");
		dlc_require("axe_v2");
	} else if (req == WEAPON_REQUEST_SETUP) {
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "rekt himself";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_fragprefix = "^xF80MELEE";
		weapon_deathtypestring = "was smashed by";
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_pryaxe_primary_animtime);
		CVAR_CACHE(g_balance_pryaxe_primary_damage);
		CVAR_CACHE(g_balance_pryaxe_primary_refire);
		CVAR_CACHE(g_balance_pryaxe_secondary_animtime);
		CVAR_CACHE(g_balance_pryaxe_secondary_damage);
		CVAR_CACHE(g_balance_pryaxe_secondary_refire);
		if (cvar("g_balance_pryaxe_swap_buttons")) {
			pryaxe_buttonatck1 = BUTTON_ATCK2;
			pryaxe_buttonatck2 = BUTTON_ATCK;
		} else {
			pryaxe_buttonatck1 = BUTTON_ATCK;
			pryaxe_buttonatck2 = BUTTON_ATCK2;
		}
		weapon_melee_init();
	}
	return TRUE;
}
