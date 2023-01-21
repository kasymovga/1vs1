float g_badass_color;
float g_badass_killcount;
float g_badass_leader;
float g_badass_kdr;
float g_badass_health_limit;
float g_badass_armor_limit;

float(void) badass_check {
	if (g_badass_killcount)
	if (self.killcount >= g_badass_killcount)
		return TRUE;

	if (g_badass_leader)
	if (score_winning_condition_helper_topscore >= g_badass_leader)
	if (score_winning_condition_helper_topscore == self.scorekeeper.scores[SP_SCORE])
		return TRUE;

	if (g_badass_kdr) {
		entity sk = self.scorekeeper;
		if (sk.scores[SP_KILLS] / max(sk.scores[SP_DEATHS], 1) >= g_badass_kdr)
			return TRUE;
	}
	return FALSE;
}

var float(float c) badass_player_colors_mod_next;
float badass_player_colors_mod(float c) {
	if (badass_check())
		c = g_badass_color;

	return badass_player_colors_mod_next(c);
}

var void() badass_player_health_armor_mods_set_next;
void() badass_player_health_armor_mods_set {
	if (badass_check()) {
		if (g_badass_health_limit)
			self.health = min(g_badass_health_limit, self.health);

		if (g_badass_armor_limit)
			self.armorvalue = min(g_badass_armor_limit, self.armorvalue);
	}
	badass_player_health_armor_mods_set_next();
}

void(void) badass_init {
	CVAR_CACHE(g_badass_color);
	CVAR_CACHE(g_badass_killcount);
	CVAR_CACHE(g_badass_kdr);
	CVAR_CACHE(g_badass_leader);
	CVAR_CACHE(g_badass_health_limit);
	CVAR_CACHE(g_badass_armor_limit);
	if (g_badass_color > -2) {
		badass_player_colors_mod_next = plugin_chain_player_colors_mod;
		plugin_chain_player_colors_mod = badass_player_colors_mod;
		if (g_badass_health_limit || g_badass_armor_limit) {
			badass_player_health_armor_mods_set_next = plugin_chain_player_health_armor_mods_set;
			plugin_chain_player_health_armor_mods_set = badass_player_health_armor_mods_set;
		}
	}
}
