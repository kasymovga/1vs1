void() gametype_writecvars {
	float i;
	for (i = GAME_DEATHMATCH; i < GAME_END; i++) {
		cvar_set(MapInfo_GetGameTypeCvar(i), ftos(game == i));
	}
}

void() gametype_readcvars {
	game = GAME_DEATHMATCH;
	teamplay = 0;
	float i;
	for (i = GAME_DEATHMATCH; i < GAME_END; i++) {
		if (cvar(MapInfo_GetGameTypeCvar(i))) {
			game = i;
			break;
		}
	}
}

void() gametype_default_delayed_init {
	if(!score_preinitialized)
		score_generic();

	score_damage_init();
	damage_record_init();
	IP2C_InitSV();
	score_basics_end();
}

float(string s) gametype_value {
	string s2 = cvar_string(strcat("g_", gametype_name(MapInfo_CurrentGametype()), "_", s));
	if (s2 != "")
		return max(0, stof(s2));
	else
		return cvar(strcat("g_", s));
}

void() gametype_init {
	VoteReset();

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
		MapInfo_SwitchGameType(MapInfo_Type_FromString(force_gametype));
	}
	if not(cvar_value_issafe(world.fog)) {
		print("The current map contains a potentially harmful fog setting, ignored\n");
		world.fog = string_null;
	}
	if(MapInfo_Map_fog != "")
		if(MapInfo_Map_fog == "none")
			world.fog = string_null;
		else
			world.fog = strzone(MapInfo_Map_fog);

	clientstuff = strzone(MapInfo_Map_clientstuff);
	MapInfo_ClearTemps();

	// in case mapinfo switched the type
	gametype_readcvars();
	gamemode_name = MapInfo_HumanString_FromType(MapInfo_CurrentGametype());
	if(game == GAME_TEAM_DEATHMATCH) {
		team_play_activate();
		tdm_init();
	}
	if(game == GAME_FREEZETAG) {
		team_play_activate();
		Freeze_Init();
	}
	if(game == GAME_CLANARENA) {
		team_play_activate();
		Clanarena_Init();
	}
	if(game == GAME_DOMINATION) {
		team_play_activate();
		dom_init();
	}
	if(game == GAME_CTF || game == GAME_CATF || game == GAME_CTFT) {
		team_play_activate();
		ctf_init();
	}
	if(game == GAME_KEYHUNT || game == GAME_KEYHUNT_CA || game == GAME_KEYHUNT_FT) {
		team_play_activate();
		kh_init();
	}
	if(game == GAME_ONSLAUGHT) {
		team_play_activate();
		onslaught_init();
	}
	if(game == GAME_RACE || game == GAME_CTS)
		race_init();

	if(game == GAME_NEXBALL) {
		team_play_activate();
		nexball_init();
	}
	if (game == GAME_CONQUEST) {
		team_play_activate();
		conquest_init();
	}
	if (game == GAME_SURVIVE) {
		team_play_activate();
		survive_init();
	}
	if (game == GAME_SINGLE || game == GAME_COOP)
		Single_Init();

	if(teamplay)
		entcs_init();

	// save it (for the next startup)
	cvar_set("gamecfg", ftos(game));

	// enforce the server's universal frag/time limits
	entity_initialize(world, gametype_default_delayed_init, INITPRIO_GAMETYPE_FALLBACK);
	if (force_gametype_restore)
		MapInfo_SwitchGameType(force_gametype_restore);

	gametype_writecvars();
	cvar_init(g_campaign ? "campaign" : cvar_string("g_profile"));
	cvar_set("timelimit", ftos(gametype_value("timelimit")));
	cvar_set("fraglimit", ftos(gametype_value("scorelimit")));
	cvar_set("leadlimit", ftos(gametype_value("leadlimit")));
}
