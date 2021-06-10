string(float g) gametype_name {
	if      (g == GAMETYPE_DEATHMATCH) return "dm";
	else if (g == GAMETYPE_TEAM_DEATHMATCH) return "tdm";
	else if (g == GAMETYPE_DOMINATION) return "dom";
	else if (g == GAMETYPE_CTF) return "ctf";
	else if (g == GAMETYPE_CATF) return "catf";
	else if (g == GAMETYPE_CTFT) return "ctft";
	else if (g == GAMETYPE_KEYHUNT) return "kh";
	else if (g == GAMETYPE_KEYHUNT_CA) return "khca";
	else if (g == GAMETYPE_KEYHUNT_FT) return "khft";
	else if (g == GAMETYPE_ONSLAUGHT) return "ons";
	else if (g == GAMETYPE_RACE) return "race";
	else if (g == GAMETYPE_NEXBALL) return "nexball";
	else if (g == GAMETYPE_CTS) return "cts";
	else if (g == GAMETYPE_FREEZETAG) return "ft";
	else if (g == GAMETYPE_CLANARENA) return "ca";
	else if (g == GAMETYPE_CONQUEST) return "conq";
	else if (g == GAMETYPE_SURVIVE) return "surv";
	else if (g == GAMETYPE_LMS) return "lms";
	else if (g == GAMETYPE_SINGLE) return "single";
	else if (g == GAMETYPE_COOP) return "coop";
	return "dm";
}
