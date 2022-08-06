string(float g) game_type_name {
	if (g == GAME_TYPE_DEATHMATCH) return "dm";
	if (g == GAME_TYPE_TEAM_DEATHMATCH) return "tdm";
	if (g == GAME_TYPE_DOMINATION) return "dom";
	if (g == GAME_TYPE_CTF) return "ctf";
	if (g == GAME_TYPE_CATF) return "catf";
	if (g == GAME_TYPE_CTFT) return "ctft";
	if (g == GAME_TYPE_KEYHUNT) return "kh";
	if (g == GAME_TYPE_KEYHUNT_CA) return "khca";
	if (g == GAME_TYPE_KEYHUNT_FT) return "khft";
	if (g == GAME_TYPE_ONSLAUGHT) return "ons";
	if (g == GAME_TYPE_RACE) return "race";
	if (g == GAME_TYPE_NEXBALL) return "nexball";
	if (g == GAME_TYPE_CTS) return "cts";
	if (g == GAME_TYPE_FREEZETAG) return "ft";
	if (g == GAME_TYPE_CLANARENA) return "ca";
	if (g == GAME_TYPE_CONQUEST) return "conq";
	if (g == GAME_TYPE_SURVIVE) return "surv";
	if (g == GAME_TYPE_LMS) return "lms";
	if (g == GAME_TYPE_SINGLE) return "single";
	if (g == GAME_TYPE_COOP) return "coop";
	if (g == GAME_TYPE_SHOOTINGRANGE) return "sr";
	return "dm";
}
