string(string s) map_info_fix_name {
	map_info_find_name(s);
	return map_info_find_name_match;
}

float(string s) map_info_get_game_types {
	float r;
	if (!map_info_get_by_name(s, 1, 0))
		return 0;

	r = map_info_map_supported_game_types;
	map_info_clear_temps();
	return r;
}

void(string pFilename, string acl, string s, float recurse) map_info_parse_set_temp {
	string t;
	float fh;
	t = str_car(s); s = str_cdr(s);
	if (t == "#include") {
		if (recurse > 0) {
			fh = fopen(s, FILE_READ);
			if (fh < 0)
				print("Map ", pFilename, " references not existing config file ", s, "\n");
			else {
				for (;;) {
					if not((s = fgets(fh)))
						break;

					// catch different sorts of comments
					if (s == "")                    // empty lines
						continue;

					if (substring(s, 0, 1) == "#")  // UNIX style
						continue;

					if (substring(s, 0, 2) == "//") // C++ style
						continue;

					if (substring(s, 0, 1) == "_")  // q3map style
						continue;

					map_info_parse_set_temp(pFilename, acl, s, recurse - 1);
				}
				fclose(fh);
			}
		} else
			print("Map ", pFilename, " uses too many levels of inclusion\n");
	} else if not(cvar_value_issafe(t))
		print("Map ", pFilename, " contains a potentially harmful setting, ignored\n");
	else if not (cvar_value_issafe(s))
		print("Map ", pFilename, " contains a potentially harmful setting, ignored\n");
	else if (substring(t, 0, 10) == "g_mapinfo_")
		print("Map ", pFilename, " contains a potentially harmful setting, ignored\n");
	else if (map_info_matchacl(acl, t) <= 0)
		print("Map ", pFilename, " contains a denied setting, ignored\n");
	else {
		if (cvar("g_mapinfo_settemp_force") && substring(t, 0, 2) == "g_" && substring(t, 0, 9) != "g_profile")
			t = strcat("force_", t);

		cvar_settemp(t, s);
	}
}

void(string s) map_info_load_map_settings { // to be called from worldspawn
	float t;
	if (!map_info_check_map_keep_temps(s)) { // with underscore, it keeps temps
		if (map_info_map_supported_game_types <= 0)
			error("Mapinfo system is not functional at all. BAILED OUT.\n");

		print("EMERGENCY: can't play the selected map in the given game mode. Falling back to a supported mode.\n");
		for (t = GAME_TYPE_DEATHMATCH; t < GAME_TYPE_END; t++) {
			if (map_info_type_from_game_type(t) & map_info_map_supported_game_types) {
				game_type_switch(t);
				break;
			}
		}
		if (t == GAME_TYPE_END)
			print("No supported game mode for map!!! How can this possible?\n");
	}
	cvar_settemp_restore();
	map_info_load_map_settings_processing = TRUE;
	map_info_get_by_name(s, 1, map_info_type_from_game_type(game_type_current()));
	map_info_load_map_settings_processing = FALSE;
}
