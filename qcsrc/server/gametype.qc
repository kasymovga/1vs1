void() gametype_writecvars {
	MapInfo_SwitchGameType(gametype);
}

void() gametype_readcvars {
	gametype = MapInfo_CurrentGametype();
}

void() gametype_default_delayed_init {
	if(!score_preinitialized)
		score_generic();

	score_damage_init();
	damage_record_init();
	client_version_init();
	IP2C_InitSV();
	score_basics_end();
}

float(string s) gametype_value {
	string s2 = cvar_string(strcat("g_", gametype_name(MapInfo_CurrentGametype()), "_", s));
	if (s2 != "")
		return max(0, stof(s2));
	else
		return max(0, cvar(strcat("g_", s)));
}

void() gametype_init {
	registercvar("_gametype", "dm");
	vote_reset();
	// make sure only ONE type is selected
	gametype_readcvars();
	MapInfo_LoadMapSettings(mapname);
	if (MapInfo_Map_description == "<DESCRIPTION>")
		map_description = "";
	else
		map_description = str_zone_ifneeded(MapInfo_Map_description);

	float force_gametype_restore = 0;
	string force_gametype = cvar_string("force_gametype");
	if (force_gametype != "") {
		force_gametype_restore = MapInfo_CurrentGametype();
		MapInfo_SwitchGameType(gametype_from_name(force_gametype));
	}
	if not(cvar_value_issafe(world.fog)) {
		print("The current map contains a potentially harmful fog setting, ignored\n");
		world.fog = NULL;
	}
	if(MapInfo_Map_fog != "")
		if(MapInfo_Map_fog == "none")
			world.fog = NULL;
		else
			world.fog = strzone(MapInfo_Map_fog);

	client_stuff = strzone(MapInfo_Map_clientstuff);
	MapInfo_ClearTemps();

	// in case mapinfo switched the type
	gametype_readcvars();
	gametype_title = MapInfo_HumanString_FromType(MapInfo_CurrentGametype());
	if(gametype == GAMETYPE_TEAM_DEATHMATCH) {
		team_play_activate();
		tdm_init();
	} else if(gametype == GAMETYPE_FREEZETAG) {
		team_play_activate();
		freeze_init();
	} else if(gametype == GAMETYPE_CLANARENA) {
		team_play_activate();
		clanarena_init();
	} else if(gametype == GAMETYPE_DOMINATION) {
		team_play_activate();
		dom_init();
	} else if(gametype == GAMETYPE_CTF || gametype == GAMETYPE_CATF || gametype == GAMETYPE_CTFT) {
		team_play_activate();
		ctf_init();
	} else if(gametype == GAMETYPE_KEYHUNT || gametype == GAMETYPE_KEYHUNT_CA || gametype == GAMETYPE_KEYHUNT_FT) {
		team_play_activate();
		kh_init();
	} else if(gametype == GAMETYPE_ONSLAUGHT) {
		team_play_activate();
		onslaught_init();
	} else if(gametype == GAMETYPE_RACE || gametype == GAMETYPE_CTS) {
		race_init();
	} else if(gametype == GAMETYPE_NEXBALL) {
		team_play_activate();
		nexball_init();
	} else if (gametype == GAMETYPE_CONQUEST) {
		team_play_activate();
		conquest_init();
	} else if (gametype == GAMETYPE_SURVIVE) {
		team_play_activate();
		survive_init();
	} else if (gametype == GAMETYPE_SHOOTINGRANGE) {
		shootingrange_init();
	} else if (gametype == GAMETYPE_SINGLE) {
		single_init();
	} else if (gametype == GAMETYPE_COOP) {
		coop_init();
	} else if (gametype == GAMETYPE_LMS) {
		lms_init();
	}
	// enforce the server's universal frag/time limits
	entity_initialize(world, gametype_default_delayed_init, INITPRIO_GAMETYPE_FALLBACK);
	if (force_gametype_restore)
		MapInfo_SwitchGameType(force_gametype_restore);

	print("--- Game started ---\n   Map: ", mapname, "\n  Mode: ", MapInfo_HumanString_FromType(gametype), "\n");
	gametype_writecvars();
	cvar_init(g_campaign ? strcat("campaign+", cvar_string("g_profile")) : cvar_string("g_profile"));
	cvar_set("timelimit", ftos(gametype_value("timelimit")));
	cvar_set("fraglimit", ftos(gametype_value("scorelimit")));
	cvar_set("leadlimit", ftos(gametype_value("leadlimit")));
}
