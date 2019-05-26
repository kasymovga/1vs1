float Freeze_FragLimitOverride() {
	return cvar("g_freeze_winlimit");
}

void Freeze_Init_Delayed()
{
	scores_generic();
	Freeze_Init_Shared("freeze");
}

void Freeze_Init()
{
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_BotChooseRole = havocbot_chooserole_ft;
	GameHook_FragLimitOverride = Freeze_FragLimitOverride;
	SetTeamCount(bound(2, cvar("g_freeze_teams"), 4));
	entity_initialize(world, Freeze_Init_Delayed, INITPRIO_GAMETYPE);
}
