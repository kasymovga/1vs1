float g_badass_color;
float g_badass_killcount;
float g_badass_leader;
float g_badass_kdr;

var float(float c) BadAss_PlayerColorsMod_NextLink;
float BadAss_PlayerColorsMod(float c) {
	if (g_badass_killcount)
	if (self.killcount >= g_badass_killcount)
		c = g_badass_color;

	if (g_badass_leader)
	if (WinningConditionHelper_topscore >= g_badass_leader)
	if (WinningConditionHelper_topscore == self.scorekeeper.scores[SP_SCORE])
		c = g_badass_color;

	if (g_badass_kdr) {
		entity sk = self.scorekeeper;
		if (sk.scores[SP_KILLS] / max(sk.scores[SP_DEATHS], 1) >= g_badass_kdr)
			c = g_badass_color;
	}
	return BadAss_PlayerColorsMod_NextLink(c);
}

void BadAss_Init() {
	CACHE_CVAR(g_badass_color);
	CACHE_CVAR(g_badass_killcount);
	CACHE_CVAR(g_badass_kdr);
	CACHE_CVAR(g_badass_leader);
	//CACHE_CVAR(g_badass_leader);
	if (g_badass_color > -2) {
		BadAss_PlayerColorsMod_NextLink = GameHookChain_PlayerColorsMod;
		GameHookChain_PlayerColorsMod = BadAss_PlayerColorsMod;
	}
}
