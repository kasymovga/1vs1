float single_level_finished;

void Single_EndLevel() {
	single_level_finished = TRUE;
	campaign_won = TRUE;
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
	entity e = spawn();
	e.targetname = "endlevel";
	e.use = Single_EndLevel;
}
