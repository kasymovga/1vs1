float Freeze_FragLimitOverride() {
	return cvar("g_freeze_winlimit");
}

void Freeze_Init_Delayed()
{
	ScoreRules_generic();
	Freeze_Init_Shared("freeze");
}

void Freeze_Init()
{
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_BotChooseRole = havocbot_chooserole_ft;
	GameHook_FragLimitOverride = Freeze_FragLimitOverride;
	InitializeEntity(world, Freeze_Init_Delayed, INITPRIO_GAMETYPE);
}
