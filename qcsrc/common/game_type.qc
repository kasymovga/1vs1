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
	if (g == GAME_TYPE_CHESS) return "chess";
	if (g == GAME_TYPE_JAILBREAK) return "jb";
	return "dm";
}

string(float t) game_type_name_long {
	if (t == GAME_TYPE_DEATHMATCH) {
		return "Deathmatch";
	} else if (t == GAME_TYPE_DOMINATION) {
		return "Domination";
	} else if (t == GAME_TYPE_TEAM_DEATHMATCH) {
		return "Team Deathmatch";
	} else if (t == GAME_TYPE_CTF) {
		return "Capture The Flag";
	} else if (t == GAME_TYPE_CATF) {
		return "CTF with CA";
	} else if (t == GAME_TYPE_CTFT) {
		return "CTF with FT";
	} else if (t == GAME_TYPE_CONQUEST) {
		return "Conquest";
	} else if (t == GAME_TYPE_NEXBALL) {
		return "Nexball";
	} else if (t == GAME_TYPE_ONSLAUGHT) {
		return "Onslaught";
	} else if (t == GAME_TYPE_KEYHUNT) {
		return "Key Hunt";
	} else if (t == GAME_TYPE_KEYHUNT_CA) {
		return "Key Hunt with CA";
	} else if (t == GAME_TYPE_KEYHUNT_FT) {
		return "Key Hunt with FT";
	} else if (t == GAME_TYPE_CTS) {
		return "CTS";
	} else if (t == GAME_TYPE_RACE) {
		return "Race";
	} else if (t == GAME_TYPE_FREEZETAG) {
		return "Freeze Tag";
	} else if (t == GAME_TYPE_CLANARENA) {
		return "Clan Arena";
	} else if (t == GAME_TYPE_SURVIVE) {
		return "Survival";
	} else if (t == GAME_TYPE_LMS) {
		return "Last Man Standing";
	} else if (t == GAME_TYPE_SINGLE) {
		return "Single Player";
	} else if (t == GAME_TYPE_COOP) {
		return "Cooperative";
	} else if (t == GAME_TYPE_SHOOTINGRANGE) {
		return "Shooting Range";
	} else if (t == GAME_TYPE_CHESS) {
		return "Chess";
	} else if (t == GAME_TYPE_JAILBREAK) {
		return "Jail Break";
	}
	return "WTF";
}
