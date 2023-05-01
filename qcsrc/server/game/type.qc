void() game_type_writecvars {
	game_type_switch(game_type);
}

void() game_type_readcvars {
	game_type = game_type_current();
}

void() game_type_default_delayed_init {
	if(!score_preinitialized)
		score_generic();

	score_basics_end();
}

float(string s) game_type_value {
	string s2 = cvar_string(strcat("g_", game_type_name(game_type_current()), "_", s));
	if (s2 != "")
		return max(0, stof(s2));
	else
		return max(0, cvar(strcat("g_", s)));
}

void() game_type_init {
	registercvar("_gametype", "dm");
	vote_reset();
	// make sure only ONE type is selected
	game_type_readcvars();
	map_info_load_map_settings(mapname);
	if (map_info_map_description == "<DESCRIPTION>")
		map_description = "";
	else
		map_description = str_zone_ifneeded(map_info_map_description);

	float force_gametype_restore = 0;
	string force_gametype = cvar_string("force_gametype");
	if (force_gametype != "") {
		force_gametype_restore = game_type_current();
		game_type_switch(game_type_from_name(force_gametype));
	}
	if not(cvar_value_issafe(world.fog)) {
		print("The current map contains a potentially harmful fog setting, ignored\n");
		world.fog = NULL;
	}
	if (map_info_map_fog != "")
		if (map_info_map_fog == "none")
			world.fog = NULL;
		else
			world.fog = strzone(map_info_map_fog);

	client_stuff = strzone(map_info_map_clientstuff);
	map_info_clear_temps();
	// in case mapinfo switched the type
	game_type_readcvars();
	game_type_title = game_type_name_long(game_type_current());
	if(game_type == GAME_TYPE_TEAM_DEATHMATCH) {
		team_play_activate();
		tdm_init();
	} else if(game_type == GAME_TYPE_FREEZETAG) {
		team_play_activate();
		freeze_init();
	} else if(game_type == GAME_TYPE_CLANARENA) {
		team_play_activate();
		clanarena_init();
	} else if(game_type == GAME_TYPE_DOMINATION) {
		team_play_activate();
		dom_init();
	} else if(game_type == GAME_TYPE_CTF || game_type == GAME_TYPE_CATF || game_type == GAME_TYPE_CTFT) {
		team_play_activate();
		ctf_init();
	} else if(game_type == GAME_TYPE_KEYHUNT || game_type == GAME_TYPE_KEYHUNT_CA || game_type == GAME_TYPE_KEYHUNT_FT) {
		team_play_activate();
		kh_init();
	} else if(game_type == GAME_TYPE_ONSLAUGHT) {
		team_play_activate();
		onslaught_init();
	} else if(game_type == GAME_TYPE_RACE || game_type == GAME_TYPE_CTS) {
		race_init();
	} else if(game_type == GAME_TYPE_NEXBALL) {
		team_play_activate();
		nexball_init();
	} else if (game_type == GAME_TYPE_CONQUEST) {
		team_play_activate();
		conquest_init();
	} else if (game_type == GAME_TYPE_SURVIVE) {
		team_play_activate();
		survive_init();
	} else if (game_type == GAME_TYPE_SHOOTINGRANGE) {
		shootingrange_init();
	} else if (game_type == GAME_TYPE_SINGLE) {
		single_init();
	} else if (game_type == GAME_TYPE_COOP) {
		coop_init();
	} else if (game_type == GAME_TYPE_LMS) {
		lms_init();
	} else if (game_type == GAME_TYPE_CHESS) {
		team_play_activate();
		chess_init();
	}
	// enforce the server's universal frag/time limits
	entity_initialize(world, game_type_default_delayed_init, INITPRIO_GAMETYPE_FALLBACK);
	if (force_gametype_restore)
		game_type_switch(force_gametype_restore);

	print("--- Game started ---\n   Map: ", mapname, "\n  Mode: ", game_type_name_long(game_type), "\n");
	game_type_writecvars();
	cvar_init(g_campaign ? strcat("campaign+", cvar_string("g_profile")) : cvar_string("g_profile"));
	cvar_set("timelimit", ftos(game_type_value("timelimit")));
	cvar_set("fraglimit", ftos(game_type_value("scorelimit")));
	cvar_set("leadlimit", ftos(game_type_value("leadlimit")));
}
