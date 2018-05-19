entity ca_controller;

float g_clanarena_enddelay;
float g_clanarena_startdelay;
float g_clanarena_healthrotpause_on_damage;

void Clanarena_Think()
{
	self.nextthink = time;
	Roundbased_TeamArenaThink();
}

var void(entity spot) Clanarena_Spawn_NextLink;
void Clanarena_Spawn(entity spot) {
	Clanarena_Spawn_NextLink(spot);
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

var float(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) Clanarena_PlayerDamageHandle_NextLink;
float Clanarena_PlayerDamageHandle(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if (attacker.flags & FL_CLIENT)
	if (deathtype != WEP_PORTO)
	if (attacker.team != self.team) {
		PlayerScore_Add(attacker, SP_SCORE, damage / 10);
		attacker.pauserothealth_finished = time + g_clanarena_healthrotpause_on_damage;
		self.pauserothealth_finished = time + g_clanarena_healthrotpause_on_damage;
	}
	return Clanarena_PlayerDamageHandle_NextLink(inflictor, attacker, damage, deathtype, hitloc, force);
}

float Clanarena_FragLimitOverride() {
	return cvar("g_clanarena_winlimit");
}

var void(float killed) Clanarena_PlayerClear_NextLink;
void Clanarena_PlayerClear(float killed) {
	Roundbased_NeedCheckTeams();
	Clanarena_PlayerClear_NextLink(killed);
}

void Clanarena_Init()
{
	CACHE_CVAR(g_clanarena_startdelay);
	CACHE_CVAR(g_clanarena_enddelay);
	CACHE_CVAR(g_clanarena_healthrotpause_on_damage);
	Clanarena_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = Clanarena_Spawn;
	GameHook_FragsHandle = Clanarena_HandleFrags;
	GameHook_DeathHandle = Clanarena_DeathHandle;
	Clanarena_PlayerDamageHandle_NextLink = GameHookChain_PlayerDamageHandle;
	GameHookChain_PlayerDamageHandle = Clanarena_PlayerDamageHandle;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = Clanarena_FragLimitOverride;
	Clanarena_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = Clanarena_PlayerClear;
	Roundbased_Init(g_clanarena_enddelay, g_clanarena_startdelay);
	ca_controller = spawn();
	ca_controller.think = Clanarena_Think;
	ca_controller.nextthink = time;
	ScoreRules_basics(2, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status", 0);
}
