float map_vote_nextthink;
float map_vote_keeptwotime;
float map_vote_timeout;
string map_vote_message;

float map_vote_count;
float map_vote_count_real;
string map_vote_maps[MAPVOTE_COUNT];
string map_vote_pictures[MAPVOTE_COUNT];
float map_vote_maps_suggested[MAPVOTE_COUNT];
string map_vote_suggestions[MAPVOTE_COUNT];
float map_vote_suggestion_ptr;
float map_vote_maxlen;
float map_vote_voters;
float map_vote_votes[MAPVOTE_COUNT];
float map_vote_run;
float map_vote_detail;
float map_vote_abstain;
.float mapvote;

void() map_vote_spawn;

void() map_vote_clear_all_votes {
	FOR_EACH_CLIENT(other) {
		other.impulse = 0;
		other.mapvote = 0;
	}
}

string(string m) map_vote_suggest {
	float i;
	if (m == "")
		return "That's not how to use this command.";

	if (!cvar("g_maplist_votable_suggestions"))
		return "Suggestions are not accepted on this server.";

	if (map_vote_initialized)
		return "Can't suggest - voting is already in progress!";

	m = map_info_fix_name(m);
	if (!m)
		return "The map you suggested is not available on this server.";

	if (!cvar("g_maplist_votable_override_mostrecent"))
		if (map_is_recent(m))
			return "This server does not allow for recent maps to be played again. Please be patient for some rounds.";

	if (!map_info_check_map(m))
		return "The map you suggested does not support the current game mode.";

	for (i = 0; i < map_vote_suggestion_ptr; ++i)
		if (map_vote_suggestions[i] == m)
			return "This map was already suggested.";

	if (map_vote_suggestion_ptr >= MAPVOTE_COUNT) {
		i = floor(random() * map_vote_suggestion_ptr);
	} else {
		i = map_vote_suggestion_ptr;
		map_vote_suggestion_ptr += 1;
	}
	if (map_vote_suggestions[i] != "")
		strunzone(map_vote_suggestions[i]);

	map_vote_suggestions[i] = strzone(m);
	return strcat("Suggestion of ", m, " accepted.");
}

void(string nextMap, float isSuggestion) map_vote_add_votable {
	float j;
	if (nextMap == "")
		return;
	for (j = 0; j < map_vote_count; ++j)
		if (map_vote_maps[j] == nextMap)
			return;

	if (strlen(nextMap) > map_vote_maxlen)
		map_vote_maxlen = strlen(nextMap);

	map_vote_maps[map_vote_count] = strzone(nextMap);
	map_info_get_by_name(nextMap, 0, 0);
	string picture = map_info_map_image;
	if (picture == "")
		picture = "gfx/m_nomap";

	map_vote_pictures[map_vote_count] = strzone(picture);
	map_vote_maps_suggested[map_vote_count] = isSuggestion;
	map_vote_count += 1;
}

void() map_vote_init {
	float i;
	float nmax, smax;
	map_vote_clear_all_votes();
	map_vote_count = 0;
	map_vote_detail = !cvar("g_maplist_votable_nodetail");
	map_vote_abstain = cvar("g_maplist_votable_abstain");
	if (map_vote_abstain)
		nmax = min(MAPVOTE_COUNT - 1, cvar("g_maplist_votable"));
	else
		nmax = min(MAPVOTE_COUNT, cvar("g_maplist_votable"));

	smax = min3(nmax, cvar("g_maplist_votable_suggestions"), map_vote_suggestion_ptr);
	if (map_vote_suggestion_ptr)
		for (i = 0; i < 100 && map_vote_count < smax; ++i)
			map_vote_add_votable(map_vote_suggestions[floor(random() * map_vote_suggestion_ptr)], TRUE);

	for (i = 0; i < 100 && map_vote_count < nmax; ++i)
		map_vote_add_votable(map_list_next_get(), FALSE);

	if (map_vote_count == 0) {
		map_list_reset();
		for (i = 0; i < 100 && map_vote_count < nmax; ++i)
			map_vote_add_votable(map_list_next_get(), FALSE);
	}
	map_vote_count_real = map_vote_count;
	if (map_vote_abstain)
		map_vote_add_votable("don't care", 0);

	map_vote_keeptwotime = time + cvar("g_maplist_votable_keeptwotime");
	map_vote_timeout = time + cvar("g_maplist_votable_timeout");
	if (map_vote_count_real < 3 || map_vote_keeptwotime <= time)
		map_vote_keeptwotime = 0;

	map_vote_message = "Choose a map and press its key!";
	map_vote_spawn();
}

void(float id) map_vote_send_picture {
	msg_entity = self;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_PICTURE);
	net_write_byte(MSG_ONE, id);
	net_write_picture(MSG_ONE, map_vote_pictures[id], 3072);
}

float map_vote_client_command(string cmd) {
	if (!map_intermission_running)
		return FALSE;

	if (cmd == "mv_getpic") {
		map_vote_send_picture(stof(argv(1)));
		return TRUE;
	}
	if (cmd == "suggestmap") {
		sprint(self, strcat(map_vote_suggest(argv(1)), "\n"));
		return TRUE;
	}
	return FALSE;
}

float() map_vote_mask {
	float mask, i, power;
	mask = 0;
	for (i = 0, power = 1; i < map_vote_count; ++i, power *= 2)
		if (map_vote_maps[i] != "")
			mask |= power;

	return mask;
}

entity map_vote_ent;
float(entity to, float sf) map_vote_send {
	string picfile, pakfile;
	float i, o;
	if (sf & 1)
		sf &= ~2; // if we send 1, we don't need to also send 2

	net_write_byte(MSG_ENTITY, NET_CSQC_MAPVOTE);
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		// flag 1 == initialization
		net_write_string(MSG_ENTITY, game_type_name_long(game_type_current()));
		net_write_byte(MSG_ENTITY, map_vote_count);
		net_write_byte(MSG_ENTITY, map_vote_abstain);
		net_write_byte(MSG_ENTITY, map_vote_detail);
		net_write_coord(MSG_ENTITY, map_vote_timeout);
		if (map_vote_count <= 8)
			net_write_byte(MSG_ENTITY, map_vote_mask());
		else
			net_write_short(MSG_ENTITY, map_vote_mask());

		for (i = 0; i < map_vote_count; ++i)
			if (map_vote_maps[i] != "") {
				if (map_vote_abstain && i == map_vote_count - 1) {
					net_write_string(MSG_ENTITY, ""); // abstain needs no text
					net_write_string(MSG_ENTITY, ""); // abstain needs no pack
				} else {
					net_write_string(MSG_ENTITY, map_vote_maps[i]);
					picfile = map_vote_pictures[i];
					net_write_string(MSG_ENTITY, picfile);
					pakfile = whichpack(strcat(picfile, ".tga"));
					if (pakfile == "")
						pakfile = whichpack(strcat(picfile, ".jpg"));

					if (pakfile == "")
						pakfile = whichpack(strcat(picfile, ".png"));

					for (o = strstrofs(pakfile, "/", 0)+1; o > 0; o = strstrofs(pakfile, "/", 0)+1)
						pakfile = substring(pakfile, o, 999);

					net_write_string(MSG_ENTITY, pakfile);
				}
			}
	}
	if (sf & 2) {
		// flag 2 == update of mask
		if (map_vote_count <= 8)
			net_write_byte(MSG_ENTITY, map_vote_mask());
		else
			net_write_short(MSG_ENTITY, map_vote_mask());
	}
	if (sf & 4) {
		if (map_vote_detail)
			for (i = 0; i < map_vote_count; ++i)
				if (map_vote_maps[i] != "")
					net_write_byte(MSG_ENTITY, map_vote_votes[i]);

		net_write_byte(MSG_ENTITY, to.mapvote);
	}
	return TRUE;
}

void() map_vote_spawn {
	net_link_entity(map_vote_ent = spawn(), FALSE, 0, map_vote_send);
}

void() map_vote_touch_mask {
	map_vote_ent.SendFlags |= 2;
}

void(entity voter) map_vote_touch_votes {
	map_vote_ent.SendFlags |= 4;
}

float(float mappos) map_vote_finished {
	FOR_EACH_REALCLIENT(other)
		client_fix_cvars(other);

	map_next_set(map_vote_maps[mappos]);
	map_change();
	map_already_changed = TRUE;
	return TRUE;
}
void() map_vote_check_rules1 {
	float i;
	for (i = 0; i < map_vote_count; ++i) if (map_vote_maps[i] != "")
		map_vote_votes[i] = 0;

	map_vote_voters = 0;
	FOR_EACH_REALCLIENT(other) {
		++map_vote_voters;
		if (other.mapvote) {
			i = other.mapvote - 1;
			map_vote_votes[i] = map_vote_votes[i] + 1;
		}
	}
}

float() map_vote_check_rules2 {
	float i;
	float firstPlace, secondPlace;
	float firstPlaceVotes, secondPlaceVotes;
	float map_vote_voters_real;
	string result;

	if (map_vote_count_real == 1)
		return map_vote_finished(0);

	map_vote_voters_real = map_vote_voters;
	if (map_vote_abstain)
		map_vote_voters_real -= map_vote_votes[map_vote_count - 1];

	random_selection_init();
	for (i = 0; i < map_vote_count_real; ++i) if (map_vote_maps[i] != "")
		random_selection_add(world, i, NULL, 1, map_vote_votes[i]);

	firstPlace = random_selection_chosen_float;
	firstPlaceVotes = random_selection_best_priority;
	random_selection_init();
	for (i = 0; i < map_vote_count_real; ++i) if (map_vote_maps[i] != "")
		if (i != firstPlace)
			random_selection_add(world, i, NULL, 1, map_vote_votes[i]);

	secondPlace = random_selection_chosen_float;
	secondPlaceVotes = random_selection_best_priority;
	if (firstPlace == -1)
		error("No first place in map vote... WTF?");

	if (secondPlace == -1 || time > map_vote_timeout || (map_vote_voters_real - firstPlaceVotes) < firstPlaceVotes)
		return map_vote_finished(firstPlace);

	if (map_vote_keeptwotime)
		if (time > map_vote_keeptwotime || (map_vote_voters_real - firstPlaceVotes - secondPlaceVotes) < secondPlaceVotes) {
			float didntvote;
			map_vote_touch_mask();
			map_vote_message = "Now decide between the TOP TWO!";
			map_vote_keeptwotime = 0;
			result = strcat(":vote:keeptwo:", map_vote_maps[firstPlace]);
			result = strcat(result, ":", ftos(firstPlaceVotes));
			result = strcat(result, ":", map_vote_maps[secondPlace]);
			result = strcat(result, ":", ftos(secondPlaceVotes), "::");
			didntvote = map_vote_voters;
			for (i = 0; i < map_vote_count; ++i)
				if (map_vote_maps[i] != "") {
					didntvote -= map_vote_votes[i];
					if (i != firstPlace)
						if (i != secondPlace) {
							result = strcat(result, ":", map_vote_maps[i]);
							result = strcat(result, ":", ftos(map_vote_votes[i]));
							if (i < map_vote_count_real) {
								strunzone(map_vote_maps[i]);
								map_vote_maps[i] = "";
							}
						}
				}
			result = strcat(result, ":didn't vote:", ftos(didntvote));
		}
	return FALSE;
}
void() map_vote_tick {
	float keeptwo;
	float totalvotes;
	keeptwo = map_vote_keeptwotime;
	if (map_vote_check_rules2()) // decide
		return;

	totalvotes = 0;
	FOR_EACH_REALCLIENT(other) {
		// clear possibly invalid votes
		if (map_vote_maps[other.mapvote - 1] == "")
			other.mapvote = 0;

		if (other.mapvote)
			++totalvotes;
	}
	map_vote_check_rules1(); // just count
}

void(void) map_vote_impulse {
	// use impulses as new vote
	if (map_vote_run && self.impulse >= 1 && self.impulse <= map_vote_count)
		if (map_vote_maps[self.impulse - 1] != "") {
			self.mapvote = self.impulse;
			map_vote_check_rules1(); // just count
			map_vote_touch_votes(self);
		}
}

void() map_vote_start {
	if (map_vote_run)
		return;

	map_info_enumerate();
	if (map_info_filter_game_type(map_info_type_from_game_type(game_type_current()), map_info_required_flags(), map_info_forbidden_flags(), 1))
		map_vote_run = TRUE;
}

void() map_vote_think {
	if (!map_vote_run)
		return;

	if (map_already_changed)
		return;

	if (time < map_vote_nextthink)
		return;

	map_vote_nextthink = time + 0.5;
	if (!map_vote_initialized) {
		map_vote_initialized = TRUE;
		if (map_do_next_override())
			return;
			
		if (!cvar("g_maplist_votable") || player_count <= 0) {
			map_goto_next();
			return;
		}
		map_vote_init();
	}
	map_vote_tick();
}
