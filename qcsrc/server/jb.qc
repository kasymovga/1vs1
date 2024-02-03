float jb;
float jb_open_blue;
float jb_open_red;
entity jb_controller;
float g_jb_capture_time;
var .float jb_player_jailed;
#define JB_PLAYER_JAILED(plr) (plr.scorekeeper.jb_player_jailed)
#define JB_PLAYER_JAIL_SET(plr, x) score_player_set(plr, SP_STATUS, x);

entity(void) jb_client_put_spawn_point {
	if not(warmup_active)
	if ((self.team == COLOR_TEAM1 && time > jb_open_red) || (self.team == COLOR_TEAM2 && time > jb_open_blue))
	if (roundbased_active) {
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
				JB_PLAYER_JAIL_SET(e, 0);
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
	jb_player_jailed = scores[SP_STATUS];
	team_teams_set_count(2);
	roundbased_init(cvar("g_jb_enddelay"), cvar("g_jb_startdelay"));
	plugin_client_put_spawn_point = jb_client_put_spawn_point;
	plugin_score_give_frag_mod = clanarena_HandleFrags;
	plugin_score_winning_condition_countdown = stub_score_winning_condition_countdown;
	precache_model("models/domination/dom_unclaimed.md3");
	precache_model("models/domination/dom_red.md3");
	precache_model("models/domination/dom_blue.md3");
	precache_sound("kh/alarm.wav");
	jb_controller = spawn();
	jb_controller.think = jb_think;
	jb_controller.nextthink = time;
	CVAR_CACHE(g_jb_capture_time);
}

void(float t, entity by) jb_open {
	string s = "";
	if (t == COLOR_TEAM1) {
		game_status_set(strcat("Jailbreak! The ^1REDS^7 are escaping!\nControl point captured by ", by.netname), 2);
		jb_open_red = time + 10;
		s = "jail_red";
	}
	if (t == COLOR_TEAM2) {
		game_status_set(strcat("Jailbreak! The ^4BLUES^7 are escaping!\nControl point captured by ", by.netname), 2);
		jb_open_blue = time + 10;
		s = "jail_blue";
	}
	if (s == "") {
		print("attempt to open unknown jail\n");
		return;
	}
	sound_play2all("kh/alarm.wav");
	entity e;
	for (e = NULL; (e = find(e, targetname, s)); ) {
		e.use();
	}
}

void(void) jb_room_touch {
	if (warmup_active) return;
	if (other.classname != "player") return;
	if (self.team == COLOR_TEAM1 && jb_open_red >= time) return; //open state
	if (self.team == COLOR_TEAM2 && jb_open_blue >= time) return; //open state
	if (!JB_PLAYER_JAILED(other)) {
		JB_PLAYER_JAIL_SET(other, 1);
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
	switch(self.team) {
	case COLOR_TEAM1:
		WaypointSprite_UpdateSprites(self.sprite, "dom-red", "", "");
		break;
	case COLOR_TEAM2:
		WaypointSprite_UpdateSprites(self.sprite, "dom-blue", "", "");
		break;
	default:
		WaypointSprite_UpdateSprites(self.sprite, "dom-neut", "", "");
	}
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_DOMPOINT, colormap_palette_color(self.team, 0));
	WaypointSprite_Ping(self.sprite);
	setsize(self, '-32 -32 -32', '32 32 32');
}

float(entity cp) jb_controlpoint_active {
	if (cp.team == COLOR_TEAM1 && jb_open_red >= time) return FALSE;
	if (cp.team == COLOR_TEAM2 && jb_open_blue >= time) return FALSE;
	if not(roundbased_active) return FALSE;
	return TRUE;
}

void(void) jb_controlpoint_think {
	entity e, capturer, e2;
	vector min1, min2, max1, max2;
	min2 = self.mins + self.origin;
	max2 = self.maxs + self.origin;
	while (self.killindicator) { //make first capturer valid or NULL
		capturer = self.killindicator.enemy;
		min1 = capturer.mins + capturer.origin;
		max1 = capturer.maxs + capturer.origin;
		if (!jb_controlpoint_active(self) || capturer.team == self.team || capturer.playerid != self.killindicator.playerid || !math_boxes_overlap(min1, max1, min2, max2)) {
			e = self.killindicator.killindicator;
			progressbar_remove(self.killindicator.sprite);
			remove(self.killindicator);
			self.killindicator = e;
		}
		break;
	}
	if (self.killindicator) //check other capturers in chain
		for (e = self.killindicator; e.killindicator; e = e.killindicator) {
			capturer = e.killindicator.enemy;
			min1 = capturer.mins + capturer.origin;
			max1 = capturer.maxs + capturer.origin;
			if (!jb_controlpoint_active(self) || capturer.team == e.team || capturer.playerid != e.killindicator.playerid || !math_boxes_overlap(min1, max1, min2, max2)) {
				e2 = e.killindicator.killindicator;
				progressbar_remove(e.killindicator.sprite);
				remove(e.killindicator);
				e.killindicator = e2;
			}
		}
	if not(self.killindicator) {
		self.state = 0;
		WaypointSprite_UpdateMaxHealth(self.sprite, 0);
		WaypointSprite_UpdateHealth(self.sprite, self.state);
		return;
	}
	self.nextthink = time;
	for (e = self.killindicator; e; e = e.killindicator) {
		self.state += frametime / g_jb_capture_time;
	}
	WaypointSprite_UpdateHealth(self.sprite, self.state);
	if (self.state >= 1) {
		self.state = 1;
	}
	for (e = self.killindicator; e; e = e.killindicator) {
		progressbar_set(self.killindicator.sprite, self.state);
	}
	if (self.state == 1) {
		self.team = self.killindicator.enemy.team;
		jb_controlpoint_model_setup();
		//Alternative escape mode?
		//for (e = NULL; (e = find(e, classname, "jb_controlpoint")); ) {
		//	if (e.team != self.team) return;
		//}
		jb_open(self.team, self.killindicator.enemy);
	}
}

void(void) jb_controlpoint_touch {
	if (other.team == self.team) return;
	if (other.classname != "player") return;
	//capture
	entity e;
	for (e = self.killindicator; e; e = e.killindicator) {
		if (e.enemy == other) return;
	}
	float somebodyjailed = FALSE;
	FOR_EACH_PLAYER(e)
		if (e.team == self.team) {
			somebodyjailed = TRUE;
			break;
		}
	if not(somebodyjailed) {
		centerprint(other, "Nobody jailed\n");
		return;
	}
	e = spawn();
	WaypointSprite_UpdateMaxHealth(self.sprite, 1);
	e.enemy = other;
	e.playerid = other.playerid;
	e.killindicator = self.killindicator;
	e.sprite = progressbar_create("Capturing...", other);
	self.killindicator = e;
	self.nextthink = time;
}

void(void) jb_controlpoint_reset {
	self.team = self.cnt;
	self.nextthink = 0;
	jb_controlpoint_model_setup();
}

void(void) jb_controlpoint {
	self.classname = "jb_controlpoint";
	WaypointSprite_SpawnFixed("dom-neut", self.origin + '0 0 32', self, sprite);
	self.cnt = self.team;
	jb_controlpoint_model_setup();
	builtin_droptofloor();
	self.touch = jb_controlpoint_touch;
	self.reset = jb_controlpoint_reset;
	self.think = jb_controlpoint_think;
	self.solid = SOLID_TRIGGER;
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
