var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) score_damage_player_damage_handle_next;
float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) score_damage_player_damage_handle {
	if (attacker.scorekeeper)
	if (!team_mode || attacker.team != self.team)
	if (attacker != self)
	if (deathtype != WEP_PORTO)
		score_player_add(attacker, SP_DAMAGE, _damage);

	return score_damage_player_damage_handle_next(inflictor, attacker, _damage, deathtype, hitloc, force);
}

void(void) score_damage_init {
	if not(cvar("g_score_damage"))
		return;

	score_damage_player_damage_handle_next = gamehook_chain_player_damage_handle;
	gamehook_chain_player_damage_handle = score_damage_player_damage_handle;
	SP_DAMAGE = score_register("damage", 0);
}
