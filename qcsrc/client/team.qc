float team_my;
entity team_list;

float(float t, float d) team_index_def {
	switch(t) {
		case COLOR_TEAM1: return 1;
		case COLOR_TEAM2: return 2;
		case COLOR_TEAM3: return 3;
		case COLOR_TEAM4: return 4;
	}
	return d;
}


vector(float color) team_rgb {
	switch(color)
	{
	default: return '1 1 1';
	case COLOR_TEAM1: return '1 0 0'; // red
	case COLOR_TEAM2: return '0 0 1'; // blue
	case COLOR_TEAM3: return '1 1 0'; // yellow
	case COLOR_TEAM4: return '1 0 1'; // pink
	}
}

float(entity Team) team_register {
	entity tm;
	for(tm = team_list.sort_next; tm; tm = tm.sort_next)
		if(tm == Team)
			error("Team already registered!");

	Team.sort_next = team_list.sort_next;
	Team.sort_prev = team_list;
	if(team_list.sort_next)
		team_list.sort_next.sort_prev = Team;

	team_list.sort_next = Team;
	return true;
}

entity(float Team, float add) team_get {
	float num;
	entity tm;
	num = (Team == COLOR_SPECTATOR) ? 16 : Team;
	if(teamslots[num])
		return teamslots[num];

	if not(add)
		return NULL;

	tm = spawn();
	tm.team = Team;
	teamslots[num] = tm;
	team_register(tm);
	return tm;
}

