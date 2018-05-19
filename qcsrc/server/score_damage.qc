var float(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) ScoreDamage_PlayerDamageHandle_NextLink;
float ScoreDamage_PlayerDamageHandle(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if (attacker.scorekeeper)
	if (!teamplay || attacker.team != self.team)
	if (deathtype != WEP_PORTO)
		PlayerScore_Add(attacker, SP_DAMAGE, damage);

	return ScoreDamage_PlayerDamageHandle_NextLink(inflictor, attacker, damage, deathtype, hitloc, force);
}

void ScoreDamage_Init() {
	if not(cvar("g_score_damage"))
		return;

	ScoreDamage_PlayerDamageHandle_NextLink = GameHookChain_PlayerDamageHandle;
	GameHookChain_PlayerDamageHandle = ScoreDamage_PlayerDamageHandle;
	ScoreInfo_SetLabel_PlayerScore(SP_DAMAGE, "damage", 0);
}
