float jb;
float jb_open_blue;
float jb_open_red;
entity jb_controller;

entity(void) jb_client_put_spawn_point {
	if not(warmup_active)
	if ((self.team == COLOR_TEAM1 && time > jb_open_red) || (self.team == COLOR_TEAM2 && time > jb_open_blue))
	if ((roundbased_active || roundbased_restart_time)) {
		entity e;
		random_selection_init();
		for (e = NULL; (e = find(e, classname, "jb_spawn")); ) {
			if (e.team == self.team)
				random_selection_add(e, 0, "", 1, 1);
		}
		return random_selection_chosen_ent;
	}
	return spawn_select(FALSE);
}

void(void) jb_think {
	jb_controller.nextthink = time;
	if (warmup_active) return;
	entity e, jail;
	float red_free = 0, blue_free = 0;
	float red_jailed = 0, blue_jailed = 0;
	float injail;
	entity oldself = self, oldother = other;
	FOR_EACH_PLAYER(e) {
		if (e.scorekeeper.scores[SP_STATUS]) {
			injail = e.deadflag;
			if not(e.deadflag)
			if ((e.team == COLOR_TEAM1 && time > jb_open_red) ||
					(e.team == COLOR_TEAM2 && time > jb_open_blue))
				for (jail = NULL; (jail = find(jail, classname, "jb_room")); ) {
					if (math_boxes_overlap(jail.absmin, jail.absmax, e.absmin, e.absmax)) {
						oldself = self;
						oldother = other;
						self = jail;
						other = e;
						if (trigger_exact_hit()) {
							injail = TRUE;
						}
						self = oldself;
						other = oldother;
					}
				}
			if (injail) {
				if (e.team == COLOR_TEAM1) red_jailed++;
				if (e.team == COLOR_TEAM2) blue_jailed++;
			} else {
				score_player_set(e, SP_STATUS, 0);
				if (roundbased_active)
					bprint(player_name(e), "^7 escaped from jail!\n");

				if (e.team == COLOR_TEAM1) red_free++;
				if (e.team == COLOR_TEAM2) blue_free++;
			}
		} else {
			if (e.team == COLOR_TEAM1) red_free++;
			if (e.team == COLOR_TEAM2) blue_free++;
		}
	}
	if (!roundbased_active || roundbased_restart_time) return;
	self = oldself;
	other = oldother;
	if (red_jailed || blue_jailed) {
		if (red_free && !blue_free && blue_jailed) { //red wins
			score_team_add_to(COLOR_TEAM1, ST_SCORE, 1);
			sound_play2all("ctf/red_capture.wav");
			roundbased_round_start_with_winner(COLOR_TEAM1);
		} else if (!red_free && blue_free && red_jailed) { //blue wins
			score_team_add_to(COLOR_TEAM2, ST_SCORE, 1);
			sound_play2all("ctf/blue_capture.wav");
			roundbased_round_start_with_winner(COLOR_TEAM2);
		} else if (red_free && blue_free) { //Still playing
		} else { //Draw
			roundbased_round_start_with_winner(0);
		}
	}
}

void(void) jb_init {
	jb = TRUE;
	score_generic();
	SP_STATUS = score_register("status", 0);
	team_teams_set_count(2);
	roundbased_init(cvar("g_jb_enddelay"), cvar("g_jb_startdelay"));
	plugin_client_put_spawn_point = jb_client_put_spawn_point;
	plugin_score_give_frag_mod = clanarena_HandleFrags;
	plugin_score_winning_condition_countdown = stub_score_winning_condition_countdown;
	precache_model("models/domination/dom_unclaimed.md3");
	precache_model("models/domination/dom_red.md3");
	precache_model("models/domination/dom_blue.md3");
	jb_controller = spawn();
	jb_controller.think = jb_think;
	jb_controller.nextthink = time;
}

void(float t) jb_open {
	if (t == COLOR_TEAM1) jb_open_red = time + 10;
	if (t == COLOR_TEAM2) jb_open_blue = time + 10;
}

void(void) jb_room_touch {
	if (warmup_active) return;
	if (other.classname != "player") return;
	if (self.team == COLOR_TEAM1 && jb_open_red >= time) return; //open state
	if (self.team == COLOR_TEAM2 && jb_open_blue >= time) return; //open state
	if (other.scorekeeper.scores[SP_STATUS] == 0) {
		score_player_set(other, SP_STATUS, 1);
		bprint(player_name(other), "^7 jailed!\n");
	}
}

void(void) jb_room {
	self.classname = "jb_room";
	trigger_solid_brush_init();
	self.touch = jb_room_touch;
}

void(void) jb_spawn {
	spawnfunc_info_player_deathmatch();
	if (wasfreed(self)) return; //just in case
	self.classname = "jb_spawn";
}

void(void) jb_controlpoint_model_setup {
	switch (self.team) {
	case COLOR_TEAM1:
		setmodel(self, "models/domination/dom_red.md3");
		break;
	case COLOR_TEAM2:
		setmodel(self, "models/domination/dom_blue.md3");
		break;
	default:
		setmodel(self, "models/domination/dom_unclaimed.md3");
		self.team = 0;
	}
	setsize(self, '-32 -32 -32', '32 32 32');
}

void(void) jb_controlpoint {
	self.classname = "jb_controlpoint";
	jb_controlpoint_model_setup();
}

void(void) spawnfunc_func_jailbreak_jail_red {
	self.team = COLOR_TEAM1;
	jb_room();
}

void(void) spawnfunc_func_jailbreak_jail_blue {
	self.team = COLOR_TEAM2;
	jb_room();
}

void(void) spawnfunc_info_jailbreak_jailspawn_red {
	self.team = COLOR_TEAM1;
	jb_spawn();
}

void(void) spawnfunc_info_jailbreak_jailspawn_blue {
	self.team = COLOR_TEAM2;
	jb_spawn();
}

void(void) spawnfunc_jailbreak_controlpoint_red {
	self.team = COLOR_TEAM1;
	jb_controlpoint();
}

void(void) spawnfunc_jailbreak_controlpoint_blue {
	self.team = COLOR_TEAM2;
	jb_controlpoint();
}
