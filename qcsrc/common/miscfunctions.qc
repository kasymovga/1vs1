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

float approach_angle(float v, float t, float d) {
	while (v - t < -180)
		v += 360;

	while (v - t > 180)
		v -= 360;

	return approach(v, t, d);
}

string car(string s)
{
	float o;
	o = strstrofs(s, " ", 0);
	if(o < 0)
		return s;
	return substring(s, 0, o);
}
string cdr(string s)
{
	float o;
	o = strstrofs(s, " ", 0);
	if(o < 0)
		return string_null;
	return substring(s, o + 1, strlen(s) - (o + 1));
}

void backtrace(string msg)
{
    float dev, war;
    dev = cvar("developer");
    war = cvar("prvm_backtraceforwarnings");
    cvar_set("developer", "1");
    cvar_set("prvm_backtraceforwarnings", "1");
    print("\n");
    print("--- CUT HERE ---\nWARNING: ");
    print(msg);
    print("\n");
    remove(world); // isn't there any better way to cause a backtrace?
    print("\n--- CUT UNTIL HERE ---\n");
    cvar_set("developer", ftos(dev));
    cvar_set("prvm_backtraceforwarnings", ftos(war));
}
