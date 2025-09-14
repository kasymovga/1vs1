float stat_db;
float stat_frags_count;
float stat_players_count;
float sv_stat_bots;

var void(void) stat_client_connect_next;
void(void) stat_client_connect {
	if (clienttype(self) == CLIENTTYPE_BOT && sv_stat_bots && self.clid == "") {
		self.clid = str_zone_ifneeded(strcat("BOTCLIENTID", ftos(num_for_edict(self))));
		stat_player_add(self);
	}
}

void(void) stat_init {
	if (team_teams == 1 || g_maxplayers == 1 || g_campaign) // single team or single player, no stat
		return;

	stat_db = -1;
	if not(cvar("sv_stat"))
		return;

	stat_db = db_create();
	CVAR_CACHE(sv_stat_bots);
	stat_client_connect_next = plugin_chain_client_connect;
	plugin_chain_client_connect = stat_client_connect;
}

void(entity plr) stat_player_add {
	if (stat_db < 0) return;
	if (plr.clid == "") return;
	float i = 0;
	string s;
	for (i = 0; i < stat_players_count; i++) {
		s = db_get(stat_db, strcat("player/", ftos(i), "/id"));
		if (s == plr.clid) {
			break;
		}
	}
	if (i == stat_players_count) {
		stat_players_count++;
		db_put(stat_db, strcat("player/", ftos(i), "/id"), plr.clid);
		db_put(stat_db, strcat("player/", ftos(i), "/name"), plr.netname);
		db_put(stat_db, strcat("player/", plr.clid, "/index"), ftos(i));
	}
	if (plr.scorekeeper && score_have_score) {
		db_put(stat_db, strcat("player/", ftos(i), "/score"), ftos(plr.scorekeeper.scores[SP_SCORE]));
	}
	float w;
	for (w = WEAPON_FIRST; w < WEAPON_COUNT_EXTRA; w++) {
		if (plr.bullets_fired[w] > 0) {
			db_put(stat_db, strcat("player/", ftos(i), "/accuracy_shots/", ftos(w)), ftos(plr.bullets_fired[w]));
			db_put(stat_db, strcat("player/", ftos(i), "/accuracy_hits/", ftos(w)), ftos(plr.bullets_hit[w]));
		}
	}
}

string(void) stat_weapon_list {
	entity e;
	string json = "[";
	float comma = FALSE;
	float w;
	for (w = WEAPON_FIRST; w < WEAPON_COUNT_EXTRA; w++) {
		e = weapon_info(w);
		if not(e.weapons & weapon_spawned_list)
		if not(e.weapons_extra & weapon_spawned_extra_list)
		if not(e.weapons & player_start_weapons)
		if not(e.weapons & player_start_weapons_extra)
			continue;

		if (comma)
			json = strcat(json, ", ");
		else
			comma = TRUE;

		json = strcat(json, "[", ftos(w), ", \"", e.netname, "\"]");
	}
	json = strcat(json, "]");
	return json;
}

string(float i) stat_player_accuracy {
	string json = "[";
	float shots, hits;
	float comma = FALSE;
	float w;
	for (w = WEAPON_FIRST; w < WEAPON_COUNT_EXTRA; w++) {
		shots = stof(db_get(stat_db, strcat("player/", ftos(i), "/accuracy_shots/", ftos(w))));
		if not(shots) continue;
		if (comma)
			json = strcat(json, ", ");
		else
			comma = TRUE;

		hits = stof(db_get(stat_db, strcat("player/", ftos(i), "/accuracy_hits/", ftos(w))));
		json = strcat(json, ftos(w), ", ", ftos(shots), ", ", ftos(hits));
	}
	json = strcat(json, "]");
	return json;
}

string(float i) stat_player_score {
	string s = db_get(stat_db, strcat("player/", ftos(i), "/score"));
	if (s != "")
		return s;

	return "-1";
}

string(void) stat_player_list {
	string json = "[";
	float i;
	for (i = 0; i < stat_players_count; i++) {
		if (i)
			json = strcat(json, ",\n");
		else
			json = strcat(json, "\n");

		json = strcat(json, "    [\"", uri_escape(db_get(stat_db, strcat("player/", ftos(i), "/id"))), "\", \", ", uri_escape(db_get(stat_db, strcat("player/", ftos(i), "/name"))), "\", ");
		json = strcat(json, stat_player_score(i), ", ", stat_player_accuracy(i), "]");
	}
	json = strcat(json, "\n  ]");
	return json;
}

string(void) stat_to_json {
	string json = "{\n";
	json = strcat(json,
			"  \"map\": \"", uri_escape(mapname), "\",\n",
			"  \"server_id\": \"", uri_escape(cvar_string("sv_stat_server_id")), "\",\n",
			"  \"game_type\": \n", uri_escape(game_type_name(game_type)), "\",\n",
			"  \"rank_type\": \n", uri_escape(rank_type()), "\",\n",
			"  \"players\": ");
	json = strcat(json, stat_player_list());
	json = strcat(json,
			",\n");
	json = strcat(json,
			"  \"weapons\": ");
	json = strcat(json, stat_weapon_list());
	json = strcat(json, ",\n");
	json = strcat(json,
			"  \"frags\": [\n    ");
	float a, t, i;
	string s;
	for (i = 0; i < stat_frags_count; i++) {
		if (i)
			json = strcat(json, ", ");
		else
			json = strcat(json, "");

		s = db_get(stat_db, strcat("frags/", ftos(i)));
		a = stof(str_car(s));
		t = stof(str_cdr(s));
		json = strcat(json, "[", ftos(a), ", ", ftos(t), "]");
	}
	json = strcat(json,
			"\n  ]\n");
	json = strcat(json,
			"}\n");
	return json;
}

float(string id) stat_player_index_by_id {
	string s = db_get(stat_db, strcat("player/", id, "/index"));
	if (s != "")
		return stof(s);

	return -1;
}

void(entity p1, entity p2, float deathtype) stat_frag_add {
	if (stat_db < 0) return;
	float i1;
	if (p1) {
		if (p1.clid == "") return;
		i1 = stat_player_index_by_id(p1.clid);
	} else
		i1 = -1;

	float i2;
	if (p2) {
		if (p2.clid == "") return;
		i2 = stat_player_index_by_id(p2.clid);
	} else
		i2 = -1;

	db_put(stat_db, strcat("frags/", ftos(stat_frags_count)), strcat(ftos(i1), " ", ftos(i2)));
	stat_frags_count++;
}

void(void) stat_shutdown {
	if (stat_db < 0) return;
	string stat_url = cvar_string("sv_stat_url");
	entity pl;
	PLAYER_FOR_EACH(pl) {
		stat_player_add(pl);
	}
	string json = stat_to_json();
	if (cvar("sv_stat_debug"))
		print(json);

	if (stat_url != "")
		uri_post(stat_url, URI_GET_DISCARD, "application/json", json);
}
