entity scores_initialized; // non-world when scores labels/rules have been set
entity teamscorekeepers[16];
string scores_label[MAX_SCORE];
float scores_flags[MAX_SCORE];
string teamscores_label[MAX_TEAMSCORE];
float teamscores_flags[MAX_TEAMSCORE];
float teamscores_entities_count;
var .float scores_primary;
var .float teamscores_primary;
float teamscores_primary_scorefield;
float scores_flags_primary;
float teamscores_flags_primary;
void(entity e, float f) scores_send_delayed;
float scores_registered;
float scores_team_registered;

vector(entity t1, entity t2, .float field, float fieldflags, vector previous) scores_field_compare {
	if(!(fieldflags & SFL_SORT_PRIO_MASK)) // column does not sort
		return previous;

	if(fieldflags & SFL_SORT_PRIO_MASK < previous_y)
		return previous;

	if(t1.field == t2.field)
		return previous;

	previous_y = fieldflags & SFL_SORT_PRIO_MASK;
	if(fieldflags & SFL_ZERO_IS_WORST)
	{
		if(t1.field == 0)
		{
			previous_x = -1;
			return previous;
		}
		else if(t2.field == 0)
		{
			previous_x = +1;
			return previous;
		}
	}
	if(fieldflags & SFL_LOWER_IS_BETTER)
		previous_x = (t2.field - t1.field);
	else
		previous_x = (t1.field - t2.field);

	return previous;
}

/*
 * teamscore entities
 */

#define scores_team_send TeamScore_SendEntity
float(entity to, float sendflags) scores_team_send {
	float i, p, longflags;

	WriteByte(MSG_ENTITY, ENT_CLIENT_TEAMSCORES);
	WriteByte(MSG_ENTITY, self.team);

	longflags = 0;
	for(i = 0, p = 1; i < MAX_TEAMSCORE; ++i, p *= 2)
		if(self.teamscores[i] > 127 || self.teamscores[i] <= -128)
			longflags |= p;

#if MAX_TEAMSCORE <= 8
	WriteByte(MSG_ENTITY, sendflags);
	WriteByte(MSG_ENTITY, longflags);
#else
	WriteShort(MSG_ENTITY, sendflags);
	WriteShort(MSG_ENTITY, longflags);
#endif
	for(i = 0, p = 1; i < MAX_TEAMSCORE; ++i, p *= 2)
		if(sendflags & p)
		{
			if(longflags & p)
				WriteInt24_t(MSG_ENTITY, self.teamscores[i]);
			else
				WriteChar(MSG_ENTITY, self.teamscores[i]);
		}

	return TRUE;
}

void(float t, string name) scores_spawn_team {
	entity ts;
	ts = spawn();
	ts.classname = "csqc_score_team";
	ts.netname = name; // not used yet, FIXME
	ts.team = t;
	Net_LinkEntity(ts, FALSE, 0, scores_team_send);
	teamscorekeepers[t - 1] = ts;
	++teamscores_entities_count;
}

float(float t, float scorefield, float score) scores_team_add_to {
	entity s;

	if(gameover)
		score = 0;

	if(!scores_initialized) return 0; // FIXME remove this when everything uses this system
	if(t <= 0 || t >= 16)
	{
		if(gameover)
			return 0;
		error("Adding score to invalid team!");
	}
	s = teamscorekeepers[t - 1];
	if(!s)
	{
		if(gameover)
			return 0;
		error("Adding score to unknown team!");
	}
	if(score)
		if(teamscores_label[scorefield] != "")
			s.SendFlags |= pow(2, scorefield);
	(s.(teamscores[scorefield]) += score);
	if (score)
	if (scorefield == teamscores_primary_scorefield)
		defer(1, teams_balance_check);

	return s.(teamscores[scorefield]);
}

float(entity player, float scorefield, float score) scores_team_add {
	return scores_team_add_to(player.team, scorefield, score);
}

float(entity t1, entity t2) scores_compare_teams {
	if(!t1 || !t2) return (!t2) - !t1;

	vector result;
	float i;
	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		var .float f;
		f = teamscores[i];
		result = scores_field_compare(t1, t2, f, teamscores_flags[i], result);
	}
	return result_x;
}

/*
 * the scoreinfo entity
 */

float(string label, float scoreflags) scores_register_score {
	if (scores_registered >= MAX_SCORE)
		error("Scores overflow!");

	scores_label[scores_registered] = label;
	scores_flags[scores_registered] = scoreflags;
	if(scoreflags & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_PRIMARY) {
		scores_primary = scores[scores_registered];
		scores_flags_primary = scoreflags;
	}
	scores_registered++;
	return scores_registered - 1;
}

float (string label, float scoreflags) scores_register_team_score {
	if (scores_team_registered >= MAX_TEAMSCORE)
		error("Team scores overflow!");

	teamscores_label[scores_team_registered] = label;
	teamscores_flags[scores_team_registered] = scoreflags;
	if(scoreflags & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_PRIMARY) {
		teamscores_primary = teamscores[scores_team_registered];
		teamscores_primary_scorefield = scores_team_registered;
		teamscores_flags_primary = scoreflags;
	}
	scores_team_registered++;
	return scores_team_registered - 1;
}

#define scores_send_info ScoreInfo_SendEntity
float(entity to, float sf) scores_send_info {
	float i;
	WriteByte(MSG_ENTITY, ENT_CLIENT_SCORES_INFO);
	WriteByte(MSG_ENTITY, game);
	for(i = 0; i < MAX_SCORE; ++i)
	{
		WriteString(MSG_ENTITY, scores_label[i]);
		WriteByte(MSG_ENTITY, scores_flags[i]);
	}
	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		WriteString(MSG_ENTITY, teamscores_label[i]);
		WriteByte(MSG_ENTITY, teamscores_flags[i]);
	}
	return TRUE;
}

#define scores_send_delayed_think ScoreInfo_SendDelayed_Think
void() scores_send_delayed_think {
	self.SendFlags = self.SendFlags | self.flags;
	self.flags = 0;
	self.lastshot_time = time + 1;
}

void(entity e, float f) scores_send_delayed {
	e.flags |= f;
	if not(e.nextthink)
		e.nextthink = max(e.lastshot_time, time);
}

/*
 * per-player score entities
 */

#define scores_send_entity PlayerScore_SendEntity
float(entity to, float sendflags) scores_send_entity {
	float i, p, longflags;

	WriteByte(MSG_ENTITY, ENT_CLIENT_SCORES);
	WriteByte(MSG_ENTITY, num_for_edict(self.owner));

	longflags = 0;
	for(i = 0, p = 1; i < MAX_SCORE; ++i, p *= 2)
		if(self.scores[i] > 127 || self.scores[i] <= -128)
			longflags |= p;

#if MAX_SCORE <= 8
	WriteByte(MSG_ENTITY, sendflags);
	WriteByte(MSG_ENTITY, longflags);
#else
	WriteShort(MSG_ENTITY, sendflags);
	WriteShort(MSG_ENTITY, longflags);
#endif
	for(i = 0, p = 1; i < MAX_SCORE; ++i, p *= 2)
		if(sendflags & p)
		{
			if(longflags & p)
				WriteInt24_t(MSG_ENTITY, self.scores[i]);
			else
				WriteChar(MSG_ENTITY, self.scores[i]);
		}

	return TRUE;
}

void(entity player) scores_clear {
	entity sk;
	float i;

	if(teamscores_entities_count)
		return;

	if not(GameHook_ClearScoreAllowed())
		return;

	sk = player.scorekeeper;
	for(i = 0; i < MAX_SCORE; ++i) if not(scores_flags[i] & SFL_NOCLEAR)
	{
		if(sk.(scores[i]) != 0)
			if(scores_label[i] != "")
				scores_send_delayed(sk, pow(2, i));
		sk.(scores[i]) = 0;
	}
}

void() scores_clear_all {
	entity p, sk;
	float i, t;
	FOR_EACH_CLIENTSLOT(p)
	{
		sk = p.scorekeeper;
		if(!sk)
			continue;
		for(i = 0; i < MAX_SCORE; ++i) if not(scores_flags[i] & SFL_NOCLEAR)
		{
			if(sk.(scores[i]) != 0)
				if(scores_label[i] != "")
					scores_send_delayed(sk, pow(2, i));
			sk.(scores[i]) = 0;
		}
	}
	for(t = 0; t < 16; ++t)
	{
		sk = teamscorekeepers[t];
		if(!sk)
			continue;
		for(i = 0; i < MAX_TEAMSCORE; ++i)
		{
			if(sk.(teamscores[i]) != 0)
				if(teamscores_label[i] != "")
					sk.SendFlags |= pow(2, i);
			sk.(teamscores[i]) = 0;
		}
	}
}

void(entity player) scores_attach {
	entity sk;
	if(player.scorekeeper)
		error("player already has a scorekeeper");
	sk = spawn();
	sk.owner = player;
	sk.think = scores_send_delayed_think;
	Net_LinkEntity(sk, FALSE, 0, PlayerScore_SendEntity);
	player.scorekeeper = sk;
}

void(entity player) scores_detach {
	if(!player.scorekeeper)
		error("player has no scorekeeper");
	remove(player.scorekeeper);
	player.scorekeeper = world;
}

float(entity player, float scorefield, float score) scores_player_set {
	entity s;

	if(!scores_initialized) return 0; // FIXME remove this when everything uses this system
	s = player.scorekeeper;
	if(!s)
	{
		if(gameover)
			return 0;
		error("Adding score to unknown player!");
	}
	scores_send_delayed(s, pow(2, scorefield));
	return (s.(scores[scorefield]) = score);
}

float(entity player, float scorefield, float score) scores_player_add {
	entity s;

	if(gameover)
		score = 0;

	if(!scores_initialized) return 0; // FIXME remove this when everything uses this system
	s = player.scorekeeper;
	if(!s)
	{
		if(gameover)
			return 0;
		error("Adding score to unknown player!");
	}
	if(score)
		if(scores_label[scorefield] != "")
			scores_send_delayed(s, pow(2, scorefield));
	return (s.(scores[scorefield]) += score);
}

float(entity player, float pscorefield, float tscorefield, float score) scores_player_team_add {
	float r;
	r = scores_player_add(player, pscorefield, score);
	if(teamscores_entities_count) // only for teamplay
		r = scores_team_add(player, tscorefield, score);

	return r;
}

float(entity t1, entity t2) scores_compare_players {
	if(!t1 || !t2) return (!t2) - !t1;

	vector result;
	float i;
	for(i = 0; i < MAX_SCORE; ++i)
	{
		var .float f;
		f = scores[i];
		result = scores_field_compare(t1, t2, f, scores_flags[i], result);
	}
	return result_x;
}

void WinningConditionHelper()
{
	float c;
	string s;
	entity p;
	float fullstatus;
	entity winnerscorekeeper;
	entity secondscorekeeper;
	entity sk;

	s = GametypeNameFromType(game);
	s = strcat(s, ":", cvar_string("g_nexuizversion"));
	s = strcat(s, "::", scores_player_string(world, 2)); // make this 1 once we can

	fullstatus = cvar("g_full_getstatus_responses");

	if(teamscores_entities_count)
	{
		float t;

		s = strcat(s, ":", scores_team_string(0, 1));
		for(t = 0; t < 16; ++t)
			if(teamscorekeepers[t])
				s = strcat(s, ":", ftos(t+1), ":", scores_team_string(t+1, 1));

		WinningConditionHelper_winnerteam = -1;
		WinningConditionHelper_secondteam = -1;
		winnerscorekeeper = world;
		secondscorekeeper = world;
		for(t = 0; t < 16; ++t)
		{
			sk = teamscorekeepers[t];
			c = scores_compare_teams(winnerscorekeeper, sk);
			if(c < 0)
			{
				WinningConditionHelper_secondteam = WinningConditionHelper_winnerteam;
				WinningConditionHelper_winnerteam = t + 1;
				secondscorekeeper = winnerscorekeeper;
				winnerscorekeeper = sk;
			}
			else
			{
				c = scores_compare_teams(secondscorekeeper, sk);
				if(c < 0)
				{
					WinningConditionHelper_secondteam = t + 1;
					secondscorekeeper = sk;
				}
			}
		}

		WinningConditionHelper_equality = (scores_compare_teams(winnerscorekeeper, secondscorekeeper) == 0);
		if(WinningConditionHelper_equality)
			WinningConditionHelper_winnerteam = WinningConditionHelper_secondteam = -1;

		WinningConditionHelper_topscore = winnerscorekeeper.teamscores_primary;
		WinningConditionHelper_secondscore = secondscorekeeper.teamscores_primary;
		WinningConditionHelper_lowerisbetter = (teamscores_flags_primary & SFL_LOWER_IS_BETTER);
		WinningConditionHelper_zeroisworst = (teamscores_flags_primary & SFL_ZERO_IS_WORST);

		WinningConditionHelper_winner = world; // not supported in teamplay
		WinningConditionHelper_second = world; // not supported in teamplay
	}
	else
	{
		WinningConditionHelper_winner = world;
		WinningConditionHelper_second = world;
		winnerscorekeeper = world;
		secondscorekeeper = world;
		FOR_EACH_PLAYER(p)
		{
			sk = p.scorekeeper;
			c = scores_compare_players(winnerscorekeeper, sk);
			if(c < 0)
			{
				WinningConditionHelper_second = WinningConditionHelper_winner;
				WinningConditionHelper_winner = p;
				secondscorekeeper = winnerscorekeeper;
				winnerscorekeeper = sk;
			}
			else
			{
				c = scores_compare_players(secondscorekeeper, sk);
				if(c < 0)
				{
					WinningConditionHelper_second = p;
					secondscorekeeper = sk;
				}
			}
		}

		WinningConditionHelper_equality = (scores_compare_players(winnerscorekeeper, secondscorekeeper) == 0);
		if(WinningConditionHelper_equality)
			WinningConditionHelper_winner = WinningConditionHelper_second = world;

		WinningConditionHelper_topscore = winnerscorekeeper.scores_primary;
		WinningConditionHelper_secondscore = secondscorekeeper.scores_primary;
		WinningConditionHelper_lowerisbetter = (scores_flags_primary & SFL_LOWER_IS_BETTER);
		WinningConditionHelper_zeroisworst = (scores_flags_primary & SFL_ZERO_IS_WORST);

		WinningConditionHelper_winnerteam = -1; // no teamplay
		WinningConditionHelper_secondteam = -1; // no teamplay
	}

	if(teamscores_flags_primary & SFL_TIME)
		WinningConditionHelper_topscore /= 10;

	if(WinningConditionHelper_topscore == 0)
	{
		if(scores_flags_primary & SFL_ZERO_IS_WORST)
		{
			if(WinningConditionHelper_lowerisbetter)
				WinningConditionHelper_topscore = 999999999;
			else
				WinningConditionHelper_topscore = -999999999;
		}
		WinningConditionHelper_equality = 0;
	}

	if(WinningConditionHelper_secondscore == 0)
	{
		if(scores_flags_primary & SFL_ZERO_IS_WORST)
		{
			if(WinningConditionHelper_lowerisbetter)
				WinningConditionHelper_secondscore = 999999999;
			else
				WinningConditionHelper_secondscore = -999999999;
		}
	}

	if(worldstatus)
		strunzone(worldstatus);
	worldstatus = strzone(s);

	FOR_EACH_CLIENT(p)
	{
		if(fullstatus)
		{
			s = scores_player_string(p, 1);
			if(clienttype(p) == CLIENTTYPE_REAL)
				s = strcat(s, ":human");
			else
				s = strcat(s, ":bot");
			if(p.classname != "player")
				s = strcat(s, ":spectator");
		}
		else
		{
			if(p.classname == "player")
				s = scores_player_string(p, 2);
			else
				s = "-666";
		}

		if(p.clientstatus)
			strunzone(p.clientstatus);
		p.clientstatus = strzone(s);
	}
}

string(string label, float fl) scores_log_label {
	if(fl & SFL_LOWER_IS_BETTER)
		label = strcat(label, "<");
	if(fl & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_PRIMARY)
		label = strcat(label, "!!");
	else if(fl & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_SECONDARY)
		label = strcat(label, "!");
	return label;
}

string scores_player_string(entity pl, float shortString)
{
	string out;
	entity sk;
	float i, f;
	string l;

	out = "";
	if(!pl)
	{
		// label
		for(i = 0; i < MAX_SCORE; ++i)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_PRIMARY)
			{
				f = scores_flags[i];
				l = scores_label[i];
				out = strcat(out, scores_log_label(l, f), ",");
			}
		if(shortString < 2)
		for(i = 0; i < MAX_SCORE; ++i)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_SECONDARY)
			{
				f = scores_flags[i];
				l = scores_label[i];
				out = strcat(out, scores_log_label(l, f), ",");
			}
		if(shortString < 1)
		for(i = 0; i < MAX_SCORE; ++i)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_PRIMARY)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_SECONDARY)
			{
				f = scores_flags[i];
				l = scores_label[i];
				out = strcat(out, scores_log_label(l, f), ",");
			}
		out = substring(out, 0, strlen(out) - 1);
	}
	else if((sk = pl.scorekeeper))
	{
		for(i = 0; i < MAX_SCORE; ++i)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_PRIMARY)
				out = strcat(out, ftos(sk.(scores[i])), ",");
		if(shortString < 2)
		for(i = 0; i < MAX_SCORE; ++i)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(scores[i])), ",");
		if(shortString < 1)
		for(i = 0; i < MAX_SCORE; ++i)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_PRIMARY)
			if(scores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(scores[i])), ",");
		out = substring(out, 0, strlen(out) - 1);
	}
	return out;
}

string(float tm, float shortString) scores_team_string {
	string out;
	entity sk;
	float i, f;
	string l;

	out = "";
	if(tm == 0)
	{
		// label
		for(i = 0; i < MAX_SCORE; ++i)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_PRIMARY)
			{
				f = teamscores_flags[i];
				l = teamscores_label[i];
				out = strcat(out, scores_log_label(l, f), ",");
			}
		if(shortString < 2)
		for(i = 0; i < MAX_SCORE; ++i)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_SECONDARY)
			{
				f = teamscores_flags[i];
				l = teamscores_label[i];
				out = strcat(out, scores_log_label(l, f), ",");
			}
		if(shortString < 1)
		for(i = 0; i < MAX_SCORE; ++i)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_PRIMARY)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_SECONDARY)
			{
				f = teamscores_flags[i];
				l = teamscores_label[i];
				out = strcat(out, scores_log_label(l, f), ",");
			}
		out = substring(out, 0, strlen(out) - 1);
	}
	else if((sk = teamscorekeepers[tm - 1]))
	{
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_PRIMARY)
				out = strcat(out, ftos(sk.(teamscores[i])), ",");
		if(shortString < 2)
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK == SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(teamscores[i])), ",");
		if(shortString < 1)
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_PRIMARY)
			if(teamscores_flags[i] & SFL_SORT_PRIO_MASK != SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(teamscores[i])), ",");
		out = substring(out, 0, strlen(out) - 1);
	}
	return out;
}

float scores_compare_players_team(entity p1, entity p2)
{
	if(teamscores_entities_count)
		if(p1.team != p2.team)
		{
			entity t1, t2;
			float r;
			t1 = teamscorekeepers[p1.team - 1];
			t2 = teamscorekeepers[p2.team - 1];
			r = scores_compare_teams(t1, t2);
			if(r == 0) // ensure a deterministic order
				r = p1.team - p2.team;
			return r;
		}

	return scores_compare_players(p1.scorekeeper, p2.scorekeeper);
}

entity(.float field) scores_sort {
	entity p, plist, pprev, pbest, pbestprev, pfirst, plast;
	float i;

	plist = world;

	FOR_EACH_CLIENT(p)
		p.field = 0;

	FOR_EACH_PLAYER(p) if(p.scorekeeper)
	{
		p.chain = plist;
		plist = p;
	}
	// Now plist points to the whole list.

	pfirst = plast = world;

	i = 0;
	while(plist)
	{
		pprev = pbestprev = world;
		pbest = plist;
		for(p = plist; (pprev = p), (p = p.chain); )
		{
			if(scores_compare_players_team(p, pbest) > 0)
			{
				pbest = p;
				pbestprev = pprev;
			}
		}

		// remove pbest out of the chain
		if(pbestprev == world)
			plist = pbest.chain;
		else
			pbestprev.chain = pbest.chain;
		pbest.chain = world;

		pbest.field = ++i;

		if not(pfirst)
			pfirst = pbest;
		if(plast)
			plast.chain = pbest;
		plast = pbest;
	}

	return pfirst;
}

float(float t) scores_team_comparable_value {
	float s;
	entity sk;

	if(t <= 0 || t >= 16)
	{
		if(gameover)
			return 0;
		error("Reading score of invalid team!");
	}

	sk = teamscorekeepers[t - 1];
	if not(sk)
		return -999999999;
	s = sk.teamscores_primary;
	if(teamscores_flags_primary & SFL_ZERO_IS_WORST)
		if(!s)
			return -999999999;
	if(teamscores_flags_primary & SFL_LOWER_IS_BETTER)
		s = -s;
	return s;
}

#define NAMEWIDTH 22
#define SCORESWIDTH 58
// TODO put this somewhere in common?
string(float vflags) scores_nice_print_item_color {
	if(vflags & SFL_SORT_PRIO_PRIMARY)
		return "^3";
	else if(vflags & SFL_SORT_PRIO_SECONDARY)
		return "^5";
	else
		return "^7";
}

void(entity to, float t, float w) scores_nice_print_team {
	string s, s2;
	float i;
	entity sk;
	float fl, sc;
	s = "";

	sk = teamscorekeepers[t - 1];
	if(sk)
	{
		s = strcat(s, ColoredTeamName(t));
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if(teamscores_label[i] != "")
			{
				fl = teamscores_flags[i];
				sc = sk.(teamscores[i]);
				s = strcat(s, " ", scores_nice_print_item_color(fl), ScoreString(fl, sc));
			}
	}
	else
		s = "Scores:";

	s = strcat(s, strpad(max(0, NAMEWIDTH - strlennocol(s)), ""));

	for(i = 0; i < MAX_SCORE; ++i)
		if(scores_label[i] != "")
		{
			fl = scores_flags[i];
			s2 = scores_label[i];
			s = strcat(s, " ", scores_nice_print_item_color(fl), strpad(-w, substring(s2, 0, w)));
		}

	print_to(to, s);
}

void(entity to, entity p, float w) scores_nice_print_player {
	string s;
	float i;
	entity sk;
	float fl, sc;
	s = "  ";

	sk = p.scorekeeper;

	s = strcat(s, p.netname);
	for(;;)
	{
		i = strlennocol(s) - NAMEWIDTH;
		if(i > 0)
			s = substring(s, 0, strlen(s) - i);
		else
		{
			s = strcat(s, strpad(i, ""));
			break;
		}
	}

	for(i = 0; i < MAX_SCORE; ++i)
		if(scores_label[i] != "")
		{
			fl = scores_flags[i];
			sc = sk.(scores[i]);
			s = strcat(s, " ", scores_nice_print_item_color(fl), strpad(-w, ScoreString(fl, sc)));
		}

	print_to(to, s);
}

.float score_dummyfield;
void(entity to) scores_nice_print {
	entity p;
	float t, i;
	float w;

	t = 0;
	for(i = 0; i < MAX_SCORE; ++i)
		if(scores_label[i] != "")
			++t;
	w = bound(6, floor(SCORESWIDTH / t - 1), 9);

	p = scores_sort(score_dummyfield);
	t = -1;

	if(!teamscores_entities_count)
		scores_nice_print_team(to, t, w);
	while(p)
	{
		if(teamscores_entities_count)
			if(t != p.team)
				scores_nice_print_team(to, p.team, w);
		scores_nice_print_player(to, p, w);
		t = p.team;
		p = p.chain;
	}

	t = 0;
	FOR_EACH_CLIENT(p)
	if(p.classname != "player")
	{
		if not(t)
			print_to(to, "Spectators:");

		print_to(to, strcat("  ", p.netname));
		t = 1;
	}
}

float leaderfrags;
float WinningCondition_Scores(float limit, float _leadlimit)
{
	// TODO make everything use THIS winning condition (except LMS)
	WinningConditionHelper();

	if(teamplay)
	{
		team1_score = scores_team_comparable_value(COLOR_TEAM1);
		team2_score = scores_team_comparable_value(COLOR_TEAM2);
		team3_score = scores_team_comparable_value(COLOR_TEAM3);
		team4_score = scores_team_comparable_value(COLOR_TEAM4);
	}

	ClearWinners();
	if(WinningConditionHelper_winner)
		WinningConditionHelper_winner.winning = 1;
	if(WinningConditionHelper_winnerteam >= 0)
		SetWinners(team, WinningConditionHelper_winnerteam);

	if(WinningConditionHelper_lowerisbetter)
	{
		WinningConditionHelper_topscore = -WinningConditionHelper_topscore;
		WinningConditionHelper_secondscore = -WinningConditionHelper_secondscore;
		limit = -limit;
	}

	if(WinningConditionHelper_zeroisworst)
		_leadlimit = 0; // not supported in this mode

	if (limit)
	if (leaderfrags != WinningConditionHelper_topscore)
	{
		leaderfrags = WinningConditionHelper_topscore;
		GameHook_WinCountDown(limit - leaderfrags);
	}
	if (WinningConditionHelper_equality)
		return FALSE;

	if (WinningConditionHelper_topscore) {
		if (limit && (WinningConditionHelper_topscore >= limit))
			return TRUE;

		if (_leadlimit && (WinningConditionHelper_topscore - WinningConditionHelper_secondscore >= _leadlimit))
			return TRUE;
	}

	return FALSE;
}

float WinningCondition_RanOutOfSpawns()
{
	entity head;

	if(!have_team_spawns)
		return FALSE;

	if(!some_spawn_has_been_used)
		return FALSE;

	team1_score = team2_score = team3_score = team4_score = 0;

	FOR_EACH_PLAYER(head) if(head.deadflag == DEAD_NO)
	{
		if(head.team == COLOR_TEAM1)
			team1_score = 1;
		else if(head.team == COLOR_TEAM2)
			team2_score = 1;
		else if(head.team == COLOR_TEAM3)
			team3_score = 1;
		else if(head.team == COLOR_TEAM4)
			team4_score = 1;
	}

	for(head = world; (head = find(head, classname, "info_player_deathmatch")) != world; )
	{
		if(head.team == COLOR_TEAM1)
			team1_score = 1;
		else if(head.team == COLOR_TEAM2)
			team2_score = 1;
		else if(head.team == COLOR_TEAM3)
			team3_score = 1;
		else if(head.team == COLOR_TEAM4)
			team4_score = 1;
	}

	ClearWinners();
	if(team1_score + team2_score + team3_score + team4_score == 0)
	{
		checkrules_equality = TRUE;
		return TRUE;
	}
	else if(team1_score + team2_score + team3_score + team4_score == 1)
	{
		float t, i;
		if(team1_score) t = COLOR_TEAM1;
		if(team2_score) t = COLOR_TEAM2;
		if(team3_score) t = COLOR_TEAM3;
		if(team4_score) t = COLOR_TEAM4;
		teams_check_allowed(world);
		for(i = 0; i < MAX_TEAMSCORE; ++i)
		{
			if(t != COLOR_TEAM1) if(c1 >= 0) scores_team_add_to(COLOR_TEAM1, i, -1000);
			if(t != COLOR_TEAM2) if(c2 >= 0) scores_team_add_to(COLOR_TEAM2, i, -1000);
			if(t != COLOR_TEAM3) if(c3 >= 0) scores_team_add_to(COLOR_TEAM3, i, -1000);
			if(t != COLOR_TEAM4) if(c4 >= 0) scores_team_add_to(COLOR_TEAM4, i, -1000);
		}

		AddWinners(team, t);
		return TRUE;
	}
	else
		return FALSE;
}

void scores_touch(entity e) {
	scores_player_set(e, SP_TEAM, e.team);
}

// NOTE: SP_ constants may not be >= MAX_SCORE; ST_constants may not be >= MAX_TEAMSCORE
// scores that should be in all modes:
void(float sprio, float stprio, float score_enabled) scores_basics {
	float i;
	scores_preinitialized = 1;
	scores_registered = 0;
	scores_team_registered = 0;
	for(i = 0; i < MAX_SCORE; ++i) {
		scores_label[i] = "";
		scores_flags[i] = 0;
	}
	for(i = 0; i < MAX_TEAMSCORE; ++i) {
		teamscores_label[i] = "";
		teamscores_flags[i] = 0;
	}
	SP_TEAM = scores_register_score("team", 0);
	if(score_enabled)
		ST_SCORE = scores_register_team_score("score", stprio);

	if not(independent_players)
		SP_KILLS = scores_register_score("kills", 0);

	SP_DEATHS = scores_register_score("deaths", SFL_LOWER_IS_BETTER);
	if not(independent_players)
		SP_SUICIDES = scores_register_score("suicides", SFL_LOWER_IS_BETTER);

	if(score_enabled)
		SP_SCORE = scores_register_score("score", sprio);
}

void() scores_basics_end {
	teams_check_allowed(world);
	if(scores_initialized) {
		scores_initialized.SendFlags |= 1; // force a resend
	} else {
		scores_initialized = spawn();
		scores_initialized.classname = "ent_client_scoreinfo";
		Net_LinkEntity(scores_initialized, FALSE, 0, ScoreInfo_SendEntity);
	}
	if(c1 >= 0)
		scores_spawn_team(COLOR_TEAM1, "Red");

	if(c2 >= 0)
		scores_spawn_team(COLOR_TEAM2, "Blue");

	if(c3 >= 0)
		scores_spawn_team(COLOR_TEAM3, "Yellow");

	if(c4 >= 0)
		scores_spawn_team(COLOR_TEAM4, "Pink");
}

void() scores_generic {
	scores_basics(SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE);
}

void(entity attacker, entity targ, float f) scores_give_frag {
	if(gameover)
		return;

	if(f < 0) {
		if(targ == attacker)
		{
			// suicide
			scores_player_add(attacker, SP_SUICIDES, 1);
		}
		else
		{
			// teamkill
			scores_player_add(attacker, SP_KILLS, -1); // or maybe add a teamkills field?
		}
	} else {
		// regular frag
		scores_player_add(attacker, SP_KILLS, 1);
	}
	scores_player_add(targ, SP_DEATHS, 1);
	f = GameHook_FragsHandle(attacker, targ, f);
	attacker.totalfrags += f;
	if(f)
		scores_player_team_add_score(attacker, f);
}

