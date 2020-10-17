// CSQC_InputEvent : Used to perform actions based on any key pressed, key released and mouse on the client.
// Return value should be 1 if CSQC handled the input, otherwise return 0 to have the input passed to the engine.
// All keys are in ascii.
// input_type = 0 is key pressed, 1 is key released, 2 is mouse input.
// In the case of keyboard input, primary is the ascii code, and secondary is 0.
// In the case of mouse input, nPrimary is xdelta, nSecondary is ydelta.
float CSQC_InputEvent(float input_type, float primary, float secondary) {
	float skip = FALSE;
	if (input_event_callback) {
		skip = input_event_callback(input_type, primary, secondary);
		input_event_callback = NULL;
		if (skip)
			return TRUE;
	}
	if (input_type == 0)
	if (primary == K_ESCAPE)
	if not(isdemo_flag) {
		GUI_Show(GUI_GAMEMENU);
		return TRUE;
	}
	return skip;
}

string(string text, string command) input_command_key {
	string keys;
	float n, j, k, l;
	if (!CVAR(sbar_showbinds))
		return text;

	keys = db_get(binddb, command);
	if (!keys) {
		n = tokenize(findkeysforcommand(command)); // uses '...' strings
		for(j = 0; j < n; ++j) {
			k = stof(argv(j));
			if(k != -1) {
				if ("" == keys)
					keys = keynumtostring(k);
				else
					keys = strcat(keys, ", ", keynumtostring(k));

				++l;
				if (CVAR(sbar_showbinds_limit) > 0 && CVAR(sbar_showbinds_limit) >= l) break;
			}

		}
		db_put(binddb, command, keys);
	}
	if ("" == keys) {
		if (CVAR(sbar_showbinds) > 1)
			return strcat(text, " (not bound)");
		else
			return text;
	} else if (CVAR(sbar_showbinds) > 1)
		return strcat(text, " (", keys, ")");
	else
		return keys;
}

string(string cmds) input_command_key_first {
	float i, k;
	float ncmds = tokenize(cmds), nkeys;
	for (i = 0; i < ncmds; ++i) {
		nkeys = tokenize(findkeysforcommand(argv(0)));
		for(k = 0; k < nkeys; ++k)
			if(stof(argv(k)) >= 0)
				return keynumtostring(stof(argv(k)));

		ncmds = tokenize(cmds);
	}
	return argv(0);
}

