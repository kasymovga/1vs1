float g_conq;
float g_conq_capture_time;
float g_conq_lasthope_time;
float g_conq_score_capture;
float g_conq_teamscore_alternative;
float conq_timelimit_save;
float conq_lasthope;

void(void) conquest_cp_free {
	remove(self.enemy);
	self.enemy = world;
	self.team = 0;
	entity e;
	if (self.target != "")
	for (e = world; (e = find(e, targetname, self.target)); )
		if (e.classname == "info_player_deathmatch")
			if (e.sprite) {
				remove(e.sprite);
				e.sprite = world;
			}
}

void(float byteam) conquest_cp_capture {
	self.enemy = spawn();
	setmodel(self.enemy, "models/ctf/flags.md3");
	if (byteam == COLOR_TEAM1)
		self.enemy.skin = 0;
	else
		self.enemy.skin = 1;

	self.enemy.scale = 0.5;
	self.enemy.modelflags = MF_ROTATE;
	setorigin(self.enemy, self.origin + '0 0 64');
	self.team = byteam;
	entity e;
	if (self.target != "")
	for (e = world; (e = find(e, targetname, self.target)); )
		if (e.classname == "info_player_deathmatch") {
			if not(e.sprite)
				marker_SpawnFixed(NULL, e.origin, e, sprite);

			marker_UpdateTeamRadar(e.sprite, 2, 0.25 * colormap_palette_color(self.team - 1, FALSE));
		}
}

.float capture_progress;
.float capture_in_progress;
.entity capture_progress_bar;

void(void) conquest_remove_progress_bar {
	if (self.capture_progress_bar) {
		progressbar_remove(self.capture_progress_bar);
		self.capture_progress_bar = world;
	}
}

void(void) conquest_update_waypoint {
	marker_UpdateTeamRadar(self.sprite, RADARICON_CONTROLPOINT, colormap_palette_color(self.team - 1, FALSE));
	string s;
	s = "";
	if (self.owner) {
		if (self.team == COLOR_TEAM1)
			s = "ons-cp-atck-red";
		else if (self.team == COLOR_TEAM2)
			s = "ons-cp-atck-blue";
	} else if (self.team == COLOR_TEAM1)
		s = "ons-cp-red";
	else if (self.team == COLOR_TEAM2)
		s = "ons-cp-blue";
	else
		s = "ons-cp-neut";

	marker_UpdateSprites(self.sprite, s, s, s);
}

void(void) conquest_cp_reset {
	if (self.team == self.cnt)
		return;

	self.team = self.cnt;
	if (self.enemy)
		conquest_cp_free();

	if (self.team > 0)
		conquest_cp_capture(self.team);

	self.owner = world;
	self.capture_progress = 0;
	conquest_remove_progress_bar();
	conquest_update_waypoint();
}

void(void) conquest_cp_think_capture {
	if (self.owner) {
		if not(self.capture_progress)
		if (self.team > 0)
		if (self.wait < time) {
			sound_play2team(self.team, "onslaught/controlpoint_underattack.ogg");
			marker_Ping(self.sprite);
			conquest_update_waypoint();
			self.wait = time + g_conq_capture_time;
		}
		self.capture_progress = self.capture_progress + (frametime / g_conq_capture_time);
		if (self.team)
			self.enemy.alpha = 1 - self.capture_progress;

		if (self.capture_progress >= 1) {
			score_player_add(self.owner, SP_SCORE, g_conq_score_capture);
			if (self.team > 0) {
				sound_play2all("domination/claim.wav");
				if (g_conq_teamscore_alternative)
					score_team_add_to(self.owner.team, ST_SCORE, 1);
				else
					score_team_add_to(self.team, ST_SCORE, -1);

				conquest_cp_free();
				print_to_spec(self.owner, PRINT_CENTER, "Control Point has been freed", "", "", "");
			} else {
				conquest_cp_capture(self.owner.team);
				score_team_add_to(self.team, ST_SCORE, 1);
				print_to_spec(self.owner, PRINT_CENTER, "Control Point has been captured", "", "", "");
				sound_play2team(self.team, "onslaught/controlpoint_built.ogg");
			}
			activator = self;
			trigger_use_targets();
			if (self.team > 0)
				team_spawn_players(self.team);

			marker_Ping(self.sprite);
			conquest_update_waypoint();
			self.owner = world;
		}
	}
	if not(self.owner) {
		if (self.team)
			self.enemy.alpha = 1;
		conquest_update_waypoint();
		self.capture_progress = 0;
		conquest_remove_progress_bar();
		return;
	}
	progressbar_set(self.capture_progress_bar, self.capture_progress);
	self.owner = world;
	self.nextthink = time;
}

void(void) conquest_cp_touch {
	if (other.classname != "player")
		return;

	if (other.deadflag != DEAD_NO)
		return;

	if (other.team == self.team)
		return;

	if (self.owner)
		return;

	bot_stay(other, 0);
	self.owner = other;
	if not(self.capture_progress_bar)
		self.capture_progress_bar = progressbar_create(((self.team > 0) ? "Freeing..." : "Capturing..."), other);

	plugin_chain_capturing(other);
	self.think = conquest_cp_think_capture;
	self.nextthink = time;
}

void(void) spawnfunc_conquest_cp {
	if not(g_conq) {
		remove(self);
		return;
	}
	setmodel(self, "models/onslaught/controlpoint_pad.md3");
	self.classname = "conquest_cp";
	if (self.team > 0) {
		conquest_cp_capture(self.team);
		team_teams_set_allowed(self.team);
	}
	self.cnt = self.team;
	self.solid = SOLID_TRIGGER;
	self.reset = conquest_cp_reset;
	self.touch = conquest_cp_touch;
	marker_SpawnFixed(NULL, self.origin + '0 0 64', self, sprite);
	marker_UpdateRule(self.sprite, 0);
	conquest_update_waypoint();
	self.maxs_z += 16;
	self.mins_z += 16;
	entity_droptofloor();
}

void(void) spawnfunc_conquest_cp_fromredflag {
	self.team = COLOR_TEAM1;
	spawnfunc_conquest_cp();
}

void(void) spawnfunc_conquest_cp_fromblueflag {
	self.team = COLOR_TEAM2;
	spawnfunc_conquest_cp();
}

float(float t) conquest_team_can_spawn {
	entity head;
	for (head = world; (head = find(head, classname, "conquest_cp")); )
		if (head.team == t)
			return TRUE;

	return FALSE;
}

float(float ignore, float ignore2) conquest_winning_condition {
	entity head;
	float t1, t2;
	float one_of_team_cannot_spawn;
	t1 = t2 = 0;
	one_of_team_cannot_spawn = FALSE;
	if(warmup_active)
		return FALSE;

	PLAYER_FOR_EACH_TEAM(head)
		if (head.team == COLOR_TEAM1)
		if (head.classname == "player")
		if not(head.deadflag) {
			t1 = 1;
			break;
		}
	PLAYER_FOR_EACH_TEAM(head)
		if (head.team == COLOR_TEAM2)
		if (head.classname == "player")
		if not(head.deadflag) {
			t2 = 1;
			break;
		}
	if (conquest_team_can_spawn(COLOR_TEAM1))
		t1 = 1;
	else
		one_of_team_cannot_spawn = TRUE;

	if (conquest_team_can_spawn(COLOR_TEAM2))
		t2 = 1;
	else
		one_of_team_cannot_spawn = TRUE;

	if (one_of_team_cannot_spawn) {
		if not(conq_lasthope) {
			float new_time_limit = (time - map_starttime + g_conq_lasthope_time) / 60;
			conq_timelimit_save = cvar("timelimit");
			cvar_set("timelimit", ftos(new_time_limit));
			conq_lasthope = 1;
		}
	} else {
		if (conq_lasthope) {
			cvar_set("timelimit", ftos(conq_timelimit_save));
			conq_lasthope = 0;
		}
	}
	if (t1 + t2 < 2) {
		// game over, only one team remains (or none)
		world_winners_clear();
		string announce_sound;
		announce_sound = "domination/claim.wav";
		if (t1) {
			world_winners_set(team, COLOR_TEAM1);
			announce_sound = "ctf/red_capture.wav";
		}
		if (t2) {
			world_winners_set(team, COLOR_TEAM2);
			announce_sound = "ctf/blue_capture.wav";
		}
		sound_play2all(announce_sound);
		CLIENT_FOR_EACH_REAL(head) {
			LocationRequest_Remove(head);
		}
		return TRUE;
	}
	// Two or more teams remain
	return FALSE;
}

float(entity attacker, entity targ, float f) conquest_score_give_frag_mod {
	score_player_add(attacker, SP_SCORE, f);
	return 0;
}

entity() conquest_client_put_spawn_point {
	if not(conquest_team_can_spawn(self.team))
		return world;

	return onslaught_client_put_spawn_point();
}

void() conquest_world_reset {
	float b1, b2;
	entity e;
	b1 = b2 = 0;
	for (e = world; (e = find(e, classname, "conquest_cp")); ) {
		if (e.team == COLOR_TEAM1)
			score_team_add_to(COLOR_TEAM1, ST_SCORE, 1);

		if (e.team == COLOR_TEAM2)
			score_team_add_to(COLOR_TEAM2, ST_SCORE, 1);
	}
}

void conquest_delayedinit() {
	entity e;
	for (e = world; (e = find(e, classname, "info_player_deathmatch")); ) {
		if not(e.team)
			continue;

		if not(e.sprite)
			marker_SpawnFixed(NULL, e.origin, e, sprite);

		marker_UpdateTeamRadar(e.sprite, 2, 0.25 * colormap_palette_color(e.team - 1, FALSE));
	}
	conquest_world_reset();
}

var void() conquest_ons_entity_spawn_pre_NextLink;
void conquest_ons_entity_spawn_pre() {
	if (self.classname == "onslaught_generator" || self.classname == "onslaught_controlpoint") {
		self.classname = "conquest_cp";
	}
}

var void() conquest_ctf_and_dom_entity_spawn_pre_NextLink;
void() conquest_ctf_and_dom_entity_spawn_pre {
	if (self.classname == "ctf_flag_team1") {
		self.classname = "conquest_cp_fromredflag";
	} else if (self.classname == "ctf_flag_team2") {
		self.classname = "conquest_cp_fromblueflag";
	} else if (self.classname == "dom_controlpoint") {
		self.classname = "conquest_cp";
	}
}

void(void) conquest_init {
	g_conq = 1;
	precache_model("models/onslaught/controlpoint_pad.md3");
	precache_model("models/ctf/flags.md3");
	precache_sound("ctf/blue_capture.wav");
	precache_sound("ctf/red_capture.wav");
	precache_sound("onslaught/controlpoint_built.ogg");
	precache_sound("onslaught/controlpoint_underattack.ogg");
	precache_sound("domination/claim.wav");
	CVAR_CACHE(g_conq_capture_time);
	CVAR_CACHE(g_conq_lasthope_time);
	CVAR_CACHE(g_conq_score_capture);
	CVAR_CACHE(g_conq_teamscore_alternative);
	if (g_conq_capture_time <= 0)
		g_conq_capture_time = 1;

	plugin_winning_condition = conquest_winning_condition;
	plugin_score_give_frag_mod = conquest_score_give_frag_mod;
	plugin_player_spawn_spot = conquest_client_put_spawn_point;
	plugin_player_death_handle = onslaught_DeathHandle;
	onslaught_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = onslaught_player_spawn;
	onslaught_PlayerClear_NextLink = plugin_chain_player_clear;
	plugin_chain_player_clear = onslaught_PlayerClear;
	plugin_world_reset = conquest_world_reset;
	plugin_score_winning_condition_countdown = stub_score_winning_condition_countdown;
	if (cvar("g_conq_use_ons")) {
		conquest_ons_entity_spawn_pre_NextLink = plugin_chain_entity_spawn_pre;
		plugin_chain_entity_spawn_pre = conquest_ons_entity_spawn_pre;
	}
	if (cvar("g_conq_use_ctf_and_dom")) {
		conquest_ctf_and_dom_entity_spawn_pre_NextLink = plugin_chain_entity_spawn_pre;
		plugin_chain_entity_spawn_pre = conquest_ctf_and_dom_entity_spawn_pre;
	}
	plugin_havocbot_role_choose = conquest_role_choose;
	entity_initialize(world, conquest_delayedinit, INITPRIO_LAST);
}
