float g_clanarena_enddelay;
float g_clanarena_startdelay;
float g_clanarena_healthrotpause_on_damage;

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

void Clanarena_Init()
{
	CACHE_CVAR(g_clanarena_startdelay);
	CACHE_CVAR(g_clanarena_enddelay);
	CACHE_CVAR(g_clanarena_healthrotpause_on_damage);
	GameHook_FragsHandle = Clanarena_HandleFrags;
	Clanarena_PlayerDamageHandle_NextLink = GameHookChain_PlayerDamageHandle;
	GameHookChain_PlayerDamageHandle = Clanarena_PlayerDamageHandle;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = Clanarena_FragLimitOverride;
	Roundbased_Init(g_clanarena_enddelay, g_clanarena_startdelay);
	ScoreRules_basics(2, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	Clanarena_Init_Shared();
}
