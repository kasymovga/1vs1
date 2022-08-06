float gametypevote_finished;
float gametypevote_start;
string sv_gametypevote;
entity gametypevote;

float gametypes[MENU_ITEMS_MAXCOUNT];
string gametypes_descr[MENU_ITEMS_MAXCOUNT];
string gametypes_profiles[MENU_ITEMS_MAXCOUNT];
float gametypes_votes[MENU_ITEMS_MAXCOUNT];
float gametypes_count;
float gametypes_mapinfo_mask;

.float gametypevote_select;

void GameTypeVote_Select(float select);

string GameTypeVote_GetDescr(float n) {
	str_unzone_ifneeded(gametypes_descr[n]);
	string s = game_type_name_long(gametypes[n]);
	string p = gametypes_profiles[n];
	if (p == "")
		p = "default";

	if (p != " ")
		s = strcat(s, " with ", strtoupper(p));

	s = strcat(s, " (", ftos(gametypes_votes[n]), ")");
	gametypes_descr[n] = strzone(s);
	return gametypes_descr[n];
}

float GameTypeVote_Think() {
	float i, max_votes, gametype_max_votes, tmp, nextmap_types, t;
	string nextmap;

	if not(gametypes_mapinfo_mask)
		return FALSE;

	if (gametypevote_finished) {
		if (gametypevote) {
			menu_remove(gametypevote);
			gametypevote = world;
			for (i = 0; i < gametypes_count; i++) {
				print(gametypes_descr[i], "\n");
				str_unzone_ifneeded(gametypes_descr[i]);
				gametypes_descr[i] = "";
			}
		}
		return FALSE;
	}
	if not(gametypevote) {
		nextmap = cvar_string("nextmap");
		nextmap_types = map_info_get_game_types(nextmap);
		gametypevote_start = time;
		gametypevote = menu_prepare(world, "gametypevote", "Please select game type for next map:", cvar("sv_gametypevote_time"), GameTypeVote_Select);
		gametypes_count = 0;
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
			if (mapinfo_type & gametypes_mapinfo_mask) {
				gametypes[gametypes_count] = t;
				gametypes_profiles[gametypes_count] = str_zone_ifneeded(profile);
				menu_add_item(gametypevote, GameTypeVote_GetDescr(gametypes_count));
				gametypes_count++;
				if (gametypes_count == MENU_ITEMS_MAXCOUNT)
					break;
			}
		}
	}
	if (gametypes_count < 1) {
		gametypevote_finished = TRUE;
		return TRUE;
	}
	if (gametypes_count == 1) {
		game_type_switch(gametypes[0]);
		gametypevote_finished = TRUE;
		return TRUE;
	}
	for (i = 0; i < gametypes_count; i++) {
		if (gametypes_votes[i] > (player_count - bot_count) / 2) {
			game_type_switch(gametypes[i]);
			string p = gametypes_profiles[i];
			if (p != " ")
				cvar_set("g_profile", p);

			gametypevote_finished = TRUE;
			return TRUE;
		}
	}
	if (gametypevote_start + cvar("sv_gametypevote_time") < time) {
		gametype_max_votes = -1;
		max_votes = 0;
		for (i = 0; i < gametypes_count; i++) {
			tmp = gametypes_votes[i];
			if (tmp > 0 && max_votes < tmp) {
				max_votes = tmp;
				gametype_max_votes = i;
			}
		}
		if (gametype_max_votes >= 0) {
			game_type_switch(gametypes[gametype_max_votes]);
			string p = gametypes_profiles[gametype_max_votes];
			if (p != " ")
				cvar_set("g_profile", p);
		}
		gametypevote_finished = TRUE;
		return TRUE;
	}

	return TRUE;
}

void GameTypeVote_Select(float select) {
	float tmp, prev_select;
	if (select < 0 || select >= gametypes_count)
		return;

	if not(gametypevote)
		return;

	if (self.gametypevote_select >= 1 && self.gametypevote_select <= gametypes_count) {
		prev_select = self.gametypevote_select - 1;
		tmp = gametypes_votes[prev_select];
		gametypes_votes[prev_select] = tmp - 1;
		menu_set_item(gametypevote, prev_select, GameTypeVote_GetDescr(prev_select));
	}
	self.gametypevote_select = select + 1;
	tmp = gametypes_votes[select] + 1;
	gametypes_votes[select] = tmp;
	menu_set_item(gametypevote, select, GameTypeVote_GetDescr(select));
}

float GameTypeVote_Mask() {
	return gametypes_mapinfo_mask;
}

void GameTypeVote_Init() {
	sv_gametypevote = cvar_string_zone_ifneeded("sv_gametypevote");
	string head, tail;
	float colon;
	tail = sv_gametypevote;
	gametypes_mapinfo_mask = 0;
	while (tail != "") {
		head = str_car(tail);
		colon = strstrofs(head, ":", 0);
		if (colon >= 0)
			head = substring(head, 0, colon);

		tail = str_cdr(tail);
		if (head != "") {
			gametypes_mapinfo_mask = gametypes_mapinfo_mask | map_info_type_from_game_type(game_type_from_name(head));
		}
	}
}
