var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) score_damage_PlayerDamageHandle_NextLink;
float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) score_damage_PlayerDamageHandle {
	if (attacker.scorekeeper)
	if (!team_mode || attacker.team != self.team)
	if (attacker != self)
	if (deathtype != WEP_PORTO)
		score_player_add(attacker, SP_DAMAGE, _damage);

	return score_damage_PlayerDamageHandle_NextLink(inflictor, attacker, _damage, deathtype, hitloc, force);
}

void(void) score_damage_init {
	if not(cvar("g_score_damage"))
		return;

	score_damage_PlayerDamageHandle_NextLink = GameHookChain_PlayerDamageHandle;
	GameHookChain_PlayerDamageHandle = score_damage_PlayerDamageHandle;
	SP_DAMAGE = score_register("damage", 0);
}
