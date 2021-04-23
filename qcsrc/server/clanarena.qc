float g_ca_healthrotpause_on_damage;

float(entity attacker, entity targ, float f) clanarena_HandleFrags {
	if (Roundbased_Active) {
		score_player_add(attacker, SP_SCORE, f);
	}
	return 0;
}

var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) clanarena_player_damage_handle_NextLink;
float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) clanarena_player_damage_handle {
	if (attacker.flags & FL_CLIENT)
	if (deathtype != WEP_PORTO)
	if (attacker.team != self.team) {
		score_player_add(attacker, SP_SCORE, _damage / 10);
		attacker.pauserothealth_finished = time + g_ca_healthrotpause_on_damage;
		self.pauserothealth_finished = time + g_ca_healthrotpause_on_damage;
	}
	return clanarena_player_damage_handle_NextLink(inflictor, attacker, _damage, deathtype, hitloc, force);
}

void(void) clanarena_init {
	CVAR_CACHE(g_ca_healthrotpause_on_damage);
	team_teams_set_count(bound(2, cvar("g_ca_teams"), 4));
	gamehook_score_give_frag_mod = clanarena_HandleFrags;
	clanarena_player_damage_handle_NextLink = gamehook_chain_player_damage_handle;
	gamehook_chain_player_damage_handle = clanarena_player_damage_handle;
	gamehook_WinCountDown = stub_WinCountDown;
	score_generic();
	clanarena_shared_init("ca");
}
