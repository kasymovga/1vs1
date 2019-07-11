float g_conquest;
float g_conquest_capture_time;
float g_conquest_lasthope_time;
float g_conquest_score_capture;
float g_conquest_teamscore_alternative;
float conq_timelimit_save;
float conq_lasthope;

void conquest_cp_free() {
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

void conquest_cp_capture(float byteam) {
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
				WaypointSprite_SpawnFixed(string_null, e.origin, e, sprite);

			WaypointSprite_UpdateTeamRadar(e.sprite, 2, 0.25 * colormap_palette_color(self.team - 1, FALSE));
		}
}

.float capture_progress;
.float capture_in_progress;
.entity capture_progress_bar;

void conquest_remove_progress_bar() {
	if (self.capture_progress_bar) {
		remove(self.capture_progress_bar);
		self.capture_progress_bar = world;
	}
}

void conquest_update_waypoint() {
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_CONTROLPOINT, colormap_palette_color(self.team - 1, FALSE));
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

	WaypointSprite_UpdateSprites(self.sprite, s, s, s);
}

void conquest_cp_reset() {
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

.float conquest_delay;

void conquest_cp_think_capture() {
	if (self.owner) {
		if not(self.capture_progress)
		if (self.team > 0)
		if (self.conquest_delay < time) {
			sound_play2team(self.team, "onslaught/controlpoint_underattack.ogg");
			WaypointSprite_Ping(self.sprite);
			conquest_update_waypoint();
			self.conquest_delay = time + g_conquest_capture_time;
		}

		self.capture_progress = self.capture_progress + (frametime / g_conquest_capture_time);
		if (self.team)
			self.enemy.alpha = 1 - self.capture_progress;

		if (self.capture_progress >= 1) {
			score_player_add(self.owner, SP_SCORE, g_conquest_score_capture);
			if (self.team > 0) {
				sound_play2all("domination/claim.wav");
				if (g_conquest_teamscore_alternative)
					score_team_add_to(self.owner.team, ST_SCORE, 1);
				else
					score_team_add_to(self.team, ST_SCORE, -1);
				conquest_cp_free();
				if (clienttype(self.owner) == CLIENTTYPE_REAL)
					centerprint(self.owner, "Control Point has been freed");

			} else {
				conquest_cp_capture(self.owner.team);
				score_team_add_to(self.team, ST_SCORE, 1);
				if (clienttype(self.owner) == CLIENTTYPE_REAL)
					centerprint(self.owner, "Control Point has been captured");

				sound_play2team(self.team, "onslaught/controlpoint_built.ogg");
			}
			activator = self;
			trigger_use_targets();

			if (self.team > 0)
				team_spawn_players(self.team);

			WaypointSprite_Ping(self.sprite);
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

void conquest_cp_touch() {
	if (other.classname != "player")
		return;

	if (other.deadflag != DEAD_NO)
		return;

	if (other.team == self.team)
		return;

	if (self.owner)
		return;

	other.bot_dontmove = time + sys_ticrate * 2;
	self.owner = other;
	if not(self.capture_progress_bar)
		self.capture_progress_bar = progressbar_create(((self.team > 0) ? "Freeing..." : "Capturing..."), other);
	
	self.think = conquest_cp_think_capture;
	self.nextthink = time;
}

void spawnfunc_conquest_cp() {
	if not(g_conquest) {
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
	WaypointSprite_SpawnFixed(string_null, self.origin + '0 0 64', self, sprite);
	WaypointSprite_UpdateRule(self.sprite, 0, SPRITERULE_DEFAULT);
	conquest_update_waypoint();
}

void spawnfunc_conquest_cp_fromredflag() {
	self.team = COLOR_TEAM1;
	setorigin(self, self.origin - '0 0 40');
	spawnfunc_conquest_cp();
}

void spawnfunc_conquest_cp_fromblueflag() {
	self.team = COLOR_TEAM2;
	setorigin(self, self.origin - '0 0 40');
	spawnfunc_conquest_cp();
}

float conquest_TeamCanSpawn(float t) {
	entity head;
	for (head = world; (head = find(head, classname, "conquest_cp")); )
		if (head.team == t)
			return TRUE;

	return FALSE;
}

float conquest_WinningCondition()
{
	entity head;
	float t1, t2;
	float one_of_team_cannot_spawn;
	t1 = t2 = 0;

	one_of_team_cannot_spawn = FALSE;
	score_winning_condition_helper(); // set worldstatus
	if(inWarmupStage)
		return FALSE;

	FOR_EACH_TEAMPLAYER(head)
		if (head.team == COLOR_TEAM1)
		if (head.classname == "player")
		if not(head.deadflag) {
			t1 = 1;
			break;
		}
				
	FOR_EACH_TEAMPLAYER(head)
		if (head.team == COLOR_TEAM2)
		if (head.classname == "player")
		if not(head.deadflag) {
			t2 = 1;
			break;
		}

	if (conquest_TeamCanSpawn(COLOR_TEAM1))
		t1 = 1;
	else
		one_of_team_cannot_spawn = TRUE;

	if (conquest_TeamCanSpawn(COLOR_TEAM2))
		t2 = 1;
	else
		one_of_team_cannot_spawn = TRUE;

	if (one_of_team_cannot_spawn) {
		if not(conq_lasthope) {
			float new_time_limit = (time - game_starttime + g_conquest_lasthope_time) / 60;
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
		FOR_EACH_REALCLIENT(head) {
			announce(head, announce_sound, "");
			LocationRequest_Remove(head);
		}
		return TRUE;
	}

	// Two or more teams remain
	return FALSE;
}

float conquest_FragsHandle(entity attacker, entity targ, float f) {
	score_player_add(attacker, SP_SCORE, f);
	attacker.totalfrags += f;
	return 0;
}

entity conquest_SelectSpawnPoint() {
	if not(conquest_TeamCanSpawn(self.team))
		return world;

	return onslaught_SelectSpawnPoint();
}

void conquest_Reset() {
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
			WaypointSprite_SpawnFixed(string_null, e.origin, e, sprite);

		WaypointSprite_UpdateTeamRadar(e.sprite, 2, 0.25 * colormap_palette_color(e.team - 1, FALSE));
	}
	conquest_Reset();
}

var void() conquest_ons_EntityPreSpawn_NextLink;
void conquest_ons_EntityPreSpawn() {
	if (self.classname == "onslaught_generator" || self.classname == "onslaught_controlpoint") {
		self.classname = "conquest_cp";
	}
}

var void() conquest_ctf_and_dom_EntityPreSpawn_NextLink;
void conquest_ctf_and_dom_EntityPreSpawn() {
	if (self.classname == "item_flag_team1") {
		self.classname = "conquest_cp_fromredflag";
	} else if (self.classname == "item_flag_team2") {
		self.classname = "conquest_cp_fromblueflag";
	} else if (self.classname == "dom_controlpoint") {
		self.classname = "conquest_cp";
	}
}

void conquest_init() {
	g_conquest = 1;
	precache_model("models/onslaught/controlpoint_pad.md3");
	precache_model("models/ctf/flags.md3");
	precache_sound("ctf/blue_capture.wav");
	precache_sound("ctf/red_capture.wav");
	precache_sound("onslaught/controlpoint_built.ogg");
	precache_sound("onslaught/controlpoint_underattack.ogg");
	precache_sound("domination/claim.wav");
	CACHE_CVAR(g_conquest_capture_time);
	CACHE_CVAR(g_conquest_lasthope_time);
	CACHE_CVAR(g_conquest_score_capture);
	CACHE_CVAR(g_conquest_teamscore_alternative);
	if (g_conquest_capture_time <= 0)
		g_conquest_capture_time = 1;

	GameHook_WinningCondition = conquest_WinningCondition;
	GameHook_FragsHandle = conquest_FragsHandle;
	GameHook_SelectSpawnPoint = conquest_SelectSpawnPoint;
	GameHook_DeathHandle = onslaught_DeathHandle;
	onslaught_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = onslaught_Spawn;

	onslaught_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = onslaught_PlayerClear;
	GameHook_Reset = conquest_Reset;
	GameHook_WinCountDown = stub_WinCountDown;
	if (cvar("g_conquest_use_ons")) {
		conquest_ons_EntityPreSpawn_NextLink = GameHookChain_EntityPreSpawn;
		GameHookChain_EntityPreSpawn = conquest_ons_EntityPreSpawn;
	}
	if (cvar("g_conquest_use_ctf_and_dom")) {
		conquest_ctf_and_dom_EntityPreSpawn_NextLink = GameHookChain_EntityPreSpawn;
		GameHookChain_EntityPreSpawn = conquest_ctf_and_dom_EntityPreSpawn;
	}
	GameHook_BotChooseRole = conquest_role_choose;
	entity_initialize(world, conquest_delayedinit, INITPRIO_LAST);
}
