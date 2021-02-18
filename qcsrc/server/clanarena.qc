float g_ca_healthrotpause_on_damage;

float Clanarena_HandleFrags(entity attacker, entity targ, float f) {
	if (Roundbased_Active) {
		score_player_add(attacker, SP_SCORE, f);
	}
	return 0;
}

var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) Clanarena_PlayerDamageHandle_NextLink;
float Clanarena_PlayerDamageHandle(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
	if (attacker.flags & FL_CLIENT)
	if (deathtype != WEP_PORTO)
	if (attacker.team != self.team) {
		score_player_add(attacker, SP_SCORE, _damage / 10);
		attacker.pauserothealth_finished = time + g_ca_healthrotpause_on_damage;
		self.pauserothealth_finished = time + g_ca_healthrotpause_on_damage;
	}
	return Clanarena_PlayerDamageHandle_NextLink(inflictor, attacker, _damage, deathtype, hitloc, force);
}

void Clanarena_Init()
{
	CVAR_CACHE(g_ca_healthrotpause_on_damage);
	team_teams_set_count(bound(2, cvar("g_ca_teams"), 4));
	GameHook_FragsHandle = Clanarena_HandleFrags;
	Clanarena_PlayerDamageHandle_NextLink = GameHookChain_PlayerDamageHandle;
	GameHookChain_PlayerDamageHandle = Clanarena_PlayerDamageHandle;
	GameHook_WinCountDown = stub_WinCountDown;
	score_generic();
	Clanarena_Init_Shared("ca");
}
