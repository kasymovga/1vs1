void Freeze_Init_Delayed()
{
	score_generic();
	Freeze_Init_Shared("ft");
}

void Freeze_Init()
{
	gamehook_WinCountDown = stub_WinCountDown;
	gamehook_BotChooseRole = freeze_role_choose;
	team_teams_set_count(bound(2, cvar("g_ft_teams"), 4));
	entity_initialize(world, Freeze_Init_Delayed, INITPRIO_GAMETYPE);
}
