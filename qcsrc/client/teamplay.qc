float teamplay;
float myteam;

float(float t, float d) team_index_def {
	switch(t) {
		case COLOR_TEAM1: return 1;
		case COLOR_TEAM2: return 2;
		case COLOR_TEAM3: return 3;
		case COLOR_TEAM4: return 4;
	}
	return d;
}


vector GetTeamRGB(float color)
{
	switch(color)
	{
	default: return '1 1 1';
	case COLOR_TEAM1: return '1 0 0'; // red
	case COLOR_TEAM2: return '0 0 1'; // blue
	case COLOR_TEAM3: return '1 1 0'; // yellow
	case COLOR_TEAM4: return '1 0 1'; // pink
	}
}

string GetTeamName(float color)
{
	switch(color)
	{
	default: return "Spectators";
	case COLOR_TEAM1: return "Red Team";
	case COLOR_TEAM2: return "Blue Team";
	case COLOR_TEAM3: return "Yellow Team";
	case COLOR_TEAM4: return "Pink Team";
	}
}
