float g_balance_teams;
float g_balance_teams_force;
float g_balance_teams_prevent_imbalance;
float g_changeteam_banned;
float bot_vs_human;

string cache_mutatormsg;
string cache_lastmutatormsg;

void ChangeTeam(entity pl, float dteam);

// client counts for each team
float c1, c2, c3, c4;
// # of bots on those teams
float cb1, cb2, cb3, cb4;

float audit_teams_time;

float IsTeamBalanceForced()
{
	if(intermission_running)
		return 0; // no rebalancing whatsoever please
	if(!teamplay)
		return 0;
	if(g_campaign)
		return 0;
	if(!g_balance_teams_force)
		return -1;
	return 1;
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

void LogTeamchange(entity pl)
{
	string str;
	if(!sv_eventlog)
		return;
	if(pl.playerid < 1)
		return;
	str = strcat(":team:", ftos(pl.playerid), ":");
	str = strcat(str, ftos(pl.team));
	GameLogEcho(str);
}

void WriteGameCvars()
{
	cvar_set("g_dm", ftos(g_dm));
	cvar_set("g_tdm", ftos(g_tdm));
	cvar_set("g_domination", ftos(g_domination));
	cvar_set("g_ctf", ftos(g_ctf));
	cvar_set("g_runematch", ftos(g_runematch));
	cvar_set("g_conquest", ftos(g_conquest));
	cvar_set("g_keyhunt", ftos(g_keyhunt));
	cvar_set("g_assault", ftos(g_assault));
	cvar_set("g_onslaught", ftos(g_onslaught));
	cvar_set("g_race", ftos(g_race));
	cvar_set("g_nexball", ftos(g_nexball));
	cvar_set("g_cts", ftos(g_cts));
	cvar_set("g_freeze", ftos(g_freeze));
	cvar_set("g_clanarena", ftos(g_clanarena));
	cvar_set("g_survive", ftos(g_survive));
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
		found += (g_dm = (!found && (prev != GAME_DEATHMATCH) && cvar("g_dm")));
		found += (g_tdm = (!found && (prev != GAME_TEAM_DEATHMATCH) && cvar("g_tdm")));
		found += (g_domination = (!found && (prev != GAME_DOMINATION) && cvar("g_domination")));
		found += (g_ctf = (!found && (prev != GAME_CTF) && cvar("g_ctf")));
		found += (g_runematch = (!found && (prev != GAME_RUNEMATCH) && cvar("g_runematch")));
		found += (g_conquest = (!found && (prev != GAME_CONQUEST) && cvar("g_conquest")));
		found += (g_keyhunt = (!found && (prev != GAME_KEYHUNT) && cvar("g_keyhunt")));
		found += (g_assault = (!found && (prev != GAME_ASSAULT) && cvar("g_assault")));
		found += (g_onslaught = (!found && (prev != GAME_ONSLAUGHT) && cvar("g_onslaught")));
		found += (g_race = (!found && (prev != GAME_RACE) && cvar("g_race")));
		found += (g_nexball = (!found && (prev != GAME_NEXBALL) && cvar("g_nexball")));
		found += (g_cts = (!found && (prev != GAME_CTS) && cvar("g_cts")));
		found += (g_freeze = (!found && (prev != GAME_FREEZETAG) && cvar("g_freeze")));
		found += (g_clanarena = (!found && (prev != GAME_CLANARENA) && cvar("g_clanarena")));
		found += (g_survive = (!found && (prev != GAME_SURVIVE) && cvar("g_survive")));

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
	if(!scores_initialized)
		ScoreRules_generic();
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

	game_cvar_init();
}

string GetClientVersionMessage() {
	local string versionmsg;
	if (self.version_mismatch) {
		if(self.version < cvar("gameversion")) {
			versionmsg = "^3Your client version is outdated.\n\n\n### YOU WON'T BE ABLE TO PLAY ON THIS SERVER ###\n\n\nPlease update!!!^8";
		} else {
			versionmsg = "^3This server is using an outdated Rexuiz version.\n\n\n ### THIS SERVER IS INCOMPATIBLE AND THUS YOU CANNOT JOIN ###.^8";
		}
	} else {
		versionmsg = "^2client version and server version are compatible.^8";
	}
	return versionmsg;
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

	local string versionmessage;
	versionmessage = GetClientVersionMessage();

	s = strcat(s, NEWLINES, "This is Rexuiz ", cvar_string("g_nexuizversion"), "\n", versionmessage);
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
	/*string s;
	s = ftos(cl);
	stuffcmd(pl, strcat("color ", s, " ", s, "\n")  );
	pl.team = cl + 1;
	//pl.clientcolors = pl.clientcolors - (pl.clientcolors & 15) + cl;
	pl.clientcolors = 16*cl + cl;*/

	float pants, shirt;
	pants = _color & 0x0F;
	shirt = _color & 0xF0;


	if(teamplay) {
		setcolor(pl, 16*pants + pants);
	} else {
		setcolor(pl, shirt + pants);
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

	if(t != s)
		LogTeamchange(pl);
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

float PlayerValue(entity p)
{
	if(IsTeamBalanceForced() == 1)
		return 1;
	return 1;
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
			value = PlayerValue(head);
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
	float totalteams, smallestteam, smallestteam_count, smallestteam_score, balance_type;
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

	smallestteam = 0;
	smallestteam_count = 999999999;
	smallestteam_score = 999999999;

	// 2 gives priority to what team you're already on, 1 goes in order
	// 2 doesn't seem to work though...
	balance_type = 1;

	if(bots_would_leave)
	//if(pl.classname != "player")
	if(clienttype(pl) != CLIENTTYPE_BOT)
	{
		c1 -= cb1 * 255.0/256;
		c2 -= cb2 * 255.0/256;
		c3 -= cb3 * 255.0/256;
		c4 -= cb4 * 255.0/256;
	}

	if(balance_type == 1)
	{
		if(c1 >= 0 && (c1 < smallestteam_count || (c1 <= smallestteam_count && team1_score < smallestteam_score)))
		{
			smallestteam = 1;
			smallestteam_count = c1;
			smallestteam_score = team1_score;
		}
		if(c2 >= 0 && (c2 < smallestteam_count || (c2 <= smallestteam_count && team2_score < smallestteam_score)))
		{
			smallestteam = 2;
			smallestteam_count = c2;
			smallestteam_score = team2_score;
		}
		if(c3 >= 0 && (c3 < smallestteam_count || (c3 <= smallestteam_count && team3_score < smallestteam_score)))
		{
			smallestteam = 3;
			smallestteam_count = c3;
			smallestteam_score = team3_score;
		}
		if(c4 >= 0 && (c4 < smallestteam_count || (c4 <= smallestteam_count && team4_score < smallestteam_score)))
		{
			smallestteam = 4;
			smallestteam_count = c4;
			smallestteam_score = team4_score;
		}
	}
	else
	{
		if(c1 >= 0 && (c1 < smallestteam_count ||
					(c1 == smallestteam_count && self.team == COLOR_TEAM1) ) )
		{
			smallestteam = 1;
			smallestteam_count = c1;
		}
		if(c2 >= 0 && c2 < (c2 < smallestteam_count ||
					(c2 == smallestteam_count && self.team == COLOR_TEAM2) ) )
		{
			smallestteam = 2;
			smallestteam_count = c2;
		}
		if(c3 >= 0 && c3 < (c3 < smallestteam_count ||
					(c3 == smallestteam_count && self.team == COLOR_TEAM3) ) )
		{
			smallestteam = 3;
			smallestteam_count = c3;
		}
		if(c4 >= 0 && c4 < (c4 < smallestteam_count ||
					(c4 == smallestteam_count && self.team == COLOR_TEAM4) ) )
		{
			smallestteam = 4;
			smallestteam_count = c4;
		}
	}

	return smallestteam;
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
				LogTeamchange(pl);
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
		LogTeamchange(pl);
	}

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
	if (g_balance_teams_prevent_imbalance)
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
	SetPlayerTeam(selected, smallestteam, source_team, FALSE);

	if(selected.deadflag == DEAD_NO)
		Damage(selected, selected, selected, 100000, DEATH_AUTOTEAMCHANGE, selected.origin, '0 0 0');
	centerprint(selected, strcat("You have been moved into a different team to improve team balance\nYou are now on: ", ColoredTeamName(selected.team)));
}

void CauseRebalance(float source_team, float howmany_toomany)
{
	if(IsTeamBalanceForced() == 1)
	{
		bprint("Rebalancing Teams\n");
		ShufflePlayerOutOfTeam(source_team);
	}
}

// part of g_balance_teams_force
// occasionally perform an audit of the teams to make
// sure they're more or less balanced in player count.
void AuditTeams()
{
	float numplayers, numteams, smallest, toomany;
	float balance;
	balance = IsTeamBalanceForced();
	if(balance == 0)
		return;

	if(audit_teams_time > time)
		return;

	audit_teams_time = time + 4 + random();

//	bprint("Auditing teams\n");

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

	if(numplayers <= 0)
		return; // no players to move around
	if(numteams < 2)
		return; // don't bother shuffling if for some reason there aren't any teams

	toomany = smallest + 1;

	if(c1 && c1 > toomany)
		CauseRebalance(1, c1 - toomany);
	if(c2 && c2 > toomany)
		CauseRebalance(2, c2 - toomany);
	if(c3 && c3 > toomany)
		CauseRebalance(3, c3 - toomany);
	if(c4 && c4 > toomany)
		CauseRebalance(4, c4 - toomany);

	// if teams are still unbalanced, balance them further in the next audit,
	// which will happen sooner (keep doing rapid audits until things are in order)
	audit_teams_time = time + 0.7 + random()*0.3;
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
	CACHE_CVAR(g_balance_teams_force);
	CACHE_CVAR(g_balance_teams_prevent_imbalance);
	CACHE_CVAR(g_changeteam_banned);
	CACHE_CVAR(bot_vs_human);
};
