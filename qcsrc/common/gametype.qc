string(float g) gametype_name {
	if      (g == GAME_DEATHMATCH) return "dm";
	else if (g == GAME_TEAM_DEATHMATCH) return "tdm";
	else if (g == GAME_DOMINATION) return "dom";
	else if (g == GAME_CTF) return "ctf";
	else if (g == GAME_CATF) return "catf";
	else if (g == GAME_CTFT) return "ctft";
	else if (g == GAME_KEYHUNT) return "kh";
	else if (g == GAME_KEYHUNT_CA) return "khca";
	else if (g == GAME_KEYHUNT_FT) return "khft";
	else if (g == GAME_ONSLAUGHT) return "ons";
	else if (g == GAME_RACE) return "race";
	else if (g == GAME_NEXBALL) return "nexball";
	else if (g == GAME_CTS) return "cts";
	else if (g == GAME_FREEZETAG) return "ft";
	else if (g == GAME_CLANARENA) return "ca";
	else if (g == GAME_CONQUEST) return "conq";
	else if (g == GAME_SURVIVE) return "surv";
	else if (g == GAME_SINGLE) return "single";
	else if (g == GAME_COOP) return "coop";
	return "dm";
}
