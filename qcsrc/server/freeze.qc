float Freeze_FragLimitOverride() {
	return cvar("g_freeze_winlimit");
}

void Freeze_Init()
{
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = Freeze_FragLimitOverride;
	GameHook_BotChooseRole = havocbot_chooserole_ft;
	Freeze_Init_Shared("freeze");
	ScoreRules_basics(2, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
}
