void(string msg) GameCommand {
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
		mapvote_preview_download(argc);
	} else if (cmd == "settemp") {
		cvar_clientsettemp(argv(1), argv(2));
	} else if (cmd == "radar") {
		ons_showmap = !ons_showmap;
	} else if (cmd == "sbar_columns_set") {
		Sbar_SetFields(argc);
	} else if (cmd == "sbar_columns_help") {
		Sbar_Help(argc);
	} else if (cmd == "sendcvar") {
	} else if (cmd == "handlevote") {
		localcmd(strcat("cmd vote ", argv(1), "\n"));
	} else if(cmd == "modelprecache") {
		precache_model(argv(1));
	} else if (cmd == "spawnentity") {
		if (spawnentity)
			remove(spawnentity);

		spawnentity = spawn();
		spawnentity.draw = spawnentity_Draw;
		setorigin(spawnentity, view_origin + view_forward * 100);
		precache_model(argv(1));
		setmodel(spawnentity, argv(1));
		spawnentity.frame = stof(argv(2));
	} else if (cmd == "showradio") {
		GUI_Show(GUI_RADIO);
	} else if (cmd == "report") {
		GUI_Show(GUI_REPORT);
	} else {
		print("Invalid command '", cmd, "'. For a list of supported commands, try cl_cmd help.\n");
	}
	return;
}

float(string strMessage) CSQC_ConsoleCommand {
	float argc;
	// Tokenize String
	//argc = tokenize(strMessage);
	argc = tokenize_console(strMessage);
	// Acquire Command
	string strCmd;
	strCmd = argv(0);
	if (strCmd == "+button4") { // zoom
		// return FALSE, because the message shall be sent to the server anyway (for demos/speccing)
		if(ignore_plus_zoom) {
			--ignore_plus_zoom;
			return FALSE;
		}
		button_zoom = 1;
		return FALSE;
	} else if (strCmd == "-button4") { // zoom
		if (ignore_minus_zoom) {
			--ignore_minus_zoom;
			return FALSE;
		}
		button_zoom = 0;
		return FALSE;
	} else if(strCmd == "+button3") { // secondary
		button_attack2 = 1;
		return FALSE;
	} else if(strCmd == "-button3") { // secondary
		button_attack2 = 0;
		return FALSE;
	} else if(strCmd == "+showscores") {
		sb_showscores = TRUE;
		return TRUE;
	} else if(strCmd == "-showscores") {
		sb_showscores = FALSE;
		return TRUE;
	} else if(strCmd == "+showaccuracy") {
		sb_showaccuracy = TRUE;
		return TRUE;
	} else if(strCmd == "-showaccuracy") {
		sb_showaccuracy = FALSE;
		return TRUE;
	}
	if(camera_active)
	if(strCmd == "+forward" || strCmd == "-back") {
		++camera_direction_x;
		return TRUE;
	} else if(strCmd == "-forward" || strCmd == "+back") {
		--camera_direction_x;
		return TRUE;
	} else if(strCmd == "+moveright" || strCmd == "-moveleft") {
		--camera_direction_y;
		return TRUE;
	} else if(strCmd == "-moveright" || strCmd == "+moveleft") {
		++camera_direction_y;
		return TRUE;
	} else if(strCmd == "+moveup" || strCmd == "-movedown") {
		++camera_direction_z;
		return TRUE;
	} else if(strCmd == "-moveup" || strCmd == "+movedown") {
		--camera_direction_z;
		return TRUE;
	} else if(strCmd == "+roll_right" || strCmd == "-roll_left") {
		++camera_roll;
		return TRUE;
	} else if(strCmd == "+roll_left" || strCmd == "-roll_right") {
		--camera_roll;
		return TRUE;
	}
	return FALSE;
}
