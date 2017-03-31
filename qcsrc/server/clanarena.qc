entity ca_controller;

float g_clanarena_enddelay;
float g_clanarena_startdelay;

void Clanarena_Think()
{
	self.nextthink = time;
	Roundbased_TeamArenaThink();
}

void Clanarena_Spawn(entity spot) {
	Roundbased_NeedCheckTeams();
	if not(Roundbased_Active)
	if not(Roundbased_RestartTime) {
		PlayerScore_Set(self, SP_STATUS, 0);
		return;
	}

	PlayerScore_Set(self, SP_STATUS, 1);
	PutObserverInServer(FALSE);
}

float Clanarena_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	Roundbased_NeedCheckTeams();
	if (Roundbased_Active)
		PlayerScore_Set(self, SP_STATUS, 1);

	return FALSE;
}

float Clanarena_HandleFrags(entity attacker, entity targ, float f) {
	if (Roundbased_Active) {
		PlayerScore_Add(attacker, SP_SCORE, f);
		attacker.totalfrags += f;
	}
	return 0;
}

float Clanarena_PlayerDamageHandle(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if (attacker.flags & FL_CLIENT)
	if (attacker.team != self.team) {
		PlayerScore_Add(attacker, SP_DAMAGE, damage);
		PlayerScore_Add(attacker, SP_SCORE, damage / 10);
	}
	return FALSE;
}

float Clanarena_FragLimitOverride() {
	return cvar("g_clanarena_winlimit");
}

void Clanarena_Init()
{
	CACHE_CVAR(g_clanarena_startdelay);
	CACHE_CVAR(g_clanarena_enddelay);
	GameHook_Spawn = Clanarena_Spawn;
	GameHook_FragsHandle = Clanarena_HandleFrags;
	GameHook_DeathHandle = Clanarena_DeathHandle;
	GameHook_PlayerDamageHandle = Clanarena_PlayerDamageHandle;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = Clanarena_FragLimitOverride;
	Roundbased_Init(g_clanarena_enddelay, g_clanarena_startdelay);
	ca_controller = spawn();
	ca_controller.think = Clanarena_Think;
	ca_controller.nextthink = time;
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	ScoreRules_basics(2, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	ScoreInfo_SetLabel_PlayerScore(SP_DAMAGE, "damage",      SFL_SORT_PRIO_SECONDARY);
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status",     SFL_LOWER_IS_BETTER);
	ScoreRules_basics_end();
}
