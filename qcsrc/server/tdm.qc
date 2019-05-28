float tdm_FragLimitOverride() {
	return cvar("g_tdm_fraglimit");
}

void(void) tdm_delayedinit {
	// if no teams are found, spawn defaults
	entity e;
	for (e = find(world, classname, "tdm_team"); e; e = find(e, classname, "tdm_team")) {
		SetAllowedTeam(e.team);
	}
	teams_check_allowed(world);
	float teams_override = cvar("g_tdm_teams_override");
	if (c1 + c2 + c3 + c4 < -2 || teams_override > 1) {
		SetTeamCount(0);
		float numteams = teams_override;
		if(numteams < 2)
			numteams = cvar("g_tdm_teams");

		numteams = bound(2, numteams, 4);
		SetAllowedTeam(COLOR_TEAM1);
		SetAllowedTeam(COLOR_TEAM2);
		if (numteams > 2) SetAllowedTeam(COLOR_TEAM3);
		if (numteams > 3) SetAllowedTeam(COLOR_TEAM4);
	}
}

void(void) tdm_init {
	entity_initialize(world, tdm_delayedinit, INITPRIO_GAMETYPE);
}
