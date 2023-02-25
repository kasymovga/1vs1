string map_name_stored;

float map_count, map_current;

// NOTE: this now expects the map list to be already tokenize()d and the count in map_count
float() map_list_get_position {
	float pos, idx;
	string map;
	map = mapname;
	idx = cvar("_g_maplist_index");
	if (idx >= 0)
		if (idx < map_count)
			if (map == argv(idx))
				return idx;

	for (pos = 0; pos < map_count; ++pos)
		if (map == argv(pos))
			return pos;

	// resume normal maplist rotation if current map is not in g_maplist
	return idx;
}

float(string map) map_has_right_size {
	float fh;
	if (bot_count || cvar("bot_number") || player_count < cvar("minplayers"))
	if (cvar("g_maplist_check_waypoints")) {
		if not(file_exists(strcat("maps/", map, ".waypoints")))
		if not(file_exists(strcat("maps/", map, ".waypoints.generated")))
			return FALSE;
	}
	// open map size restriction file
	fh = fopen(strcat("maps/", map, ".sizes"), FILE_READ);
	if (fh >= 0) {
		float mapmin, mapmax;
		mapmin = stof(fgets(fh));
		mapmax = stof(fgets(fh));
		fclose(fh);
		if (player_count < mapmin)
			return FALSE;

		if (player_count > mapmax)
			return FALSE;

		return TRUE;
	}
	return TRUE;
}

void(string m) map_mark_as_recent {
	registercvar("_g_maplist_mostrecent", "");
	float n = cvar("g_maplist_mostrecent_count");
	if (n < 1)
		cvar_set("_g_maplist_mostrecent", "");
	else {
		float i;
		string head, tail, recentlist;
		tail = cvar_string("_g_maplist_mostrecent");
		recentlist = m;
		n = n - 1;
		for (i = 0; i < n && tail != ""; i++) {
			head = str_car(tail);
			tail = str_cdr(tail);
			recentlist = strcat(recentlist, " ", head);
		}
		cvar_set("_g_maplist_mostrecent", recentlist);
	}
}

float(string m) map_is_recent {
	return (strstrofs(strcat(" ", cvar_string("_g_maplist_mostrecent"), " "), strcat(" ", m, " "), 0) >= 0);
}

float(float position, float pass) map_check {
	string map_next;
	map_next = argv(position);
	if (pass <= 1) {
		if (map_is_recent(map_next))
			return 0;
	}
	if (map_info_check_map(map_next)) {
		if (pass == 2)
			return 1;

		if (map_has_right_size(map_next))
			return 1;

		return 0;
	}
	return 0;
}

void(string nextmapname) map_next_set {
	str_unzone_ifneeded(map_name_stored);
	map_name_stored = str_zone_ifneeded(nextmapname);
}

void(float position) map_goto_set_index {
	registercvar("_g_maplist_index", "");
	cvar_set("_g_maplist_index", ftos(position));
	map_next_set(argv(position));
}

void() map_change {
	localcmd("\nsettemp_restore\n");
	print("Loading map: ", map_name_stored, "\n");
	map_info_load_map(map_name_stored);
}

// return codes of map selectors:
//   -1 = temporary failure (that is, try some method that is guaranteed to succeed)
//   -2 = permanent failure
float() map_list_method_iterate { // usual method
	float pass, i;
	for (pass = 1; pass <= 2; ++pass) {
		for (i = 1; i < map_count; ++i) {
			float mapindex;
			mapindex = math_mod(i + map_current, map_count);
			if (map_check(mapindex, pass))
				return mapindex;
		}
	}
	return -1;
}

float() map_list_method_random { // random map selection
	float i, imax;
	imax = 42;
	for (i = 0; i <= imax; ++i) {
		float mapindex;
		mapindex = math_mod(map_current + floor(random() * (map_count - 1) + 1), map_count); // any OTHER map
		if (map_check(mapindex, 1))
			return mapindex;
	}
	return -1;
}

float(float exponent) map_list_method_shuffle { // more clever shuffling
	// the exponent sets a bias on the map selection:
	// the higher the exponent, the less likely "shortly repeated" same maps are
	float i, j, imax, insertpos;
	imax = 42;
	for (i = 0; i <= imax; ++i) {
		string newlist;
		// now reinsert this at another position
		insertpos = pow(random(), 1 / exponent);       // ]0, 1]
		insertpos = insertpos * (map_count - 1);       // ]0, map_count - 1]
		insertpos = ceil(insertpos) + 1;               // {2, 3, 4, ..., map_count}
		// insert the current map there
		newlist = "";
		for (j = 1; j < insertpos; ++j)                 // i == 1: no loop, will be inserted as first; however, i == 1 has been excluded above
			newlist = strcat(newlist, " ", argv(j));

		newlist = strcat(newlist, " ", argv(0));       // now insert the just selected map
		for (j = insertpos; j < map_count; ++j)         // i == map_count: no loop, has just been inserted as last
			newlist = strcat(newlist, " ", argv(j));

		newlist = substring(newlist, 1, strlen(newlist) - 1);
		cvar_set("_g_maplist", newlist);
		map_count = tokenizebyseparator(cvar_string("_g_maplist"), " ");
		// NOTE: the selected map has just been inserted at (insertpos-1)th position
		map_current = insertpos - 1; // this is not really valid, but this way the fallback has a chance of working
		if (map_check(map_current, 1))
			return map_current;
	}
	return -1;
}

void(void) map_list_filter {
	string sf = "";
	float n = tokenizebyseparator(cvar_string("_g_maplist"), " ");
	float i;
	for (i = 0; i < n; i++) {
		if (map_check(i, 2))
			sf = strcat(sf, " ", argv(i));
	}
	cvar_set("_g_maplist", sf);
}

string(float pRequiredFlags, float pForbiddenFlags) map_list_allowed_maps {
	string out;
	float i;
	// to make absolutely sure:
	map_info_enumerate();
	map_info_filter_game_type(map_info_type_from_game_type(game_type_current()), pRequiredFlags, pForbiddenFlags, 0);
	out = "";
	for (i = 0; i < map_info_count; ++i)
		out = strcat(out, " ", map_info_glob_item(map_info_filter_list_lookup(i)));

	return substring(out, 1, strlen(out) - 1);
}

void(void) map_list_reset {
	print("Building map list...\n");
	string exclude = strcat(" ", cvar_string("g_maplist_exclude"), " ");
	string list = "";
	string h, t = map_list_allowed_maps(map_info_required_flags(), map_info_forbidden_flags());
	while (t != "") {
		h = str_car(t);
		t = str_cdr(t);
		if (strstrofs(exclude, strcat(" ", h, " "), 0) >= 0) {
			print("Map ", h, " excluded from map list\n");
			continue;
		}
		list = strcat(list, h, " ");
	}
	cvar_set("_g_maplist", list);
	print("Map list size: ", ftos(strlen(list)), "\n");
	map_list_filter();
	if (cvar("g_maplist_shuffle"))
		map_list_shuffle();
}

void(void) map_list_init {
	string s = cvar_string("g_maplist");
	string se = cvar_string("g_maplist_exclude");
	string gt = game_type_name(game_type_current());
	registercvar("_g_maplist_gametype", "");
	registercvar("_g_maplist_source", "");
	registercvar("_g_maplist_source_exclude", "");
	registercvar("_g_maplist", "");
	if (s != cvar_string("_g_maplist_source") || se != cvar_string("_g_maplist_source_exclude") || gt != cvar_string("_g_maplist_gametype")) {
		print("Map list refiltering required...\n");
		cvar_set("_g_maplist_gametype", gt);
		cvar_set("_g_maplist", s);
		map_list_filter();
		cvar_set("_g_maplist_source", s);
		cvar_set("_g_maplist_source_exclude", se);
		if (cvar("g_maplist_shuffle"))
			map_list_shuffle();
	}
	map_count = tokenizebyseparator(cvar_string("_g_maplist"), " ");
	if (map_count == 0) {
		map_list_reset();
		map_count = tokenizebyseparator(cvar_string("_g_maplist"), " ");
	}
	if (map_count == 0)
		error("empty maplist, cannot select a new map");

	map_current = bound(0, map_list_get_position(), map_count - 1);
}

string() map_list_next_get {
	float nextMap;
	map_list_init();
	nextMap = -1;
	if (cvar("g_maplist_shuffle") > 0)
		nextMap = map_list_method_shuffle(cvar("g_maplist_shuffle") + 1);

	if (nextMap == -1)
		if (cvar("g_maplist_selectrandom"))
			nextMap = map_list_method_random();

	if (nextMap == -1)
		nextMap = map_list_method_iterate();

	if (nextMap == -1)
	if (map_check(map_current, 2))
		nextMap = map_current;

	if (nextMap >= 0) {
		map_goto_set_index(nextMap);
		return map_name_stored;
	}
	return "";
}

float() map_do_next_override {
	if (g_campaign) {
		campaign_postintermission();
		if (!campaign_map_transition) {
			map_already_changed = TRUE;
			return TRUE;
		}
	}
	if (cvar("quit_when_empty")) {
		if (player_count <= bot_count) {
			localcmd("quit\n");
			map_already_changed = TRUE;
			return TRUE;
		}
	}
	if (cvar_string("quit_and_redirect") != "") {
		redirection_target = strzone(cvar_string("quit_and_redirect"));
		map_already_changed = TRUE;
		return TRUE;
	}
	if (plugin_map_restart()) {
		localcmd("restart\n");
		map_already_changed = TRUE;
		return TRUE;
	}
	if (cvar_string("nextmap") != "") {
		print("Have nextmap override (", cvar_string("nextmap"), ")\n");
		if (map_info_check_map(cvar_string("nextmap"))) {
			print("nextmap override successful\n");
			map_next_set(cvar_string("nextmap"));
			map_change();
			map_already_changed = TRUE;
			return TRUE;
		} else {
			print("nextmap override don't support game mode\n");
		}
	}
	return FALSE;
}

void() map_goto_next {
	//local string nextmap;
	//local float n, nummaps;
	//local string s;
	if (map_already_changed)
		return;

	map_already_changed = TRUE;
	string nextMap;
	float allowReset;
	for (allowReset = 1; allowReset >= 0; --allowReset) {
		nextMap = map_list_next_get();
		if (nextMap != "")
			break;

		if (allowReset) {
			print( "Maplist contains no single playable map!  Resetting it to default map list.\n" );
			map_list_reset();
		} else {
			error("Everything is broken - not even the default map list works. Please report this to the developers.");
		}
	}
	map_change();
}

string(string m) map_goto {
	if not(map_info_get_game_types(m) & (map_info_type_from_game_type(game_type_current()) | game_type_vote_mapinfo_mask))
		return "The map you chose is not available on this server.";

	cvar_set("nextmap", m);
	cvar_set("timelimit", "-1");
	if (map_vote_initialized || map_already_changed) {
		if (map_do_next_override())
			return "Map switch initiated.";
		else
			return "Hm... no. For some reason I like THIS map more.";
	}
	else
		return "Map switch will happen after scoreboard.";
}

void() map_list_shuffle {
	cvar_set("_g_maplist", str_shuffle_words(cvar_string("_g_maplist")));
}

entity map_intermission;
void(void) map_intermission_screenshot {
	entity e;
	if (cvar("sv_autoscreenshot"))
	FOR_EACH_CLIENT(e) {
		if (clienttype(self) == CLIENTTYPE_REAL)
			stuffcmd(self, "\nscreenshot\necho \"^5A screenshot has been taken at request of the server.\"\n");

		return;
	}
}

void(void) map_intermission_think {
	self.nextthink = time + frametime;
	if (game_type_vote_think()) {
		return;
	}
	map_vote_start();
}

void() map_finish {
	string s;
	entity e;
	map_finished = TRUE;
	string map_finished_message;
	rank_distribute(world);
	map_finished_message = "^2Game finished!";
	if (team_mode) {
		if (score_winning_condition_helper_winnerteam > 0)
			map_finished_message = strcat(map_finished_message, "\n", team_color_code(score_winning_condition_helper_winnerteam), team_color_name(score_winning_condition_helper_winnerteam), " Team^2 wins!");
	} else {
		if (score_winning_condition_helper_winner)
			map_finished_message = strcat(map_finished_message, "\nThe winner is ", score_winning_condition_helper_winner.netname);
	}
	game_status_set(plugin_map_finish_message_mod(map_finished_message), 30);
	sound_play2all("misc/menu2.wav");
	map_intermission_running = 1;
	FOR_EACH_CLIENT(e) {
		e.solid = SOLID_NOT;
		e.movetype = MOVETYPE_NONE;
		e.takedamage = DAMAGE_NO;
		if (e.weaponentity) {
			e.weaponentity.effects = EFFECT_NODRAW;
			if (e.weaponentity.weaponentity)
				e.weaponentity.weaponentity.effects = EFFECT_NODRAW;
		}
		if (clienttype(e) == CLIENTTYPE_REAL) {
			s = cvar_string("sv_intermission_cdtrack");
			if (s != "")
				stuffcmd(e, strcat("\ncd loop ", s, "\n"));
		}
	}
	// enforce a wait time before allowing changelevel
	if (player_count > 0)
		map_intermission_exittime = time + cvar("sv_mapchange_delay");
	else
		map_intermission_exittime = -1;

	map_intermission = spawn();
	map_intermission.think = map_intermission_think;
	if (cvar("sv_autoscreenshot")) {
		defer(0.8, map_intermission_screenshot);
		map_intermission.nextthink = time + max(1 + time, cvar("sv_mapchange_delay"));
	} else {
		map_intermission.nextthink = time + max(frametime, cvar("sv_mapchange_delay"));
	}
	vote_reset();
	world_dump_stats(TRUE);
	IRC_Announce_GameOver();
	FOR_EACH_CLIENT(other) {
		if (other.winning)
			bprint(other.netname, " ^7wins.\n");
	}
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_GAMEOVER);
	if (g_campaign)
		campaign_preintermission();

	localcmd("\nsv_hook_gameend;");
	cvar_set("timelimit", "-1");
}
