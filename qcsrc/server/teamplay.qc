float g_balance_teams;
float g_balance_teams_force;
float g_balance_teams_prevent_imbalance;
float g_balance_teams_autoswap;
float g_balance_teams_autoswap_zerolead;
float g_balance_teams_autoswap_lead;
float g_changeteam_banned;
float bot_vs_human;

string cache_mutatormsg;
string cache_lastmutatormsg;

void ChangeTeam(entity pl, float dteam);
void AuditTeams(float force);

// client counts for each team
float c1, c2, c3, c4;
// # of bots on those teams
float cb1, cb2, cb3, cb4;

void Balance_Centerprint(entity e) {
	centerprint(e, strcat("You have been moved into a different team to improve team balance\nYou are now on: ", ColoredTeamName(e.team)));
}

void TeamchangeFrags(entity e)
{
	PlayerScore_Clear(e);
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

void dom_init();
void ctf_init();
void onslaught_init();
void runematch_init();
void tdm_init();
void nb_init();
void entcs_init();

void WriteGameCvars()
{
	cvar_set("_g_dm", ftos(g_dm));
	cvar_set("_g_tdm", ftos(g_tdm));
	cvar_set("_g_domination", ftos(g_domination));
	cvar_set("_g_ctf", ftos(g_ctf));
	cvar_set("_g_runematch", ftos(g_runematch));
	cvar_set("_g_conquest", ftos(g_conquest));
	cvar_set("_g_keyhunt", ftos(g_keyhunt));
	cvar_set("_g_assault", ftos(g_assault));
	cvar_set("_g_onslaught", ftos(g_onslaught));
	cvar_set("_g_race", ftos(g_race));
	cvar_set("_g_nexball", ftos(g_nexball));
	cvar_set("_g_cts", ftos(g_cts));
	cvar_set("_g_freeze", ftos(g_freeze));
	cvar_set("_g_clanarena", ftos(g_clanarena));
	cvar_set("_g_survive", ftos(g_survive));
}

void ReadGameCvars()
{
	float found;
	float prev;
	float i;

	found = 0;
	prev = cvar("gamecfg");
	for(i = 0; i < 2; ++i)
	{
		found += (g_dm = (!found && (prev != GAME_DEATHMATCH) && cvar("_g_dm")));
		found += (g_tdm = (!found && (prev != GAME_TEAM_DEATHMATCH) && cvar("_g_tdm")));
		found += (g_domination = (!found && (prev != GAME_DOMINATION) && cvar("_g_domination")));
		found += (g_ctf = (!found && (prev != GAME_CTF) && cvar("_g_ctf")));
		found += (g_runematch = (!found && (prev != GAME_RUNEMATCH) && cvar("_g_runematch")));
		found += (g_conquest = (!found && (prev != GAME_CONQUEST) && cvar("_g_conquest")));
		found += (g_keyhunt = (!found && (prev != GAME_KEYHUNT) && cvar("_g_keyhunt")));
		found += (g_assault = (!found && (prev != GAME_ASSAULT) && cvar("_g_assault")));
		found += (g_onslaught = (!found && (prev != GAME_ONSLAUGHT) && cvar("_g_onslaught")));
		found += (g_race = (!found && (prev != GAME_RACE) && cvar("_g_race")));
		found += (g_nexball = (!found && (prev != GAME_NEXBALL) && cvar("_g_nexball")));
		found += (g_cts = (!found && (prev != GAME_CTS) && cvar("_g_cts")));
		found += (g_freeze = (!found && (prev != GAME_FREEZETAG) && cvar("_g_freeze")));
		found += (g_clanarena = (!found && (prev != GAME_CLANARENA) && cvar("_g_clanarena")));
		found += (g_survive = (!found && (prev != GAME_SURVIVE) && cvar("_g_survive")));

		if(found)
			break;

		prev = -1; // second attempt takes place WITHOUT prev set
	}

	if(!found)
		g_dm = 1;

	if(g_dm && cvar("deathmatch_force_teamplay"))
	{
		g_dm = 0;
		g_tdm = 1;
	}

	teamplay = 0;
}

void default_delayedinit()
{
	if(!scores_preinitialized)
		ScoreRules_generic();

	ScoreDamage_Init();
	Damage_RecordInit();
	ScoreRules_basics_end();
}

void ActivateTeamplay()
{
	teamplay = TRUE;
	cvar_set("teamplay", ftos(teamplay));
}

float tdm_FragLimitOverride() {
	return cvar("g_tdm_fraglimit");
}

void InitGameplayMode()
{
	float fraglimit_override, timelimit_override, leadlimit_override;

	VoteReset();

	cvar_set("teamplay", "0");

	// make sure only ONE type is selected
	ReadGameCvars();
	WriteGameCvars();

	// find out good world mins/maxs bounds, either the static bounds found by looking for solid, or the mapinfo specified bounds
	get_mi_min_max(1);
	world.mins = mi_min;
	world.maxs = mi_max;

	cvar_set("timelimit", cvar_string("timelimit_default"));
	cvar_set("fraglimit", cvar_string("fraglimit_default"));
	MapInfo_LoadMapSettings(mapname);
	float force_gametype_restore = 0;
	string force_gametype = cvar_string("force_gametype");
	if (force_gametype != "")
	{
		force_gametype_restore = MapInfo_CurrentGametype();
		MapInfo_SwitchGameType(MapInfo_Type_FromString(force_gametype));
	}

	if not(cvar_value_issafe(world.fog))
	{
		print("The current map contains a potentially harmful fog setting, ignored\n");
		world.fog = string_null;
	}
	if(MapInfo_Map_fog != "")
		if(MapInfo_Map_fog == "none")
			world.fog = string_null;
		else
			world.fog = strzone(MapInfo_Map_fog);
	clientstuff = strzone(MapInfo_Map_clientstuff);

	MapInfo_ClearTemps();

	// in case mapinfo switched the type
	ReadGameCvars();

	gamemode_name = MapInfo_HumanString_FromType(MapInfo_CurrentGametype());
	if(g_dm)
	{
		game = GAME_DEATHMATCH;
	}

	if(g_tdm)
	{
		game = GAME_TEAM_DEATHMATCH;
		ActivateTeamplay();
		GameHook_FragLimitOverride = tdm_FragLimitOverride;
		tdm_init();
	}

	if(g_freeze)
	{
		game = GAME_FREEZETAG;
		ActivateTeamplay();
		tdm_init();
		Freeze_Init();
	}

	if(g_clanarena)
	{
		game = GAME_CLANARENA;
		ActivateTeamplay();
		tdm_init();
		Clanarena_Init();
	}

	if(g_domination)
	{
		game = GAME_DOMINATION;
		ActivateTeamplay();
		dom_init();
	}

	if(g_ctf)
	{
		game = GAME_CTF;
		ActivateTeamplay();
		ctf_init();
	}

	if(g_runematch)
	{
		game = GAME_RUNEMATCH;
		if(cvar("deathmatch_force_teamplay"))
			ActivateTeamplay();

		runematch_init();
	}

	if(g_keyhunt)
	{
		game = GAME_KEYHUNT;
		ActivateTeamplay();
		kh_init();
	}

	if(g_assault)
	{
		game = GAME_ASSAULT;
		assault_init();
		ActivateTeamplay();
	}

	if(g_onslaught)
	{
		game = GAME_ONSLAUGHT;
		ActivateTeamplay();
		onslaught_init();
	}

	if(g_cts)
		game = GAME_CTS;

	if(g_race)
		game = GAME_RACE;

	if(g_race || g_cts)
		race_init();


	if(g_nexball)
	{
		game = GAME_NEXBALL;
		ActivateTeamplay();
		nb_init();
	}

	if (g_conquest)
	{
		game = GAME_CONQUEST;
		ActivateTeamplay();
		conquest_init();
	}

	if (g_survive)
	{
		game = GAME_SURVIVE;
		ActivateTeamplay();
		survive_init();
	}

	if(teamplay)
		entcs_init();

	// save it (for the next startup)
	cvar_set("gamecfg", ftos(game));

	cache_mutatormsg = strzone("");
	cache_lastmutatormsg = strzone("");

	// enforce the server's universal frag/time limits
	if(!g_campaign)
	{
		timelimit_override = GameHook_TimeLimitOverride();
		fraglimit_override = GameHook_FragLimitOverride();
		leadlimit_override = GameHook_LeadLimitOverride();
		if(fraglimit_override >= 0)
			cvar_set("fraglimit", ftos(fraglimit_override));
		if(timelimit_override >= 0)
			cvar_set("timelimit", ftos(timelimit_override));
		if(leadlimit_override >= 0)
			cvar_set("leadlimit", ftos(leadlimit_override));
	}

	InitializeEntity(world, default_delayedinit, INITPRIO_GAMETYPE_FALLBACK);

	if (force_gametype_restore)
		MapInfo_SwitchGameType(force_gametype_restore);

	game_cvar_init(g_campaign ? "campaign" : cvar_string("g_profile"));
}

void PrintWelcomeMessage(entity pl)
{
	string s, modifications, motd;

	if(self.cvar_scr_centertime == 0) return;

	if(g_campaign)
	{
		if(self.classname == "player" && !self.BUTTON_INFO)
			return;
	}
	else
	{
		if((time - self.jointime) > cvar("welcome_message_time") && !self.BUTTON_INFO)
			return;
	}

	if( !(timeoutStatus >= 1) ) { //really print the WelcomeMessage to the player every frame when timeout-seconds are shown or the game is restarted, to make sure that the shown number is accurate
		if(self.welcomemessage_time > time) return;
		self.welcomemessage_time = time + max(0.5, self.cvar_scr_centertime * 0.6);
	}

	if(g_campaign)
	{
		centerprint(pl, campaign_message);
		return;
	}

//TODO GreEn`mArine: make the timeout-messages clientside as well (just like the ready restart countdown)!
	if(!self.BUTTON_INFO)
	{
		// TODO get rid of this too
		local string specString;
		specString = NEWLINES;
		//if(time < game_starttime) //also show the countdown when being a spectator
		//	specString = strcat(specString, "\n\n^1Game starts in ", ftos(ceil(game_starttime - time)), " seconds^7");
		//else
		if (timeoutStatus != 0)
			specString = strcat(specString, "\n\n", getTimeoutText(1));
		else
		{
			if(self.classname == "player")
				return;
			goto normal;
		}
		return centerprint_atprio(self, CENTERPRIO_SPAM, specString);
	}

:normal
	modifications = GameHookChain_WelcomeMessageMod("");
	if(cvar("sv_gravity") < 800)
		modifications = strcat(modifications, ", Low gravity");
	if(g_footsteps)
		modifications = strcat(modifications, ", Steps");
	if(g_grappling_hook)
		modifications = strcat(modifications, ", Hook");
	if(g_pinata)
		modifications = strcat(modifications, ", Pinata");
	if(g_weapon_stay)
		modifications = strcat(modifications, ", Weapons stay");
	if(g_jetpack)
		modifications = strcat(modifications, ", Jet pack");
	modifications = substring(modifications, 2, strlen(modifications) - 2);

	s = strcat(s, NEWLINES, "This is Rexuiz ", cvar_string("g_nexuizversion"), "\n");
	s = strcat(s, "^8\n\nmatch type is ^1", gamemode_name, "^8\n");

	if(modifications != "")
		s = strcat(s, "^8\nactive modifications: ^3", modifications, "^8\n");

	if(timeoutStatus != 0)
		s = strcat(s, "\n\n", getTimeoutText(1));

	if (g_grappling_hook)
		s = strcat(s, "\n\n^3grappling hook^8 is enabled, press 'e' to use it\n");

	if(cache_lastmutatormsg != cvar_string("g_mutatormsg"))
	{
		if(cache_lastmutatormsg)
			strunzone(cache_lastmutatormsg);
		if(cache_mutatormsg)
			strunzone(cache_mutatormsg);
		cache_lastmutatormsg = strzone(cvar_string("g_mutatormsg"));
		cache_mutatormsg = strzone(cache_lastmutatormsg);
	}

	if (cache_mutatormsg != "") {
		s = strcat(s, "\n\n^8special gameplay tips: ^7", cache_mutatormsg);
	}

	motd = cvar_string("sv_motd");
	if (motd != "") {
		s = strcat(s, "\n\n^8MOTD: ^7", strreplace("\\n", "\n", motd));
	}
	s = strcat(s, "\n");

	centerprint(pl, s);
}


void SetPlayerColors(entity pl, float _color)
{
	float pants, shirt;
	pants = _color & 0x0F;
	shirt = _color & 0xF0;
	if(teamplay) {
		setcolor(pl, 16*pants + pants);
	} else {
		float t = pl.team;
		setcolor(pl, shirt + pants);
		pl.team = t;
	}
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

	SetPlayerColors(pl, pl.team - 1);

	if(!noprint && t != s)
	{
		//bprint(pl.netname, " has changed to ", TeamNoName(t), "\n");
		bprint(pl.netname, "^7 has changed from ", TeamNoName(s), " to ", TeamNoName(t), "\n");
	}
	ScoreKeeper_Touch(pl);
}

// set c1...c4 to show what teams are allowed
void CheckAllowedTeams (entity for_whom)
{
	float dm;
	entity head;
	string teament_name;

	c1 = c2 = c3 = c4 = -1;
	cb1 = cb2 = cb3 = cb4 = 0;

	if(g_onslaught)
	{
		// onslaught is special
		head = findchain(classname, "onslaught_generator");
		while (head)
		{
			if (head.team == COLOR_TEAM1) c1 = 0;
			if (head.team == COLOR_TEAM2) c2 = 0;
			if (head.team == COLOR_TEAM3) c3 = 0;
			if (head.team == COLOR_TEAM4) c4 = 0;
			head = head.chain;
		}
	}
	else if(g_domination)
		teament_name = "dom_team";
	else if(g_ctf)
		teament_name = "ctf_team";
	else if(g_tdm)
		teament_name = "tdm_team";
	else if(g_nexball)
		teament_name = "nexball_team";
	else if(g_assault)
		c1 = c2 = 0; // Assault always has 2 teams
	else
	{
		// cover anything else by treating it like tdm with no teams spawned
		if(g_keyhunt)
			dm = kh_teams;
		else if(g_race)
			dm = race_teams;
		else
			dm = 2;

		if(dm >= 4)
			c1 = c2 = c3 = c4 = 0;
		else if(dm >= 3)
			c1 = c2 = c3 = 0;
		else if (g_survive)
			c1 = 0;
		else
			c1 = c2 = 0;
	}

	// find out what teams are allowed if necessary
	if(teament_name)
	{
		head = find(world, classname, teament_name);
		while(head)
		{
			if(!(g_domination && head.netname == ""))
			{
				if(head.team == COLOR_TEAM1)
					c1 = 0;
				else if(head.team == COLOR_TEAM2)
					c2 = 0;
				else if(head.team == COLOR_TEAM3)
					c3 = 0;
				else if(head.team == COLOR_TEAM4)
					c4 = 0;
			}
			head = find(head, classname, teament_name);
		}
	}

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
}

// returns # of smallest team (1, 2, 3, 4)
// NOTE: Assumes CheckAllowedTeams has already been called!
float FindSmallestTeam(entity pl, float ignore_pl)
{
	float totalteams, smallestteam_count, smallestteam_score, team_random;
	totalteams = 0;

	// find out what teams are available
	//CheckAllowedTeams();

	// make sure there are at least 2 teams to join
	if(c1 >= 0)
		totalteams = totalteams + 1;
	if(c2 >= 0)
		totalteams = totalteams + 1;
	if(c3 >= 0)
		totalteams = totalteams + 1;
	if(c4 >= 0)
		totalteams = totalteams + 1;

	if(bot_vs_human)
		totalteams += 1;

	if(totalteams <= 1)
	{
		if(g_domination)
			error("Too few teams available for domination\n");
		else if(g_ctf)
			error("Too few teams available for ctf\n");
		else if(g_keyhunt)
			error("Too few teams available for key hunt\n");
		else if(g_survive) {}
		else
			error("Too few teams available for team deathmatch\n");
	}

	// count how many players are in each team
	if(ignore_pl)
		GetTeamCounts(pl);
	else
		GetTeamCounts(world);

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

float JoinBestTeam(entity pl, float only_return_best, float forcebestteam)
{
	float smallest, selectedteam;

	// don't join a team if we're not playing a team game
	if not(teamplay) {
		pl.team = 0;
		return 0;
	}

	// find out what teams are available
	CheckAllowedTeams(pl);

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
		if(selectedteam > 0)
		{
			if(!only_return_best)
			{
				SetPlayerTeam(pl, TeamColorSkin(selectedteam), TeamColorSkin(pl.team), FALSE);
			}
			return selectedteam;
		}
		// otherwise end up on the smallest team (handled below)
	}

	smallest = FindSmallestTeam(pl, TRUE);


	if(!only_return_best)
	{
		TeamchangeFrags(pl);
		if(smallest == 1)
		{
			SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM1), TeamColorSkin(pl.team), FALSE);
		}
		else if(smallest == 2)
		{
			SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM2), TeamColorSkin(pl.team), FALSE);
		}
		else if(smallest == 3)
		{
			SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM3), TeamColorSkin(pl.team), FALSE);
		}
		else if(smallest == 4)
		{
			SetPlayerTeam(pl, TeamColorSkin(COLOR_TEAM4), TeamColorSkin(pl.team), FALSE);
		}
		else
		{
			error("smallest team: invalid team\n");
		}
	}
	AuditTeams(FALSE);
	return smallest;
}

void SV_ChangeTeam(float _color)
{
	if(teamplay)
		return;

	SetPlayerColors(self, _color);
}

void ChangeTeam(entity pl, float dteam) {
	float dcount, scount;
	CheckAllowedTeams(pl);
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
	else if (pl.classname == "player")
		TeamchangeFrags(pl);

	entity oldself = self;
	SetPlayerTeam(pl, TeamColorSkin(dteam), TeamColorSkin(pl.team), FALSE);
	if(pl.classname == "player") {
		if(pl.deadflag == DEAD_NO) // kill player when changing teams
			Damage(pl, pl, pl, 100000, DEATH_TEAMCHANGE, pl.origin, '0 0 0');
	} else if not(teamchange) {
		self = pl;
		LeaveSpectatorMode();
		self = oldself;
	}
	entity e;
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
	FOR_EACH_CLIENT(head)
	{
		if(head.team == steam)
		{
			if(head.isbot)
			{
				if(head.totalfrags < lowest_bot_score)
				{
					lowest_bot = head;
					lowest_bot_score = head.totalfrags;
				}
			}
			else
			{
				if(head.totalfrags < lowest_player_score)
				{
					lowest_player = head;
					lowest_player_score = head.totalfrags;
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
	TeamchangeFrags(selected);
	entity oldself = self;
	self = selected;
	PlayerClear(FALSE);
	self = oldself;
	SetPlayerTeam(selected, smallestteam, source_team, FALSE);

	if(selected.deadflag == DEAD_NO)
		Damage(selected, selected, selected, 100000, DEATH_AUTOTEAMCHANGE, selected.origin, '0 0 0');

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

	CheckAllowedTeams(world);
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
					teams_note.think = Teams_Note_Think;
					teams_note.nextthink = time;
					teams_note.dmg = time + g_balance_teams_force;
				}
			}
			teams_note.cnt = team_flags;
			teams_note.SendFlags = 1;
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

// spawn some default teams if the map is not set up for tdm
void tdm_spawnteams()
{
	float numteams;

	numteams = cvar("g_tdm_teams_override");
	if(numteams < 2)
		numteams = cvar("g_tdm_teams");
	numteams = bound(2, numteams, 4);

	tdm_spawnteam("Red", COLOR_TEAM1-1);
	tdm_spawnteam("Blue", COLOR_TEAM2-1);
	if(numteams >= 3)
		tdm_spawnteam("Yellow", COLOR_TEAM3-1);
	if(numteams >= 4)
		tdm_spawnteam("Pink", COLOR_TEAM4-1);
};

void tdm_delayedinit()
{
	// if no teams are found, spawn defaults
	if (find(world, classname, "tdm_team") == world)
		tdm_spawnteams();
};

void tdm_init()
{
	InitializeEntity(world, tdm_delayedinit, INITPRIO_GAMETYPE);
};

void Teamplay_ReadCvars()
{
	CACHE_CVAR(g_balance_teams);
	CACHE_CVAR(g_balance_teams_autoswap);
	CACHE_CVAR(g_balance_teams_autoswap_zerolead);
	CACHE_CVAR(g_balance_teams_autoswap_lead);
	CACHE_CVAR(g_balance_teams_force);
	CACHE_CVAR(g_balance_teams_prevent_imbalance);
	CACHE_CVAR(g_changeteam_banned);
	CACHE_CVAR(bot_vs_human);
};

float autoswap_last_time;
void Team_AutoSwap_BestWithWorst(float from, float to) {
	entity best = world, worst = world;
	entity e;
	autoswap_last_time = time;
	FOR_EACH_PLAYER(e) {
		if (e.team == from) {
			if (best) {
				if (PlayerScore_Compare(best.scorekeeper, e.scorekeeper) < 0)
					best = e;
			} else
				best = e;
		}
	}
	FOR_EACH_PLAYER(e) {
		if (e.team == to) {
			if (worst) {
				if (PlayerScore_Compare(worst.scorekeeper, e.scorekeeper) > 0)
					worst = e;
			} else
				worst = e;
		}
	}
	if (best) {
		//print("Autoswap: ", best.netname, "\n");
		//print("Autoswap: ", worst.netname, "\n");
		if (c1 - c2 == 0 && worst) {
			PlayerToSpec(best);
			PlayerToSpec(worst);
			SetPlayerTeam(best, TeamColorSkin(to), TeamColorSkin(from), FALSE);
			SetPlayerTeam(worst, TeamColorSkin(from), TeamColorSkin(to), FALSE);
			e = self;
			self = best;
			LeaveSpectatorMode();
			self = worst;
			LeaveSpectatorMode();
			self = e;
			Balance_Centerprint(best);
			Balance_Centerprint(worst);
		} else if ((c1 < c2 && from == COLOR_TEAM2) || (c1 > c2 && from == COLOR_TEAM1)) {
			PlayerToSpec(best);
			SetPlayerTeam(best, TeamColorSkin(to), TeamColorSkin(from), FALSE);
			e = self;
			self = best;
			LeaveSpectatorMode();
			self = e;
			Balance_Centerprint(best);
			if (fabs(c1 - c2) == 1 && worst) {
				PlayerToSpec(worst);
				SetPlayerTeam(worst, TeamColorSkin(from), TeamColorSkin(to), FALSE);
				e = self;
				self = worst;
				LeaveSpectatorMode();
				self = e;
			}
		}
	}

}

void Team_AutoSwap_Check() {
	if not(g_balance_teams_autoswap)
		return;

	if (autoswap_last_time + 1 >= time)
		return;

	CheckAllowedTeams(world);
	GetTeamCounts(world);
	if (c1 >= 0)
	if (c2 >= 0)
	if (c3 < 0)
	if (c4 < 0)
	if (c1 + c2 > 2)
	{
		float t1 = TeamScore_GetCompareValue(COLOR_TEAM1);
		float t2 = TeamScore_GetCompareValue(COLOR_TEAM2);
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
