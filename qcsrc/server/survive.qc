float wave_number;
float wave_not_found;
float survive_active;
float g_survive_wave_pause;
float g_survive_monster_factor;
float survive_monster_quant;
entity survive_plan_entity;

string wave_string() {
	return strcat("wave", ftos(wave_number));
}

float survive_has_alive_players() {
	entity e;
	FOR_EACH_PLAYER(e)
		if (PLAYER_ALIVE(e))
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
		PlayerScore_Set(self, SP_STATUS, 0);
		return;
	}
	PutObserverInServer(FALSE);
	PlayerScore_Set(self, SP_STATUS, 1);
}

float survive_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	PlayerScore_Set(self, SP_STATUS, 1);
	return FALSE;
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
			if (self.classname != "player") {
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
		self.use();
	}
	float i;
	float wave_to_max = wave_number + 10;
	for (i = wave_number; i < wave_to_max; i++)
	for (self = world; (self = find(self, targetname, strcat("waveto", ftos(i)))); ) {
		activator = survive_plan_entity;
		self.use();
	}
	for (i = 1; i <= wave_number; i++)
	for (self = world; (self = find(self, targetname, strcat("wavefrom", ftos(i)))); ) {
		activator = survive_plan_entity;
		self.use();
	}
	survive_active = TRUE;
	GameStatus_Set("^1New wave incoming!!!\n^1Try to survive", 2);

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
	survive_active = FALSE;
	entity oldself = self;
	FOR_EACH_CLIENT(self) {
		if (self.team >= 0) {
			if (self.classname != "player") {
				self.classname = "player";
				PutClientInServer();
			}
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
	WinningConditionHelper(); // set worldstatus
	if (time < game_starttime)
		return FALSE;

	//print("survive_WinningCondition()\n");
	entity e, oldself, monster;
	if (wave_not_found) {
		FOR_EACH_CLIENT(e)
			e.winning = TRUE;

		GameStatus_Set("^2All enemies destroyed!!!\n^2You successfully survived\n", 5);
		e = find(world, targetname, "survive_success");
		if (e) {
			oldself = self;
			self = e;
			activator = world;
			other = world;
			self.use();
			self = oldself;
		}
		return TRUE;
	}

	if (survive_active)
	if not(survive_has_alive_players())
		return TRUE;

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
			GameStatus_Set(strcat("^3New wave starts in ", ftos(countdown), " seconds"), 1);
			survive_last_countdown = countdown;
		}
	}

	return FALSE;
}

void survive_MonsterKilled(entity attacker) {
	if (attacker.classname == "player") {
		PlayerScore_Add(attacker, SP_SCORE, self.frags);
		TeamScore_AddToTeam(attacker.team, ST_SCORE, self.frags);
	}
}

float survive_MonsterQuant() {
	return survive_monster_quant;
}

void spawnfunc_survive_wave() {
	self.use = SUB_Null;
}

void survive_init() {
	survive_monster_quant = 1;
	GameHook_WinningCondition = survive_WinningCondition;
	GameHook_DeathHandle = survive_DeathHandle;

	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_MonsterQuant = survive_MonsterQuant;
	GameHook_MonsterKilled = survive_MonsterKilled;

	survive_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = survive_Spawn;

	ScoreRules_basics(1, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status", 0);

	CACHE_CVAR(g_survive_wave_pause);
	g_survive_monster_factor = bound(0, cvar("g_survive_monster_factor"), 1);
	wave_number = cvar("g_survive_wave_skip");
}
