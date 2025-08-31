void(void) tdm_init {
	team_teams_set_count(bound(2, cvar("g_tdm_teams"), 4));
}
