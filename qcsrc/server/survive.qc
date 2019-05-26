float wave_number;
float wave_not_found;
float survive_active;
float g_survive_wave_pause;
float g_survive_freeze;
float g_survive_monster_factor;
float survive_monster_quant;
entity survive_plan_entity;
string survive_gameover_message;
string survive_wave_prefix;

string wave_string() {
	return strcat("wave", ftos(wave_number));
}

float survive_has_alive_players() {
	entity e;
	FOR_EACH_PLAYER(e)
		if (PLAYER_REALLY_ALIVE(e))
			return TRUE;

	return FALSE;
}

float survive_has_players() {
	entity e;
	FOR_EACH_CLIENT(e)
		if (e.team >= 0 || e.classname == "player")
			return TRUE;

	return FALSE;
}

var void(entity spot) survive_Spawn_NextLink;
void survive_Spawn(entity spot) {
	survive_Spawn_NextLink(spot);
	if not(survive_active) {
		scores_player_set(self, SP_STATUS, 0);
		return;
	}
	spectator_observer_spawn(FALSE);
	scores_player_set(self, SP_STATUS, 1);
}

void survive_trigger() {
	if not(survive_has_players()) {
		self.nextthink = time + g_survive_wave_pause;
		return;
	}
	entity oldself = self;
	survive_monster_quant = (1 - g_survive_monster_factor);
	survive_active = FALSE;
	FOR_EACH_CLIENT(self) {
		if (self.team >= 0) {
			if (self.classname != "player" || (g_survive_freeze && self.deadflag == DEAD_FREEZE)) {
				self.classname = "player";
				PutClientInServer();
			}
			survive_monster_quant += g_survive_monster_factor;
		}
	}
	self = oldself;
	if (survive_monster_quant)
		survive_monster_quant = 1 / (survive_monster_quant + 0.001);
	else
		survive_monster_quant = 1;

	for (self = world; (self = find(self, targetname, wave_string())); ) {
		activator = survive_plan_entity;
		if (self.use)
			self.use();
	}
	float i;
	float wave_to_max = wave_number + 10;
	for (i = wave_number; i < wave_to_max; i++)
	for (self = world; (self = find(self, targetname, strcat("waveto", ftos(i)))); ) {
		activator = survive_plan_entity;
		if (self.use)
			self.use();
	}
	for (i = 1; i <= wave_number; i++)
	for (self = world; (self = find(self, targetname, strcat("wavefrom", ftos(i)))); ) {
		activator = survive_plan_entity;
		if (self.use)
			self.use();
	}
	survive_active = TRUE;
	GameStatus_Set("^1New wave incoming!\n^1Try to survive", 2);
	FOR_EACH_REALCLIENT(self)
		announce(self, "announcer/robotic/begin.wav");

	self = oldself;
	remove(self);
	survive_plan_entity = world;
}

void survive_plan() {
	wave_number++;
	survive_plan_entity = spawn();
	survive_plan_entity.classname = "monster";
	survive_plan_entity.think = survive_trigger;
	survive_plan_entity.nextthink = time + g_survive_wave_pause;
	survive_plan_entity.team = -1; //Fake team
	if (survive_active)
		survive_wave_prefix = "^2Wave cleared!";

	survive_active = FALSE;
	entity oldself = self;
	FOR_EACH_CLIENT(self) {
		if (self.team >= 0) {
			if (self.classname != "player" || (g_survive_freeze && self.deadflag == DEAD_FREEZE)) {
				self.classname = "player";
				PutClientInServer();
			}
			if (clienttype(self) == CLIENTTYPE_REAL)
				announce_force(self, "domination/claim.wav");
		}
	}
	self = oldself;
}

float survive_checkNextWave() {
	string wave_ind_str = ftos(wave_number + 1);
	if (find(world, targetname, strcat("wave", wave_ind_str)))
		return TRUE;

	if (find(world, targetname, strcat("waveto", wave_ind_str)))
		return TRUE;

	return FALSE;
}

float survive_last_countdown;
float survive_WinningCondition() {
	scores_winning_condition_helper(); // set worldstatus
	if (time < game_starttime)
		return FALSE;

	//print("survive_WinningCondition()\n");
	entity e, oldself, monster;
	if (wave_not_found) {
		FOR_EACH_CLIENT(e)
			e.winning = TRUE;

		survive_gameover_message = "^2All enemies destroyed!\n^2You successfully survived\n";
		e = find(world, targetname, "survive_success");
		if (e) {
			oldself = self;
			self = e;
			activator = world;
			other = world;
			if (self.use)
				self.use();
			self = oldself;
		}
		return TRUE;
	}

	if (survive_active)
	if not(survive_has_alive_players()) {
		survive_gameover_message = "^1No alive players left!\n^1Nobody survived\n";
		return TRUE;
	}

	monster = find(world, classname, "monster");
	if not(monster)
	for (e = world; (e = find(e, targetname, wave_string()));) {
		if (strstrofs(e.classname, "_spawn", 0) > 0)
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	float i;
	for (i = 1; !monster && i <= wave_number; i++)
	for (e = world; (e = find(e, targetname, strcat("wavefrom", ftos(i)))); ) {
		if (strstrofs(e.classname, "_spawn", 0) > 0)
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	for (i = wave_number; !monster && i >= 1; i--)
	for (e = world; (e = find(e, targetname, strcat("waveto", ftos(i)))); ) {
		if (strstrofs(e.classname, "_spawn", 0) > 0)
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	if not(monster) {
		if (survive_checkNextWave())
			survive_plan();
		else
			wave_not_found = TRUE;
	}
	if (survive_plan_entity) {
		float countdown = ceil(survive_plan_entity.nextthink - time);
		if (survive_last_countdown != countdown) {
			GameStatus_Set(strcat(survive_wave_prefix, "\n^3New wave starts in ", ftos(countdown), " seconds"), 1);
			FOR_EACH_REALCLIENT(e)
				if (countdown <= 3)
					announce(e, strcat("announcer/robotic/", ftos(countdown), ".wav"));

			survive_last_countdown = countdown;
		}
	}

	return FALSE;
}

void survive_MonsterKilled(entity attacker) {
	if (attacker.classname == "player") {
		scores_player_add(attacker, SP_SCORE, self.frags);
		scores_team_add_to(attacker.team, ST_SCORE, self.frags);
	}
}

float survive_MonsterQuant() {
	return survive_monster_quant;
}

void spawnfunc_survive_wave() {
	self.use = SUB_Null;
}

float survive_IceSkipThink() {
	return !survive_active;
}

void survive_IceUnfroze(entity unfrozer) {
	scores_player_set(self.owner, SP_STATUS, 0);
	if (unfrozer.classname == "player") {
		scores_player_add(unfrozer, SP_SCORE, 1);
		scores_player_add(unfrozer, SP_REVIVE, 1);
	}
}

void survive_IceFrozenStatus() {
	scores_player_set(self, SP_STATUS, 1);
}

float survive_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	survive_IceFrozenStatus();
	return FALSE;
}

string survive_GameOverMessageMod(string s) {
	return survive_gameover_message;
}

void survive_init_delayed() {
	if (g_survive_freeze) {
		IceHook_SkipThink = survive_IceSkipThink;
		IceHook_SkipDeathHandle = survive_IceSkipThink;
		IceHook_Unfroze = survive_IceUnfroze;
		IceHook_FrozenStatus = survive_IceFrozenStatus;
		Ice_Init();
	} else {
		GameHook_DeathHandle = survive_DeathHandle;
	}
}

float survive_return0() {
	return 0;
}

void survive_init() {
	SetTeamCount(1);
	survive_gameover_message = "^3No time left, game finished";
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	CACHE_CVAR(g_survive_freeze);
	entity_initialize(world, survive_init_delayed, INITPRIO_GAMETYPE);
	survive_monster_quant = 1;
	GameHook_WinningCondition = survive_WinningCondition;
	GameHook_GameOverMessageMod = survive_GameOverMessageMod;
	GameHook_FragLimitOverride = survive_return0;
	GameHook_LeadLimitOverride = survive_return0;

	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_MonsterQuant = survive_MonsterQuant;
	GameHook_MonsterKilled = survive_MonsterKilled;

	survive_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = survive_Spawn;

	scores_basics(SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	SP_STATUS = scores_register_score("status", 0);
	if (g_survive_freeze)
		SP_REVIVE = scores_register_score("revs", SFL_SORT_PRIO_SECONDARY);

	CACHE_CVAR(g_survive_wave_pause);
	g_survive_monster_factor = bound(0, cvar("g_survive_monster_factor"), 1);
	wave_number = cvar("g_survive_wave_skip");
}
