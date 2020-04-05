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


float GetPlayerColorForce(float i)
{
	if(!teamplay)
		return 0;
	else
		return (stof(getplayerkey(i, "colors")) & 15) + 1;
}

float GetPlayerColor(float i)
{
	entity pl = playerslots[i];
	if not(pl.gotscores) // unconnected
		return COLOR_SPECTATOR;
	else if(pl.team == COLOR_SPECTATOR)
		return COLOR_SPECTATOR;
	else if (teamplay)
		return pl.team;
	else
		return GetPlayerColorForce(i);
}

string GetPlayerName(float i)
{
	return ColorTranslateRGB(getplayerkey(i, "name"));
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
