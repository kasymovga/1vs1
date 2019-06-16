void map_goto_next();
void() map_list_shuffle;
float() map_do_next_override;

void() map_goto_first_map_think {
	float n;
	if(cvar("_sv_init"))
	{
		// cvar_set("_sv_init", "0");
		// we do NOT set this to 0 any more, so someone "accidentally" changing
		// to this "init" map on a dedicated server will cause no permanent
		// harm
		if(cvar("g_maplist_shuffle"))
			map_list_shuffle();

		n = tokenizebyseparator(cvar_string("g_maplist"), " ");
		cvar_set("g_maplist_index", ftos(n - 1)); // jump to map 0 in map_goto_next
		MapInfo_Enumerate();
		MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		if(!map_do_next_override())
			map_goto_next();

		return;
	}
	if(time < 5)
		self.nextthink = time;
	else {
		self.nextthink = time + 1;
		print("Waiting for _sv_init being set to 1 by initialization scripts...\n");
	}
}

void() map_goto_first_map {
	entity e = spawn();
	e.think = map_goto_first_map_think;
	e.nextthink = time;
}

string getmapname_stored;

float Map_Count, Map_Current;
string Map_Current_Name;

// NOTE: this now expects the map list to be already tokenize()d and the count in Map_Count
float() map_list_get_position {
	float pos, idx;
	string map;

	map = mapname;
	idx = cvar("g_maplist_index");

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
	if(currentbots || cvar("bot_number") || player_count < cvar("minplayers"))
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

string strwords(string s, float w)
{
	float endpos;
	for(endpos = 0; w && endpos >= 0; --w)
		endpos = strstrofs(s, " ", endpos + 1);
	if(endpos < 0)
		return s;
	else
		return substring(s, 0, endpos);
}

float strhasword(string s, string w)
{
	return strstrofs(strcat(" ", s, " "), strcat(" ", w, " "), 0) >= 0;
}

void(string m) map_mark_as_recent {
	cvar_set("g_maplist_mostrecent", strwords(strcat(m, " ", cvar_string("g_maplist_mostrecent")), max(0, cvar("g_maplist_mostrecent_count"))));
}

float(string m) map_is_recent {
	return strhasword(cvar_string("g_maplist_mostrecent"), m);
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
	cvar_set("g_maplist_index", ftos(position));
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
			mapindex = mod(i + Map_Current, Map_Count);
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
		mapindex = mod(Map_Current + floor(random() * (Map_Count - 1) + 1), Map_Count); // any OTHER map
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
		cvar_set("g_maplist", newlist);
		Map_Count = tokenizebyseparator(cvar_string("g_maplist"), " ");

		// NOTE: the selected map has just been inserted at (insertpos-1)th position
		Map_Current = insertpos - 1; // this is not really valid, but this way the fallback has a chance of working
		if(map_check(Map_Current, 1))
			return Map_Current;
	}
	return -1;
}

void map_list_init() {
	Map_Count = tokenizebyseparator(cvar_string("g_maplist"), " ");
	if(Map_Count == 0) {
		bprint( "Maplist is empty!  Resetting it to default map list.\n" );
		cvar_set("g_maplist", MapInfo_ListAllowedMaps(MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags()));
		if(cvar("g_maplist_shuffle"))
			map_list_shuffle();
			
		localcmd("\nmenu_cmd sync\n");
		Map_Count = tokenizebyseparator(cvar_string("g_maplist"), " ");
	}
	if(Map_Count == 0)
		error("empty maplist, cannot select a new map");
	Map_Current = bound(0, map_list_get_position(), Map_Count - 1);
	if(Map_Current_Name)
		strunzone(Map_Current_Name);

	Map_Current_Name = strzone(argv(Map_Current)); // will be automatically freed on exit thanks to DP
	// this may or may not be correct, but who cares, in the worst case a map
	// isn't chosen in the first pass that should have been
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
};

float() map_do_next_override {
	if(g_campaign)
	{
		CampaignPostIntermission();
		if (!campaign_map_transition) {
			alreadychangedlevel = TRUE;
			return TRUE;
		}
	}
	if(cvar("quit_when_empty"))
	{
		if(player_count <= currentbots)
		{
			localcmd("quit\n");
			alreadychangedlevel = TRUE;
			return TRUE;
		}
	}
	if(cvar_string("quit_and_redirect") != "")
	{
		redirection_target = strzone(cvar_string("quit_and_redirect"));
		alreadychangedlevel = TRUE;
		return TRUE;
	}
	if (cvar("samelevel") || GameHook_SameLevel()) // if samelevel is set, stay on same level
	{
		// this does not work because it tries to exec maps/nexdm01.mapcfg (which doesn't exist, it should be trying maps/dm_nexdm01.mapcfg for example)
		//localcmd(strcat("exec \"maps/", mapname, ".mapcfg\"\n"));
		// so instead just restart the current map using the restart command (DOES NOT WORK PROPERLY WITH exit_cfg STUFF)
		localcmd("restart\n");
		//changelevel (mapname);
		alreadychangedlevel = TRUE;
		return TRUE;
	}
	if(cvar_string("nextmap") != "")
		if(MapInfo_CheckMap(cvar_string("nextmap")))
		{
			map_next_set(cvar_string("nextmap"));
			map_change();
			alreadychangedlevel = TRUE;
			return TRUE;
		}
	return FALSE;
};

void() map_goto_next {
	//local string nextmap;
	//local float n, nummaps;
	//local string s;
	if (alreadychangedlevel)
		return;

	alreadychangedlevel = TRUE;
	string nextMap;
	float allowReset;
	for(allowReset = 1; allowReset >= 0; --allowReset) {
		nextMap = map_list_next_get();
		if(nextMap != "")
			break;

		if(allowReset) {
			bprint( "Maplist contains no single playable map!  Resetting it to default map list.\n" );
			cvar_set("g_maplist", MapInfo_ListAllowedMaps(MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags()));
			if(cvar("g_maplist_shuffle"))
				map_list_shuffle();

			localcmd("\nmenu_cmd sync\n");
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
	if(mapvote_initialized || alreadychangedlevel) {
		if(map_do_next_override())
			return "Map switch initiated.";
		else
			return "Hm... no. For some reason I like THIS map more.";
	}
	else
		return "Map switch will happen after scoreboard.";
}

void() map_list_shuffle {
	cvar_set("g_maplist", shufflewords(cvar_string("g_maplist")));
}
