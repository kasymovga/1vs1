float rb_team_check;
float rb_respawn_all;
float rb_need_check_teams;
float rb_winner_team;
float rb_countdown_last;
float rb_have_death_players;
float rb_team_alive;
float rb_enddelay;
float rb_startdelay;
float rb_after_warmup;

float Roundbased_Active;

void Roundbased_SetRoundStart() {
	rb_respawn_all = time + rb_enddelay;
	round_warmup = rb_respawn_all + rb_startdelay;
}

void Roundbased_TeamArenaThink()
{
	if (gameover)
		return;

	if (inWarmupStage)
		return;

	if (time < game_starttime)
		return;

	entity oldself;
	entity plr;
	if (rb_need_check_teams) {
		rb_team_check = 0;
		FOR_EACH_TEAMPLAYER(plr) {
			if not(rb_team_check)
				rb_team_check = plr.team;
			else if (plr.team != rb_team_check) {
				rb_team_check = -1;
				break;
			}
		}
	}
	if (rb_team_check >= 0) {
		FOR_EACH_REALCLIENT(plr)
			centerprint(plr, "^2Awaiting players...\n");

		Roundbased_Active = 0;
		Roundbased_SetRoundStart();
		rb_need_check_teams = 0;
		return;
	}
	if not(Roundbased_Active)
	{
		if (rb_after_warmup) {
			rb_respawn_all = 0;
			if (cvar("sv_ready_restart_after_countdown"))
				round_warmup = game_starttime + rb_startdelay;
			else
				round_warmup = game_starttime;

			rb_after_warmup = FALSE;
		}
		if (rb_respawn_all)
		if (time >= rb_respawn_all) {
			reset_map(FALSE);
			rb_respawn_all = 0;
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
			rb_countdown_last = 0;
			Roundbased_Active = 1;
			FOR_EACH_REALCLIENT(plr) {
				centerprint(plr, "^2New round started\n");
				announce(plr, "announcer/robotic/begin.wav");
			}
		}
		else
		{
			string winner_message;
			if (rb_winner_team > 0)
				winner_message = strcat("^2Round finished!\n^2", Team_ColorName(rb_winner_team), " Team wins!\n");
			else
				winner_message = "";
			float countdown = ceil(round_warmup - time);
			FOR_EACH_REALCLIENT(plr)
			{
				if (rb_countdown_last != countdown)
				{
					centerprint(plr, strcat(winner_message, "^2Starting in ", ftos(countdown), "\n"));
					rb_countdown_last = countdown;

					if (countdown <= 3)
						FOR_EACH_REALCLIENT(plr)
							announce(plr, strcat("announcer/robotic/", ftos(countdown), ".wav"));
				}
			}
		}
		return;
	}

	if (rb_need_check_teams) {
		rb_team_alive = 0;
		rb_have_death_players = 0;
		FOR_EACH_TEAMPLAYER(plr)
		{
			if (plr.classname != "player" || plr.deadflag != DEAD_NO)
			{
				rb_have_death_players = 1;
				continue;
			}
			if (rb_team_alive > 0) {
				if (plr.team != rb_team_alive)
				{
					rb_team_alive = -1;
					break;
				}
			}
			else if not(rb_team_alive)
			{
				rb_team_alive = plr.team;
			}
		}
		rb_need_check_teams = 0;
	}
	if (rb_team_alive > 0 && rb_have_death_players)
		TeamScore_AddToTeam(rb_team_alive, ST_SCORE, 1);
	else if (rb_team_alive < 0)
		return;

	if (rb_have_death_players)
	{
		FOR_EACH_REALPLAYER(plr)
			announce(plr, "domination/claim.wav");

		rb_winner_team = rb_team_alive;
		Roundbased_Active = 0;
		Roundbased_SetRoundStart();
	}
}

void Roundbased_NeedCheckTeams() {
	rb_need_check_teams = TRUE;
}

void Roundbased_Init(float enddelay, float startdelay) {
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	Roundbased_NeedCheckTeams();
	rb_enddelay = enddelay;
	rb_startdelay = startdelay;
	rb_respawn_all = 0;
	if (inWarmupStage)
		rb_after_warmup = TRUE;
	else
		round_warmup = time + rb_startdelay;
}
