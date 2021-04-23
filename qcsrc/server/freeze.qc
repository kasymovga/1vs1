void Freeze_Init_Delayed()
{
	score_generic();
	Freeze_Init_Shared("ft");
}

void Freeze_Init()
{
	gamehook_score_winning_condition_countdown = stub_score_winning_condition_countdown;
	gamehook_havocbot_role_choose = freeze_role_choose;
	team_teams_set_count(bound(2, cvar("g_ft_teams"), 4));
	entity_initialize(world, Freeze_Init_Delayed, INITPRIO_GAMETYPE);
}
