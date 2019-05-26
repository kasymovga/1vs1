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
	if(!scores_preinitialized)
		scores_generic();

	ScoreDamage_Init();
	damage_record_init();
	IP2C_InitSV();
	scores_basics_end();
}

void() gametype_init {
	float fraglimit_override, timelimit_override, leadlimit_override;
	VoteReset();

	// make sure only ONE type is selected
	gametype_readcvars();

	// find out good world mins/maxs bounds, either the static bounds found by looking for solid, or the mapinfo specified bounds
	get_mi_min_max(1);
	world.mins = mi_min;
	world.maxs = mi_max;
	cvar_set("timelimit", cvar_string("timelimit_default"));
	cvar_set("fraglimit", cvar_string("fraglimit_default"));
	MapInfo_LoadMapSettings(mapname);
	if (MapInfo_Map_description == "<DESCRIPTION>")
		map_description = "";
	else
		map_description = zone_ifneeded(MapInfo_Map_description);

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
		ActivateTeamplay();
		GameHook_FragLimitOverride = tdm_FragLimitOverride;
		tdm_init();
	}
	if(game == GAME_FREEZETAG) {
		ActivateTeamplay();
		Freeze_Init();
	}
	if(game == GAME_CLANARENA) {
		ActivateTeamplay();
		Clanarena_Init();
	}
	if(game == GAME_DOMINATION) {
		ActivateTeamplay();
		dom_init();
	}
	if(game == GAME_CTF || game == GAME_CATF || game == GAME_CTFT) {
		ActivateTeamplay();
		ctf_init();
	}
	if(game == GAME_KEYHUNT || game == GAME_KEYHUNT_CA || game == GAME_KEYHUNT_FT) {
		ActivateTeamplay();
		kh_init();
	}
	if(game == GAME_ONSLAUGHT) {
		ActivateTeamplay();
		onslaught_init();
	}
	if(game == GAME_RACE || game == GAME_CTS)
		race_init();

	if(game == GAME_NEXBALL) {
		ActivateTeamplay();
		nb_init();
	}
	if (game == GAME_CONQUEST) {
		ActivateTeamplay();
		conquest_init();
	}
	if (game == GAME_SURVIVE) {
		ActivateTeamplay();
		survive_init();
	}
	if (game == GAME_SINGLE || game == GAME_COOP)
		Single_Init();

	if(teamplay)
		entcs_init();

	// save it (for the next startup)
	cvar_set("gamecfg", ftos(game));

	// enforce the server's universal frag/time limits
	if(!g_campaign)
	{
		timelimit_override = GameHook_TimeLimitOverride();
		fraglimit_override = GameHook_FragLimitOverride();
		leadlimit_override = GameHook_LeadLimitOverride();
		if(fraglimit_override >= 0)
			cvar_set("fraglimit", ftos(fraglimit_override));
		if(timelimit_override >= 0)
			cvar_set("timelimit", ftos(timelimit_override));
		if(leadlimit_override >= 0)
			cvar_set("leadlimit", ftos(leadlimit_override));
	}
	entity_initialize(world, gametype_default_delayed_init, INITPRIO_GAMETYPE_FALLBACK);
	if (force_gametype_restore)
		MapInfo_SwitchGameType(force_gametype_restore);

	gametype_writecvars();
}
