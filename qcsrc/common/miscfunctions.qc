string zone_ifneeded(string s) {
	if (s != "")
		return strzone(s);

	return "";
}

string cvar_string_zone_ifneeded(string cvar_name) {
	return zone_ifneeded(cvar_string(cvar_name));
}

void unzone_ifneeded(string s) {
	if (s != "")
		strunzone(s);
}

float fexists(string path) {
	float f = fopen(path, FILE_READ);
	if (f < 0)
		return FALSE;

	fclose(f);
	return TRUE;
}

float approach(float v, float t, float d) {
	if(v < t) {
		v += d;
		if(v > t)
			return t;
	} else if(v > t) {
		v -= d;
		if(v < t)
			return t;
	}
	return v;
}

float TeamColorSkin(float t) {
    switch(t) {
        case COLOR_TEAM1:   return 1; break;
        case COLOR_TEAM2:   return 2; break;
        case COLOR_TEAM3:   return 3; break;
        case COLOR_TEAM4:   return 4; break;
    }
    return 0;
}

float fexists(string f)
{
    float fh;
    fh = fopen(f, FILE_READ);
    if (fh < 0)
        return FALSE;
    fclose(fh);
    return TRUE;
}
