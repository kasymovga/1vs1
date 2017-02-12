float g_conquest_capture_time;

void conquest_cp_free() {
	remove(self.enemy);
	self.enemy = world;
	self.team = 0;
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
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_CONTROLPOINT, 0.5 * colormapPaletteColor(self.team - 1, FALSE));
	string s;
	if(self.team == COLOR_TEAM1)
		s = "ons-cp-red";
	else if(self.team == COLOR_TEAM2)
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

void conquest_cp_think_capture() {
	if (self.owner) {
		self.capture_progress = self.capture_progress + (frametime / g_conquest_capture_time);
		if (self.team)
			self.enemy.alpha = 1 - self.capture_progress;

		if (self.capture_progress >= 1) {
			PlayerScore_Add(self.owner, SP_SCORE, 10);
			if (self.team > 0) {
				play2team(self.team, "onslaught/controlpoint_underattack.ogg");
				play2team(self.owner.team, "domination/claim.wav");
				conquest_cp_free();
				if (clienttype(self.owner) == CLIENTTYPE_REAL)
					centerprint(self.owner, "Control point was freed");

			} else {
				conquest_cp_capture(self.owner.team);
				if (clienttype(self.owner) == CLIENTTYPE_REAL)
					centerprint(self.owner, "Control point was captured");

				play2team(self.team, "onslaught/controlpoint_built.ogg");
			}
			activator = self;
			SUB_UseTargets();

			entity e, oldself;
			if (self.target != "")
			if (self.team > 0)
				FOR_EACH_CLIENT(e)
					if (e.team == self.team)
					if (e.classname != "player") {
						oldself = self;
						self = e;
						PutClientInServer();
						self = oldself;
					}

			WaypointSprite_Ping(self.sprite);
			conquest_update_waypoint();
			self.owner = world;
		}
	}
	if not(self.owner) {
		if (self.team)
			self.enemy.alpha = 1;
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

	self.owner = other;
	if not(self.capture_progress_bar)
		self.capture_progress_bar = ProgressBar_Create(((self.team > 0) ? "Freeing control point..." : "Capturing control point..."), other);
	
	self.think = conquest_cp_think_capture;
	self.nextthink = time;
}

void spawnfunc_conquest_cp() {
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
}

float conquest_WinningCondition()
{
	entity head;
	float t1, t2;

	WinningConditionHelper(); // set worldstatus
	if(inWarmupStage)
		return WINNING_NO;

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

	if not(t1)
	if (conquest_TeamCanSpawn(COLOR_TEAM1))
		t1 = 1;

	if not(t2)
	if (conquest_TeamCanSpawn(COLOR_TEAM2))
		t2 = 1;

	if (t1 + t2 < 2) {
		// game over, only one team remains (or none)
		ClearWinners();
		if (t1) SetWinners(team, COLOR_TEAM1);
		if (t2) SetWinners(team, COLOR_TEAM2);
		dprint("Have a winner, ending game.\n");
		return WINNING_YES;
	}

	// Two or more teams remain
	return WINNING_NO;
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

void conquest_init() {
	precache_model("models/onslaught/controlpoint_pad.md3");
	precache_model("models/ctf/flags.md3");
	precache_sound("onslaught/controlpoint_built.ogg");
	precache_sound("onslaught/controlpoint_underattack.ogg");
	precache_sound("domination/claim.wav");
	CACHE_CVAR(g_conquest_capture_time);
	if (g_conquest_capture_time <= 0)
		g_conquest_capture_time = 1;

	GameHook_WinningCondition = conquest_WinningCondition;
	GameHook_FragsHandle = conquest_FragsHandle;
	GameHook_SelectSpawnPoint = conquest_SelectSpawnPoint;
	GameHook_DeathHandle = onslaught_DeathHandle;
	GameHook_Spawn = onslaught_Spawn;
	GameHook_PlayerClear = onslaught_PlayerClear;
}
