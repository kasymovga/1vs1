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

.float has_team;
float(entity o, float Team) team_set {
	entity tm;
	if (Team != -1)
	if (team_mode || Team)
	if not(team_get(Team, false))
		Team = COLOR_SPECTATOR;

	if (Team == -1) {
		if (o.has_team) {
			//print("(DISCONNECT) leave team ", ftos(o.team), "\n");
			tm = team_get(o.team, false);
			tm.team_size -= 1;
			o.has_team = 0;
			return TRUE;
		}
	} else {
		if not(o.has_team) {
			//print("(CONNECT) enter team ", ftos(o.team), "\n");
			o.has_team = 1;
		} else if (Team != o.team) {
			tm = team_get(o.team, false);
			tm.team_size -= 1;
		} else
			return FALSE;

		tm = team_get(Team, false);
		if not(tm) {
			tm = team_get(COLOR_SPECTATOR, false);
			Team = COLOR_SPECTATOR;
		}
		o.team = Team;
		tm.team_size += 1;
		return TRUE;
	}
	return FALSE;
}
