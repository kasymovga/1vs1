float MAP_INFO_TYPE_CTF = 1;
float MAP_INFO_TYPE_SHOOTINGRANGE = 2;
float MAP_INFO_TYPE_ONSLAUGHT = 4;
float MAP_INFO_TYPE_RACE = 8;
float MAP_INFO_TYPE_DEATHMATCH = 16;
float MAP_INFO_TYPE_TEAM_DEATHMATCH = 32;
float MAP_INFO_TYPE_DOMINATION = 64;
float MAP_INFO_TYPE_CONQUEST = 256;
float MAP_INFO_TYPE_KEYHUNT = 1024;
float MAP_INFO_TYPE_NEXBALL = 2048;
float MAP_INFO_TYPE_CTS = 4096;
float MAP_INFO_TYPE_SURVIVE = 32768;
float MAP_INFO_TYPE_SINGLE = 65536;

void(float n, swapfunc_t swap, comparefunc_t cmp, entity pass) map_info_heapsort {
	float start, end, root, child;
	// heapify
	start = floor((n - 2) / 2);
	while (start >= 0) {
		// siftdown(start, count-1);
		root = start;
		while (root * 2 + 1 <= n-1) {
			child = root * 2 + 1;
			if (child < n-1)
				if (cmp(child, child+1, pass) < 0)
					++child;

			if (cmp(root, child, pass) < 0) {
				swap(root, child, pass);
				root = child;
			} else
				break;
		}
		// end of siftdown
		--start;
	}
	// extract
	end = n - 1;
	while (end > 0) {
		swap(0, end, pass);
		--end;
		// siftdown(0, end);
		root = 0;
		while (root * 2 + 1 <= end) {
			child = root * 2 + 1;
			if (child < end && cmp(child, child+1, pass) < 0)
				++child;

			if (cmp(root, child, pass) < 0) {
				swap(root, child, pass);
				root = child;
			} else
				break;
		}
		// end of siftdown
	}
}

float(string acl, string str) map_info_matchacl {
	string t, s = "";
	float r, d;
	r = 0;
	while (acl) {
		t = str_car(acl); acl = str_cdr(acl);
		d = 1;
		if (substring(t, 0, 1) == "-") {
			d = -1;
			t = substring(t, 1, strlen(t) - 1);
		} else if (substring(t, 0, 1) == "+")
			t = substring(t, 1, strlen(t) - 1);

		if (substring(t, -1, 1) == "*") {
			t = substring(t, 0, strlen(t) - 1);
			s = substring(s, 0, strlen(t));
		} else
			s = str;

		if (s == t)
			r = d;
	}
	return r;
}

float map_info_cache_active;
float map_info_cache_db_name_to_index;
float map_info_cache_buf_index_to_map_data;

void(void) map_info_cache_destroy {
	if (!map_info_cache_active)
		return;

	db_close(map_info_cache_db_name_to_index);
	buf_del(map_info_cache_buf_index_to_map_data);
	map_info_cache_active = 0;
}

void(void) map_info_cache_create {
	map_info_cache_destroy();
	map_info_cache_db_name_to_index = db_create();
	map_info_cache_buf_index_to_map_data = buf_create();
	map_info_cache_active = 1;
}

void(void) map_info_cache_store {
	float i;
	string s;
	if (!map_info_cache_active)
		return;

	s = db_get(map_info_cache_db_name_to_index, map_info_map_bspname);
	if (s == "") {
		i = buf_getsize(map_info_cache_buf_index_to_map_data);
		db_put(map_info_cache_db_name_to_index, map_info_map_bspname, ftos(i));
	}
	else
		i = stof(s);

	// now store all the stuff
	bufstr_set(map_info_cache_buf_index_to_map_data,   i, map_info_map_bspname);
	bufstr_set(map_info_cache_buf_index_to_map_data, ++i, map_info_map_title);
	bufstr_set(map_info_cache_buf_index_to_map_data, ++i, map_info_map_description);
	bufstr_set(map_info_cache_buf_index_to_map_data, ++i, map_info_map_author);
	bufstr_set(map_info_cache_buf_index_to_map_data, ++i, ftos(map_info_map_supported_game_types));
	bufstr_set(map_info_cache_buf_index_to_map_data, ++i, ftos(map_info_map_supported_features));
	bufstr_set(map_info_cache_buf_index_to_map_data, ++i, ftos(map_info_map_flags));
	bufstr_set(map_info_cache_buf_index_to_map_data, ++i, map_info_map_image);
}

float(string map) map_info_cache_retrieve {
	float i;
	string s;
	if (!map_info_cache_active)
		return 0;

	s = db_get(map_info_cache_db_name_to_index, map);
	if (s == "")
		return 0;

	i = stof(s);
	// now retrieve all the stuff
	map_info_map_bspname = bufstr_get(map_info_cache_buf_index_to_map_data, i);
	map_info_map_title = bufstr_get(map_info_cache_buf_index_to_map_data, ++i);
	map_info_map_description = bufstr_get(map_info_cache_buf_index_to_map_data, ++i);
	map_info_map_author = bufstr_get(map_info_cache_buf_index_to_map_data, ++i);
	map_info_map_supported_game_types = stof(bufstr_get(map_info_cache_buf_index_to_map_data, ++i));
	map_info_map_supported_features = stof(bufstr_get(map_info_cache_buf_index_to_map_data, ++i));
	map_info_map_flags = stof(bufstr_get(map_info_cache_buf_index_to_map_data, ++i));
	map_info_map_image = bufstr_get(map_info_cache_buf_index_to_map_data, ++i);
	return 1;
}

// GLOB HANDLING (for all BSP files)
float map_info_globopen;
float map_info_globcount;
float map_info_globhandle;
string(float i) map_info_glob_item {
	string s;
	s = search_getfilename(map_info_globhandle, i);
	return substring(s, 5, strlen(s) - 9); // without maps/ and .bsp
}

void(void) map_info_enumerate {
	if (map_info_globopen)
		search_end(map_info_globhandle);

	map_info_cache_create();
	map_info_globhandle = search_begin("maps/*.bsp", TRUE, TRUE);
	map_info_globcount = search_getsize(map_info_globhandle);
	map_info_globopen = 1;
}

// filter the info by game type mask (updates map_info_count)
//
float map_info_filtered;
float map_info_filtered_allocated;
float(float i) map_info_filter_list_lookup {
	return stof(bufstr_get(map_info_filtered, i));
}

void(float i, float j, entity pass) map_info_filter_list_swap {
	string h;
	h = bufstr_get(map_info_filtered, i);
	bufstr_set(map_info_filtered, i, bufstr_get(map_info_filtered, j));
	bufstr_set(map_info_filtered, j, h);
}

float(float i, float j, entity pass) map_info_filter_list_cmp {
	string a, b;
	a = map_info_glob_item(stof(bufstr_get(map_info_filtered, i)));
	b = map_info_glob_item(stof(bufstr_get(map_info_filtered, j)));
	return strcasecmp(a, b);
}

float(float pGametype, float pFlagsRequired, float pFlagsForbidden, float pAbortOnGenerate) map_info_filter_game_type {
	float i, j;
	if not(map_info_filtered_allocated) {
		map_info_filtered_allocated = 1;
		map_info_filtered = buf_create();
	}
	map_info_count = 0;
	for (i = 0, j = -1; i < map_info_globcount; ++i) {
		if (map_info_get_by_name(map_info_glob_item(i), 1, 0) == 2) // if we generated one... BAIL OUT and let the caller continue in the next frame.
			if (pAbortOnGenerate) {
				map_info_progress = i / map_info_globcount;
				return 0;
			}
		if ((map_info_map_supported_game_types & pGametype) != 0)
		if ((map_info_map_flags & pFlagsForbidden) == 0)
		if ((map_info_map_flags & pFlagsRequired) == pFlagsRequired)
			bufstr_set(map_info_filtered, ++j, ftos(i));
	}
	map_info_count = j + 1;
	map_info_clear_temps();
	// sometimes the glob isn't sorted nicely, so fix it here...
	map_info_heapsort(map_info_count, map_info_filter_list_swap, map_info_filter_list_cmp, NULL);
	return 1;
}

void() map_info_filter_free {
	if (map_info_filtered_allocated) {
		buf_del(map_info_filtered);
		map_info_filtered_allocated = 0;
	}
}

// load info about the i-th map into the map_info_map_* globals
string(float i) map_info_bsp_name_by_id {
	return map_info_glob_item(map_info_filter_list_lookup(i));
}

string(string s) map_info_unquote {
	float i, j, l;
	l = strlen(s);
	j = -1;
	for (i = 0; i < l; ++i) {
		string ch;
		ch = substring(s, i, 1);
		if (ch != " ")
		if (ch != "\"") {
			for (j = strlen(s) - i - 1; j > 0; --j) {
				ch = substring(s, i+j, 1);
				if (ch != " ") if (ch != "\"")
					return substring(s, i, j+1);
			}
			return substring(s, i, 1);
		}
	}
	return "";
}

float(float i) map_info_get_by_id {
	if (map_info_get_by_name(map_info_bsp_name_by_id(i), 0, 0))
		return 1;

	return 0;
}

string map_info_map_worldspawn_music;

float(string pFilename) map_info_generate { // 0: failure, 1: ok ent, 2: ok bsp
	string fn;
	float fh;
	string s, k, v;
	vector o;
	float i;
	float inWorldspawn;
	float r;
	float twoBaseModes;
	float diameter, spawnpoints;
	float spawnplaces;
	vector mapMins = '0 0 0', mapMaxs = '0 0 0';
	r = 1;
	fn = strcat("maps/", pFilename, ".ent");
	fh = fopen(fn, FILE_READ);
	if (fh < 0) {
		r = 2;
		fn = strcat("maps/", pFilename, ".bsp");
		fh = fopen(fn, FILE_READ);
	}
	if (fh < 0)
		return 0;

	print("Analyzing ", fn, " to generate initial mapinfo; please edit that file later\n");
	inWorldspawn = 2;
	map_info_map_flags = 0;
	map_info_map_supported_game_types = 0;
	spawnpoints = 0;
	spawnplaces = 0;
	map_info_map_worldspawn_music = "";
	float loopprotect;
	for (loopprotect = 0; loopprotect < 10000; loopprotect++) {
		if not((s = fgets(fh)))
			break;

		if (inWorldspawn == 1)
			if (substring(s, 0, 1) == "}")
				inWorldspawn = 0;

		k = map_info_unquote(str_car(s));
		v = map_info_unquote(str_cdr(s));
		if (inWorldspawn) {
			if (k == "classname" && v == "worldspawn")
				inWorldspawn = 1;
			else if (k == "author")
				map_info_map_author = v;
			else if (k == "_description")
				map_info_map_description = v;
			else if (k == "music")
				map_info_map_worldspawn_music = v;
			else if (k == "noise")
				map_info_map_worldspawn_music = v;
			else if (k == "message") {
				i = strstrofs(v, " by ", 0);
				if (map_info_map_author == "<AUTHOR>" && i >= 0) {
					map_info_map_title = substring(v, 0, i);
					map_info_map_author = substring(v, i + 4, strlen(v) - (i + 4));
				} else
					map_info_map_title = v;
			}
		} else {
			if (k == "origin") {
				o = stov(strcat("'", v, "'"));
				mapMins_x = min(mapMins_x, o_x);
				mapMins_y = min(mapMins_y, o_y);
				mapMins_z = min(mapMins_z, o_z);
				mapMaxs_x = max(mapMaxs_x, o_x);
				mapMaxs_y = max(mapMaxs_y, o_y);
				mapMaxs_z = max(mapMaxs_z, o_z);
			} else if (k == "race_place") {
				if (stof(v) > 0)
					spawnplaces = 1;
			} else if (k == "classname") {
				if (v == "dom_controlpoint")
					map_info_map_supported_game_types |= MAP_INFO_TYPE_DOMINATION;
				else if (v == "item_flag_team2")
					map_info_map_supported_game_types |= MAP_INFO_TYPE_CTF;
				else if (v == "team_CTF_blueflag")
					map_info_map_supported_game_types |= MAP_INFO_TYPE_CTF;
				else if (v == "onslaught_generator")
					map_info_map_supported_game_types |= MAP_INFO_TYPE_ONSLAUGHT;
				else if (substring(v, 0, 8) == "nexball_" || substring(v, 0, 4) == "ball")
					map_info_map_supported_game_types |= MAP_INFO_TYPE_NEXBALL;
				else if (v == "info_player_team1")
					++spawnpoints;
				else if (v == "info_player_team2")
					++spawnpoints;
				else if (v == "info_player_start")
					++spawnpoints;
				else if (v == "info_player_deathmatch")
					++spawnpoints;
				else if (v == "trigger_race_checkpoint")
					map_info_map_supported_game_types |= MAP_INFO_TYPE_RACE;
				else if (v == "target_startTimer") {
					map_info_map_supported_game_types |= MAP_INFO_TYPE_CTS;
				} else if (substring(v, 0, 7) == "weapon_")
					map_info_map_supported_features |= MAP_INFO_FEATURE_WEAPONS;
				else if (v == "shootingrange_target")
					map_info_map_supported_game_types |= MAP_INFO_TYPE_SHOOTINGRANGE;
			}
		}
	}
	if (inWorldspawn && loopprotect != 10000) {
		print(fn, " ended still in worldspawn, BUG\n");
		return 0;
	}
	diameter = vlen(mapMaxs - mapMins);
	twoBaseModes = (map_info_map_supported_game_types & (MAP_INFO_TYPE_CTF | MAP_INFO_TYPE_RACE | MAP_INFO_TYPE_NEXBALL));
	if (twoBaseModes && (map_info_map_supported_game_types == twoBaseModes)) {
		// we have a CTF-only or Assault-only map. Don't add other modes then,
		// as the map is too symmetric for them.
	} else if not(map_info_map_supported_game_types & MAP_INFO_TYPE_CTS) {
		map_info_map_supported_game_types |= MAP_INFO_TYPE_DEATHMATCH;      // DM always works
		if (spawnpoints >= 8  && diameter > 4096)
			map_info_map_supported_game_types |= MAP_INFO_TYPE_TEAM_DEATHMATCH;
		if (spawnpoints >= 12 && diameter > 5120)
			map_info_map_supported_game_types |= MAP_INFO_TYPE_KEYHUNT;
	}
	if (map_info_map_supported_game_types & MAP_INFO_TYPE_RACE)
	if (!spawnplaces) {
		map_info_map_supported_game_types &= ~MAP_INFO_TYPE_RACE;
		map_info_map_supported_game_types |= MAP_INFO_TYPE_CTS;
	}
	fclose(fh);
	return r;
}

void(void) map_info_map_reset {
	map_info_map_title = "<TITLE>";
	map_info_map_description = "<DESCRIPTION>";
	map_info_map_author = "<AUTHOR>";
	map_info_map_supported_game_types = 0;
	map_info_map_supported_features = 0;
	map_info_map_flags = 0;
	map_info_map_clientstuff = "";
	map_info_map_fog = "";
	map_info_map_mins = '0 0 0';
	map_info_map_maxs = '0 0 0';
	cvar_set("_map_dlc", "");
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
		cvar_settemp(t, s);
#ifdef SVQC
		if (g_campaign)
			cvar_set(t, s);
#endif
	}
}

// load info about a map by name into the map_info_map_* globals
float(string pFilename, float pAllowGenerate, float pGametypeToSet) map_info_get_by_name {
	string fn;
	string s, t;
	float fh;
	float r, f, n, i;
	string acl;
	acl = cvar_string("g_mapinfo_settemp_acl");
	if (pFilename == "")
		return 0;

	if (strstrofs(pFilename, "/", 0) >= 0) {
		print("Invalid character in map name, ignored\n");
		return 0;
	}
	if (pGametypeToSet == 0)
		if (map_info_cache_retrieve(pFilename))
			return 1;

	r = 1;
	map_info_map_bspname = pFilename;
	if not(file_exists(strcat("maps/", pFilename, ".bsp"))) {
		return 0;
	}
	map_info_map_image = strcat("maps/", map_info_map_bspname);
	if not(file_exists_image(map_info_map_image)) {
		map_info_map_image = strcat("levelshots/", map_info_map_bspname);
		if not(file_exists_image(map_info_map_image)) {
			map_info_map_image = strcat("gfx/", map_info_map_bspname, "_mini");
			if not(file_exists_image(map_info_map_image))
				map_info_map_image = "gfx/m_nomap";
		}
	}
	// default all generic fields so they have "good" values in case something fails
	fn = strcat("maps/", pFilename, ".mapinfo");
	fh = fopen(fn, FILE_READ);
	if (fh < 0) {
		if (!pAllowGenerate)
			return 0;

		map_info_map_reset();
		r = map_info_generate(pFilename);
		if (!r)
			return 0;

		fh = fopen(fn, FILE_WRITE);
		fputs(fh, strcat("title ", map_info_map_title, "\n"));
		fputs(fh, strcat("description ", map_info_map_description, "\n"));
		fputs(fh, strcat("author ", map_info_map_author, "\n"));
		if (map_info_map_worldspawn_music != "") {
			if (
					substring(map_info_map_worldspawn_music, strlen(map_info_map_worldspawn_music) - 4, 4) == ".wav"
					||
					substring(map_info_map_worldspawn_music, strlen(map_info_map_worldspawn_music) - 4, 4) == ".ogg")
				fputs(fh, strcat("cdtrack ", substring(map_info_map_worldspawn_music, 0, strlen(map_info_map_worldspawn_music) - 4), "\n"));
			else
				fputs(fh, strcat("cdtrack ", map_info_map_worldspawn_music, "\n"));
		} else {
			n = tokenize_console(cvar_string("g_cdtracks_remaplist"));
			s = strcat(" ", cvar_string("g_cdtracks_dontusebydefault"), " ");
			for (;;) {
				i = floor(random() * n);
				if (strstrofs(s, strcat(" ", argv(i), " "), 0) < 0)
					break;
			}
			fputs(fh, strcat("cdtrack ", ftos(i + 1), "\n"));
		}
		if (map_info_map_supported_features & MAP_INFO_FEATURE_WEAPONS)
			fputs(fh, "has weapons\n");
		else
			fputs(fh, "// uncomment this if you added weapon pickups: has weapons\n");

		if (map_info_map_flags & MAP_INFO_FLAG_FRUSTRATING)
			fputs(fh, "frustrating\n");

		if (map_info_map_supported_game_types & MAP_INFO_TYPE_DEATHMATCH)      fputs(fh, "type dm 30 20\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_TEAM_DEATHMATCH) fputs(fh, "type tdm 50 20 2\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_DOMINATION)      fputs(fh, "type dom 200 20\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_CTF)             fputs(fh, "type ctf 300 20 10\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_KEYHUNT)         fputs(fh, "type kh 1000 20 3\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_RACE)            fputs(fh, "type rc 20 5 7 15\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_ONSLAUGHT)       fputs(fh, "type ons 20\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_NEXBALL)         fputs(fh, "type nexball 5 20\n");
		if (map_info_map_supported_game_types & MAP_INFO_TYPE_CTS)             fputs(fh, "type cts 20 -1\n");
		fputs(fh, "// optional: fog density red green blue alpha mindist maxdist\n");
		fputs(fh, "// optional: settemp_for_type (all|gametypename) cvarname value\n");
		fputs(fh, "// optional: clientsettemp_for_type (all|gametypename) cvarname value\n");
		fputs(fh, "// optional: size mins_x mins_y mins_z maxs_x maxs_y maxs_z\n");
		fputs(fh, "// optional: hidden\n");
		fclose(fh);
		r = 2;
		// return r;
		fh = fopen(fn, FILE_READ);
		if (fh < 0)
			error("... but I just wrote it!");
	}
	map_info_map_reset();
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

		t = str_car(s); s = str_cdr(s);
		if (t == "title")
			map_info_map_title = s;
		else if (t == "description")
			map_info_map_description = s;
		else if (t == "author")
			map_info_map_author = s;
		else if (t == "has") {
			t = str_car(s); s = str_cdr(s);
			if     (t == "weapons") map_info_map_supported_features |= MAP_INFO_FEATURE_WEAPONS;
		} else if (t == "hidden") {
			map_info_map_flags |= MAP_INFO_FLAG_HIDDEN;
		} else if (t == "forbidden") {
			map_info_map_flags |= MAP_INFO_FLAG_FORBIDDEN;
		} else if (t == "frustrating") {
			map_info_map_flags |= MAP_INFO_FLAG_FRUSTRATING;
		} else if (t == "type" || t == "gametype") {
			t = str_car(s); s = str_cdr(s);
			f = map_info_type_from_game_type(game_type_from_name(t));
			map_info_map_supported_game_types |= f;
			if (map_info_map_supported_game_types & MAP_INFO_TYPE_DEATHMATCH)
				if (cvar("g_tdm_use_dm_maps"))
					map_info_map_supported_game_types |= MAP_INFO_TYPE_TEAM_DEATHMATCH;

			if (map_info_map_supported_game_types & MAP_INFO_TYPE_CTF)
				if (cvar("g_tdm_use_ctf_maps"))
					map_info_map_supported_game_types |= MAP_INFO_TYPE_TEAM_DEATHMATCH;

			if (map_info_map_supported_game_types & MAP_INFO_TYPE_TEAM_DEATHMATCH)
				if (cvar("g_dm_use_tdm_maps"))
					map_info_map_supported_game_types |= MAP_INFO_TYPE_DEATHMATCH;

			if (map_info_map_supported_game_types & MAP_INFO_TYPE_TEAM_DEATHMATCH) {
				if (cvar("g_kh_use_tdm_maps"))
					map_info_map_supported_game_types |= MAP_INFO_TYPE_KEYHUNT;
			}
		} else if (t == "size") {
			float a, b, c, d, e;
			t = str_car(s); s = str_cdr(s); a = stof(t);
			t = str_car(s); s = str_cdr(s); b = stof(t);
			t = str_car(s); s = str_cdr(s); c = stof(t);
			t = str_car(s); s = str_cdr(s); d = stof(t);
			t = str_car(s); s = str_cdr(s); e = stof(t);
			if (s == "")
				print("Map ", pFilename, " contains an incorrect size line (not enough params), syntax: size mins_x mins_y mins_z maxs_x maxs_y maxs_z\n");
			else {
				t = str_car(s); s = str_cdr(s); f = stof(t);
				if (s != "")
					print("Map ", pFilename, " contains an incorrect size line (too many params), syntax: size mins_x mins_y mins_z maxs_x maxs_y maxs_z\n");
				else {
					if (a >= d || b >= e || c >= f)
						print("Map ", pFilename, " contains an incorrect size line, mins have to be < maxs\n");
					else {
						map_info_map_mins_x = a;
						map_info_map_mins_y = b;
						map_info_map_mins_z = c;
						map_info_map_maxs_x = d;
						map_info_map_maxs_y = e;
						map_info_map_maxs_z = f;
					}
				}
			}
		} else if (t == "settemp_for_type") {
			t = str_car(s); s = str_cdr(s);
			if ((t == "all" && pGametypeToSet) || (map_info_type_from_game_type(game_type_from_name(t)) & pGametypeToSet)) {
				map_info_parse_set_temp(pFilename, acl, s, 1);
			}
		} else if (t == "clientsettemp_for_type") {
			t = str_car(s); s = str_cdr(s);
			if ((t == "all" && pGametypeToSet) || (map_info_type_from_game_type(game_type_from_name(t)) & pGametypeToSet)) {
				t = str_car(s); s = str_cdr(s);
				if not(cvar_value_issafe(t))
					print("Map ", pFilename, " contains a potentially harmful client setting, ignored\n");
				else if not (cvar_value_issafe(s))
					print("Map ", pFilename, " contains a potentially harmful client setting, ignored\n");
				else {
					map_info_map_clientstuff = strcat(
						map_info_map_clientstuff, "cl_cmd settemp \"", t, "\" \"", s, "\"\n"
					);
				}
			}
		} else if (t == "require_dlc") {
			cvar_set("_map_dlc", s);
		} else if (t == "fog") {
			if not(cvar_value_issafe(t))
				print("Map ", pFilename, " contains a potentially harmful fog setting, ignored\n");
			else
				map_info_map_fog = s;
		} else if (t == "cdtrack") {
			if (pGametypeToSet) {
				if not(cvar_value_issafe(t))
					print("Map ", pFilename, " contains a potentially harmful cdtrack, ignored\n");
				else
					map_info_map_clientstuff = strcat(map_info_map_clientstuff, "cd loop \"", s, "\"\n");
			}
		}
	}
	fclose(fh);
	if (pGametypeToSet)
		if (!(map_info_map_supported_game_types & pGametypeToSet)) {
			print("map_info_map_supported_game_types = ", ftos(map_info_map_supported_game_types), "\n");
			print("pGametypeToSet = ", ftos(pGametypeToSet), "\n");
			error("Can't select the requested game type. Bailing out.");
		}
	map_info_cache_store();
	if (map_info_map_supported_game_types != 0)
		return r;

	return 0;
}

float(string s) map_info_find_name {
	// if there is exactly one map of prefix s, return it
	// if not, return the null string
	// note that DP sorts glob results... so I can use a binary search
	float l, r, m, cmp;
	l = 0;
	r = map_info_count;
	// invariants: r is behind s, l-1 is equal or before
	while (l != r) {
		m = floor((l + r) / 2);
		map_info_find_name_match = map_info_glob_item(map_info_filter_list_lookup(m));
		cmp = strcasecmp(map_info_find_name_match, s);
		if (cmp == 0)
			return m; // found and good
		if (cmp < 0)
			l = m + 1; // l-1 is before s
		else
			r = m; // behind s
	}
	map_info_find_name_match = map_info_glob_item(map_info_filter_list_lookup(l));
	map_info_find_name_first_result = l;
	// r == l, so: l is behind s, l-1 is before
	// SO: if there is any, l is the one with the right prefix
	//     and l+1 may be one too
	if (l == map_info_count) {
		map_info_find_name_match = NULL;
		map_info_find_name_first_result = -1;
		return -1; // no map_info_find_name_match, behind last item
	}
	if (strcasecmp(substring(map_info_find_name_match, 0, strlen(s)), s) == 0) {
		map_info_find_name_match = NULL;
		map_info_find_name_first_result = -1;
		return -1; // wrong prefix
	}
	if (l == map_info_count - 1)
		return l; // last one, nothing can follow => unique
	if (strcasecmp(substring(map_info_glob_item(map_info_filter_list_lookup(l + 1)), 0, strlen(s)), s) == 0) {
		map_info_find_name_match = NULL;
		return -1; // ambigous map_info_find_name_match
	}
	return l;
}

float(string s) map_info_check_map_keep_temps { // returns 0 if the map can't be played with the current settings, 1 otherwise
	if (s == "")
		return 0;

	if (!map_info_get_by_name(s, 1, 0))
		return 0;

	if ((map_info_map_supported_game_types & map_info_type_from_game_type(game_type_current())) == 0)
		return 0;

	return 1;
}

float(string s) map_info_check_map { // returns 0 if the map can't be played with the current settings, 1 otherwise
	float r;
	r = map_info_check_map_keep_temps(s);
	map_info_clear_temps();
	return r;
}

float(float t) map_info_type_from_game_type {
	switch (t) {
	case GAME_TYPE_DEATHMATCH:      return MAP_INFO_TYPE_DEATHMATCH;
	case GAME_TYPE_TEAM_DEATHMATCH: return MAP_INFO_TYPE_TEAM_DEATHMATCH;
	case GAME_TYPE_FREEZETAG:       return MAP_INFO_TYPE_TEAM_DEATHMATCH;
	case GAME_TYPE_CLANARENA:       return MAP_INFO_TYPE_TEAM_DEATHMATCH;
	case GAME_TYPE_DOMINATION:      return MAP_INFO_TYPE_DOMINATION;
	case GAME_TYPE_CTF:             return MAP_INFO_TYPE_CTF;
	case GAME_TYPE_CATF:            return MAP_INFO_TYPE_CTF;
	case GAME_TYPE_CTFT:            return MAP_INFO_TYPE_CTF;
	case GAME_TYPE_CONQUEST:        return MAP_INFO_TYPE_CONQUEST;
	case GAME_TYPE_KEYHUNT:         return MAP_INFO_TYPE_KEYHUNT;
	case GAME_TYPE_KEYHUNT_CA:      return MAP_INFO_TYPE_KEYHUNT;
	case GAME_TYPE_KEYHUNT_FT:      return MAP_INFO_TYPE_KEYHUNT;
	case GAME_TYPE_ONSLAUGHT:       return MAP_INFO_TYPE_ONSLAUGHT;
	case GAME_TYPE_RACE:            return MAP_INFO_TYPE_RACE;
	case GAME_TYPE_CTS:             return MAP_INFO_TYPE_CTS;
	case GAME_TYPE_SURVIVE:         return MAP_INFO_TYPE_SURVIVE;
	case GAME_TYPE_LMS:             return MAP_INFO_TYPE_DEATHMATCH;
	case GAME_TYPE_COOP:            return MAP_INFO_TYPE_SINGLE;
	case GAME_TYPE_SINGLE:          return MAP_INFO_TYPE_SINGLE;
	case GAME_TYPE_NEXBALL:         return MAP_INFO_TYPE_NEXBALL;
	case GAME_TYPE_SHOOTINGRANGE:   return MAP_INFO_TYPE_SHOOTINGRANGE;
	}
	return 0;
}

void(string s) map_info_load_map {
	map_info_map_supported_game_types = 0;
	if (!map_info_check_map(s)) {
		print("EMERGENCY: can't play the selected map in the given game mode. Falling back to DM.\n");
		game_type_switch(GAME_TYPE_DEATHMATCH);
	}
	localcmd(strcat("\nsettemp_restore\nchangelevel ", s, "\n"));
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
	map_info_get_by_name(s, 1, map_info_type_from_game_type(game_type_current()));
}

void(void) map_info_clear_temps {
	map_info_map_bspname = NULL;
	map_info_map_title = NULL;
	map_info_map_description = NULL;
	map_info_map_author = NULL;
	map_info_map_clientstuff = NULL;
	map_info_map_image = NULL;
	map_info_map_supported_game_types = 0;
	map_info_map_supported_features = 0;
}

void(void) map_info_shutdown {
	map_info_clear_temps();
	map_info_filter_free();
	map_info_cache_destroy();
	if (map_info_globopen) {
		search_end(map_info_globhandle);
		map_info_globhandle = -1;
		map_info_globopen = FALSE;
	}
}

float(void) map_info_forbidden_flags {
	float f;
	f = MAP_INFO_FLAG_FORBIDDEN;
#ifndef MENUQC
	if not(cvar("g_maplist_allow_hidden"))
#endif
		f |= MAP_INFO_FLAG_HIDDEN;

	if not(cvar("g_maplist_allow_frustrating"))
		f |= MAP_INFO_FLAG_FRUSTRATING;

	return f;
}

float(void) map_info_required_flags {
	float f;
	f = 0;
	if (cvar("g_maplist_allow_frustrating") > 1)
		f |= MAP_INFO_FLAG_FRUSTRATING;

	return f;
}

void(void) map_info_on_restore {
	map_info_filtered_allocated = FALSE;
	map_info_globopen = FALSE;
	map_info_cache_active = FALSE;
	map_info_enumerate();
	map_info_filter_game_type(map_info_type_from_game_type(game_type_current()), map_info_required_flags(), map_info_forbidden_flags(), 1);
}
