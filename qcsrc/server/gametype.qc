void() gametype_writecvars {
	gametype_switch(gametype);
}

void() gametype_readcvars {
	gametype = gametype_current();
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
	string s2 = cvar_string(strcat("g_", gametype_name(gametype_current()), "_", s));
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
	map_info_load_map_settings(mapname);
	if (map_info_map_description == "<DESCRIPTION>")
		map_description = "";
	else
		map_description = str_zone_ifneeded(map_info_map_description);

	float force_gametype_restore = 0;
	string force_gametype = cvar_string("force_gametype");
	if (force_gametype != "") {
		force_gametype_restore = gametype_current();
		gametype_switch(gametype_from_name(force_gametype));
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
	gametype_readcvars();
	gametype_title = gametype_name_long(gametype_current());
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
		gametype_switch(force_gametype_restore);

	print("--- Game started ---\n   Map: ", mapname, "\n  Mode: ", gametype_name_long(gametype), "\n");
	gametype_writecvars();
	cvar_init(g_campaign ? strcat("campaign+", cvar_string("g_profile")) : cvar_string("g_profile"));
	cvar_set("timelimit", ftos(gametype_value("timelimit")));
	cvar_set("fraglimit", ftos(gametype_value("scorelimit")));
	cvar_set("leadlimit", ftos(gametype_value("leadlimit")));
}
