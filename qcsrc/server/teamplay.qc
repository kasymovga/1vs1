float g_balance_teams;
float g_balance_teams_force;
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

void() tdm_init;

void ChangeTeam(entity pl, float dteam, float nobalance);
void AuditTeams(float force);

// # of bots on those teams
float cb1, cb2, cb3, cb4;

string Team_ColorName(float t)
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

string Team_ColorNameLowerCase(float t)
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


void Balance_Centerprint(entity e) {
	centerprint(e, strcat("You have been moved into a different team to improve team balance\nYou are now on: ", ColoredTeamName(e.team)));
}

vector TeamColorMod(float teamcolor) {
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

float Team_Index(float t) {
    switch(t) {
        case COLOR_TEAM1: return 0;
        case COLOR_TEAM2: return 1;
        case COLOR_TEAM3: return 2;
        case COLOR_TEAM4: return 3;
    }

    return -1;
}

float Team_FromIndex(float i) {
    switch(i) {
        case 0: return COLOR_TEAM1;
        case 1: return COLOR_TEAM2;
        case 2: return COLOR_TEAM3;
        case 3: return COLOR_TEAM4;
    }

    return 0;
}

vector TeamColor(float teem)
{
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

string TeamName(float t)
{
	return strcat(Team_ColorName(t), " Team");
}
string ColoredTeamName(float t)
{
	return strcat(Team_ColorCode(t), Team_ColorName(t), " Team^7");
}
string TeamNoName(float t)
{
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

void ActivateTeamplay()
{
	teamplay = TRUE;
}

float tdm_FragLimitOverride() {
	return cvar("g_tdm_fraglimit");
}

void SetPlayerColors(entity pl, float _color)
{
	float pants, shirt;
	pants = _color & 0x0F;
	shirt = _color & 0xF0;
	float t = pl.team;
	if(teamplay)
		setcolor(pl, 16*pants + pants);
	else
		setcolor(pl, shirt + pants);

	pl.team = t;
}

void SetPlayerTeam(entity pl, float t, float s, float noprint)
{
	if(t == 4)
		pl.team = COLOR_TEAM4;
	else if(t == 3)
		pl.team = COLOR_TEAM3;
	else if(t == 2)
		pl.team = COLOR_TEAM2;
	else if (t == 1)
		pl.team = COLOR_TEAM1;
	else
		return;

	if(!noprint && t != s)
	{
		//bprint(pl.netname, " has changed to ", TeamNoName(t), "\n");
		bprint(pl.netname, "^7 has changed from ", TeamNoName(s), " to ", TeamNoName(t), "\n");
	}
	scores_touch(pl);
}

float at1, at2, at3, at4;
void SetAllowedTeam(float _team) {
	if (_team == COLOR_TEAM1)
		at1 = TRUE;
	else if (_team == COLOR_TEAM2)
		at2 = TRUE;
	else if (_team == COLOR_TEAM3)
		at3 = TRUE;
	else if (_team == COLOR_TEAM4)
		at4 = TRUE;
}

void SetTeamCount(float c) {
	at1 = at2 = at3 = at4 = 0;
	if (c > 0) at1 = 1;
	if (c > 1) at2 = 1;
	if (c > 2) at3 = 1;
	if (c > 3) at4 = 1;
}

// set c1...c4 to show what teams are allowed
void(entity for_whom) teams_check_allowed {
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
void GetTeamCounts(entity ignore)
{
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
// NOTE: Assumes teams_check_allowed has already been called!
float FindSmallestTeam(entity pl)
{
	float smallestteam_count, smallestteam_score, team_random;

	// find out what teams are available
	//teams_check_allowed();

	// make sure there are at least 2 teams to join
	// count how many players are in each team
	GetTeamCounts(pl);

	// c1...c4 now have counts of each team
	// figure out which is smallest, giving priority to the team the player is already on as a tie-breaker

	smallestteam_count = 999999999;
	smallestteam_score = 999999999;

	if(bots_would_leave)
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
		smallestteam_score = min(smallestteam_score, team1_score);

	if (c2 == smallestteam_count)
		smallestteam_score = min(smallestteam_score, team2_score);

	if (c3 == smallestteam_count)
		smallestteam_score = min(smallestteam_score, team3_score);

	if (c4 == smallestteam_count)
		smallestteam_score = min(smallestteam_score, team4_score);

	team_random = 0;
	if (c1 == smallestteam_count)
	if (smallestteam_score == team1_score)
		team_random++;

	if (c2 == smallestteam_count)
	if (smallestteam_score == team2_score)
		team_random++;

	if (c3 == smallestteam_count)
	if (smallestteam_score == team3_score)
		team_random++;

	if (c4 == smallestteam_count)
	if (smallestteam_score == team4_score)
		team_random++;

	team_random = team_random * random();
	if (c1 == smallestteam_count)
	if (smallestteam_score == team1_score) {
		if (team_random <= 1)
			return 1;
		else
			team_random -= 1;
	}
	if (c2 == smallestteam_count)
	if (smallestteam_score == team2_score) {
		if (team_random <= 1)
			return 2;
		else
			team_random -= 1;
	}
	if (c3 == smallestteam_count)
	if (smallestteam_score == team3_score) {
		if (team_random <= 1)
			return 3;
		else
			team_random -= 1;
	}
	if (c4 == smallestteam_count)
	if (smallestteam_score == team4_score) {
		if (team_random <= 1)
			return 4;
		else
			team_random -= 1;
	}
	//never gonna happen
	return 1;
}

void JoinBestTeam(entity pl, float forcebestteam)
{
	float smallest, selectedteam;
	// don't join a team if we're not playing a team game
	if not(teamplay) {
		pl.team = 0;
		return;
	}
	// find out what teams are available
	teams_check_allowed(pl);
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
			SetPlayerTeam(pl, TeamColorSkin(selectedteam), TeamColorSkin(pl.team), FALSE);
			return;
		}
		// otherwise end up on the smallest team (handled below)
	}
	smallest = FindSmallestTeam(pl);
	if(smallest == 1)
		SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM1), TeamColorSkin(pl.team), FALSE);
	else if(smallest == 2)
		SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM2), TeamColorSkin(pl.team), FALSE);
	else if(smallest == 3)
		SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM3), TeamColorSkin(pl.team), FALSE);
	else if(smallest == 4)
		SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM4), TeamColorSkin(pl.team), FALSE);
	else
		error("smallest team: invalid team\n");

	AuditTeams(FALSE);
	return;
}

void SV_ChangeTeam(float _color)
{
	if (teamplay)
		return;

	SetPlayerColors(self, _color);
}

void ChangeTeam(entity pl, float dteam, float nobalance) {
	float dcount, scount;
	teams_check_allowed(pl);
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
		GetTeamCounts(pl);
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
	SetPlayerTeam(pl, TeamColorSkin(dteam), TeamColorSkin(pl.team), FALSE);
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
				PutClientInServer();
				self = oldself;
				break;
			}
		AuditTeams(FALSE);
	}
}


void ShufflePlayerOutOfTeam (float source_team)
{
	float smallestteam, smallestteam_count, steam;
	float lowest_bot_score, lowest_player_score;
	entity head, lowest_bot, lowest_player, selected;

	smallestteam = 0;
	smallestteam_count = 999999999;

	if(c1 >= 0 && c1 < smallestteam_count)
	{
		smallestteam = 1;
		smallestteam_count = c1;
	}
	if(c2 >= 0 && c2 < smallestteam_count)
	{
		smallestteam = 2;
		smallestteam_count = c2;
	}
	if(c3 >= 0 && c3 < smallestteam_count)
	{
		smallestteam = 3;
		smallestteam_count = c3;
	}
	if(c4 >= 0 && c4 < smallestteam_count)
	{
		smallestteam = 4;
		smallestteam_count = c4;
	}

	if(!smallestteam)
	{
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

	lowest_bot = world;
	lowest_bot_score = 999999999;
	lowest_player = world;
	lowest_player_score = 999999999;

	// find the lowest-scoring player & bot of that team
	float player_score;
	FOR_EACH_CLIENT(head)
	{
		player_score = head.scorekeeper.scores[SP_SCORE];
		if(head.team == steam)
		{
			if(head.isbot)
			{
				if(player_score < lowest_bot_score)
				{
					lowest_bot = head;
					lowest_bot_score = player_score;
				}
			}
			else
			{
				if(player_score < lowest_player_score)
				{
					lowest_player = head;
					lowest_player_score = player_score;
				}
			}
		}
	}

	// prefers to move a bot...
	if(lowest_bot != world)
		selected = lowest_bot;
	// but it will move a player if it has to
	else
		selected = lowest_player;
	// don't do anything if it couldn't find anyone
	if(!selected)
	{
		bprint("warning: couldn't find a player to move from team\n");
		return;
	}

	// smallest team gains a member
	if(smallestteam == 1)
	{
		c1 = c1 + 1;
	}
	else if(smallestteam == 2)
	{
		c2 = c2 + 1;
	}
	else if(smallestteam == 3)
	{
		c3 = c3 + 1;
	}
	else if(smallestteam == 4)
	{
		c4 = c4 + 1;
	}
	else
	{
		bprint("warning: destination team invalid\n");
		return;
	}
	// source team loses a member
	if(source_team == 1)
	{
		c1 = c1 + 1;
	}
	else if(source_team == 2)
	{
		c2 = c2 + 2;
	}
	else if(source_team == 3)
	{
		c3 = c3 + 3;
	}
	else if(source_team == 4)
	{
		c4 = c4 + 4;
	}
	else
	{
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
	SetPlayerTeam(selected, smallestteam, source_team, FALSE);

	if(selected.deadflag == DEAD_NO)
		damage(selected, selected, selected, 100000, DEATH_AUTOTEAMCHANGE, selected.origin, '0 0 0');

	Balance_Centerprint(selected);
}

void CauseRebalance(float source_team, float howmany_toomany)
{
	bprint("Rebalancing Teams\n");
	ShufflePlayerOutOfTeam(source_team);
}

entity teams_note;

void Teams_Note_Message() {
	self.message = "^1Teamnumbers are unbalanced!\n^2Press ^3{menu_showteamselect}^2 to adjust";
	if (self.dmg)
		self.message = strcat(self.message, "\n^2Autobalance in ^1", ftos(ceil(self.dmg - time)), "^2 seconds");
}

float Teams_Note_Customize() {
	switch (other.team) {
	case COLOR_TEAM1: return self.cnt & 1;
	case COLOR_TEAM2: return self.cnt & 2;
	case COLOR_TEAM3: return self.cnt & 4;
	case COLOR_TEAM4: return self.cnt & 8;
	}
	return FALSE;
}

void Teams_Note_Think() {
	if (time > self.dmg) {
		AuditTeams(TRUE);
		return;
	}
	self.nextthink = time + 1;
	self.SendFlags = 1;
}

void Teams_Note_Remove() {
	if (teams_note) {
		remove(teams_note);
		teams_note = world;
	}
}

void() Teams_Note_Reset {
	AuditTeams(TRUE);
}

float FastTeamSwitchAllowed(entity plr, float targetteam) {
	if (teams_note) {
		switch (targetteam) {
		case COLOR_TEAM1: if (teams_note.cnt & 1) return FALSE; break;
		case COLOR_TEAM2: if (teams_note.cnt & 2) return FALSE; break;
		case COLOR_TEAM3: if (teams_note.cnt & 4) return FALSE; break;
		case COLOR_TEAM4: if (teams_note.cnt & 8) return FALSE; break;
		}
		switch (plr.team) {
		case COLOR_TEAM1: return teams_note.cnt & 1;
		case COLOR_TEAM2: return teams_note.cnt & 2;
		case COLOR_TEAM3: return teams_note.cnt & 4;
		case COLOR_TEAM4: return teams_note.cnt & 8;
		}
	}
	return FALSE;
}

void AuditTeams(float force)
{
	float numplayers, numteams, smallest, toomany;
	if(intermission_running)
		return; // no rebalancing whatsoever please

	if(g_campaign)
		return;

	if (bot_vs_human)
		return;

	teams_check_allowed(world);
	GetTeamCounts(world);
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
		Teams_Note_Remove();
		return; // no players to move around
	}
	if(numteams < 2) {
		return; // don't bother shuffling if for some reason there aren't any teams
	}
	toomany = smallest + 1;
	float team_flags = ((c1 > toomany) ? 1 : 0) + ((c2 > toomany) ? 2 : 0) + ((c3 > toomany) ? 4 : 0) + ((c4 > toomany) ? 8 : 0);
	if not(team_flags)
		Teams_Note_Remove();

	if (!force && g_balance_teams_force >= 0) {
		if (team_flags) {
			if not(teams_note) {
				teams_note = NoteLine_New(Teams_Note_Message);
				teams_note.customizeentityforclient = Teams_Note_Customize;
				if (g_balance_teams_force) {
					teams_note.dmg = time + g_balance_teams_force;
					teams_note.reset = Teams_Note_Reset;
				}
			}
			teams_note.cnt = team_flags;
			teams_note.SendFlags = 1;
			if (g_balance_teams_force) {
				teams_note.think = Teams_Note_Think;
				teams_note.nextthink = time;
			}
		}
		return;
	}
	if(c1 > toomany)
		CauseRebalance(1, c1 - toomany);
	if(c2 > toomany)
		CauseRebalance(2, c2 - toomany);
	if(c3 > toomany)
		CauseRebalance(3, c3 - toomany);
	if(c4 > toomany)
		CauseRebalance(4, c4 - toomany);

	if (force)
		AuditTeams(FALSE);
}

// code from here on is just to support maps that don't have team entities
void tdm_spawnteam (string teamname, float teamcolor)
{
	local entity e;
	e = spawn();
	e.classname = "tdm_team";
	e.netname = teamname;
	e.cnt = teamcolor;
	e.team = e.cnt + 1;
};

void tdm_delayedinit()
{
	// if no teams are found, spawn defaults
	entity e;
	for (e = find(world, classname, "tdm_team"); e; e = find(e, classname, "tdm_team")) {
		SetAllowedTeam(e.team);
	}
	teams_check_allowed(world);
	float teams_override = cvar("g_tdm_teams_override");
	if (c1 + c2 + c3 + c4 < -2 || teams_override > 1) {
		SetTeamCount(0);
		float numteams = teams_override;
		if(numteams < 2)
			numteams = cvar("g_tdm_teams");

		numteams = bound(2, numteams, 4);
		SetAllowedTeam(COLOR_TEAM1);
		SetAllowedTeam(COLOR_TEAM2);
		if (numteams > 2) SetAllowedTeam(COLOR_TEAM3);
		if (numteams > 3) SetAllowedTeam(COLOR_TEAM4);
	}
};

void tdm_init()
{
	entity_initialize(world, tdm_delayedinit, INITPRIO_GAMETYPE);
};

void Teamplay_ReadCvars()
{
	CACHE_CVAR(g_balance_teams);
	CACHE_CVAR(g_balance_teams_autoswap);
	CACHE_CVAR(g_balance_teams_autoswap_from_small_team_minplayers);
	CACHE_CVAR(g_balance_teams_autoswap_required_humans);
	CACHE_CVAR(g_balance_teams_autoswap_interval);
	CACHE_CVAR(g_balance_teams_autoswap_zerolead);
	CACHE_CVAR(g_balance_teams_autoswap_lead);
	CACHE_CVAR(g_balance_teams_force);
	CACHE_CVAR(g_balance_teams_prevent_imbalance);
	CACHE_CVAR(g_balance_teams_adjust_sizes);
	CACHE_CVAR(g_balance_teams_adjust_sizes_factor);
	CACHE_CVAR(g_changeteam_banned);
	CACHE_CVAR(bot_vs_human);
};

float autoswap_last_time;
void Team_AutoSwap_BestWithWorst(float from, float to) {
	entity best = world, worst = world;
	entity e;
	autoswap_last_time = time;
	autoswap_last_from = from;
	FOR_EACH_PLAYER(e) {
		if (e.team == from) {
			if (best) {
				if (scores_compare_players(best.scorekeeper, e.scorekeeper) < 0)
					best = e;
			} else
				best = e;
		}
	}
	FOR_EACH_PLAYER(e) {
		if (e.team == to) {
			if (worst) {
				if (scores_compare_players(worst.scorekeeper, e.scorekeeper) > 0)
					worst = e;
			} else
				worst = e;
		}
	}
	autoswap_last_best = best;
	if (best) {
		if (c1 - c2 == 0 && worst) {
			ChangeTeam(best, to, TRUE);
			ChangeTeam(worst, from, TRUE);
		} else if ((c1 < c2 && from == COLOR_TEAM2) || (c1 > c2 && from == COLOR_TEAM1)) {
			ChangeTeam(best, to, TRUE);
			if (fabs(c1 - c2) == 1 && worst) {
				ChangeTeam(worst, from, TRUE);
			} else
				AuditTeams(FALSE);
		} else if ((c1 == c2 + 1 && from == COLOR_TEAM2) || (c1 + 1 == c2 && from == COLOR_TEAM1) && worst && c1 + c2 >= g_balance_teams_autoswap_from_small_team_minplayers) {
			ChangeTeam(best, to, TRUE);
			ChangeTeam(worst, from, TRUE);
		}
	}

}

float autoswap_lastmaxscore;
void() teams_balance_check {
	if (gameover)
		return;

	if (bot_vs_human)
		return;

	float t1 = scores_team_comparable_value(COLOR_TEAM1);
	float t2 = scores_team_comparable_value(COLOR_TEAM2);
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
		AuditTeams(FALSE);
	}
	if (autoswap_last_time + g_balance_teams_autoswap_interval >= time)
		return;

	if not(g_balance_teams_autoswap)
		return;

	teams_check_allowed(world);
	GetTeamCounts(world);
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
			Team_AutoSwap_BestWithWorst(COLOR_TEAM2, COLOR_TEAM1);
		} else if (g_balance_teams_autoswap_zerolead && t2 == 0 && t1 >= g_balance_teams_autoswap_zerolead) {
			Team_AutoSwap_BestWithWorst(COLOR_TEAM1, COLOR_TEAM2);
		} else if (g_balance_teams_autoswap_lead && t1 - t2 >= g_balance_teams_autoswap_lead) {
			Team_AutoSwap_BestWithWorst(COLOR_TEAM1, COLOR_TEAM2);
		} else if (g_balance_teams_autoswap_lead && t2 - t1 >= g_balance_teams_autoswap_lead) {
			Team_AutoSwap_BestWithWorst(COLOR_TEAM2, COLOR_TEAM1);
		}
	}
}

float(entity a, entity b) teams_is_different {
	if(teamplay) {
		if(a.team == b.team)
			return 0;
	} else {
		if(a == b)
			return 0;
	}
	return 1;
}

void(float t) teams_spawn_team {
	entity e, oldself;
	FOR_EACH_CLIENT(e)
		if (e.team == t)
		if (e.classname != "player") {
			e.classname = "player";
			oldself = self;
			self = e;
			PutClientInServer();
			self = oldself;
		}
}
