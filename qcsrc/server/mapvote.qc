float mapvote_nextthink;
float mapvote_keeptwotime;
float mapvote_timeout;
string mapvote_message;
string mapvote_screenshot_dir;

float mapvote_count;
float mapvote_count_real;
string mapvote_maps[MAPVOTE_COUNT];
string mapvote_pictures[MAPVOTE_COUNT];
float mapvote_maps_suggested[MAPVOTE_COUNT];
string mapvote_suggestions[MAPVOTE_COUNT];
float mapvote_suggestion_ptr;
float mapvote_maxlen;
float mapvote_voters;
float mapvote_votes[MAPVOTE_COUNT];
float mapvote_run;
float mapvote_detail;
float mapvote_abstain;
.float mapvote;

void() mapvote_spawn;

void() mapvote_clear_all_votes {
	FOR_EACH_CLIENT(other) {
		other.impulse = 0;
		other.mapvote = 0;
	}
}

string(string m) mapvote_suggest {
	float i;
	if(m == "")
		return "That's not how to use this command.";
	if(!cvar("g_maplist_votable_suggestions"))
		return "Suggestions are not accepted on this server.";
	if(mapvote_initialized)
		return "Can't suggest - voting is already in progress!";
	m = MapInfo_FixName(m);
	if(!m)
		return "The map you suggested is not available on this server.";
	if(!cvar("g_maplist_votable_override_mostrecent"))
		if(map_is_recent(m))
			return "This server does not allow for recent maps to be played again. Please be patient for some rounds.";

	if(!MapInfo_CheckMap(m))
		return "The map you suggested does not support the current game mode.";
	for(i = 0; i < mapvote_suggestion_ptr; ++i)
		if(mapvote_suggestions[i] == m)
			return "This map was already suggested.";
	if(mapvote_suggestion_ptr >= MAPVOTE_COUNT)
	{
		i = floor(random() * mapvote_suggestion_ptr);
	}
	else
	{
		i = mapvote_suggestion_ptr;
		mapvote_suggestion_ptr += 1;
	}
	if(mapvote_suggestions[i] != "")
		strunzone(mapvote_suggestions[i]);
	mapvote_suggestions[i] = strzone(m);
	return strcat("Suggestion of ", m, " accepted.");
}

void(string nextMap, float isSuggestion) mapvote_add_votable {
	float j;
	if(nextMap == "")
		return;
	for(j = 0; j < mapvote_count; ++j)
		if(mapvote_maps[j] == nextMap)
			return;
	if(strlen(nextMap) > mapvote_maxlen)
		mapvote_maxlen = strlen(nextMap);

	mapvote_maps[mapvote_count] = strzone(nextMap);
	MapInfo_Get_ByName(nextMap, 0, 0);
	string picture = MapInfo_Map_image;
	if (picture == "")
		picture = "gfx/menu/silver/background_ingame";

	mapvote_pictures[mapvote_count] = strzone(picture);
	mapvote_maps_suggested[mapvote_count] = isSuggestion;
	mapvote_count += 1;
}

void() mapvote_init {
	float i;
	float nmax, smax;
	mapvote_clear_all_votes();
	mapvote_count = 0;
	mapvote_detail = !cvar("g_maplist_votable_nodetail");
	mapvote_abstain = cvar("g_maplist_votable_abstain");
	if(mapvote_abstain)
		nmax = min(MAPVOTE_COUNT - 1, cvar("g_maplist_votable"));
	else
		nmax = min(MAPVOTE_COUNT, cvar("g_maplist_votable"));

	smax = min3(nmax, cvar("g_maplist_votable_suggestions"), mapvote_suggestion_ptr);
	if(mapvote_suggestion_ptr)
		for(i = 0; i < 100 && mapvote_count < smax; ++i)
			mapvote_add_votable(mapvote_suggestions[floor(random() * mapvote_suggestion_ptr)], TRUE);

	for(i = 0; i < 100 && mapvote_count < nmax; ++i)
		mapvote_add_votable(map_list_next_get(), FALSE);

	if(mapvote_count == 0) {
		map_list_reset();
		for(i = 0; i < 100 && mapvote_count < nmax; ++i)
			mapvote_add_votable(map_list_next_get(), FALSE);
	}
	mapvote_count_real = mapvote_count;
	if(mapvote_abstain)
		mapvote_add_votable("don't care", 0);

	mapvote_keeptwotime = time + cvar("g_maplist_votable_keeptwotime");
	mapvote_timeout = time + cvar("g_maplist_votable_timeout");
	if(mapvote_count_real < 3 || mapvote_keeptwotime <= time)
		mapvote_keeptwotime = 0;
	mapvote_message = "Choose a map and press its key!";
	mapvote_screenshot_dir = cvar_string("g_maplist_votable_screenshot_dir");
	if(mapvote_screenshot_dir == "")
		mapvote_screenshot_dir = "maps";
	mapvote_screenshot_dir = strzone(mapvote_screenshot_dir);
	mapvote_spawn();
}

void mapvote_send_picture(float id) {
	msg_entity = self;
	WriteByte(MSG_ONE, SVC_TEMPENTITY);
	WriteByte(MSG_ONE, TE_CSQC_PICTURE);
	WriteByte(MSG_ONE, id);
	WritePicture(MSG_ONE, strcat(mapvote_screenshot_dir, "/", mapvote_maps[id]), 3072);
}

float mapvote_client_command(string cmd) {
	if(!map_intermission_running)
		return FALSE;

	if(cmd == "mv_getpic") {
		mapvote_send_picture(stof(argv(1)));
		return TRUE;
	}
	if(cmd == "suggestmap") {
		sprint(self, strcat(mapvote_suggest(argv(1)), "\n"));
		return TRUE;
	}
	return FALSE;
}

float mapvote_mask() {
	float mask, i, power;
	mask = 0;
	for(i = 0, power = 1; i < mapvote_count; ++i, power *= 2)
		if(mapvote_maps[i] != "")
			mask |= power;
	return mask;
}

entity mapvote_ent;
#define mapvote_send MapVote_SendEntity
float(entity to, float sf) mapvote_send {
	string picfile, pakfile;
	float i, o;
	if(sf & 1)
		sf &~= 2; // if we send 1, we don't need to also send 2

	WriteByte(MSG_ENTITY, ENT_CLIENT_MAPVOTE);
	WriteByte(MSG_ENTITY, sf);
	if(sf & 1) {
		// flag 1 == initialization
		WriteString(MSG_ENTITY, MapInfo_HumanString_FromType(MapInfo_CurrentGametype()));
		WriteByte(MSG_ENTITY, mapvote_count);
		WriteByte(MSG_ENTITY, mapvote_abstain);
		WriteByte(MSG_ENTITY, mapvote_detail);
		WriteCoord(MSG_ENTITY, mapvote_timeout);
		if(mapvote_count <= 8)
			WriteByte(MSG_ENTITY, mapvote_mask());
		else
			WriteShort(MSG_ENTITY, mapvote_mask());

		for(i = 0; i < mapvote_count; ++i)
			if(mapvote_maps[i] != "") {
				if(mapvote_abstain && i == mapvote_count - 1) {
					WriteString(MSG_ENTITY, ""); // abstain needs no text
					WriteString(MSG_ENTITY, ""); // abstain needs no pack
				} else {
					WriteString(MSG_ENTITY, mapvote_maps[i]);
					picfile = mapvote_pictures[i];
					WriteString(MSG_ENTITY, picfile);
					pakfile = whichpack(picfile);
					for(o = strstrofs(pakfile, "/", 0)+1; o > 0; o = strstrofs(pakfile, "/", 0)+1)
						pakfile = substring(pakfile, o, 999);

					WriteString(MSG_ENTITY, pakfile);
				}
			}
	}
	if(sf & 2) {
		// flag 2 == update of mask
		if(mapvote_count <= 8)
			WriteByte(MSG_ENTITY, mapvote_mask());
		else
			WriteShort(MSG_ENTITY, mapvote_mask());
	}
	if(sf & 4) {
		if(mapvote_detail)
			for(i = 0; i < mapvote_count; ++i)
				if(mapvote_maps[i] != "")
					WriteByte(MSG_ENTITY, mapvote_votes[i]);

		WriteByte(MSG_ENTITY, to.mapvote);
	}
	return TRUE;
}

void() mapvote_spawn {
	net_link_entity(mapvote_ent = spawn(), FALSE, 0, mapvote_send);
}

void() mapvote_touch_mask {
	mapvote_ent.SendFlags |= 2;
}

void(entity voter) mapvote_touch_votes {
	mapvote_ent.SendFlags |= 4;
}

float(float mappos) mapvote_finished {
	FOR_EACH_REALCLIENT(other)
		client_fix_cvars(other);

	map_next_set(mapvote_maps[mappos]);
	map_change();
	map_already_changed = TRUE;
	return TRUE;
}
void() mapvote_check_rules1 {
	float i;
	for(i = 0; i < mapvote_count; ++i) if(mapvote_maps[i] != "")
		mapvote_votes[i] = 0;

	mapvote_voters = 0;
	FOR_EACH_REALCLIENT(other) {
		++mapvote_voters;
		if(other.mapvote) {
			i = other.mapvote - 1;
			mapvote_votes[i] = mapvote_votes[i] + 1;
		}
	}
}

float() mapvote_check_rules2 {
	float i;
	float firstPlace, secondPlace;
	float firstPlaceVotes, secondPlaceVotes;
	float mapvote_voters_real;
	string result;

	if(mapvote_count_real == 1)
		return mapvote_finished(0);

	mapvote_voters_real = mapvote_voters;
	if(mapvote_abstain)
		mapvote_voters_real -= mapvote_votes[mapvote_count - 1];

	random_selection_init();
	for(i = 0; i < mapvote_count_real; ++i) if(mapvote_maps[i] != "")
		random_selection_add(world, i, string_null, 1, mapvote_votes[i]);

	firstPlace = random_selection_chosen_float;
	firstPlaceVotes = random_selection_best_priority;
	random_selection_init();
	for(i = 0; i < mapvote_count_real; ++i) if(mapvote_maps[i] != "")
		if(i != firstPlace)
			random_selection_add(world, i, string_null, 1, mapvote_votes[i]);

	secondPlace = random_selection_chosen_float;
	secondPlaceVotes = random_selection_best_priority;
	if(firstPlace == -1)
		error("No first place in map vote... WTF?");

	if(secondPlace == -1 || time > mapvote_timeout || (mapvote_voters_real - firstPlaceVotes) < firstPlaceVotes)
		return mapvote_finished(firstPlace);

	if(mapvote_keeptwotime)
		if(time > mapvote_keeptwotime || (mapvote_voters_real - firstPlaceVotes - secondPlaceVotes) < secondPlaceVotes) {
			float didntvote;
			mapvote_touch_mask();
			mapvote_message = "Now decide between the TOP TWO!";
			mapvote_keeptwotime = 0;
			result = strcat(":vote:keeptwo:", mapvote_maps[firstPlace]);
			result = strcat(result, ":", ftos(firstPlaceVotes));
			result = strcat(result, ":", mapvote_maps[secondPlace]);
			result = strcat(result, ":", ftos(secondPlaceVotes), "::");
			didntvote = mapvote_voters;
			for(i = 0; i < mapvote_count; ++i)
				if(mapvote_maps[i] != "") {
					didntvote -= mapvote_votes[i];
					if(i != firstPlace)
						if(i != secondPlace)
						{
							result = strcat(result, ":", mapvote_maps[i]);
							result = strcat(result, ":", ftos(mapvote_votes[i]));
							if(i < mapvote_count_real)
							{
								strunzone(mapvote_maps[i]);
								mapvote_maps[i] = "";
							}
						}
				}
			result = strcat(result, ":didn't vote:", ftos(didntvote));
		}
	return FALSE;
}
void() mapvote_tick {
	float keeptwo;
	float totalvotes;
	keeptwo = mapvote_keeptwotime;
	mapvote_check_rules1(); // count
	if(mapvote_check_rules2()) // decide
		return;

	totalvotes = 0;
	FOR_EACH_REALCLIENT(other) {
		// clear possibly invalid votes
		if(mapvote_maps[other.mapvote - 1] == "")
			other.mapvote = 0;

		// use impulses as new vote
		if(other.impulse >= 1 && other.impulse <= mapvote_count)
			if(mapvote_maps[other.impulse - 1] != "")
			{
				other.mapvote = other.impulse;
				mapvote_touch_votes(other);
			}

		other.impulse = 0;
		if(other.mapvote)
			++totalvotes;
	}
	mapvote_check_rules1(); // just count
}

void() mapvote_start {
	if(mapvote_run)
		return;

	MapInfo_Enumerate();
	if(MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1))
		mapvote_run = TRUE;
}

void mapvote_think() {
	if(!mapvote_run)
		return;

	if(map_already_changed)
		return;

	if(time < mapvote_nextthink)
		return;

	mapvote_nextthink = time + 0.5;
	if(!mapvote_initialized) {
		mapvote_initialized = TRUE;
		if(map_do_next_override())
			return;
			
		if(!cvar("g_maplist_votable") || player_count <= 0) {
			map_goto_next();
			return;
		}
		mapvote_init();
	}
	mapvote_tick();
}
