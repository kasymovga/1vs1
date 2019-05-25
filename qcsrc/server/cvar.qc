string cvar_game_prefix;
string cvar_profile_prefix;
var float(string s) cvar_orig;
var string(string s) cvar_string_orig;

float cvar_ext(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return cvar_orig(cvarname);

	string s;
	if (cvar_profile_prefix != "") {
		s = strcat(cvar_profile_prefix, "_", cvar_game_prefix, "_", cvarname);
		if (cvar_string_orig(s) != "")
			return cvar_orig(s);

		s = strcat(cvar_profile_prefix, "_", cvarname);
		if (cvar_string_orig(s) != "")
			return cvar_orig(s);
	}
	s = strcat(cvar_game_prefix, "_", cvarname);
	if (cvar_string_orig(s) != "")
		return cvar_orig(s);

	return cvar_orig(cvarname);
}

string cvar_string_ext(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return cvar_string_orig(cvarname);

	string s, val;
	if (cvar_profile_prefix != "") {
		s = strcat(cvar_profile_prefix, "_", cvar_game_prefix, "_", cvarname);
		val = cvar_string_orig(s);
		if (val != "")
			return val;

		s = strcat(cvar_profile_prefix, "_", cvarname);
		val = cvar_string_orig(s);
		if (val != "")
			return val;
	}
	s = strcat(cvar_game_prefix, "_", cvarname);
	val = cvar_string_orig(s);
	if (val != "")
		return val;

	return cvar_string_orig(cvarname);
}

float cvar_initialized;
void cvar_deinit() {
	if not(cvar_initialized)
		return;

	cvar = cvar_orig;
	cvar_string = cvar_string_orig;
	unzone_ifneeded(cvar_profile_prefix);
	cvar_initialized = 0;
}

void cvar_init(string profile) {
	if (cvar_initialized)
		cvar_deinit();

	cvar_orig = cvar;
	cvar_string_orig = cvar_string;
	cvar_game_prefix = GametypeNameFromType(MapInfo_CurrentGametype());
	cvar_profile_prefix = zone_ifneeded(profile);
	cvar = cvar_ext;
	cvar_string = cvar_string_ext;
	cvar_initialized = 1;
}

