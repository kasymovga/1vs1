var void(entity spot) clanarena_shared_spawn_next;
void clanarena_shared_spawn(entity spot) {
	clanarena_shared_spawn_next(spot);
	Roundbased_NeedCheckTeams();
	if not(Roundbased_Active)
	if not(Roundbased_RestartTime) {
		score_player_set(self, SP_STATUS, 0);
		return;
	}
	score_player_set(self, SP_STATUS, 1);
	spectator_observer_spawn(FALSE);
}

float clanarena_shared_death_handle(entity attacker, entity inflictor, float deathtype) {
	Roundbased_NeedCheckTeams();
	if (Roundbased_Active)
		score_player_set(self, SP_STATUS, 1);

	return FALSE;
}

var void(float killed) clanarena_shared_player_clear_next;
void clanarena_shared_player_clear(float killed) {
	Roundbased_NeedCheckTeams();
	clanarena_shared_player_clear_next(killed);
}

void(string gt) clanarena_shared_init {
	Roundbased_Init(cvar(strcat("g_", gt, "_enddelay")), cvar(strcat("g_", gt, "_startdelay")));
	gamehook_player_death_handle = clanarena_shared_death_handle;
	clanarena_shared_player_clear_next = gamehook_chain_player_clear;
	gamehook_chain_player_clear = clanarena_shared_player_clear;
	clanarena_shared_spawn_next = gamehook_chain_spawn;
	gamehook_chain_spawn = clanarena_shared_spawn;
	SP_STATUS = score_register("status", 0);
}
