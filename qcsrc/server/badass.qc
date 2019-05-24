float g_badass_color;
float g_badass_killcount;
float g_badass_leader;
float g_badass_kdr;
float g_badass_health_limit;
float g_badass_armor_limit;

float BadAss_Check() {
	if (g_badass_killcount)
	if (self.killcount >= g_badass_killcount)
		return TRUE;

	if (g_badass_leader)
	if (scores_winning_condition_helper_topscore >= g_badass_leader)
	if (scores_winning_condition_helper_topscore == self.scorekeeper.scores[SP_SCORE])
		return TRUE;

	if (g_badass_kdr) {
		entity sk = self.scorekeeper;
		if (sk.scores[SP_KILLS] / max(sk.scores[SP_DEATHS], 1) >= g_badass_kdr)
			return TRUE;
	}
	return FALSE;
}

var float(float c) BadAss_PlayerColorsMod_NextLink;
float BadAss_PlayerColorsMod(float c) {
	if (BadAss_Check())
		c = g_badass_color;

	return BadAss_PlayerColorsMod_NextLink(c);
}

var void() BadAss_HealthArmorFuelModsSet_NextLink;
void BadAss_HealthArmorFuelModsSet() {
	if (BadAss_Check()) {
		if (g_badass_health_limit)
			self.health = min(g_badass_health_limit, self.health);

		if (g_badass_armor_limit)
			self.armorvalue = min(g_badass_armor_limit, self.armorvalue);
	}
	BadAss_HealthArmorFuelModsSet_NextLink();
}

void BadAss_Init() {
	CACHE_CVAR(g_badass_color);
	CACHE_CVAR(g_badass_killcount);
	CACHE_CVAR(g_badass_kdr);
	CACHE_CVAR(g_badass_leader);
	CACHE_CVAR(g_badass_health_limit);
	CACHE_CVAR(g_badass_armor_limit);
	if (g_badass_color > -2) {
		BadAss_PlayerColorsMod_NextLink = GameHookChain_PlayerColorsMod;
		GameHookChain_PlayerColorsMod = BadAss_PlayerColorsMod;
		if (g_badass_health_limit || g_badass_armor_limit) {
			BadAss_HealthArmorFuelModsSet_NextLink = GameHookChain_HealthArmorFuelModsSet;
			GameHookChain_HealthArmorFuelModsSet = BadAss_HealthArmorFuelModsSet;
		}
	}
}
