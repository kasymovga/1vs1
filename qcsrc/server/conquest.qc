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

			WaypointSprite_UpdateTeamRadar(e.sprite, 2, 0.25 * colormapPaletteColor(self.team - 1, FALSE));
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
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_CONTROLPOINT, colormapPaletteColor(self.team - 1, FALSE));
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
			play2team(self.team, "onslaught/controlpoint_underattack.ogg");
			WaypointSprite_Ping(self.sprite);
			conquest_update_waypoint();
			self.conquest_delay = time + g_conquest_capture_time;
		}

		self.capture_progress = self.capture_progress + (frametime / g_conquest_capture_time);
		if (self.team)
			self.enemy.alpha = 1 - self.capture_progress;

		if (self.capture_progress >= 1) {
			PlayerScore_Add(self.owner, SP_SCORE, g_conquest_score_capture);
			if (self.team > 0) {
				play2all("domination/claim.wav");
				if (g_conquest_teamscore_alternative)
					TeamScore_AddToTeam(self.owner.team, ST_SCORE, 1);
				else
					TeamScore_AddToTeam(self.team, ST_SCORE, -1);
				conquest_cp_free();
				if (clienttype(self.owner) == CLIENTTYPE_REAL)
					centerprint(self.owner, "Control Point has been freed");

			} else {
				conquest_cp_capture(self.owner.team);
				TeamScore_AddToTeam(self.team, ST_SCORE, 1);
				if (clienttype(self.owner) == CLIENTTYPE_REAL)
					centerprint(self.owner, "Control Point has been captured");

				play2team(self.team, "onslaught/controlpoint_built.ogg");
			}
			activator = self;
			SUB_UseTargets();

			if (self.team > 0)
				PutTeamToServer(self.team);

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
	ProgressBar_SetValue(self.capture_progress_bar, self.capture_progress);
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
		self.capture_progress_bar = ProgressBar_Create(((self.team > 0) ? "Freeing..." : "Capturing..."), other);
	
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
	if (self.team > 0)
		conquest_cp_capture(self.team);

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
	WinningConditionHelper(); // set worldstatus
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
		ClearWinners();
		string announce_sound;
		announce_sound = "domination/claim.wav";
		if (t1) {
			SetWinners(team, COLOR_TEAM1);
			announce_sound = "ctf/red_capture.wav";
		}
		if (t2) {
			SetWinners(team, COLOR_TEAM2);
			announce_sound = "ctf/blue_capture.wav";
		}
		if (t1 + t2 > 0)
		FOR_EACH_REALCLIENT(head)

		dprint("Have a winner, ending game.\n");
		FOR_EACH_REALCLIENT(head) {
			announce(head, announce_sound);
			LocationRequest_Remove(head);
		}
		return TRUE;
	}

	// Two or more teams remain
	return FALSE;
}

float conquest_FragsHandle(entity attacker, entity targ, float f) {
	PlayerScore_Add(attacker, SP_SCORE, f);
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
			TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, 1);

		if (e.team == COLOR_TEAM2)
			TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, 1);
	}
}

void conquest_delayedinit() {
	entity e;
	for (e = world; (e = find(e, classname, "info_player_deathmatch")); ) {
		if not(e.team)
			continue;

		if not(e.sprite)
			WaypointSprite_SpawnFixed(string_null, e.origin, e, sprite);

		WaypointSprite_UpdateTeamRadar(e.sprite, 2, 0.25 * colormapPaletteColor(e.team - 1, FALSE));
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
	InitializeEntity(world, conquest_delayedinit, INITPRIO_LAST);
}
