float(string t) game_type_from_name {
	if (t == "dm") return GAME_TYPE_DEATHMATCH;
	if (t == "tdm") return GAME_TYPE_TEAM_DEATHMATCH;
	if (t == "ft" ||
			t == "freeze" ||
			t == "frezetag") return GAME_TYPE_FREEZETAG;
	if (t == "ca" ||
			t == "clanarena") return GAME_TYPE_CLANARENA;
	if (t == "dom" ||
			t == "domination") return GAME_TYPE_DOMINATION;
	if (t == "ctf") return GAME_TYPE_CTF;
	if (t == "catf") return GAME_TYPE_CATF;
	if (t == "ctft") return GAME_TYPE_CTFT;
	if (t == "conq" ||
			t == "conquest") return GAME_TYPE_CONQUEST;
	if (t == "kh" ||
			t == "keyhunt") return GAME_TYPE_KEYHUNT;
	if (t == "khca") return GAME_TYPE_KEYHUNT_CA;
	if (t == "khft") return GAME_TYPE_KEYHUNT_FT;
	if (t == "ons" ||
			t == "onslaught") return GAME_TYPE_ONSLAUGHT;
	if (t == "rc" ||
			t == "race") return GAME_TYPE_RACE;
	if (t == "nexball" ||
			t == "nb" ) return GAME_TYPE_NEXBALL;
	if (t == "cts") return GAME_TYPE_CTS;
	if (t == "lms") return GAME_TYPE_LMS;
	if (t == "surv" ||
			t == "survive") return GAME_TYPE_SURVIVE;
	if (t == "single") return GAME_TYPE_SINGLE;
	if (t == "coop") return GAME_TYPE_COOP;
	if (t == "shootingrange" || t == "sr") return GAME_TYPE_SHOOTINGRANGE;
	if (t == "chess") return GAME_TYPE_CHESS;
	return 0;
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
	}
	return "WTF";
}

float(void) game_type_current {
	float f = game_type_from_name(cvar_string("_gametype"));
	return (f ? f : GAME_TYPE_DEATHMATCH);
}

void(float t) game_type_switch {
	cvar_set("_gametype", game_type_name(t));
}
