string game_cvar_prefix;
string profile_cvar_prefix;
var float(string s) nogame_cvar;
var string(string s) nogame_cvar_string;
float cvar_mapped(string cvarname) {
	string s;
	s = strcat("mapvar_", cvarname);
	if (nogame_cvar_string(s) != "")
		cvarname = s;

	return nogame_cvar(cvarname);
}

string cvar_mapped_string(string cvarname) {
	string s;
	s = strcat("mapvar_", cvarname);
	if (nogame_cvar_string(s) != "")
		cvarname = s;

	return nogame_cvar_string(cvarname);
}

float game_cvar(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return nogame_cvar(cvarname);

	string s;
	if (profile_cvar_prefix != "") {
		s = strcat(profile_cvar_prefix, "_", game_cvar_prefix, "_", cvarname);
		if (nogame_cvar_string(s) != "")
			return nogame_cvar(s);

		s = strcat(profile_cvar_prefix, "_", cvarname);
		if (nogame_cvar_string(s) != "")
			return nogame_cvar(s);
	}
	s = strcat(game_cvar_prefix, "_", cvarname);
	if (nogame_cvar_string(s) != "")
		return nogame_cvar(s);

	return nogame_cvar(cvarname);
}

string game_cvar_string(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return nogame_cvar_string(cvarname);

	string s, val;
	if (profile_cvar_prefix != "") {
		s = strcat(profile_cvar_prefix, "_", game_cvar_prefix, "_", cvarname);
		val = nogame_cvar_string(s);
		if (val != "")
			return val;

		s = strcat(profile_cvar_prefix, "_", cvarname);
		val = nogame_cvar_string(s);
		if (val != "")
			return val;
	}
	s = strcat(game_cvar_prefix, "_", cvarname);
	val = nogame_cvar_string(s);
	if (val != "")
		return val;

	return nogame_cvar_string(cvarname);
}

float game_cvar_initialized;
void game_cvar_deinit() {
	if not(game_cvar_initialized)
		return;

	cvar = nogame_cvar;
	cvar_string = nogame_cvar_string;
	unzone_ifneeded(profile_cvar_prefix);

	game_cvar_initialized = 0;
}

void game_cvar_init(string profile) {
	if (game_cvar_initialized)
		game_cvar_deinit();

	nogame_cvar = cvar;
	nogame_cvar_string = cvar_string;
	game_cvar_prefix = MapInfo_String_FromType(MapInfo_CurrentGametype());
	profile_cvar_prefix = zone_ifneeded(profile);
	cvar = game_cvar;
	cvar_string = game_cvar_string;
	game_cvar_initialized = 1;
}
