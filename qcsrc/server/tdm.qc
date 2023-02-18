void(void) tdm_delayedinit {
	// if no teams are found, spawn defaults
	entity e;
	for (e = find(world, classname, "tdm_team"); e; e = find(e, classname, "tdm_team")) {
		team_teams_set_allowed(e.team);
	}
	team_teams_allowed(world);
	float numteams = cvar("g_tdm_teams");
	if (team_teams < 2 || (numteams > 1 && numteams != team_teams)) {
		team_teams_set_count(0);
		numteams = bound(2, numteams, 4);
		team_teams_set_allowed(COLOR_TEAM1);
		team_teams_set_allowed(COLOR_TEAM2);
		if (numteams > 2) team_teams_set_allowed(COLOR_TEAM3);
		if (numteams > 3) team_teams_set_allowed(COLOR_TEAM4);
	}
}

void(void) tdm_init {
	entity_initialize(world, tdm_delayedinit, INITPRIO_GAMETYPE);
}
