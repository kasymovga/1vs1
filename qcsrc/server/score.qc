entity score_initialized; // the scoreinfo entity, non-world when scores labels/rules have been set
entity score_teem_keepers[16]; // teamscore entities
string score_label[SCORE_FILEDS_MAX];
float score_flags[SCORE_FILEDS_MAX];
string score_team_label[SCORE_TEAM_FIELDS_MAX];
float score_team_flags[SCORE_TEAM_FIELDS_MAX];
float score_team_entities_count;
var .float score_primary;
var .float score_team_primary;
float score_team_primary_scorefield;
float score_flags_primary;
float score_team_flags_primary;
void(entity e, float f) score_send_delayed;
float score_registered;
float score_team_registered;

vector(entity t1, entity t2, .float field, float fieldflags, vector previous) score_field_compare {
	if (!(fieldflags & SCORE_FLAG_SORT_PRIO_MASK)) // column does not sort
		return previous;

	if (fieldflags & SCORE_FLAG_SORT_PRIO_MASK < previous_y)
		return previous;

	if (t1.field == t2.field)
		return previous;

	previous_y = fieldflags & SCORE_FLAG_SORT_PRIO_MASK;
	if (fieldflags & SCORE_FLAG_ZERO_IS_WORST) {
		if (t1.field == 0) {
			previous_x = -1;
			return previous;
		} else if (t2.field == 0) {
			previous_x = +1;
			return previous;
		}
	}
	if (fieldflags & SCORE_FLAG_LOWER_IS_BETTER)
		previous_x = (t2.field - t1.field);
	else
		previous_x = (t1.field - t2.field);

	return previous;
}

float(entity to, float sendflags) score_team_send {
	float i, p, longflags;
	net_write_byte(MSG_ENTITY, NET_CSQC_TEAMSCORES);
	net_write_byte(MSG_ENTITY, self.team);
	longflags = 0;
	float score;
	for (i = 0, p = 1; i < SCORE_TEAM_FIELDS_MAX; ++i, p *= 2) {
		score = self.scores[i];
		if (score > 127 || score <= -128)
			longflags |= p;
	}
#if SCORE_TEAM_FIELDS_MAX <= 8
	net_write_byte(MSG_ENTITY, sendflags);
	net_write_byte(MSG_ENTITY, longflags);
#else
	net_write_short(MSG_ENTITY, sendflags);
	net_write_short(MSG_ENTITY, longflags);
#endif
	for (i = 0, p = 1; i < SCORE_TEAM_FIELDS_MAX; ++i, p *= 2)
		if (sendflags & p) {
			score = self.scores[i];
			if (longflags & p)
				net_write_int24(MSG_ENTITY, score);
			else
				net_write_char(MSG_ENTITY, score);
		}
	return TRUE;
}

void(float t, string name) score_spawn_team {
	entity ts;
	ts = spawn();
	ts.classname = "csqc_score_team";
	ts.netname = name; // not used yet, FIXME
	ts.team = t;
	net_link_entity(ts, FALSE, 0, score_team_send);
	score_teem_keepers[t - 1] = ts;
	++score_team_entities_count;
}

float(float t, float scorefield, float score) score_team_add_to {
	entity s;
	if (map_finished)
		score = 0;

	if (!score_initialized) return 0; // FIXME remove this when everything uses this system
	if (t <= 0 || t >= 16) {
		print("Adding score to invalid team!");
		return 0;
	}
	s = score_teem_keepers[t - 1];
	if (!s) {
		print("Adding score to unknown team!");
		return 0;
	}
	if (score)
		if (score_team_label[scorefield] != "")
			s.SendFlags |= pow(2, scorefield);

	float newscore = s.(scores[scorefield]) + score;
	s.(scores[scorefield]) = newscore;
	return newscore;
}

float(entity player, float scorefield, float score) score_team_add {
	if (clienttype(player) == CLIENTTYPE_DISCONNECTED) return 0;
	return score_team_add_to(player.team, scorefield, score);
}

float(entity t1, entity t2) score_compare_teams {
	if (!t1 || !t2) return (!t2) - !t1;
	vector result = '0 0 0';
	float i;
	for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i) {
		var .float f;
		f = scores[i];
		result = score_field_compare(t1, t2, f, score_team_flags[i], result);
	}
	return result_x;
}

float(string label, float scoreflags) score_register {
	if (score_registered >= SCORE_FILEDS_MAX)
		error("Scores overflow!");

	score_label[score_registered] = label;
	score_flags[score_registered] = scoreflags;
	if ((scoreflags & SCORE_FLAG_SORT_PRIO_MASK) == SCORE_FLAG_SORT_PRIO_PRIMARY) {
		score_primary = scores[score_registered];
		score_flags_primary = scoreflags;
	}
	score_registered++;
	return score_registered - 1;
}

float (string label, float scoreflags) score_register_team_score {
	if (score_team_registered >= SCORE_TEAM_FIELDS_MAX)
		error("Team scores overflow!");

	score_team_label[score_team_registered] = label;
	score_team_flags[score_team_registered] = scoreflags;
	if ((scoreflags & SCORE_FLAG_SORT_PRIO_MASK) == SCORE_FLAG_SORT_PRIO_PRIMARY) {
		score_team_primary = scores[score_team_registered];
		score_team_primary_scorefield = score_team_registered;
		score_team_flags_primary = scoreflags;
	}
	score_team_registered++;
	return score_team_registered - 1;
}

float(entity to, float sf) score_info_send {
	float i, f;
	net_write_byte(MSG_ENTITY, NET_CSQC_SCORES_INFO);
	net_write_byte(MSG_ENTITY, game_type);
	for (i = 0; i < SCORE_FILEDS_MAX; ++i) {
		f = score_flags[i];
		if (f & SCORE_FLAG_HIDDEN) {
			net_write_string(MSG_ENTITY, "");
			net_write_byte(MSG_ENTITY, 0);
		} else {
			net_write_string(MSG_ENTITY, score_label[i]);
			net_write_byte(MSG_ENTITY, f);
		}
	}
	for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i) {
		net_write_string(MSG_ENTITY, score_team_label[i]);
		net_write_byte(MSG_ENTITY, score_team_flags[i]);
	}
	return TRUE;
}

void() score_send_delayed_think {
	self.SendFlags |= self.flags;
	self.flags = 0;
	self.lastshot_time = time + 1;
}

void(entity e, float f) score_send_delayed {
	if (score_flags[f] & SCORE_FLAG_HIDDEN) return;
	e.flags |= f;
	if not(e.nextthink)
		e.nextthink = max(e.lastshot_time, time);
}

/*
 * per-player score entities
 */

float(entity to, float sendflags) score_send_entity {
	float i, p, longflags, n;
	net_write_byte(MSG_ENTITY, NET_CSQC_SCORES);
	net_write_byte(MSG_ENTITY, num_for_edict(self.owner));
	longflags = 0;
	for (i = 0, p = 1; i < SCORE_FILEDS_MAX; ++i, p *= 2)
		if (self.scores[i] > 127 || self.scores[i] <= -128)
			longflags |= p;

	if (sendflags & 0xF0000) {
		net_write_byte(MSG_ENTITY, 4);
		n = SCORE_FILEDS_MAX;
		net_write_coord(MSG_ENTITY, sendflags);
		net_write_coord(MSG_ENTITY, longflags);
	} else if (sendflags & 0xFF00) {
		n = 16;
		net_write_byte(MSG_ENTITY, 2);
		net_write_short(MSG_ENTITY, sendflags & 0xFFFF);
		net_write_short(MSG_ENTITY, longflags & 0xFFFF);
	} else {
		n = 8;
		net_write_byte(MSG_ENTITY, 1);
		net_write_byte(MSG_ENTITY, sendflags & 0xFF);
		net_write_byte(MSG_ENTITY, longflags & 0xFF);
	}
	for (i = 0, p = 1; i < n; ++i, p *= 2)
		if (sendflags & p) {
			if (longflags & p)
				net_write_int24(MSG_ENTITY, self.scores[i]);
			else
				net_write_char(MSG_ENTITY, self.scores[i]);
		}
	return TRUE;
}

void(entity player) score_clear {
	entity sk;
	float i;
	if (score_team_entities_count)
		return;

	if not(plugin_ClearScoreAllowed())
		return;

	sk = player.scorekeeper;
	rank_distribute(player);
	player.play_time = 0;
	for (i = 0; i < SCORE_FILEDS_MAX; ++i) if not(score_flags[i] & SCORE_FLAG_NOCLEAR) {
		if (sk.(scores[i]) != 0)
			if (score_label[i] != "")
				score_send_delayed(sk, pow(2, i));

		if (i != SP_TEAM)
			sk.(scores[i]) = 0;
	}
}

void() score_clear_all {
	entity p, sk;
	float i, t;
	CLIENT_FOR_EACH_SLOT(p) {
		p.play_time = 0;
		sk = p.scorekeeper;
		if (!sk)
			continue;
		for (i = 0; i < SCORE_FILEDS_MAX; ++i)
			if not(score_flags[i] & SCORE_FLAG_NOCLEAR) {
				if (i == SP_TEAM)
					continue;

				if (sk.(scores[i]) != 0)
					if (score_label[i] != "")
						score_send_delayed(sk, pow(2, i));

				sk.(scores[i]) = 0;
			}
	}
	for (t = 0; t < 16; ++t) {
		sk = score_teem_keepers[t];
		if (!sk)
			continue;

		for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i) {
			if (sk.(scores[i]) != 0)
				if (score_team_label[i] != "")
					sk.SendFlags |= pow(2, i);

			sk.(scores[i]) = 0;
		}
	}
}

void(entity player) score_attach {
	entity sk;
	if (player.scorekeeper) {
		backtrace("player already has a scorekeeper");
		return;
	}
	sk = spawn();
	sk.classname = "scorekeeper";
	sk.owner = player;
	sk.think = score_send_delayed_think;
	net_link_entity(sk, FALSE, 0, score_send_entity);
	player.scorekeeper = sk;
}

void(entity player) score_detach {
	if (!player.scorekeeper) {
		backtrace("player has no scorekeeper");
		return;
	}
	remove(player.scorekeeper);
	player.scorekeeper = world;
}

entity(entity player) score_keeper_get {
	entity e = player.scorekeeper;
	if not(e) {
		backtrace("Adding score to unknown player!");
	} else if (e.think == score_send_delayed_think)
		return e;

	print("player ", player.netname, " have wrong scorekeeper, fixing\n");
	e = world;
	while ((e = find(e, classname, "scorekeeper"))) {
		if (e.owner == player) {
			player.scorekeeper = e;
			return e;
		}
	}
	player.scorekeeper = world;
	score_attach(player);
	score_touch(player);
	return player.scorekeeper;
}

float(entity player, float scorefield, float score) score_player_set {
	if (clienttype(player) == CLIENTTYPE_DISCONNECTED) return 0;
	entity s;
	if (scorefield < 0 || scorefield >= SCORE_FILEDS_MAX) {
		backtrace("incorrect score field");
		return 0;
	}
	if (!score_initialized || map_finished) return 0;
	s = score_keeper_get(player);
	score_send_delayed(s, pow(2, scorefield));
	return (s.(scores[scorefield]) = score);
}

float(entity player, float scorefield, float score) score_player_add {
	if (clienttype(player) == CLIENTTYPE_DISCONNECTED) return 0;
	entity s;
	if (scorefield < 0 || scorefield >= SCORE_FILEDS_MAX) {
		backtrace("incorrect score field");
		return 0;
	}
	if (!score_initialized || map_finished) return 0;
	s = score_keeper_get(player);
	if (score)
		if (score_label[scorefield] != "")
			score_send_delayed(s, pow(2, scorefield));

	float newscore = (s.(scores[scorefield]) + score);
	s.(scores[scorefield]) = newscore;
	return newscore;
}

float(entity player, float pscorefield, float tscorefield, float score) score_player_team_add {
	float r;
	r = score_player_add(player, pscorefield, score);
	if (score_team_entities_count) // only for teamplay
		r = score_team_add(player, tscorefield, score);

	return r;
}

float(entity t1, entity t2) score_compare_players {
	if (!t1 || !t2) return (!t2) - !t1;
	vector result = '0 0 0';
	float i;
	for (i = 0; i < SCORE_FILEDS_MAX; ++i) {
		var .float f;
		f = scores[i];
		result = score_field_compare(t1, t2, f, score_flags[i], result);
	}
	return result_x;
}

void() score_winning_condition_helper {
	float c;
	string s;
	entity p;
	float fullstatus;
	entity winnerscorekeeper;
	entity secondscorekeeper;
	entity sk;
	s = game_type_name(game_type);
	s = strcat(s, ":", cvar_string("rexuizversion"));
	s = strcat(s, "::", score_player_string(world, 2)); // make this 1 once we can
	fullstatus = builtin_cvar("g_full_getstatus_responses");
	if (score_team_entities_count) {
		float t;
		s = strcat(s, ":", score_team_string(0, 1));
		for (t = 0; t < 16; ++t)
			if (score_teem_keepers[t])
				s = strcat(s, ":", ftos(t+1), ":", score_team_string(t+1, 1));

		score_winning_condition_helper_winnerteam = -1;
		score_winning_condition_helper_secondteam = -1;
		winnerscorekeeper = world;
		secondscorekeeper = world;
		for (t = 0; t < 16; ++t) {
			sk = score_teem_keepers[t];
			c = score_compare_teams(winnerscorekeeper, sk);
			if (c < 0) {
				score_winning_condition_helper_secondteam = score_winning_condition_helper_winnerteam;
				score_winning_condition_helper_winnerteam = t + 1;
				secondscorekeeper = winnerscorekeeper;
				winnerscorekeeper = sk;
			} else {
				c = score_compare_teams(secondscorekeeper, sk);
				if (c < 0) {
					score_winning_condition_helper_secondteam = t + 1;
					secondscorekeeper = sk;
				}
			}
		}
		score_winning_condition_helper_equality = (score_compare_teams(winnerscorekeeper, secondscorekeeper) == 0);
		if (score_winning_condition_helper_equality)
			score_winning_condition_helper_winnerteam = score_winning_condition_helper_secondteam = -1;

		score_winning_condition_helper_topscore = winnerscorekeeper.score_team_primary;
		score_winning_condition_helper_secondscore = secondscorekeeper.score_team_primary;
		score_winning_condition_helper_lowerisbetter = (score_team_flags_primary & SCORE_FLAG_LOWER_IS_BETTER);
		score_winning_condition_helper_zeroisworst = (score_team_flags_primary & SCORE_FLAG_ZERO_IS_WORST);
		score_winning_condition_helper_winner = world; // not supported in teamplay
		score_winning_condition_helper_second = world; // not supported in teamplay
	} else {
		score_winning_condition_helper_winner = world;
		score_winning_condition_helper_second = world;
		winnerscorekeeper = world;
		secondscorekeeper = world;
		PLAYER_FOR_EACH(p) {
			sk = p.scorekeeper;
			c = score_compare_players(winnerscorekeeper, sk);
			if (c < 0) {
				score_winning_condition_helper_second = score_winning_condition_helper_winner;
				score_winning_condition_helper_winner = p;
				secondscorekeeper = winnerscorekeeper;
				winnerscorekeeper = sk;
			} else {
				c = score_compare_players(secondscorekeeper, sk);
				if (c < 0) {
					score_winning_condition_helper_second = p;
					secondscorekeeper = sk;
				}
			}
		}
		score_winning_condition_helper_equality = (score_compare_players(winnerscorekeeper, secondscorekeeper) == 0);
		if (score_winning_condition_helper_equality)
			score_winning_condition_helper_winner = score_winning_condition_helper_second = world;

		score_winning_condition_helper_topscore = winnerscorekeeper.score_primary;
		score_winning_condition_helper_secondscore = secondscorekeeper.score_primary;
		score_winning_condition_helper_lowerisbetter = (score_flags_primary & SCORE_FLAG_LOWER_IS_BETTER);
		score_winning_condition_helper_zeroisworst = (score_flags_primary & SCORE_FLAG_ZERO_IS_WORST);
		score_winning_condition_helper_winnerteam = -1; // no teamplay
		score_winning_condition_helper_secondteam = -1; // no teamplay
	}
	if (score_team_flags_primary & SCORE_FLAG_TIME)
		score_winning_condition_helper_topscore /= 10;

	if (score_winning_condition_helper_topscore == 0) {
		if (score_flags_primary & SCORE_FLAG_ZERO_IS_WORST) {
			if (score_winning_condition_helper_lowerisbetter)
				score_winning_condition_helper_topscore = 999999999;
			else
				score_winning_condition_helper_topscore = -999999999;
		}
		score_winning_condition_helper_equality = 0;
	}
	if (score_winning_condition_helper_secondscore == 0) {
		if (score_flags_primary & SCORE_FLAG_ZERO_IS_WORST) {
			if (score_winning_condition_helper_lowerisbetter)
				score_winning_condition_helper_secondscore = 999999999;
			else
				score_winning_condition_helper_secondscore = -999999999;
		}
	}
	if (worldstatus)
		strunzone(worldstatus);

	worldstatus = strzone(s);
	CLIENT_FOR_EACH(p) {
		if (fullstatus) {
			s = score_player_string(p, 1);
			if (clienttype(p) == CLIENTTYPE_REAL)
				s = strcat(s, ":human");
			else
				s = strcat(s, ":bot");

			if (p.classname != "player")
				s = strcat(s, ":spectator");
		} else {
			if (p.classname == "player")
				s = score_player_string(p, 2);
			else
				s = "-666";
		}
		if (p.clientstatus)
			strunzone(p.clientstatus);

		p.clientstatus = strzone(s);
	}
}

string(string label, float fl) score_log_label {
	if (fl & SCORE_FLAG_LOWER_IS_BETTER)
		label = strcat(label, "<");
	if (fl & SCORE_FLAG_SORT_PRIO_MASK == SCORE_FLAG_SORT_PRIO_PRIMARY)
		label = strcat(label, "!!");
	else if (fl & SCORE_FLAG_SORT_PRIO_MASK == SCORE_FLAG_SORT_PRIO_SECONDARY)
		label = strcat(label, "!");

	return label;
}

string score_player_string(entity pl, float shortString) {
	string out;
	entity sk;
	float i, f;
	string l;
	out = "";
	if (!pl) {
		// label
		for (i = 0; i < SCORE_FILEDS_MAX; ++i)
			if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) == SCORE_FLAG_SORT_PRIO_PRIMARY) {
				f = score_flags[i];
				l = score_label[i];
				out = strcat(out, score_log_label(l, f), ",");
			}
		if (shortString < 2)
			for (i = 0; i < SCORE_FILEDS_MAX; ++i)
				if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) == SCORE_FLAG_SORT_PRIO_SECONDARY) {
					f = score_flags[i];
					l = score_label[i];
					out = strcat(out, score_log_label(l, f), ",");
				}
		if (shortString < 1)
			for (i = 0; i < SCORE_FILEDS_MAX; ++i)
				if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) != SCORE_FLAG_SORT_PRIO_PRIMARY)
				if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) != SCORE_FLAG_SORT_PRIO_SECONDARY) {
					f = score_flags[i];
					l = score_label[i];
					out = strcat(out, score_log_label(l, f), ",");
				}
		out = substring(out, 0, strlen(out) - 1);
	} else if ((sk = pl.scorekeeper)) {
		for (i = 0; i < SCORE_FILEDS_MAX; ++i)
			if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) == SCORE_FLAG_SORT_PRIO_PRIMARY)
				out = strcat(out, ftos(sk.(scores[i])), ",");

		if (shortString < 2)
			for (i = 0; i < SCORE_FILEDS_MAX; ++i)
				if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) == SCORE_FLAG_SORT_PRIO_SECONDARY)
					out = strcat(out, ftos(sk.(scores[i])), ",");

		if (shortString < 1)
			for (i = 0; i < SCORE_FILEDS_MAX; ++i)
				if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) != SCORE_FLAG_SORT_PRIO_PRIMARY)
				if ((score_flags[i] & SCORE_FLAG_SORT_PRIO_MASK) != SCORE_FLAG_SORT_PRIO_SECONDARY)
					out = strcat(out, ftos(sk.(scores[i])), ",");

		out = substring(out, 0, strlen(out) - 1);
	}
	return out;
}

string(float tm, float shortString) score_team_string {
	string out;
	entity sk;
	float i, f;
	string l;
	out = "";
	if (tm == 0) {
		// label
		for (i = 0; i < SCORE_FILEDS_MAX; ++i)
			if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK == SCORE_FLAG_SORT_PRIO_PRIMARY) {
				f = score_team_flags[i];
				l = score_team_label[i];
				out = strcat(out, score_log_label(l, f), ",");
			}
		if (shortString < 2)
			for (i = 0; i < SCORE_FILEDS_MAX; ++i)
				if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK == SCORE_FLAG_SORT_PRIO_SECONDARY) {
					f = score_team_flags[i];
					l = score_team_label[i];
					out = strcat(out, score_log_label(l, f), ",");
				}
		if (shortString < 1)
			for (i = 0; i < SCORE_FILEDS_MAX; ++i)
				if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK != SCORE_FLAG_SORT_PRIO_PRIMARY)
				if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK != SCORE_FLAG_SORT_PRIO_SECONDARY) {
					f = score_team_flags[i];
					l = score_team_label[i];
					out = strcat(out, score_log_label(l, f), ",");
				}
		out = substring(out, 0, strlen(out) - 1);
	} else if ((sk = score_teem_keepers[tm - 1])) {
		for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i)
			if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK == SCORE_FLAG_SORT_PRIO_PRIMARY)
				out = strcat(out, ftos(sk.(scores[i])), ",");

		if (shortString < 2)
			for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i)
				if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK == SCORE_FLAG_SORT_PRIO_SECONDARY)
					out = strcat(out, ftos(sk.(scores[i])), ",");

		if (shortString < 1)
			for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i)
				if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK != SCORE_FLAG_SORT_PRIO_PRIMARY)
				if (score_team_flags[i] & SCORE_FLAG_SORT_PRIO_MASK != SCORE_FLAG_SORT_PRIO_SECONDARY)
					out = strcat(out, ftos(sk.(scores[i])), ",");
		out = substring(out, 0, strlen(out) - 1);
	}
	return out;
}

float(entity p1, entity p2) score_compare_players_team {
	if (score_team_entities_count)
		if (p1.team != p2.team) {
			entity t1, t2;
			float r;
			t1 = score_teem_keepers[p1.team - 1];
			t2 = score_teem_keepers[p2.team - 1];
			r = score_compare_teams(t1, t2);
			if (r == 0) // ensure a deterministic order
				r = p1.team - p2.team;

			return r;
		}
	return score_compare_players(p1.scorekeeper, p2.scorekeeper);
}

entity(.float field) score_sort {
	entity p, plist, pprev, pbest, pbestprev, pfirst, plast;
	float i;
	plist = world;
	CLIENT_FOR_EACH(p)
		p.field = 0;

	PLAYER_FOR_EACH(p)
		if (p.scorekeeper) {
			p.chain = plist;
			plist = p;
		}
	// Now plist points to the whole list.
	pfirst = plast = world;
	i = 0;
	while (plist) {
		pprev = pbestprev = world;
		pbest = plist;
		for (p = plist; (pprev = p), (p = p.chain); ) {
			if (score_compare_players_team(p, pbest) > 0) {
				pbest = p;
				pbestprev = pprev;
			}
		}
		// remove pbest out of the chain
		if (pbestprev == world)
			plist = pbest.chain;
		else
			pbestprev.chain = pbest.chain;

		pbest.chain = world;
		pbest.field = ++i;
		if not(pfirst)
			pfirst = pbest;

		if (plast)
			plast.chain = pbest;

		plast = pbest;
	}
	return pfirst;
}

float(float t) score_team_comparable_value {
	float s;
	entity sk;
	if (t <= 0 || t >= 16) {
		if (map_finished)
			return 0;

		error("Reading score of invalid team!");
	}
	sk = score_teem_keepers[t - 1];
	if not(sk)
		return -999999999;

	s = sk.score_team_primary;
	if (score_team_flags_primary & SCORE_FLAG_ZERO_IS_WORST)
		if (!s)
			return -999999999;

	if (score_team_flags_primary & SCORE_FLAG_LOWER_IS_BETTER)
		s = -s;

	return s;
}

#define NAMEWIDTH 22
#define SCORESWIDTH 58
// TODO put this somewhere in common?
string(float vflags) score_nice_print_item_color {
	if (vflags & SCORE_FLAG_SORT_PRIO_PRIMARY)
		return "^3";
	else if (vflags & SCORE_FLAG_SORT_PRIO_SECONDARY)
		return "^5";
	else
		return "^7";
}

void(entity to, float t, float w) score_nice_print_team {
	string s, s2;
	float i;
	entity sk;
	float fl, sc;
	s = "";
	sk = score_teem_keepers[t - 1];
	if (sk) {
		s = strcat(s, team_colored_name(t));
		for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i)
			if (score_team_label[i] != "") {
				fl = score_team_flags[i];
				sc = sk.(scores[i]);
				s = strcat(s, " ", score_nice_print_item_color(fl), score_string(fl, sc));
			}
	} else
		s = "Scores:";

	s = strcat(s, strpad(max(0, NAMEWIDTH - strlennocol(s)), ""));
	for (i = 0; i < SCORE_FILEDS_MAX; ++i)
		if (score_label[i] != "") {
			fl = score_flags[i];
			s2 = score_label[i];
			s = strcat(s, " ", score_nice_print_item_color(fl), strpad(-w, substring(s2, 0, w)));
		}
	cmd_print_to(to, s);
}

void(entity to, entity p, float w) score_nice_print_player {
	string s;
	float i;
	entity sk;
	float fl, sc;
	s = "  ";
	sk = p.scorekeeper;
	s = strcat(s, p.netname);
	for (;;) {
		i = strlennocol(s) - NAMEWIDTH;
		if (i > 0)
			s = substring(s, 0, strlen(s) - i);
		else {
			s = strcat(s, strpad(i, ""));
			break;
		}
	}
	for (i = 0; i < SCORE_FILEDS_MAX; ++i)
		if (score_label[i] != "") {
			fl = score_flags[i];
			sc = sk.(scores[i]);
			s = strcat(s, " ", score_nice_print_item_color(fl), strpad(-w, score_string(fl, sc)));
		}
	cmd_print_to(to, s);
}

.float score_dummyfield;
void(entity to) score_nice_print {
	entity p;
	float t, i;
	float w;
	t = 0;
	for (i = 0; i < SCORE_FILEDS_MAX; ++i)
		if (score_label[i] != "")
			++t;

	w = bound(6, floor(SCORESWIDTH / t - 1), 9);
	p = score_sort(score_dummyfield);
	t = -1;
	if (!score_team_entities_count)
		score_nice_print_team(to, t, w);

	while (p) {
		if (score_team_entities_count)
			if (t != p.team)
				score_nice_print_team(to, p.team, w);

		score_nice_print_player(to, p, w);
		t = p.team;
		p = p.chain;
	}
	t = 0;
	CLIENT_FOR_EACH(p)
	if (p.classname != "player") {
		if not(t)
			cmd_print_to(to, "Spectators:");

		cmd_print_to(to, strcat("  ", p.netname));
		t = 1;
	}
}

float score_leaderfrags;
float(float limit, float _leadlimit) score_winning_condition {
	if (team_mode) {
		score_team1 = score_team_comparable_value(COLOR_TEAM1);
		score_team2 = score_team_comparable_value(COLOR_TEAM2);
		score_team3 = score_team_comparable_value(COLOR_TEAM3);
		score_team4 = score_team_comparable_value(COLOR_TEAM4);
	}
	world_winners_clear();
	if (score_winning_condition_helper_winner)
		score_winning_condition_helper_winner.winning = 1;

	if (score_winning_condition_helper_winnerteam >= 0)
		world_winners_set(team, score_winning_condition_helper_winnerteam);

	if (score_winning_condition_helper_lowerisbetter) {
		score_winning_condition_helper_topscore = -score_winning_condition_helper_topscore;
		score_winning_condition_helper_secondscore = -score_winning_condition_helper_secondscore;
		limit = -limit;
	}
	if (score_winning_condition_helper_zeroisworst)
		_leadlimit = 0; // not supported in this mode

	if (limit)
	if (score_leaderfrags != score_winning_condition_helper_topscore) {
		score_leaderfrags = score_winning_condition_helper_topscore;
		plugin_score_winning_condition_countdown(limit - score_leaderfrags);
	}
	if (score_winning_condition_helper_equality)
		return FALSE;

	if (score_winning_condition_helper_topscore) {
		if (limit && (score_winning_condition_helper_topscore >= limit))
			return TRUE;

		if (_leadlimit && (score_winning_condition_helper_topscore - score_winning_condition_helper_secondscore >= _leadlimit))
			return TRUE;
	}
	return FALSE;
}

void score_touch(entity e) {
	score_player_set(e, SP_TEAM, e.team);
}

// NOTE: SP_ constants may not be >= SCORE_FILEDS_MAX; ST_constants may not be >= SCORE_TEAM_FIELDS_MAX
// scores that should be in all modes:
float score_have_score;
void(float sprio, float stprio, float score_enabled) score_basics {
	float i;
	score_have_score = score_enabled;
	score_preinitialized = 1;
	score_registered = 0;
	score_team_registered = 0;
	for (i = 0; i < SCORE_FILEDS_MAX; ++i) {
		score_label[i] = "";
		score_flags[i] = 0;
	}
	for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i) {
		score_team_label[i] = "";
		score_team_flags[i] = 0;
	}
	SP_TEAM = score_register("team", 0);
	if (score_enabled)
		ST_SCORE = score_register_team_score("score", stprio);

	if not(player_independent)
		SP_KILLS = score_register("kills", 0);

	SP_DEATHS = score_register("deaths", SCORE_FLAG_LOWER_IS_BETTER);
	if not(player_independent)
		SP_SUICIDES = score_register("suicides", SCORE_FLAG_LOWER_IS_BETTER);

	if (score_enabled)
		SP_SCORE = score_register("score", sprio);

	RM(SP_PLAYTIME = score_register("playtime", 0);)
}

void() score_basics_end {
	plugin_chain_score_basics_end();
	team_teams_allowed(world);
	if (score_initialized) {
		score_initialized.SendFlags |= 1; // force a resend
	} else {
		score_initialized = spawn();
		score_initialized.classname = "ent_client_scoreinfo";
		net_link_entity(score_initialized, FALSE, 0, score_info_send);
	}
	if (team1 >= 0)
		score_spawn_team(COLOR_TEAM1, "Red");

	if (team2 >= 0)
		score_spawn_team(COLOR_TEAM2, "Blue");

	if (team3 >= 0)
		score_spawn_team(COLOR_TEAM3, "Yellow");

	if (team4 >= 0)
		score_spawn_team(COLOR_TEAM4, "Pink");

	if (score_label[SP_SCORE] == "score") {
		if ((score_flags[SP_SCORE]) == SCORE_FLAG_SORT_PRIO_PRIMARY)
			rank_init();
	}
}

void() score_generic {
	score_basics(SCORE_FLAG_SORT_PRIO_PRIMARY, SCORE_FLAG_SORT_PRIO_PRIMARY, TRUE);
}

void(entity attacker, entity targ, float f) score_give_frag {
	if (map_finished)
		return;

	score_player_add(targ, SP_DEATHS, 1);
	if (clienttype(attacker) == CLIENTTYPE_DISCONNECTED) return;
	if (player_independent)
		return;

	if (f < 0) {
		if (targ == attacker) {
			// suicide
			score_player_add(attacker, SP_SUICIDES, 1);
		} else {
			// teamkill
			score_player_add(attacker, SP_KILLS, -1); // or maybe add a teamkills field?
		}
	} else {
		// regular frag
		score_player_add(attacker, SP_KILLS, 1);
	}
	f = plugin_score_give_frag_mod(attacker, targ, f);
	if (f)
	if (score_have_score)
		score_player_team_add_score(attacker, f);
}

