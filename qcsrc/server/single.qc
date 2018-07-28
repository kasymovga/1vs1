float single_level_finished;

void Single_EndLevel_Touch() {
	single_level_finished = TRUE;
	campaign_won = TRUE;
}

void spawnfunc_trigger_endlevel() {
	EXACTTRIGGER_INIT;
	self.touch = Single_EndLevel_Touch;
	self.use = Single_EndLevel_Touch;
}

float Single_WinningCondition() {
	return single_level_finished;
}

var void(entity) Single_Spawn_NextLink;
void Single_Spawn(entity spot) {
	reset_map(FALSE);
	Single_Spawn_NextLink(spot);
}

string Single_GameOverMessageMod(string s) {
	return "Level finished";
}

void Single_Init() {
	GameHook_WinningCondition = Single_WinningCondition;
	GameHook_GameOverMessageMod = Single_GameOverMessageMod;
	Single_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = Single_Spawn;
}
