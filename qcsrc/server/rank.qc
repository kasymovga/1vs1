string sv_rank_external_database;
string sv_rank_external_database_key;

float RANK_URI_HANDLER;

void(float id, float status, string data) rank_uri_handler {
	if (status) {
		print(strcat("rank_uri_handler: external rank database error: ", ftos(status), "\n"));
		return;
	}
	if (map_finished)
		return;

	string player_id = str_car(data);
	string s = str_cdr(data);
	string type = str_car(s);
	if (type != rank_id) {
		print("rank_uri_handler: wrong rank type '", type, "' (expected '", rank_id, "') from external rank database\n");
		return;
	}
	float _rank = stof(str_cdr(s));
	if not(_rank)
		return;

	entity pl;
	CLIENT_FOR_EACH_REAL(pl) {
		if (pl.clid == player_id) {
			score_player_set(pl, RANK_SCORE_PLAYER_FIELD, _rank);
		}
	}
}

void(void) rank_init {
	if not(cvar("sv_rank"))
		return;

	if (rank_available)
		return;

	if (team_mode && team_teams == 1)
		return;

	if (g_maxplayers == 1 || g_campaign) // single player, no rank
		return;

	string rank_prefix;
	if (team_mode)
		rank_prefix = "team";
	else if (g_maxplayers == 2)
		rank_prefix = "duel";
	else
		rank_prefix = "ffa";

	rank_id = strzone(strcat(rank_prefix, cvar_string("g_rank_type")));
	rank_available = 1;
	RANK_SCORE_PLAYER_FIELD = score_register("rank", (cvar("sv_rank_hide") ? SCORE_FLAG_HIDDEN : 0) | SCORE_FLAG_NOCLEAR);
	rank = scores[RANK_SCORE_PLAYER_FIELD];
	CVAR_CACHE_STR(sv_rank_external_database);
	CVAR_CACHE_STR(sv_rank_external_database_key);
	if (sv_rank_external_database != "") {
		RANK_URI_HANDLER = uri_register_handler(rank_uri_handler);
	}
}

void(entity whom) rank_distribute {
	entity pl;
	float totalscorepm = 0;
	float totalrank = 0;
	float newtotalrank = 0;
	float newrank;
	float score;
	float totalplayers = 0;
	if not(rank_available)
		return;

	CLIENT_FOR_EACH_REAL(pl) {
		if (pl.scorekeeper)
		if (pl.scorekeeper.rank)
		if (pl.play_time > 60) {
			score = pl.scorekeeper.scores[SP_SCORE];
			if (score <= 0) continue;
			score = pow(max(0, score / (pl.play_time / 60)), 0.5);
			totalrank += pl.scorekeeper.rank;
			totalscorepm += score;
			totalplayers++;
		}
	}
	if (totalplayers < 2)
		return;

	if (totalscorepm <= 0)
		return;

	totalrank = totalrank * 0.99 + totalplayers * 10; // slowly normalize to 1000 per player
	CLIENT_FOR_EACH_REAL(pl) {
		if (pl.scorekeeper)
		if (pl.scorekeeper.rank)
		if (pl.play_time > 60) {
			score = pl.scorekeeper.scores[SP_SCORE];
			if (score <= 0) continue;
			score = pow(max(0, score / (pl.play_time / 60)), 0.5);
			newrank = totalrank * (score / totalscorepm);
			newrank = bound(100, newrank * 0.1 + pl.scorekeeper.rank * 0.9 + 0.5, 10000);
			newtotalrank += newrank;
			pl.rank = newrank;
		}
	}
	float norm = totalrank / newtotalrank; // keep total rank at same level
	CLIENT_FOR_EACH_REAL(pl) {
		if (!whom || pl == whom)
		if (pl.scorekeeper)
		if (pl.scorekeeper.rank)
		if (pl.play_time > 60) {
			score = pl.scorekeeper.scores[SP_SCORE];
			if (score <= 0) continue;
			print(pl.netname, " have rank changed in ", rank_id, ": ", ftos(pl.scorekeeper.rank));
			newrank = floor(norm * pl.rank + 0.5);
			print(" -> ", ftos(newrank), "\n");
			pl.scorekeeper.rank = newrank;
			if (pl.clid != "") {
				db_put(db_server, strcat("r/", rank_id, "/", pl.clid), ftos(newrank));
				if (sv_rank_external_database != "") {
					string request = strcat(sv_rank_external_database, "?action=put&id=", pl.clid, "&rank=", ftos(newrank), "&type=", uri_escape(rank_id));
					request = strcat(request, "&nick=", uri_escape(pl.netname), "&key=", sv_rank_external_database_key);
					uri_get(request, RANK_URI_HANDLER);
				}
			}
		}
	}
}

void(void) rank_load {
	float _rank = stof(db_get(db_server, strcat("r/", rank_id, "/", self.clid)));
	if not(rank_available)
		return;

	if not(_rank)
		_rank = 1000;

	print(self.netname, " have rank in ", rank_id, ": ", ftos(_rank), "\n");
	score_player_set(self, RANK_SCORE_PLAYER_FIELD, _rank);
	if (sv_rank_external_database != "") {
		string request = strcat(sv_rank_external_database, "?action=get&id=", self.clid, "&type=", uri_escape(rank_id), "&key=", sv_rank_external_database_key);
		request = strcat(request, "&nick=", uri_escape(self.netname));
		uri_get(request, RANK_URI_HANDLER);
	}
}
