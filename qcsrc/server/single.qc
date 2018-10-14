float single_level_finished;

void Single_EndLevel() {
	single_level_finished = TRUE;
	campaign_won = TRUE;
}

float Single_WinningCondition() {
	return single_level_finished;
}

string Single_GameOverMessageMod(string s) {
	if (campaign_won)
		return "^2Level finished";
	else
		return "^1Game over";
}

float Single_Return0() {
	return 0;
}

float Single_DeathHandle() {
	single_level_finished = TRUE;
	campaign_won = FALSE;
	return FALSE;
}

void Single_Init() {
	GameHook_WinningCondition = Single_WinningCondition;
	GameHook_GameOverMessageMod = Single_GameOverMessageMod;
	GameHook_FragLimitOverride = Single_Return0;
	GameHook_TimeLimitOverride = Single_Return0;
	GameHook_LeadLimitOverride = Single_Return0;
	GameHook_DeathHandle = Single_DeathHandle;
	entity e = spawn();
	e.targetname = "endlevel";
	e.use = Single_EndLevel;
}
