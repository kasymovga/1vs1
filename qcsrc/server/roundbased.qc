float rb_team_check;
float rb_need_check_teams;
float rb_winner_team;
float rb_countdown_last;
float rb_have_death_players;
float rb_team_alive;
float rb_enddelay;
float rb_startdelay;
float rb_after_warmup;
float rb_score_field;
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
	Roundbased_Active = 0;
	Roundbased_RestartTime = time + rb_enddelay;
	round_warmup = Roundbased_RestartTime + rb_startdelay;
}

void Roundbased_SetRoundStartWithWinner(float winner) {
	rb_winner_team = winner;
	Roundbased_Active = 0;
	Roundbased_RestartTime = time + rb_enddelay;
	round_warmup = Roundbased_RestartTime + rb_startdelay;
}

var void() Roundbased_ServerFrame_NextLink;
void Roundbased_ServerFrame()
{
	Roundbased_ServerFrame_NextLink();
	if (map_finished)
		return;

	if (warmup_active)
		return;

	if (time < map_starttime)
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
		GameStatus_Set("^2Awaiting players...\n", 1);
		Roundbased_SetRoundStartWithWinner(0);
		rb_need_check_teams = 0;
		return;
	}
	if not(Roundbased_Active)
	{
		if (rb_after_warmup) {
			Roundbased_RestartTime = 0;
			round_warmup = map_starttime + rb_startdelay;
			rb_after_warmup = FALSE;
		}
		if (Roundbased_RestartTime)
		if (time >= Roundbased_RestartTime) {
			world_reset(FALSE);
			Roundbased_RestartTime = 0;
			oldself = self;
			FOR_EACH_TEAMPLAYER(plr) {
				self = plr;
				self.classname = "player";
				client_put();
			}
			self = oldself;
		}
		if (time >= round_warmup)
		{
			rb_countdown_last = 0;
			Roundbased_Active = 1;
			sound_play2all("announcer/robotic/begin.wav");
			GameStatus_Set("^2New round started\n", 3);
		}
		else
		{
			string winner_message;
			if (rb_winner_team > 0)
				winner_message = strcat("^2Round finished!\n", team_color_code(rb_winner_team), team_color_name(rb_winner_team), " Team^2 wins!\n");
			else if (rb_winner_team < 0)
				winner_message = "^1Round aborted!\n";
			else
				winner_message = "";
			float countdown = ceil(round_warmup - time);
			if (rb_countdown_last != countdown)
			{
				if (countdown <= 3)
					sound_play2all(strcat("announcer/robotic/", ftos(countdown), ".wav"));

				GameStatus_Set(strcat(winner_message, "^2Starting in ", ftos(countdown), "\n"), 3);
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
		score_team_add_to(rb_team_alive, rb_score_field, 1);
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

		sound_play2all(announce_sound);
		FOR_EACH_CLIENT(plr) {
			if (plr.classname == "player")
			if (plr.deadflag == DEAD_NO) {
				bprint(plr.netname, " - ^1H:", ftos(floor(plr.health)), "^0|^2A:", ftos(floor(plr.armorvalue)), "\n");
			}
		}
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
		gamehook_chain_damage_mod = 0;
		if (targ != attacker) {
			gamehook_chain_damage_mod_force = 0;
			return; //No sense in other chain links
		}
	}
	Roundbased_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

void Roundbased_SetScoreField(float sf) {
	rb_score_field = sf;
}

var float(string cmd, float tokens) Roundbased_cmd_game_handle_NextLink;
float Roundbased_cmd_game_handle(string cmd, float tokens) {
	if (cmd == "endround") {
		if (Roundbased_Active)
			Roundbased_SetRoundStartWithWinner(-1);

		return TRUE;
	}
	return Roundbased_cmd_game_handle_NextLink(cmd, tokens);
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
	rb_score_field = ST_SCORE;
	rb_enddelay = enddelay;
	rb_startdelay = startdelay;
	Roundbased_RestartTime = 0;
	if (warmup_active)
		rb_after_warmup = TRUE;
	else
		round_warmup = map_starttime + rb_startdelay;

	Roundbased_PlayerCanFire_NextLink = gamehook_chain_PlayerCanFire;
	gamehook_chain_PlayerCanFire = Roundbased_PlayerCanFire;
	Roundbased_DamageForceModsSet_NextLink = gamehook_chain_damage_mods_set;
	gamehook_chain_damage_mods_set = Roundbased_DamageForceModsSet;
	Roundbased_ServerFrame_NextLink = gamehook_chain_world_frame_start;
	gamehook_chain_world_frame_start = Roundbased_ServerFrame;
	Roundbased_cmd_game_handle_NextLink = gamehook_chain_cmd_game_handle;
	gamehook_chain_cmd_game_handle = Roundbased_cmd_game_handle;
}
