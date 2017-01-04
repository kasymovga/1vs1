entity ca_controller;
float ca_countdown_last;
float ca_active;
float ca_need_check_teams;
float ca_winner_team;
float ca_team_check;
float ca_team_alive;
float ca_have_death_players;
float ca_spawn_all;

float g_clanarena_enddelay;
float g_clanarena_startdelay;

#define FOR_EACH_TEAMPLAYER(x) FOR_EACH_CLIENT(x) if (x.team > 0)

void Clanarena_SetRoundStart() {
	ca_spawn_all = time + g_clanarena_enddelay;
	round_warmup = ca_spawn_all + g_clanarena_startdelay;
}

void Clanarena_Think()
{
	self.nextthink = time;
	if (gameover)
		return;
	if (time < game_starttime || inWarmupStage)
		return;

	entity oldself;

	entity plr;
	if (ca_need_check_teams) {
		ca_team_check = 0;
		FOR_EACH_TEAMPLAYER(plr) {
			if not(ca_team_check)
				ca_team_check = plr.team;
			else if (plr.team != ca_team_check) {
				ca_team_check = -1;
				break;
			}
		}
	}
	if (ca_team_check >= 0) {
		FOR_EACH_REALCLIENT(plr)
			centerprint(plr, "^2Awaiting players...\n");

		ca_active = 0;
		Clanarena_SetRoundStart();
		ca_need_check_teams = 0;
		return;
	}
	if not(ca_active)
	{
		if (ca_spawn_all)
		if (time >= ca_spawn_all) {
			reset_map(FALSE);
			ca_spawn_all = 0;
			oldself = self;
			FOR_EACH_TEAMPLAYER(plr) {
				self = plr;
				self.classname = "player";
				PutClientInServer();
			}
			self = oldself;
		}
		if (time >= round_warmup)
		{
			ca_countdown_last = 0;
			ca_active = 1;
			FOR_EACH_REALCLIENT(plr) {
				centerprint(plr, "^2New round started\n");
				announce(plr, "announcer/robotic/begin.wav");
			}
		}
		else
		{
			string winner_message;
			if (ca_winner_team > 0)
				winner_message = strcat("^2Round finished!\n^2", Team_ColorName(ca_winner_team), " Team wins!\n");
			else
				winner_message = "";
			float countdown = ceil(round_warmup - time);
			FOR_EACH_REALCLIENT(plr)
			{
				if (ca_countdown_last != countdown)
				{
					centerprint(plr, strcat(winner_message, "^2Restarting in ", ftos(countdown), "\n"));
					ca_countdown_last = countdown;

					if (countdown <= 3)
						FOR_EACH_REALCLIENT(plr)
							announce(plr, strcat("announcer/robotic/", ftos(countdown), ".wav"));
				}
			}
		}
		return;
	}

	if (ca_need_check_teams) {
		ca_team_alive = 0;
		ca_have_death_players = 0;
		FOR_EACH_TEAMPLAYER(plr)
		{
			if (plr.classname != "player" || plr.deadflag != DEAD_NO)
			{
				ca_have_death_players = 1;
				continue;
			}
			if (ca_team_alive > 0) {
				if (plr.team != ca_team_alive)
				{
					ca_team_alive = -1;
					break;
				}
			}
			else if not(ca_team_alive)
			{
				ca_team_alive = plr.team;
			}
		}
		ca_need_check_teams = 0;
	}
	if (ca_team_alive > 0 && ca_have_death_players)
		TeamScore_AddToTeam(ca_team_alive, ST_SCORE, 1);
	else if (ca_team_alive < 0)
		return;

	if (ca_have_death_players)
	{
		FOR_EACH_REALPLAYER(plr)
			announce(plr, "domination/claim.wav");

		ca_winner_team = ca_team_alive;
		ca_active = 0;
		Clanarena_SetRoundStart();
	}
}

void Clanarena_SpawnHook() {
	ca_need_check_teams = TRUE;
	if not(ca_active)
		return;

	PutObserverInServer(FALSE);
}

float Clanarena_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	ca_need_check_teams = TRUE;
	if not(ca_active) {
		PutClientInServer();
	}
	return FALSE;
}

float Clanarena_HandleFrags(entity attacker, entity targ, float f) {
	if (ca_active) {
		PlayerScore_Add(attacker, SP_SCORE, f);
		attacker.totalfrags += f;
	}
	return 0;
}

void Clanarena_Init()
{
	CACHE_CVAR(g_clanarena);
	if not(g_clanarena)
		return;

	CACHE_CVAR(g_clanarena_startdelay);
	CACHE_CVAR(g_clanarena_enddelay);

	GameHook_Spawn = Clanarena_SpawnHook;
	GameHook_FragsHandle = Clanarena_HandleFrags;
	GameHook_DeathHandle = Clanarena_DeathHandle;
	Clanarena_SetRoundStart();
	ca_controller = spawn();
	ca_controller.think = Clanarena_Think;
	ca_controller.nextthink = time;
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	ca_need_check_teams = 1;
}
