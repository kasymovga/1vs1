entity cmd_spawnentity;
void(void) cmd_spawnentity_draw {
	R_AddEntity(self);
}

void(string msg) GameCommand { //called by engine
	float argc;
	argc = tokenize_console(msg);
	if (argv(0) == "help" || argc == 0) {
		print("Usage: cl_cmd COMMAND..., where possible commands are:\n");
		print("  settemp cvar value\n");
		print("  radar\n");
		print("  sbar_columns_set ...\n");
		print("  sbar_columns_help\n");
		return;
	}
	string cmd;
	cmd = argv(0);
	if (cmd == "mv_download") {
		map_vote_preview_download(argc);
	} else if (cmd == "settemp") {
		cvar_clientsettemp(argv(1), argv(2));
	} else if (cmd == "radar") {
		teamradar_show = !teamradar_show;
	} else if (cmd == "sbar_columns_set") {
		sbar_field_set(argc);
	} else if (cmd == "sbar_columns_help") {
		sbar_help(argc);
	} else if (cmd == "sendcvar") {
	} else if (cmd == "handlevote") {
		localcmd(strcat("cmd vote ", argv(1), "\n"));
	} else if(cmd == "modelprecache") {
		precache_model(argv(1));
	} else if (cmd == "spawnentity") {
		if (cmd_spawnentity)
			remove(cmd_spawnentity);

		cmd_spawnentity = spawn();
		cmd_spawnentity.draw = cmd_spawnentity_draw;
		setorigin(cmd_spawnentity, view_origin + view_forward * 100);
		precache_model(argv(1));
		setmodel(cmd_spawnentity, argv(1));
		cmd_spawnentity.frame = stof(argv(2));
	} else if (cmd == "showradio") {
		GUI_Show(GUI_RADIO);
	} else if (cmd == "report") {
		float i;
		if (argc > REPORT_REASONS_COUNT_MAX - 1)
			argc = REPORT_REASONS_COUNT_MAX - 1;

		report_reasons_count = argc - 1;
		for (i = 1; i < argc; i++) {
			str_unzone_ifneeded(report_reasons[i]);
			report_reasons[i - 1] = str_zone_ifneeded(argv(i));
		}
		for (; i < REPORT_REASONS_COUNT_MAX; i++) {
			str_unzone_ifneeded(report_reasons[i]);
			report_reasons[i] = "";
		}
		GUI_Show(GUI_REPORT);
	} else if (cmd == "recordlist") {
		GUI_Show(GUI_RECORDLIST);
	} else if (cmd == "r_restart") {
		waypointsprite_init();
		draw_init();
		weapon_update_icons();
	} else if (cmd == "mute" && argc == 2) {
		mute_add(rint(stof(argv(1))));
	} else if (cmd == "unmute" && argc == 2) {
		mute_remove(rint(stof(argv(1))));
	} else if (cmd == "sbar_reset") {
		sbar_set_defaults();
	} else if (cmd == "sbar_save" && argc == 2) {
		sbar_save(strcat(argv(1), ".hud"));
	} else if (cmd == "sbar_load" && argc == 2) {
		sbar_load(strcat("data/", argv(1), ".hud"));
	} else if (cmd == "rm_skin_load" && argc == 2) {
		string s = argv(1);
		if (rm_skin_load(s))
			cvar_set("cl_rm_skin", s);
	} else if (cmd == "rm_skin_unload" && argc == 1) {
		rm_skin_unload();
		cvar_set("cl_rm_skin", "");
	} else {
		print("Invalid command '", cmd, "'. For a list of supported commands, try cl_cmd help.\n");
	}
	return;
}

float(string strMessage) CSQC_ConsoleCommand { //called by engine
	float argc;
	// Tokenize String
	//argc = tokenize(strMessage);
	argc = tokenize_console(strMessage);
	// Acquire Command
	string strCmd;
	strCmd = argv(0);
	if (strCmd == "+button4") { // zoom
		// return FALSE, because the message shall be sent to the server anyway (for demos/speccing)
		if(cmd_ignore_plus_zoom) {
			--cmd_ignore_plus_zoom;
			return FALSE;
		}
		input_button_zoom = 1;
		return FALSE;
	} else if (strCmd == "-button4") { // zoom
		if (cmd_ignore_minus_zoom) {
			--cmd_ignore_minus_zoom;
			return FALSE;
		}
		input_button_zoom = 0;
		return FALSE;
	} else if(strCmd == "+button3") { // secondary
		input_button_attack2 = 1;
		return FALSE;
	} else if(strCmd == "-button3") { // secondary
		input_button_attack2 = 0;
		return FALSE;
	} else if(strCmd == "+showscores") {
		sbar_showscores = TRUE;
		return TRUE;
	} else if(strCmd == "-showscores") {
		sbar_showscores = FALSE;
		return TRUE;
	} else if(strCmd == "+showaccuracy") {
		sbar_showaccuracy = TRUE;
		return TRUE;
	} else if(strCmd == "-showaccuracy") {
		sbar_showaccuracy = FALSE;
		return TRUE;
	}
	if(view_camera_active)
	if(strCmd == "+forward" || strCmd == "-back") {
		++view_camera_direction_x;
		return TRUE;
	} else if(strCmd == "-forward" || strCmd == "+back") {
		--view_camera_direction_x;
		return TRUE;
	} else if(strCmd == "+moveright" || strCmd == "-moveleft") {
		--view_camera_direction_y;
		return TRUE;
	} else if(strCmd == "-moveright" || strCmd == "+moveleft") {
		++view_camera_direction_y;
		return TRUE;
	} else if(strCmd == "+moveup" || strCmd == "-movedown") {
		++view_camera_direction_z;
		return TRUE;
	} else if(strCmd == "-moveup" || strCmd == "+movedown") {
		--view_camera_direction_z;
		return TRUE;
	} else if(strCmd == "+roll_right" || strCmd == "-roll_left") {
		++view_camera_roll;
		return TRUE;
	} else if(strCmd == "+roll_left" || strCmd == "-roll_right") {
		--view_camera_roll;
		return TRUE;
	}
	return FALSE;
}
