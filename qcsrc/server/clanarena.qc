float g_clanarena_healthrotpause_on_damage;

float Clanarena_HandleFrags(entity attacker, entity targ, float f) {
	if (Roundbased_Active) {
		scores_player_add(attacker, SP_SCORE, f);
		attacker.totalfrags += f;
	}
	return 0;
}

var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) Clanarena_PlayerDamageHandle_NextLink;
float Clanarena_PlayerDamageHandle(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
	if (attacker.flags & FL_CLIENT)
	if (deathtype != WEP_PORTO)
	if (attacker.team != self.team) {
		scores_player_add(attacker, SP_SCORE, _damage / 10);
		attacker.pauserothealth_finished = time + g_clanarena_healthrotpause_on_damage;
		self.pauserothealth_finished = time + g_clanarena_healthrotpause_on_damage;
	}
	return Clanarena_PlayerDamageHandle_NextLink(inflictor, attacker, _damage, deathtype, hitloc, force);
}

float Clanarena_FragLimitOverride() {
	return cvar("g_clanarena_winlimit");
}

void Clanarena_Init()
{
	CACHE_CVAR(g_clanarena_healthrotpause_on_damage);
	team_teams_set_count(bound(2, cvar("g_clanarena_teams"), 4));
	GameHook_FragsHandle = Clanarena_HandleFrags;
	Clanarena_PlayerDamageHandle_NextLink = GameHookChain_PlayerDamageHandle;
	GameHookChain_PlayerDamageHandle = Clanarena_PlayerDamageHandle;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = Clanarena_FragLimitOverride;
	scores_generic();
	Clanarena_Init_Shared("clanarena");
}
