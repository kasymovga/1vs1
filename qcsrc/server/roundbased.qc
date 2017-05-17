float rb_team_check;
float rb_need_check_teams;
float rb_winner_team;
float rb_countdown_last;
float rb_have_death_players;
float rb_team_alive;
float rb_enddelay;
float rb_startdelay;
float rb_after_warmup;
float round_warmup;

float Roundbased_Active;
float Roundbased_RestartTime;

var float(entity plr, float wep) Roundbased_PlayerCanFire_NextLink;
float Roundbased_PlayerCanFire(entity plr, float wep) {
	if (Roundbased_Active)
		return Roundbased_PlayerCanFire_NextLink(plr, wep);

	if (wep) //Always allow shoot with laser (no damage when round not active)
	if (plr.weapon == WEP_LASER)
		return Roundbased_PlayerCanFire_NextLink(plr, wep);

	return FALSE;
}

void Roundbased_SetRoundStart() {
	Roundbased_RestartTime = time + rb_enddelay;
	round_warmup = Roundbased_RestartTime + rb_startdelay;
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
			Roundbased_RestartTime = 0;
			round_warmup = game_starttime + rb_startdelay;
			rb_after_warmup = FALSE;
		}
		if (Roundbased_RestartTime)
		if (time >= Roundbased_RestartTime) {
			reset_map(FALSE);
			Roundbased_RestartTime = 0;
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
				winner_message = strcat("^2Round finished!\n", Team_ColorCode(rb_winner_team), Team_ColorName(rb_winner_team), " Team^2 wins!\n");
			else
				winner_message = "";
			float countdown = ceil(round_warmup - time);
			if (rb_countdown_last != countdown)
			{
				FOR_EACH_REALCLIENT(plr)
				{
					centerprint(plr, strcat(winner_message, "^2Starting in ", ftos(countdown), "\n"));
					if (countdown <= 3)
						announce(plr, strcat("announcer/robotic/", ftos(countdown), ".wav"));
				}
				rb_countdown_last = countdown;
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
		rb_winner_team = rb_team_alive;
		string announce_sound = ((rb_winner_team == COLOR_TEAM1) ?
				"ctf/red_capture.wav" :
				((rb_winner_team == COLOR_TEAM2) ?
						"ctf/blue_capture.wav" :
						"domination/claim.wav"));

		FOR_EACH_REALCLIENT(plr)
			announce_force(plr, announce_sound);

		Roundbased_Active = 0;
		Roundbased_SetRoundStart();
	}
}

void Roundbased_NeedCheckTeams() {
	rb_need_check_teams = TRUE;
}

var void(entity targ, entity attacker, float deathtype) Roundbased_DamageForceModsSet_NextLink;
void Roundbased_DamageForceModsSet(entity targ, entity attacker, float deathtype) {
	if not(Roundbased_Active)
	if (DEATH_ISWEAPON(deathtype, WEP_LASER)) {
		GameHook_DamageMod = 0;
		if (targ != attacker) {
			GameHook_ForceMod = 0;
			return; //No sense in other chain links
		}
	}
	Roundbased_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

void Roundbased_Init(float enddelay, float startdelay) {
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	precache_sound("ctf/blue_capture.wav");
	precache_sound("ctf/red_capture.wav");
	Roundbased_NeedCheckTeams();
	rb_enddelay = enddelay;
	rb_startdelay = startdelay;
	Roundbased_RestartTime = 0;
	if (inWarmupStage)
		rb_after_warmup = TRUE;
	else
		round_warmup = game_starttime + rb_startdelay;

	Roundbased_PlayerCanFire_NextLink = GameHookChain_PlayerCanFire;
	GameHookChain_PlayerCanFire = Roundbased_PlayerCanFire;
	Roundbased_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = Roundbased_DamageForceModsSet;
}
