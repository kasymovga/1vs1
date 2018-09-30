var void(entity spot) Clanarena_Spawn_NextLink;
void Clanarena_Spawn(entity spot) {
	Clanarena_Spawn_NextLink(spot);
	Roundbased_NeedCheckTeams();
	if not(Roundbased_Active)
	if not(Roundbased_RestartTime) {
		PlayerScore_Set(self, SP_STATUS, 0);
		return;
	}
	PlayerScore_Set(self, SP_STATUS, 1);
	PutObserverInServer(FALSE);
}

float Clanarena_DeathHandle(entity attacker, entity inflictor, float deathtype) {
	Roundbased_NeedCheckTeams();
	if (Roundbased_Active)
		PlayerScore_Set(self, SP_STATUS, 1);

	return FALSE;
}


var void(float killed) Clanarena_PlayerClear_NextLink;
void Clanarena_PlayerClear(float killed) {
	Roundbased_NeedCheckTeams();
	Clanarena_PlayerClear_NextLink(killed);
}

void Clanarena_Init_Shared(string gt) {
	Roundbased_Init(cvar(strcat("g_", gt, "_enddelay")), cvar(strcat("g_", gt, "_startdelay")));
	GameHook_DeathHandle = Clanarena_DeathHandle;
	Clanarena_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = Clanarena_PlayerClear;
	Clanarena_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = Clanarena_Spawn;
	ScoreInfo_SetLabel_PlayerScore(SP_STATUS, "status", 0);
}
