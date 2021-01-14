string getmapname_stored;

float Map_Count, Map_Current;

// NOTE: this now expects the map list to be already tokenize()d and the count in Map_Count
float() map_list_get_position {
	float pos, idx;
	string map;

	map = mapname;
	idx = cvar("_g_maplist_index");

	if(idx >= 0)
		if(idx < Map_Count)
			if(map == argv(idx))
				return idx;

	for(pos = 0; pos < Map_Count; ++pos)
		if(map == argv(pos))
			return pos;

	// resume normal maplist rotation if current map is not in g_maplist
	return idx;
}

float(string map) map_has_right_size {
	float fh;
	if(bot_count || cvar("bot_number") || player_count < cvar("minplayers"))
	if(cvar("g_maplist_check_waypoints"))
	{
		fh = fopen(strcat("maps/", map, ".waypoints"), FILE_READ);
		if(fh < 0)
			return FALSE;

		fclose(fh);
	}
	// open map size restriction file
	fh = fopen(strcat("maps/", map, ".sizes"), FILE_READ);
	if(fh >= 0)
	{
		float mapmin, mapmax;
		mapmin = stof(fgets(fh));
		mapmax = stof(fgets(fh));
		fclose(fh);
		if(player_count < mapmin)
			return FALSE;

		if(player_count > mapmax)
			return FALSE;

		return TRUE;
	}
	return TRUE;
}

float strhasword(string s, string w)
{
	return strstrofs(strcat(" ", s, " "), strcat(" ", w, " "), 0) >= 0;
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
	return strhasword(cvar_string("_g_maplist_mostrecent"), m);
}

float(float position, float pass) map_check {
	string map_next;
	map_next = argv(position);
	if(pass <= 1)
	{
		if(map_is_recent(map_next))
			return 0;
	}
	if(MapInfo_CheckMap(map_next))
	{
		if(pass == 2)
			return 1;
		if(map_has_right_size(map_next))
			return 1;
		return 0;
	}
	return 0;
}

void(string nextmapname) map_next_set
{
	if(getmapname_stored != "")
		strunzone(getmapname_stored);
	if(nextmapname == "")
		getmapname_stored = "";
	else
		getmapname_stored = strzone(nextmapname);
}

void(float position) map_goto_set_index {
	registercvar("_g_maplist_index", "");
	cvar_set("_g_maplist_index", ftos(position));
	map_next_set(argv(position));
}

void() map_change {
	localcmd("\nsettemp_restore\n");
	MapInfo_LoadMap(getmapname_stored);
}

// return codes of map selectors:
//   -1 = temporary failure (that is, try some method that is guaranteed to succeed)
//   -2 = permanent failure
float() map_list_method_iterate = // usual method
{
	float pass, i;

	for(pass = 1; pass <= 2; ++pass)
	{
		for(i = 1; i < Map_Count; ++i)
		{
			float mapindex;
			mapindex = math_mod(i + Map_Current, Map_Count);
			if(map_check(mapindex, pass))
				return mapindex;
		}
	}
	return -1;
}

float() map_list_method_repeat = // fallback method
{
	if(map_check(Map_Current, 2))
		return Map_Current;
	return -2;
}

float() map_list_method_random = // random map selection
{
	float i, imax;

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		float mapindex;
		mapindex = math_mod(Map_Current + floor(random() * (Map_Count - 1) + 1), Map_Count); // any OTHER map
		if(map_check(mapindex, 1))
			return mapindex;
	}
	return -1;
}

float(float exponent) map_list_method_shuffle = // more clever shuffling
// the exponent sets a bias on the map selection:
// the higher the exponent, the less likely "shortly repeated" same maps are
{
	float i, j, imax, insertpos;

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		string newlist;

		// now reinsert this at another position
		insertpos = pow(random(), 1 / exponent);       // ]0, 1]
		insertpos = insertpos * (Map_Count - 1);       // ]0, Map_Count - 1]
		insertpos = ceil(insertpos) + 1;               // {2, 3, 4, ..., Map_Count}
		// insert the current map there
		newlist = "";
		for(j = 1; j < insertpos; ++j)                 // i == 1: no loop, will be inserted as first; however, i == 1 has been excluded above
			newlist = strcat(newlist, " ", argv(j));
		newlist = strcat(newlist, " ", argv(0));       // now insert the just selected map
		for(j = insertpos; j < Map_Count; ++j)         // i == Map_Count: no loop, has just been inserted as last
			newlist = strcat(newlist, " ", argv(j));
		newlist = substring(newlist, 1, strlen(newlist) - 1);
		cvar_set("_g_maplist", newlist);
		Map_Count = tokenizebyseparator(cvar_string("_g_maplist"), " ");

		// NOTE: the selected map has just been inserted at (insertpos-1)th position
		Map_Current = insertpos - 1; // this is not really valid, but this way the fallback has a chance of working
		if(map_check(Map_Current, 1))
			return Map_Current;
	}
	return -1;
}

void(void) map_list_reset {
	print("Building map list.\n");
	string exclude = strcat(" ", cvar_string("g_maplist_exclude"), " ");
	string list;
	string h, t = MapInfo_ListAllowedMaps(MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags());
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
}

void(void) map_list_init {
	string s = cvar_string("g_maplist");
	string se = cvar_string("g_maplist_exclude");
	string gt = gametype_name(MapInfo_CurrentGametype());
	registercvar("_g_maplist_gametype", "");
	registercvar("_g_maplist_source", "");
	registercvar("_g_maplist_source_exclude", "");
	registercvar("_g_maplist", "");
	if (s != cvar_string("_g_maplist_source") || se != cvar_string("_g_maplist_source_exclude") || gt != cvar_string("_g_maplist_gametype")) {
		cvar_set("_g_maplist_gametype", gt);
		cvar_set("_g_maplist", s);
		cvar_set("_g_maplist_source", s);
		cvar_set("_g_maplist_source_exclude", se);
	}
	Map_Count = tokenizebyseparator(cvar_string("_g_maplist"), " ");
	if(Map_Count == 0) {
		map_list_reset();
		Map_Count = tokenizebyseparator(cvar_string("_g_maplist"), " ");
	}
	if(Map_Count == 0)
		error("empty maplist, cannot select a new map");
	Map_Current = bound(0, map_list_get_position(), Map_Count - 1);
}

string() map_list_next_get {
	float nextMap;
	map_list_init();
	nextMap = -1;
	if(nextMap == -1)
		if(cvar("g_maplist_shuffle") > 0)
			nextMap = map_list_method_shuffle(cvar("g_maplist_shuffle") + 1);

	if(nextMap == -1)
		if(cvar("g_maplist_selectrandom"))
			nextMap = map_list_method_random();

	if(nextMap == -1)
		nextMap = map_list_method_iterate();

	if(nextMap == -1)
		nextMap = map_list_method_repeat();

	if(nextMap >= 0)
	{
		map_goto_set_index(nextMap);
		return getmapname_stored;
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
	if(cvar("quit_when_empty"))
	{
		if(player_count <= bot_count)
		{
			localcmd("quit\n");
			map_already_changed = TRUE;
			return TRUE;
		}
	}
	if(cvar_string("quit_and_redirect") != "")
	{
		redirection_target = strzone(cvar_string("quit_and_redirect"));
		map_already_changed = TRUE;
		return TRUE;
	}
	if (gamehook_map_restart()) {
		localcmd("restart\n");
		map_already_changed = TRUE;
		return TRUE;
	}
	if(cvar_string("nextmap") != "")
		if(MapInfo_CheckMap(cvar_string("nextmap")))
		{
			map_next_set(cvar_string("nextmap"));
			map_change();
			map_already_changed = TRUE;
			return TRUE;
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
	for(allowReset = 1; allowReset >= 0; --allowReset) {
		nextMap = map_list_next_get();
		if(nextMap != "")
			break;

		if(allowReset) {
			print( "Maplist contains no single playable map!  Resetting it to default map list.\n" );
			map_list_reset();
			if(cvar("g_maplist_shuffle"))
				map_list_shuffle();
		} else {
			error("Everything is broken - not even the default map list works. Please report this to the developers.");
		}
	}
	map_change();
}

string(string m) map_goto {
	if not(MapInfo_GetGameTypes(m) & (MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()) | GameTypeVote_Mask()))
		return "The map you chose is not available on this server.";

	cvar_set("nextmap", m);
	cvar_set("timelimit", "-1");
	if(mapvote_initialized || map_already_changed) {
		if(map_do_next_override())
			return "Map switch initiated.";
		else
			return "Hm... no. For some reason I like THIS map more.";
	}
	else
		return "Map switch will happen after scoreboard.";
}

void() map_list_shuffle {
	cvar_set("_g_maplist", shufflewords(cvar_string("_g_maplist")));
}

entity map_intermission;
void(void) map_intermission_screenshot {
	entity e;
	if(cvar("sv_autoscreenshot"))
	FOR_EACH_CLIENT(e) {
		if(clienttype(self) == CLIENTTYPE_REAL)
			stuffcmd(self, "\nscreenshot\necho \"^5A screenshot has been taken at request of the server.\"\n");

		return;
	}
}

void(void) map_intermission_think {
	self.nextthink = time + frametime;
	if (GameTypeVote_Think()) {
		return;
	}
	mapvote_start();
}

void() map_finish {
	string s;
	entity e;
	map_finished = TRUE;
	string map_finished_message;
	map_finished_message = "^2Game finished!";
	if (team_mode) {
		if (score_winning_condition_helper_winnerteam > 0)
			map_finished_message = strcat(map_finished_message, "\n", team_color_code(score_winning_condition_helper_winnerteam), team_color_name(score_winning_condition_helper_winnerteam), " Team^2 wins!");
	} else {
		if (score_winning_condition_helper_winner)
			map_finished_message = strcat(map_finished_message, "\nThe winner is ", score_winning_condition_helper_winner.netname);
	}
	GameStatus_Set(gamehook_map_finish_message_mod(map_finished_message), 30);
	sound_play2all("misc/menu2.wav");
	map_intermission_running = 1;
	FOR_EACH_CLIENT(e) {
		e.solid = SOLID_NOT;
		e.movetype = MOVETYPE_NONE;
		e.takedamage = DAMAGE_NO;
		if(e.weaponentity) {
			e.weaponentity.effects = EF_NODRAW;
			if (e.weaponentity.weaponentity)
				e.weaponentity.weaponentity.effects = EF_NODRAW;
		}
		if(clienttype(e) == CLIENTTYPE_REAL) {
			stuffcmd(e, "\nscr_printspeed 1000000\n");
			s = cvar_string("sv_intermission_cdtrack");
			if(s != "")
				stuffcmd(e, strcat("\ncd loop ", s, "\n"));
		}
	}
// enforce a wait time before allowing changelevel
	if(player_count > 0)
		map_intermission_exittime = time + cvar("sv_mapchange_delay");
	else
		map_intermission_exittime = -1;

	map_intermission = spawn();
	map_intermission.think = map_intermission_think;
	if(cvar("sv_autoscreenshot")) {
		defer(0.8, map_intermission_screenshot);
		map_intermission.nextthink = time + max(1 + time, cvar("sv_mapchange_delay"));
	} else {
		map_intermission.nextthink = time + max(frametime, cvar("sv_mapchange_delay"));
	}
	vote_reset();
	world_dump_stats(TRUE);
	IRC_Announce_GameOver();
	FOR_EACH_CLIENT(other) {
		if(other.winning)
			bprint(other.netname, " ^7wins.\n");
	}
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_GAMEOVER);
	if (g_campaign)
		campaign_preintermission();

	localcmd("\nsv_hook_gameend;");
}
