float g_balance_teams;
float g_balance_teams_force;
float g_balance_teams_movetype;
float g_balance_teams_prevent_imbalance;
float g_balance_teams_autoswap;
float g_balance_teams_autoswap_from_small_team_minplayers;
float g_balance_teams_autoswap_required_humans;
float g_balance_teams_autoswap_interval;
float g_balance_teams_autoswap_zerolead;
float g_balance_teams_autoswap_lead;
float g_balance_teams_adjust_sizes;
float g_balance_teams_adjust_sizes_factor;
float g_changeteam_banned;
float bot_vs_human;
float autoswap_last_from;
entity autoswap_last_best;
float team_size_adjust;
float team_size_adjust_value;

void team_change(entity pl, float dteam, float nobalance);
void team_balance_audit(float force);

// # of bots on those teams
float cb1, cb2, cb3, cb4;

string team_color_name(float t)
{
    // fixme: Search for team entities and get their .netname's!
    if (t == COLOR_TEAM1)
        return "Red";
    if (t == COLOR_TEAM2)
        return "Blue";
    if (t == COLOR_TEAM3)
        return "Yellow";
    if (t == COLOR_TEAM4)
        return "Pink";
    return "Neutral";
}

string team_color_nameLowerCase(float t)
{
    // fixme: Search for team entities and get their .netname's!
    if (t == COLOR_TEAM1)
        return "red";
    if (t == COLOR_TEAM2)
        return "blue";
    if (t == COLOR_TEAM3)
        return "yellow";
    if (t == COLOR_TEAM4)
        return "pink";
    return "neutral";
}


vector team_colormod(float teamcolor) {
    if (teamcolor == COLOR_TEAM1)
		return '1.8 0.6 0.6';
    else if (teamcolor == COLOR_TEAM2)
		return '0.6 0.6 1.8';
    else if (teamcolor == COLOR_TEAM3)
		return '1.4 1.4 0.2';
    else if (teamcolor == COLOR_TEAM4)
		return '1.4 0.2 1.4';

	return '0 0 0';
}

float team_from_index(float i) {
    switch(i) {
        case 0: return COLOR_TEAM1;
        case 1: return COLOR_TEAM2;
        case 2: return COLOR_TEAM3;
        case 3: return COLOR_TEAM4;
    }

    return 0;
}

vector(float teem) team_color {
	switch(teem)
	{
		case COLOR_TEAM1:
			return '1 0.0625 0.0625';
		case COLOR_TEAM2:
			return '0.0625 0.0625 1';
		case COLOR_TEAM3:
			return '1 1 0.0625';
		case COLOR_TEAM4:
			return '1 0.0625 1';
		default:
			return '1 1 1';
	}
}

string(float t) team_name {
	return strcat(team_color_name(t), " Team");
}

string(float t) team_colored_name {
	return strcat(team_color_code(t), team_color_name(t), " Team^7");
}

string(float t) team_name_by_no {
	// fixme: Search for team entities and get their .netname's!
	if(t == 1)
		return "Red Team";
	if(t == 2)
		return "Blue Team";
	if(t == 3)
		return "Yellow Team";
	if(t == 4)
		return "Pink Team";
	return "Neutral Team";
}

void(void) team_play_activate {
	teamplay = TRUE;
}

float at1, at2, at3, at4;
void(float _team) team_teams_set_allowed {
	if (_team == COLOR_TEAM1)
		at1 = 1;
	else if (_team == COLOR_TEAM2)
		at2 = 1;
	else if (_team == COLOR_TEAM3)
		at3 = 1;
	else if (_team == COLOR_TEAM4)
		at4 = 1;

	team_teams = at1 + at2 + at3 + at4;
}

void(float c) team_teams_set_count {
	at1 = at2 = at3 = at4 = 0;
	if (c > 0) at1 = 1;
	if (c > 1) at2 = 1;
	if (c > 2) at3 = 1;
	if (c > 3) at4 = 1;
	team_teams = at1 + at2 + at3 + at4;
}

// set c1...c4 to show what teams are allowed
void(entity for_whom) team_teams_allowed {
	c1 = c2 = c3 = c4 = -1;
	cb1 = cb2 = cb3 = cb4 = 0;
	if (at1) c1 = 0;
	if (at2) c2 = 0;
	if (at3) c3 = 0;
	if (at4) c4 = 0;

	// TODO: Balance quantity of bots across > 2 teams when bot_vs_human is set (and remove next line)
	if(c3==-1&&c4==-1)
	if(bot_vs_human && for_whom)
	{
		if(bot_vs_human > 0)
		{
			// bots are all blue
			if(clienttype(for_whom) == CLIENTTYPE_BOT)
				c1 = c3 = c4 = -1;
			else
				c2 = -1;
		}
		else
		{
			// bots are all red
			if(clienttype(for_whom) == CLIENTTYPE_BOT)
				c2 = c3 = c4 = -1;
			else
				c1 = -1;
		}
	}
	if (for_whom && for_whom == autoswap_last_best) {
		if (autoswap_last_from == COLOR_TEAM1)
			c1 = -1;
		else if (autoswap_last_from == COLOR_TEAM2)
			c2 = -1;
		else if (autoswap_last_from == COLOR_TEAM3)
			c3 = -1;
		else if (autoswap_last_from == COLOR_TEAM4)
			c4 = -1;
	}
}

// c1...c4 should be set to -1 (not allowed) or 0 (allowed).
// teams that are allowed will now have their player counts stored in c1...c4
void(entity ignore) team_teams_count {
	entity head;
	float value, bvalue;
	// now count how many players are on each team already

	// FIXME: also find and memorize the lowest-scoring bot on each team (in case players must be shuffled around)
	// also remember the lowest-scoring player

	FOR_EACH_CLIENT(head)
	{
		if(head != ignore)// && head.netname != "")
		{
			value = 1;
			if(clienttype(head) == CLIENTTYPE_BOT)
				bvalue = value;
			else
				bvalue = 0;
			if(head.team == COLOR_TEAM1)
			{
				if(c1 >= 0)
				{
					c1 = c1 + value;
					cb1 = cb1 + bvalue;
				}
			}
			if(head.team == COLOR_TEAM2)
			{
				if(c2 >= 0)
				{
					c2 = c2 + value;
					cb2 = cb2 + bvalue;
				}
			}
			if(head.team == COLOR_TEAM3)
			{
				if(c3 >= 0)
				{
					c3 = c3 + value;
					cb3 = cb3 + bvalue;
				}
			}
			if(head.team == COLOR_TEAM4)
			{
				if(c4 >= 0)
				{
					c4 = c4 + value;
					cb4 = cb4 + bvalue;
				}
			}
		}
	}
	float n = c1 + c2;
	if (c1 >= 0)
	if (c2 >= 0)
	if (c3 < 0)
	if (c4 < 0)
	if (n > 2)
	if (team_size_adjust) {
		float f = ceil((n + ((ignore.team > 0) ? 0 : 1)) * team_size_adjust_value * g_balance_teams_adjust_sizes_factor);
		f = bound(0, f, n - 2);
		if (team_size_adjust == COLOR_TEAM1) {
			c1 = c1 + f;
		} else if (team_size_adjust == COLOR_TEAM2) {
			c2 = c2 + f;
		}
	}
}

// returns # of smallest team (1, 2, 3, 4)
// NOTE: Assumes team_teams_allowed has already been called!
float(entity pl) team_find_smallest {
	float smallestteam_count, smallestteam_score, team_random;

	// find out what teams are available
	//team_teams_allowed();

	// make sure there are at least 2 teams to join
	// count how many players are in each team
	team_teams_count(pl);

	// c1...c4 now have counts of each team
	// figure out which is smallest, giving priority to the team the player is already on as a tie-breaker

	smallestteam_count = 999999999;
	smallestteam_score = 999999999;

	if(bot_would_leave)
	//if(pl.classname != "player")
	if(clienttype(pl) != CLIENTTYPE_BOT)
	{
		c1 -= cb1 * 255.0/256;
		c2 -= cb2 * 255.0/256;
		c3 -= cb3 * 255.0/256;
		c4 -= cb4 * 255.0/256;
	}
	if(c1 >= 0 && c1 < smallestteam_count)
		smallestteam_count = c1;

	if(c2 >= 0 && c2 < smallestteam_count)
		smallestteam_count = c2;

	if(c3 >= 0 && c3 < smallestteam_count)
		smallestteam_count = c3;

	if(c4 >= 0 && c4 < smallestteam_count)
		smallestteam_count = c4;

	if (c1 == smallestteam_count && pl.team == COLOR_TEAM1) return 1;
	if (c2 == smallestteam_count && pl.team == COLOR_TEAM2) return 2;
	if (c3 == smallestteam_count && pl.team == COLOR_TEAM3) return 3;
	if (c4 == smallestteam_count && pl.team == COLOR_TEAM4) return 4;
	if (c1 == smallestteam_count)
		smallestteam_score = min(smallestteam_score, score_team1);

	if (c2 == smallestteam_count)
		smallestteam_score = min(smallestteam_score, score_team2);

	if (c3 == smallestteam_count)
		smallestteam_score = min(smallestteam_score, score_team3);

	if (c4 == smallestteam_count)
		smallestteam_score = min(smallestteam_score, score_team4);

	team_random = 0;
	if (c1 == smallestteam_count)
	if (smallestteam_score == score_team1)
		team_random++;

	if (c2 == smallestteam_count)
	if (smallestteam_score == score_team2)
		team_random++;

	if (c3 == smallestteam_count)
	if (smallestteam_score == score_team3)
		team_random++;

	if (c4 == smallestteam_count)
	if (smallestteam_score == score_team4)
		team_random++;

	team_random = team_random * random();
	if (c1 == smallestteam_count)
	if (smallestteam_score == score_team1) {
		if (team_random <= 1)
			return 1;
		else
			team_random -= 1;
	}
	if (c2 == smallestteam_count)
	if (smallestteam_score == score_team2) {
		if (team_random <= 1)
			return 2;
		else
			team_random -= 1;
	}
	if (c3 == smallestteam_count)
	if (smallestteam_score == score_team3) {
		if (team_random <= 1)
			return 3;
		else
			team_random -= 1;
	}
	if (c4 == smallestteam_count)
	if (smallestteam_score == score_team4) {
		if (team_random <= 1)
			return 4;
		else
			team_random -= 1;
	}
	//never gonna happen
	return 1;
}

void (entity pl, float forcebestteam) team_join_best {
	float smallest, selectedteam;
	// don't join a team if we're not playing a team game
	if not(teamplay) {
		pl.team = 0;
		return;
	}
	// find out what teams are available
	team_teams_allowed(pl);
	// if we don't care what team he ends up on, put him on whatever team he entered as.
	// if he's not on a valid team, then let other code put him on the smallest team
	if(!forcebestteam)
	{
		if(     c1 >= 0 && pl.team == COLOR_TEAM1)
			selectedteam = pl.team;
		else if(c2 >= 0 && pl.team == COLOR_TEAM2)
			selectedteam = pl.team;
		else if(c3 >= 0 && pl.team == COLOR_TEAM3)
			selectedteam = pl.team;
		else if(c4 >= 0 && pl.team == COLOR_TEAM4)
			selectedteam = pl.team;
		else
			selectedteam = -1;

		if(selectedteam > 0) {
			player_set_team(pl, team_index(selectedteam), team_index(pl.team), FALSE);
			return;
		}
		// otherwise end up on the smallest team (handled below)
	}
	smallest = team_find_smallest(pl);
	if(smallest == 1)
		player_set_team(pl, team_index(COLOR_TEAM1), team_index(pl.team), FALSE);
	else if(smallest == 2)
		player_set_team(pl, team_index(COLOR_TEAM2), team_index(pl.team), FALSE);
	else if(smallest == 3)
		player_set_team(pl, team_index(COLOR_TEAM3), team_index(pl.team), FALSE);
	else if(smallest == 4)
		player_set_team(pl, team_index(COLOR_TEAM4), team_index(pl.team), FALSE);
	else
		error("smallest team: invalid team\n");

	team_balance_audit(FALSE);
	return;
}

void(float _color) SV_ChangeTeam {
	if (teamplay)
		return;

	player_set_colors(self, _color);
}

void(entity pl, float dteam, float nobalance) team_change {
	float dcount, scount;
	team_teams_allowed(pl);
	switch (dteam) {
	case COLOR_TEAM1: if (c1 < 0) return; break;
	case COLOR_TEAM2: if (c2 < 0) return; break;
	case COLOR_TEAM3: if (c3 < 0) return; break;
	case COLOR_TEAM4: if (c4 < 0) return; break;
	}
	float teamchange = (pl.team > 0);
	if((g_campaign && teamchange) || (g_changeteam_banned && pl.wasplayer)) {
		sprint(pl, "Team changes not allowed\n");
		return; // changing teams is not allowed
	}
	if not(nobalance)
	if (g_balance_teams_prevent_imbalance || g_balance_teams_force)
	if (pl.team != dteam)
	{
		// only allow changing to a smaller or equal size team
		// find out what teams are available
		// count how many players on each team
		team_teams_count(pl);
		float cr1 = c1 - cb1;
		float cr2 = c2 - cb2;
		float cr3 = c3 - cb3;
		float cr4 = c4 - cb4;
		switch (pl.team) {
		case COLOR_TEAM1: scount = cr1; break;
		case COLOR_TEAM2: scount = cr2; break;
		case COLOR_TEAM3: scount = cr3; break;
		case COLOR_TEAM4: scount = cr4; break;
		}
		if(dteam == COLOR_TEAM1 && c1 >= 0)
			dcount = cr1;
		else if(dteam == COLOR_TEAM2 && c2 >= 0)
			dcount = cr2;
		else if(dteam == COLOR_TEAM3 && c3 >= 0)
			dcount = cr3;
		else if(dteam == COLOR_TEAM4 && c4 >= 0)
			dcount = cr4;

		float largeteam;
		largeteam = FALSE;
		if (teamchange)
			if (scount < dcount)
				largeteam = TRUE;

		if ((cr1 >= 0 && dcount > cr1)
				|| (cr2 >= 0 && dcount > cr2)
				|| (cr3 >= 0 && dcount > cr3)
				|| (cr4 >= 0 && dcount > cr4)) {
			largeteam = TRUE;
		}
		if (largeteam) {
			sprint(pl, "Cannot change to a larger team\n");
			return;
		}
	}
	if (pl.team == dteam)
		return;

	entity oldself = self;
	player_set_team(pl, team_index(dteam), team_index(pl.team), FALSE);
	if(pl.classname == "player") {
		if(pl.deadflag == DEAD_NO) // kill player when changing teams
			damage(pl, pl, pl, 100000, DEATH_TEAMCHANGE, pl.origin, '0 0 0');
	} else if not(teamchange) {
		self = pl;
		spectator_to_player();
		self = oldself;
	}
	entity e;
	if not(nobalance) {
		if (teamchange)
		if (clienttype(pl) == CLIENTTYPE_REAL)
		FOR_EACH_PLAYER(e)
			if (clienttype(e) == CLIENTTYPE_BOT)
			if (e.team == dteam) {
				e.team = -1;
				self = e;
				client_put();
				self = oldself;
				break;
			}
		team_balance_audit(FALSE);
	}
}

void(float source_team) team_shuffle_player_out {
	float smallestteam, smallestteam_count, steam;
	float selected_bot_score, selected_player_score;
	entity head, selected_bot, selected_player, selected;
	bprint("Rebalancing Teams\n");
	smallestteam = 0;
	smallestteam_count = 999999999;
	if(c1 >= 0 && c1 < smallestteam_count) {
		smallestteam = 1;
		smallestteam_count = c1;
	}
	if(c2 >= 0 && c2 < smallestteam_count) {
		smallestteam = 2;
		smallestteam_count = c2;
	}
	if(c3 >= 0 && c3 < smallestteam_count) {
		smallestteam = 3;
		smallestteam_count = c3;
	}
	if(c4 >= 0 && c4 < smallestteam_count) {
		smallestteam = 4;
		smallestteam_count = c4;
	}
	if(!smallestteam) {
		bprint("warning: no smallest team\n");
		return;
	}
	if(source_team == 1)
		steam = COLOR_TEAM1;
	else if(source_team == 2)
		steam = COLOR_TEAM2;
	else if(source_team == 3)
		steam = COLOR_TEAM3;
	else if(source_team == 4)
		steam = COLOR_TEAM4;

	selected_bot = world;
	selected_player = world;
	float player_score;
	if (g_balance_teams_movetype == 1) { //random
		random_selection_init();
		FOR_EACH_CLIENT(head) {
			if (head.team == steam)
			if (head.isbot) {
				random_selection_add(head, 0, "", 1, 1);
			}
		}
		selected_bot = random_selection_chosen_ent;
		random_selection_init();
		FOR_EACH_CLIENT(head) {
			if (head.team == steam)
			if not(head.isbot) {
				random_selection_add(head, 0, "", 1, 1);
			}
		}
		selected_player = random_selection_chosen_ent;
	} else if (g_balance_teams_movetype == 2) { //best
		FOR_EACH_CLIENT(head) {
			player_score = head.scorekeeper.scores[SP_SCORE];
			if(head.team == steam) {
				if(head.isbot) {
					if(!selected_bot || player_score > selected_bot_score) {
						selected_bot = head;
						selected_bot_score = player_score;
					}
				} else {
					if(!selected_player || player_score > selected_player_score) {
						selected_player = head;
						selected_player_score = player_score;
					}
				}
			}
		}
	} else { //worst
		FOR_EACH_CLIENT(head) {
			player_score = head.scorekeeper.scores[SP_SCORE];
			if(head.team == steam) {
				if(head.isbot) {
					if(!selected_bot || player_score < selected_bot_score) {
						selected_bot = head;
						selected_bot_score = player_score;
					}
				} else {
					if(!selected_player || player_score < selected_player_score) {
						selected_player = head;
						selected_player_score = player_score;
					}
				}
			}
		}
	}
	// prefers to move a bot...
	if(selected_bot != world)
		selected = selected_bot;
	else // but it will move a player if it has to
		selected = selected_player;

	// don't do anything if it couldn't find anyone
	if(!selected) {
		bprint("warning: couldn't find a player to move from team\n");
		return;
	}
	// smallest team gains a member
	if(smallestteam == 1) {
		c1 = c1 + 1;
	} else if(smallestteam == 2) {
		c2 = c2 + 1;
	} else if(smallestteam == 3) {
		c3 = c3 + 1;
	} else if(smallestteam == 4) {
		c4 = c4 + 1;
	} else {
		bprint("warning: destination team invalid\n");
		return;
	}
	// source team loses a member
	if(source_team == 1) {
		c1 = c1 + 1;
	} else if(source_team == 2) {
		c2 = c2 + 2;
	} else if(source_team == 3) {
		c3 = c3 + 3;
	} else if(source_team == 4) {
		c4 = c4 + 4;
	} else {
		bprint("warning: source team invalid\n");
		return;
	}
	// move the player to the new team
	if (autoswap_last_best == selected)
		autoswap_last_best = world;

	entity oldself = self;
	self = selected;
	player_clear(FALSE);
	self = oldself;
	player_set_team(selected, smallestteam, source_team, FALSE);
	if(selected.deadflag == DEAD_NO)
		damage(selected, selected, selected, 100000, DEATH_AUTOTEAMCHANGE, selected.origin, '0 0 0');

	centerprint(selected, strcat("You have been moved into a different team to improve team balance\nYou are now on: ", team_colored_name(selected.team)));
}

entity team_note;

void(void) team_note_message {
	self.message = "^1Teamnumbers are unbalanced!\n^2Press ^3{menu_showteamselect}^2 to adjust";
	if (self.dmg)
		self.message = strcat(self.message, "\n^2Autobalance in ^1", ftos(ceil(self.dmg - time)), "^2 seconds");
}

float(void) team_note_customize {
	switch (other.team) {
	case COLOR_TEAM1: return self.cnt & 1;
	case COLOR_TEAM2: return self.cnt & 2;
	case COLOR_TEAM3: return self.cnt & 4;
	case COLOR_TEAM4: return self.cnt & 8;
	}
	return FALSE;
}

void(void) team_note_think {
	if (time > self.dmg) {
		team_balance_audit(TRUE);
		return;
	}
	self.nextthink = time + 1;
	self.SendFlags = 1;
}

void(void) team_note_remove {
	if (team_note) {
		remove(team_note);
		team_note = world;
	}
}

void(void) team_note_reset {
	team_balance_audit(TRUE);
}

float(entity plr, float targetteam) team_fast_switch_allowed {
	if (team_note) {
		switch (targetteam) {
		case COLOR_TEAM1: if (team_note.cnt & 1) return FALSE; break;
		case COLOR_TEAM2: if (team_note.cnt & 2) return FALSE; break;
		case COLOR_TEAM3: if (team_note.cnt & 4) return FALSE; break;
		case COLOR_TEAM4: if (team_note.cnt & 8) return FALSE; break;
		}
		switch (plr.team) {
		case COLOR_TEAM1: return team_note.cnt & 1;
		case COLOR_TEAM2: return team_note.cnt & 2;
		case COLOR_TEAM3: return team_note.cnt & 4;
		case COLOR_TEAM4: return team_note.cnt & 8;
		}
	}
	return FALSE;
}

void team_balance_audit(float force)
{
	float numplayers, numteams, smallest, toomany;
	if(map_intermission_running)
		return; // no rebalancing whatsoever please

	if(g_campaign)
		return;

	if (bot_vs_human)
		return;

	team_teams_allowed(world);
	team_teams_count(world);
	numteams = numplayers = smallest = 0;
	if(c1 >= 0)
	{
		numteams = numteams + 1;
		numplayers = numplayers + c1;
		smallest = c1;
	}
	if(c2 >= 0)
	{
		numteams = numteams + 1;
		numplayers = numplayers + c2;
		if(c2 < smallest)
			smallest = c2;
	}
	if(c3 >= 0)
	{
		numteams = numteams + 1;
		numplayers = numplayers + c3;
		if(c3 < smallest)
			smallest = c3;
	}
	if(c4 >= 0)
	{
		numteams = numteams + 1;
		numplayers = numplayers + c4;
		if(c4 < smallest)
			smallest = c4;
	}

	if(numplayers <= 0) {
		team_note_remove();
		return; // no players to move around
	}
	if(numteams < 2) {
		return; // don't bother shuffling if for some reason there aren't any teams
	}
	toomany = smallest + 1;
	float team_flags = ((c1 > toomany) ? 1 : 0) + ((c2 > toomany) ? 2 : 0) + ((c3 > toomany) ? 4 : 0) + ((c4 > toomany) ? 8 : 0);
	if not(team_flags)
		team_note_remove();

	if (!force && g_balance_teams_force >= 0) {
		if (team_flags) {
			if not(team_note) {
				team_note = NoteLine_New(team_note_message);
				team_note.customizeentityforclient = team_note_customize;
				if (g_balance_teams_force) {
					team_note.dmg = time + g_balance_teams_force;
					team_note.reset = team_note_reset;
				}
			}
			team_note.cnt = team_flags;
			team_note.SendFlags = 1;
			if (g_balance_teams_force) {
				team_note.think = team_note_think;
				team_note.nextthink = time;
			}
		}
		return;
	}
	if(c1 > toomany)
		team_shuffle_player_out(1);
	if(c2 > toomany)
		team_shuffle_player_out(2);
	if(c3 > toomany)
		team_shuffle_player_out(3);
	if(c4 > toomany)
		team_shuffle_player_out(4);

	if (force)
		team_balance_audit(FALSE);
}

void(void) team_init {
	CACHE_CVAR(g_balance_teams);
	CACHE_CVAR(g_balance_teams_autoswap);
	CACHE_CVAR(g_balance_teams_autoswap_from_small_team_minplayers);
	CACHE_CVAR(g_balance_teams_autoswap_required_humans);
	CACHE_CVAR(g_balance_teams_autoswap_interval);
	CACHE_CVAR(g_balance_teams_autoswap_zerolead);
	CACHE_CVAR(g_balance_teams_autoswap_lead);
	CACHE_CVAR(g_balance_teams_force);
	CACHE_CVAR(g_balance_teams_movetype);
	CACHE_CVAR(g_balance_teams_prevent_imbalance);
	CACHE_CVAR(g_balance_teams_adjust_sizes);
	CACHE_CVAR(g_balance_teams_adjust_sizes_factor);
	CACHE_CVAR(g_changeteam_banned);
	CACHE_CVAR(bot_vs_human);
};

float autoswap_last_time;
void team_autoswap_best_with_worst(float from, float to) {
	entity best = world, worst = world;
	entity e;
	autoswap_last_time = time;
	autoswap_last_from = from;
	FOR_EACH_PLAYER(e) {
		if (e.team == from) {
			if (best) {
				if (score_compare_players(best.scorekeeper, e.scorekeeper) < 0)
					best = e;
			} else
				best = e;
		}
	}
	FOR_EACH_PLAYER(e) {
		if (e.team == to) {
			if (worst) {
				if (score_compare_players(worst.scorekeeper, e.scorekeeper) > 0)
					worst = e;
			} else
				worst = e;
		}
	}
	autoswap_last_best = best;
	if (best) {
		if (c1 - c2 == 0 && worst) {
			team_change(best, to, TRUE);
			team_change(worst, from, TRUE);
		} else if ((c1 < c2 && from == COLOR_TEAM2) || (c1 > c2 && from == COLOR_TEAM1)) {
			team_change(best, to, TRUE);
			if (fabs(c1 - c2) == 1 && worst) {
				team_change(worst, from, TRUE);
			} else
				team_balance_audit(FALSE);
		} else if ((c1 == c2 + 1 && from == COLOR_TEAM2) || (c1 + 1 == c2 && from == COLOR_TEAM1) && worst && c1 + c2 >= g_balance_teams_autoswap_from_small_team_minplayers) {
			team_change(best, to, TRUE);
			team_change(worst, from, TRUE);
		}
	}

}

float autoswap_lastmaxscore;
void() teams_balance_check {
	if (map_finished)
		return;

	if (bot_vs_human)
		return;

	float t1 = score_team_comparable_value(COLOR_TEAM1);
	float t2 = score_team_comparable_value(COLOR_TEAM2);
	if (g_balance_teams_adjust_sizes > 0) {
		float f = t2 - t1;
		team_size_adjust = 0;
		if (f >= g_balance_teams_adjust_sizes) {
			team_size_adjust = COLOR_TEAM2;
			team_size_adjust_value = (f / g_balance_teams_adjust_sizes);
		} else if (f <= -g_balance_teams_adjust_sizes) {
			team_size_adjust = COLOR_TEAM1;
			team_size_adjust_value = (f / -g_balance_teams_adjust_sizes);
		}
		team_balance_audit(FALSE);
	}
	if (autoswap_last_time + g_balance_teams_autoswap_interval >= time)
		return;

	if not(g_balance_teams_autoswap)
		return;

	team_teams_allowed(world);
	team_teams_count(world);
	if (c1 >= 0)
	if (c2 >= 0)
	if (c3 < 0)
	if (c4 < 0)
	if (c1 + c2 > 2)
	if (c1 - cb1 + c2 - cb2 >= g_balance_teams_autoswap_required_humans)
	{
		float maxscore = max(t1, t2);
		if (maxscore == autoswap_lastmaxscore)
			return;

		autoswap_lastmaxscore = maxscore;
		if (g_balance_teams_autoswap_zerolead && t1 == 0 && t2 >= g_balance_teams_autoswap_zerolead) {
			team_autoswap_best_with_worst(COLOR_TEAM2, COLOR_TEAM1);
		} else if (g_balance_teams_autoswap_zerolead && t2 == 0 && t1 >= g_balance_teams_autoswap_zerolead) {
			team_autoswap_best_with_worst(COLOR_TEAM1, COLOR_TEAM2);
		} else if (g_balance_teams_autoswap_lead && t1 - t2 >= g_balance_teams_autoswap_lead) {
			team_autoswap_best_with_worst(COLOR_TEAM1, COLOR_TEAM2);
		} else if (g_balance_teams_autoswap_lead && t2 - t1 >= g_balance_teams_autoswap_lead) {
			team_autoswap_best_with_worst(COLOR_TEAM2, COLOR_TEAM1);
		}
	}
}

float(entity a, entity b) team_is_different_teams {
	if(teamplay) {
		if(a.team == b.team)
			return 0;
	} else {
		if(a == b)
			return 0;
	}
	return 1;
}

void(float t) team_spawn_players {
	entity e, oldself;
	FOR_EACH_CLIENT(e)
		if (e.team == t)
		if (e.classname != "player") {
			e.classname = "player";
			oldself = self;
			self = e;
			client_put();
			self = oldself;
		}
}
