float wave_number;
float wave_not_found;
float survive_active;
float g_survive_wave_pause;
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
	entity e;
	survive_monster_quant = 0;
	survive_active = FALSE;
	FOR_EACH_CLIENT(self) {
		if (self.team >= 0) {
			if (self.classname != "player") {
				self.classname = "player";
				PutClientInServer();
			}
			survive_monster_quant++;
		}
	}
	self = oldself;
	if (survive_monster_quant) {
		survive_monster_quant = 1 / survive_monster_quant + 0.01;
	}

	wave_not_found = TRUE;
	string wave_str = wave_string();
	for (self = world; (self = find(self, targetname, wave_str)); ) {
		wave_not_found = FALSE;
		self.reset();
		self.use();
	}
	float i;
	for (i = wave_number; i >= 1; i--)
	for (self = world; (self = find(self, targetname, strcat("waveto", ftos(i)))); ) {
		wave_not_found = FALSE;
		self.reset();
		self.use();
	}
	if not(wave_not_found)
	for (i = 1; i <= wave_number; i++)
	for (self = world; (self = find(self, targetname, strcat("wavefrom", ftos(i)))); ) {
		self.team = COLOR_TEAM2;
		self.reset();
		self.use();
	}
	if not(wave_not_found) {
		survive_active = TRUE;
		FOR_EACH_REALCLIENT(e)
			centerprint(e, "^2New wave coming!!!\nTry to survive\n");
	} else {
		FOR_EACH_REALCLIENT(e)
			centerprint(e, "^2All enemy destroyed!!!\nYou successfully survived\n");
	}
	self = oldself;
	remove(self);
	survive_plan_entity = world;
}

void survive_plan() {
	entity e;
	FOR_EACH_REALCLIENT(e)
		centerprint(e, "^2Waiting new wave...\n");

	wave_number++;
	survive_plan_entity = spawn();
	survive_plan_entity.classname = "monster";
	survive_plan_entity.think = survive_trigger;
	survive_plan_entity.nextthink = time + g_survive_wave_pause;
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
}

float survive_WinningCondition() {
	//print("survive_WinningCondition()\n");
	entity e;
	entity monster;
	if (wave_not_found)
		return TRUE;

	if (survive_active)
	if not(survive_has_alive_players())
		return TRUE;

	monster = find(world, classname, "monster");
	string wave_str = wave_string();
	if not(monster)
	for (e = world; (e = find(e, targetname, wave_str));) {
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	float i;
	for (i = 1; !monster && i <= wave_number; i++)
	for (e = world; (e = find(e, targetname, strcat("wavefrom", ftos(i)))); ) {
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	for (i = wave_number; !monster && i >= 1; i--)
	for (e = world; (e = find(e, targetname, strcat("waveto", ftos(i)))); ) {
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	if (survive_active)
	if not(monster)
		survive_plan();

	if not(survive_active)
	if not(survive_plan_entity)
		survive_plan();

	return FALSE;
}

void survive_MonsterKilled(entity attacker) {
	if (attacker.classname == "player") {
		PlayerScore_Add(attacker, SP_SCORE, 1);
		TeamScore_AddToTeam(attacker.team, ST_SCORE, 1);
	}
}

float survive_MonsterQuant() {
	return survive_monster_quant;
}

void spawnfunc_survive_wave() {
	self.reset = SUB_Null;
	self.use = SUB_Null;
}

void survive_init() {
	GameHook_WinningCondition = survive_WinningCondition;
	GameHook_DeathHandle = survive_DeathHandle;

	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_MonsterQuant = survive_MonsterQuant;
	GameHook_MonsterKilled = survive_MonsterKilled;

	survive_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = survive_Spawn;

	ScoreRules_basics(1, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status", SFL_LOWER_IS_BETTER);
	ScoreRules_basics_end();

	CACHE_CVAR(g_survive_wave_pause);
}
