string(float g) gametype_name {
	if (g == GAMETYPE_DEATHMATCH) return "dm";
	if (g == GAMETYPE_TEAM_DEATHMATCH) return "tdm";
	if (g == GAMETYPE_DOMINATION) return "dom";
	if (g == GAMETYPE_CTF) return "ctf";
	if (g == GAMETYPE_CATF) return "catf";
	if (g == GAMETYPE_CTFT) return "ctft";
	if (g == GAMETYPE_KEYHUNT) return "kh";
	if (g == GAMETYPE_KEYHUNT_CA) return "khca";
	if (g == GAMETYPE_KEYHUNT_FT) return "khft";
	if (g == GAMETYPE_ONSLAUGHT) return "ons";
	if (g == GAMETYPE_RACE) return "race";
	if (g == GAMETYPE_NEXBALL) return "nexball";
	if (g == GAMETYPE_CTS) return "cts";
	if (g == GAMETYPE_FREEZETAG) return "ft";
	if (g == GAMETYPE_CLANARENA) return "ca";
	if (g == GAMETYPE_CONQUEST) return "conq";
	if (g == GAMETYPE_SURVIVE) return "surv";
	if (g == GAMETYPE_LMS) return "lms";
	if (g == GAMETYPE_SINGLE) return "single";
	if (g == GAMETYPE_COOP) return "coop";
	if (g == GAMETYPE_SHOOTINGRANGE) return "sr";
	return "dm";
}
