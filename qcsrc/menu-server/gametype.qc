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
