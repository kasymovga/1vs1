void(void) freeze_init_delayed {
	score_generic();
	freeze_shared_init("ft");
}

void(void) freeze_init {
	plugin_score_winning_condition_countdown = stub_score_winning_condition_countdown;
	plugin_havocbot_role_choose = freeze_role_choose;
	team_teams_set_count(bound(2, cvar("g_ft_teams"), 4));
	entity_initialize(world, freeze_init_delayed, INITPRIO_GAMETYPE);
}
