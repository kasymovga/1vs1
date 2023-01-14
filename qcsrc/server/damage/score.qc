float DAMAGE_SCORE;
var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) damage_score_player_damage_handle_next;
float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) damage_score_player_damage_handle {
	if (attacker.scorekeeper)
	if (!team_mode || attacker.team != self.team)
	if (attacker != self)
	if (deathtype != WEAPON_PORTO)
		score_player_add(attacker, DAMAGE_SCORE, _damage);

	return damage_score_player_damage_handle_next(inflictor, attacker, _damage, deathtype, hitloc, force);
}

var void(void) damage_score_score_basics_end_next;
void(void) damage_score_score_basics_end {
	DAMAGE_SCORE = score_register("damage", 0);
	damage_score_score_basics_end_next();
}

void(void) damage_score_init {
	if not(cvar("g_score_damage"))
		return;

	damage_score_player_damage_handle_next = plugin_chain_player_damage_handle;
	plugin_chain_player_damage_handle = damage_score_player_damage_handle;
	damage_score_score_basics_end_next = plugin_chain_score_basics_end;
	plugin_chain_score_basics_end = damage_score_score_basics_end;
}
