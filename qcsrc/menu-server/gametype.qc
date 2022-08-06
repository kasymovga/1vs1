float(string t) gametype_from_name {
	if (t == "dm") return GAMETYPE_DEATHMATCH;
	if (t == "tdm") return GAMETYPE_TEAM_DEATHMATCH;
	if (t == "ft" ||
			t == "freeze" ||
			t == "frezetag") return GAMETYPE_FREEZETAG;
	if (t == "ca" ||
			t == "clanarena") return GAMETYPE_CLANARENA;
	if (t == "dom" ||
			t == "domination") return GAMETYPE_DOMINATION;
	if (t == "ctf") return GAMETYPE_CTF;
	if (t == "catf") return GAMETYPE_CATF;
	if (t == "ctft") return GAMETYPE_CTFT;
	if (t == "conq" ||
			t == "conquest") return GAMETYPE_CONQUEST;
	if (t == "kh" ||
			t == "keyhunt") return GAMETYPE_KEYHUNT;
	if (t == "khca") return GAMETYPE_KEYHUNT_CA;
	if (t == "khft") return GAMETYPE_KEYHUNT_FT;
	if (t == "ons" ||
			t == "onslaught") return GAMETYPE_ONSLAUGHT;
	if (t == "rc" ||
			t == "race") return GAMETYPE_RACE;
	if (t == "nexball" ||
			t == "nb" ) return GAMETYPE_NEXBALL;
	if (t == "cts") return GAMETYPE_CTS;
	if (t == "lms") return GAMETYPE_LMS;
	if (t == "surv" ||
			t == "survive") return GAMETYPE_SURVIVE;
	if (t == "single") return GAMETYPE_SINGLE;
	if (t == "coop") return GAMETYPE_COOP;
	if (t == "shootingrange" || t == "sr") return GAMETYPE_SHOOTINGRANGE;
	return 0;
}

string(float t) gametype_name_long {
	if (t == GAMETYPE_DEATHMATCH) {
		return "Deathmatch";
	} else if (t == GAMETYPE_DOMINATION) {
		return "Domination";
	} else if (t == GAMETYPE_TEAM_DEATHMATCH) {
		return "Team Deathmatch";
	} else if (t == GAMETYPE_CTF) {
		return "Capture The Flag";
	} else if (t == GAMETYPE_CATF) {
		return "CTF with CA";
	} else if (t == GAMETYPE_CTFT) {
		return "CTF with FT";
	} else if (t == GAMETYPE_CONQUEST) {
		return "Conquest";
	} else if (t == GAMETYPE_NEXBALL) {
		return "Nexball";
	} else if (t == GAMETYPE_ONSLAUGHT) {
		return "Onslaught";
	} else if (t == GAMETYPE_KEYHUNT) {
		return "Key Hunt";
	} else if (t == GAMETYPE_KEYHUNT_CA) {
		return "Key Hunt with CA";
	} else if (t == GAMETYPE_KEYHUNT_FT) {
		return "Key Hunt with FT";
	} else if (t == GAMETYPE_CTS) {
		return "CTS";
	} else if (t == GAMETYPE_RACE) {
		return "Race";
	} else if (t == GAMETYPE_FREEZETAG) {
		return "Freeze Tag";
	} else if (t == GAMETYPE_CLANARENA) {
		return "Clan Arena";
	} else if (t == GAMETYPE_SURVIVE) {
		return "Survival";
	} else if (t == GAMETYPE_LMS) {
		return "Last Man Standing";
	} else if (t == GAMETYPE_SINGLE) {
		return "Single Player";
	} else if (t == GAMETYPE_COOP) {
		return "Cooperative";
	} else if (t == GAMETYPE_SHOOTINGRANGE) {
		return "Shooting Range";
	}
	return "WTF";
}

float(void) gametype_current {
	float f = gametype_from_name(cvar_string("_gametype"));
	return (f ? f : GAMETYPE_DEATHMATCH);
}

void(float t) gametype_switch {
	cvar_set("_gametype", gametype_name(t));
}
