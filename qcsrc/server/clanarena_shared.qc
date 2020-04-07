var void(entity spot) Clanarena_Spawn_NextLink;
void Clanarena_Spawn(entity spot) {
	Clanarena_Spawn_NextLink(spot);
	Roundbased_NeedCheckTeams();
	if not(Roundbased_Active)
	if not(Roundbased_RestartTime) {
		score_player_set(self, SP_STATUS, 0);
		return;
	}
	score_player_set(self, SP_STATUS, 1);
	spectator_observer_spawn(FALSE);
}

float Clanarena_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	Roundbased_NeedCheckTeams();
	if (Roundbased_Active)
		score_player_set(self, SP_STATUS, 1);

	return FALSE;
}


var void(float killed) Clanarena_PlayerClear_NextLink;
void Clanarena_PlayerClear(float killed) {
	Roundbased_NeedCheckTeams();
	Clanarena_PlayerClear_NextLink(killed);
}

void Clanarena_Init_Shared(string gt) {
	Roundbased_Init(cvar(strcat("g_", gt, "_enddelay")), cvar(strcat("g_", gt, "_startdelay")));
	gamehook_player_death_handle = Clanarena_DeathHandle;
	Clanarena_PlayerClear_NextLink = gamehook_chain_player_clear;
	gamehook_chain_player_clear = Clanarena_PlayerClear;
	Clanarena_Spawn_NextLink = gamehook_chain_spawn;
	gamehook_chain_spawn = Clanarena_Spawn;
	SP_STATUS = score_register("status", 0);
}
