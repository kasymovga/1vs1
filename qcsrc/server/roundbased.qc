float roundbased_team_check;
float roundbased_need_check_teams;
float roundbased_winner_team;
float roundbased_countdown_last;
float roundbased_have_death_players;
float roundbased_team_alive;
float roundbased_enddelay;
float roundbased_startdelay;
float roundbased_after_warmup;
float roundbased_score_field;
float roundbased_warmup;
float roundbased_active;
float roundbased_restart_time;

var float(entity plr, float wep) roundbased_player_can_fire_next;
float(entity plr, float wep) roundbased_player_can_fire {
	if (roundbased_active)
		return roundbased_player_can_fire_next(plr, wep);

	if (wep) //Always allow shoot with laser (no damage when round not active)
	if (plr.weapon == WEP_LASER)
		return roundbased_player_can_fire_next(plr, wep);

	return FALSE;
}

void(void) roundbased_round_start {
	roundbased_active = 0;
	roundbased_restart_time = time + roundbased_enddelay;
	roundbased_warmup = roundbased_restart_time + roundbased_startdelay;
}

void(float winner) roundbased_round_start_with_winner {
	roundbased_winner_team = winner;
	roundbased_active = 0;
	roundbased_restart_time = time + roundbased_enddelay;
	roundbased_warmup = roundbased_restart_time + roundbased_startdelay;
}

var void(void) roundbased_world_frame_start_next;
void(void) roundbased_world_frame_start {
	roundbased_world_frame_start_next();
	if (map_finished)
		return;

	if (warmup_active)
		return;

	if (time < map_starttime)
		return;

	entity oldself;
	entity plr;
	if (roundbased_need_check_teams) {
		roundbased_team_check = 0;
		FOR_EACH_TEAMPLAYER(plr) {
			if not(roundbased_team_check)
				roundbased_team_check = plr.team;
			else if (plr.team != roundbased_team_check) {
				roundbased_team_check = -1;
				break;
			}
		}
	}
	if (roundbased_team_check >= 0) {
		game_status_set("^2Awaiting players...\n", 1);
		roundbased_round_start_with_winner(0);
		roundbased_need_check_teams = 0;
		return;
	}
	if not(roundbased_active) {
		if (roundbased_after_warmup) {
			roundbased_restart_time = 0;
			roundbased_warmup = map_starttime + roundbased_startdelay;
			roundbased_after_warmup = FALSE;
		}
		if (roundbased_restart_time)
		if (time >= roundbased_restart_time) {
			world_reset(FALSE);
			roundbased_restart_time = 0;
			oldself = self;
			FOR_EACH_TEAMPLAYER(plr) {
				self = plr;
				self.classname = "player";
				client_put();
			}
			self = oldself;
		}
		if (time >= roundbased_warmup) {
			roundbased_countdown_last = 0;
			roundbased_active = 1;
			sound_play2all("announcer/robotic/begin.wav");
			game_status_set("^2New round started\n", 3);
		} else {
			string winner_message;
			if (roundbased_winner_team > 0)
				winner_message = strcat("^2Round finished!\n", team_color_code(roundbased_winner_team), team_color_name(roundbased_winner_team), " Team^2 wins!\n");
			else if (roundbased_winner_team < 0)
				winner_message = "^1Round aborted!\n";
			else
				winner_message = "";

			float countdown = ceil(roundbased_warmup - time);
			if (roundbased_countdown_last != countdown) {
				if (countdown <= 3)
					sound_play2all(strcat("announcer/robotic/", ftos(countdown), ".wav"));

				game_status_set(strcat(winner_message, "^2Starting in ", ftos(countdown), "\n"), 3);
				roundbased_countdown_last = countdown;
			}
		}
		return;
	}
	if (roundbased_need_check_teams) {
		roundbased_team_alive = 0;
		roundbased_have_death_players = 0;
		FOR_EACH_TEAMPLAYER(plr) {
			if (plr.classname != "player" || plr.deadflag != DEAD_NO) {
				roundbased_have_death_players = 1;
				continue;
			}
			if (roundbased_team_alive > 0) {
				if (plr.team != roundbased_team_alive) {
					roundbased_team_alive = -1;
					break;
				}
			} else if not(roundbased_team_alive) {
				roundbased_team_alive = plr.team;
			}
		}
		roundbased_need_check_teams = 0;
	}
	if (roundbased_team_alive > 0 && roundbased_have_death_players)
		score_team_add_to(roundbased_team_alive, roundbased_score_field, 1);
	else if (roundbased_team_alive < 0)
		return;

	if (roundbased_have_death_players) {
		roundbased_winner_team = roundbased_team_alive;
		string announce_sound = ((roundbased_winner_team == COLOR_TEAM1) ?
				"ctf/red_capture.wav" :
				((roundbased_winner_team == COLOR_TEAM2) ?
				"ctf/blue_capture.wav" :
				"domination/claim.wav"));
		sound_play2all(announce_sound);
		FOR_EACH_CLIENT(plr) {
			if (plr.classname == "player")
			if (plr.deadflag == DEAD_NO) {
				bprint(plr.netname, " - ^1H:", ftos(floor(plr.health)), "^0|^2A:", ftos(floor(plr.armorvalue)), "\n");
			}
		}
		roundbased_round_start();
	}
}

void(void) roundbased_check_teams {
	roundbased_need_check_teams = TRUE;
}

var void(entity targ, entity attacker, float deathtype) roundbased_damage_mods_set_next;
void(entity targ, entity attacker, float deathtype) roundbased_damage_mods_set {
	if not(roundbased_active)
	if (DEATH_ISWEAPON(deathtype, WEP_LASER)) {
		plugin_chain_damage_mod = 0;
		if (targ != attacker) {
			plugin_chain_damage_mod_force = 0;
			return; //No sense in other chain links
		}
	}
	roundbased_damage_mods_set_next(targ, attacker, deathtype);
}

void(float sf) roundbased_score_field_set {
	roundbased_score_field = sf;
}

var float(string cmd, float tokens) Roundbased_cmd_game_handle_NextLink;
float(string cmd, float tokens) Roundbased_cmd_game_handle {
	if (cmd == "endround") {
		if (roundbased_active)
			roundbased_round_start_with_winner(-1);

		return TRUE;
	}
	return Roundbased_cmd_game_handle_NextLink(cmd, tokens);
}

void(float enddelay, float startdelay) roundbased_init {
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	precache_sound("ctf/blue_capture.wav");
	precache_sound("ctf/red_capture.wav");
	roundbased_need_check_teams = TRUE;
	roundbased_score_field = ST_SCORE;
	roundbased_enddelay = enddelay;
	roundbased_startdelay = startdelay;
	roundbased_restart_time = 0;
	if (warmup_active)
		roundbased_after_warmup = TRUE;
	else
		roundbased_warmup = map_starttime + roundbased_startdelay;

	roundbased_player_can_fire_next = plugin_chain_player_can_fire;
	plugin_chain_player_can_fire = roundbased_player_can_fire;
	roundbased_damage_mods_set_next = plugin_chain_damage_mods_set;
	plugin_chain_damage_mods_set = roundbased_damage_mods_set;
	roundbased_world_frame_start_next = plugin_chain_world_frame_start;
	plugin_chain_world_frame_start = roundbased_world_frame_start;
	Roundbased_cmd_game_handle_NextLink = plugin_chain_cmd_game_handle;
	plugin_chain_cmd_game_handle = Roundbased_cmd_game_handle;
}
