float team_my;
float team_count_no_spectator;
entity team_list;
entity team_slots[17];    // 17 teams (including "spectator team")

entity team_alive_update_ent;
void(void) team_alive_update_draw {
	team_alive_red = 0;
	team_alive_blue = 0;
	team_alive_yellow = 0;
	team_alive_pink = 0;
	entity o;
	var .float score_status = scores[SP_STATUS_FIELD];
	for (o = player_list.sort_next; o; o = o.sort_next)
		if (o.team > 0)
		if not(o.score_status) {
			if (o.team == COLOR_TEAM1) team_alive_red++;
			else if (o.team == COLOR_TEAM2) team_alive_blue++;
			else if (o.team == COLOR_TEAM3) team_alive_yellow++;
			else if (o.team == COLOR_TEAM4) team_alive_pink++;
		}
	remove(self);
	team_alive_update_ent = NULL;
}

void(void) team_alive_update {
	if (team_alive_update_ent) return;
	team_alive_update_ent = spawn();
	team_alive_update_ent.draw = team_alive_update_draw;
}

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

	if (Team.team > 0 && Team.team != TEAM_COLOR_SPECTATOR) team_count_no_spectator++;
	Team.sort_next = team_list.sort_next;
	Team.sort_prev = team_list;
	if(team_list.sort_next)
		team_list.sort_next.sort_prev = Team;

	team_list.sort_next = Team;
	return TRUE;
}

entity(float Team, float add) team_get {
	float num;
	entity tm;
	num = (Team == TEAM_COLOR_SPECTATOR) ? 16 : Team;
	if(team_slots[num])
		return team_slots[num];

	if not(add)
		return NULL;

	tm = spawn();
	tm.team = Team;
	team_slots[num] = tm;
	team_register(tm);
	return tm;
}

.float has_team;
float(entity o, float Team) team_set {
	entity tm;
	if (Team != -1)
	if (team_mode || Team)
	if not(team_get(Team, FALSE))
		Team = TEAM_COLOR_SPECTATOR;

	if (Team == -1) {
		if (o.has_team) {
			//print("(DISCONNECT) leave team ", ftos(o.team), "\n");
			tm = team_get(o.team, FALSE);
			tm.team_size -= 1;
			o.has_team = 0;
			o.team = TEAM_COLOR_SPECTATOR;
			return TRUE;
		}
	} else {
		if not(o.has_team) {
			//print("(CONNECT) enter team ", ftos(o.team), "\n");
			o.has_team = 1;
		} else if (Team != o.team) {
			tm = team_get(o.team, FALSE);
			tm.team_size -= 1;
		} else
			return FALSE;

		tm = team_get(Team, FALSE);
		if not(tm) {
			tm = team_get(TEAM_COLOR_SPECTATOR, FALSE);
			Team = TEAM_COLOR_SPECTATOR;
		}
		o.team = Team;
		tm.team_size += 1;
		return TRUE;
	}
	return FALSE;
}
