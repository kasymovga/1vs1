float game_type_vote_finished;
float game_type_vote_start;
string sv_gametypevote;
entity game_type_vote;

float game_type_vote_types[MENU_ITEMS_MAXCOUNT];
string game_type_vote_descriptions[MENU_ITEMS_MAXCOUNT];
string game_type_vote_profiles[MENU_ITEMS_MAXCOUNT];
float game_type_vote_votes[MENU_ITEMS_MAXCOUNT];
float game_type_vote_count;

.float gametypevote_select;

void(float select) game_type_vote_select;

string(float n) game_type_vote_get_description {
	str_unzone_ifneeded(game_type_vote_descriptions[n]);
	string s = game_type_name_long(game_type_vote_types[n]);
	string p = game_type_vote_profiles[n];
	if (p == "")
		p = "default";

	if (p != " ")
		s = strcat(s, " with ", strtoupper(p));

	s = strcat(s, " (", ftos(game_type_vote_votes[n]), ")");
	game_type_vote_descriptions[n] = strzone(s);
	return game_type_vote_descriptions[n];
}

float(void) game_type_vote_think {
	float i, max_votes, gametype_max_votes, tmp, nextmap_types, t;
	string nextmap;

	if not(game_type_vote_mapinfo_mask)
		return FALSE;

	if (game_type_vote_finished) {
		if (game_type_vote) {
			menu_remove(game_type_vote);
			game_type_vote = world;
			for (i = 0; i < game_type_vote_count; i++) {
				print(game_type_vote_descriptions[i], "\n");
				str_unzone_ifneeded(game_type_vote_descriptions[i]);
				game_type_vote_descriptions[i] = "";
			}
		}
		return FALSE;
	}
	if not(game_type_vote) {
		nextmap = cvar_string("nextmap");
		nextmap_types = map_info_get_game_types(nextmap);
		game_type_vote_start = time;
		game_type_vote = menu_prepare(world, "gametypevote", "Please select game type for next map:", cvar("sv_gametypevote_time"), game_type_vote_select);
		game_type_vote_count = 0;
		string head, tail, type, profile;
		tail = sv_gametypevote;
		float gametype_vote_mask = 0;
		float mapinfo_type;
		float colon;
		while (tail != "") {
			head = str_car(tail);
			tail = str_cdr(tail);
			colon = strstrofs(head, ":", 0);
			if (colon >= 0) {
				type = substring(head, 0, colon);
				profile = substring(head, colon + 1, -1);
			} else {
				type = head;
				profile = " ";
			}
			t = game_type_from_name(type);
			if (t <= 0) {
				print("Unknown game type: ", type, "\n");
				continue;
			}
			mapinfo_type = map_info_type_from_game_type(t);
			if (!nextmap_types || (mapinfo_type & nextmap_types))
			if (mapinfo_type & game_type_vote_mapinfo_mask) {
				game_type_vote_types[game_type_vote_count] = t;
				game_type_vote_profiles[game_type_vote_count] = str_zone_ifneeded(profile);
				menu_add_item(game_type_vote, game_type_vote_get_description(game_type_vote_count));
				game_type_vote_count++;
				if (game_type_vote_count == MENU_ITEMS_MAXCOUNT)
					break;
			}
		}
	}
	if (game_type_vote_count < 1) {
		game_type_vote_finished = TRUE;
		return TRUE;
	}
	if (game_type_vote_count == 1) {
		game_type_switch(game_type_vote_types[0]);
		game_type_vote_finished = TRUE;
		return TRUE;
	}
	for (i = 0; i < game_type_vote_count; i++) {
		if (game_type_vote_votes[i] > (player_count - bot_count) / 2) {
			game_type_switch(game_type_vote_types[i]);
			string p = game_type_vote_profiles[i];
			if (p != " ")
				cvar_set("g_profile", p);

			game_type_vote_finished = TRUE;
			return TRUE;
		}
	}
	if (game_type_vote_start + cvar("sv_gametypevote_time") < time) {
		gametype_max_votes = -1;
		max_votes = 0;
		for (i = 0; i < game_type_vote_count; i++) {
			tmp = game_type_vote_votes[i];
			if (tmp > 0 && max_votes < tmp) {
				max_votes = tmp;
				gametype_max_votes = i;
			}
		}
		if (gametype_max_votes >= 0) {
			game_type_switch(game_type_vote_types[gametype_max_votes]);
			string p = game_type_vote_profiles[gametype_max_votes];
			if (p != " ")
				cvar_set("g_profile", p);
		}
		game_type_vote_finished = TRUE;
		return TRUE;
	}
	return TRUE;
}

void game_type_vote_select(float select) {
	float tmp, prev_select;
	if (select < 0 || select >= game_type_vote_count)
		return;

	if not(game_type_vote)
		return;

	if (self.gametypevote_select >= 1 && self.gametypevote_select <= game_type_vote_count) {
		prev_select = self.gametypevote_select - 1;
		tmp = game_type_vote_votes[prev_select];
		game_type_vote_votes[prev_select] = tmp - 1;
		menu_set_item(game_type_vote, prev_select, game_type_vote_get_description(prev_select));
	}
	self.gametypevote_select = select + 1;
	tmp = game_type_vote_votes[select] + 1;
	game_type_vote_votes[select] = tmp;
	menu_set_item(game_type_vote, select, game_type_vote_get_description(select));
}

void(void) game_type_vote_init {
	sv_gametypevote = cvar_string_zone_ifneeded("sv_gametypevote");
	string head, tail;
	float colon;
	tail = sv_gametypevote;
	game_type_vote_mapinfo_mask = 0;
	while (tail != "") {
		head = str_car(tail);
		colon = strstrofs(head, ":", 0);
		if (colon >= 0)
			head = substring(head, 0, colon);

		tail = str_cdr(tail);
		if (head != "") {
			game_type_vote_mapinfo_mask = game_type_vote_mapinfo_mask | map_info_type_from_game_type(game_type_from_name(head));
		}
	}
}
