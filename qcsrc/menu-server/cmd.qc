float(string command) cmd_generic {
	float argc;
	float i, f, n;
	string s, s2;
	argc = tokenize_console(command);
	if (argv(0) == "help") {
		print("  maplist add map\n");
		print("  maplist remove map\n");
		print("  maplist shuffle\n");
		print("  maplist cleanup\n");
		print("  addtolist variable addedvalue\n");
		return TRUE;
	}
	if (argv(0) == "maplist") {
		if (argv(1) == "add" && argc == 3) {
			f = fopen(strcat("maps/", argv(2), ".bsp"), FILE_READ);
			if (f != -1)
				fclose(f);
			else {
				print("maplist: ERROR: ", argv(2), " does not exist!\n");
				return TRUE;
			}
			if (cvar_string("g_maplist") == "")
				cvar_set("g_maplist", argv(2));
			else
				cvar_set("g_maplist", strcat(argv(2), " ", cvar_string("g_maplist")));

			return TRUE;
		} else if (argv(1) == "remove" && argc == 3) {
			s = argv(2);
			n = tokenizebyseparator(cvar_string("g_maplist"), " ");
			s2 = "";
			for(i = 0; i < n; ++i)
				if (argv(i) != s)
					s2 = strcat(s2, " ", argv(i));

			s2 = substring(s2, 1, strlen(s2) - 1);
			cvar_set("g_maplist", s2);
			return TRUE;
		} else if (argv(1) == "shuffle" && argc == 2) {
			registercvar("_g_maplist", ""
					#ifndef SVQC
					, 0
					#endif
			);
			cvar_set("_g_maplist", str_shuffle_words(cvar_string("_g_maplist")));
			return TRUE;
		} else if (argv(1) == "cleanup") {
			map_info_enumerate();
			map_info_filter_game_type(map_info_type_from_game_type(game_type_current()), map_info_required_flags(), map_info_forbidden_flags(), 0);
			n = tokenizebyseparator(cvar_string("g_maplist"), " ");
			s2 = "";
			for(i = 0; i < n; ++i)
				if (map_info_check_map(argv(i)))
					s2 = strcat(s2, " ", argv(i));

			s2 = substring(s2, 1, strlen(s2) - 1);
			cvar_set("g_maplist", s2);
			return TRUE;
		}
	} else if (argv(0) == "addtolist") {
		if (argc >= 2) {
			s = argv(1);
			s2 = argv(2);
			if (cvar_string(s) == "")
				cvar_set(s, s2);
			else {
				n = tokenizebyseparator(cvar_string(s), " ");
				for(i = 0; i < n; ++i)
					if (argv(i) == s2)
						return TRUE; // already in list

				cvar_set(s, strcat(s2, " ", cvar_string(s)));
			}
		}
		return TRUE;
	}
	return FALSE;
}
