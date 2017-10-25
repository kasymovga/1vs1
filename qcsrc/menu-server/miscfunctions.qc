string game_cvar_prefix;
var float(string s) nogame_cvar;
var string(string s) nogame_cvar_string;
float game_cvar(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return nogame_cvar(cvarname);

	string s = strcat(game_cvar_prefix, "_", cvarname);
	if (nogame_cvar_string(s) != "")
		return nogame_cvar(s);

	return nogame_cvar(cvarname);
}

string game_cvar_string(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return nogame_cvar_string(cvarname);

	string s = strcat(game_cvar_prefix, "_", cvarname);
	if (nogame_cvar_string(s) != "")
		return nogame_cvar_string(s);

	return nogame_cvar_string(cvarname);
}

float game_cvar_initialized;
void game_cvar_deinit() {
	if not(game_cvar_initialized)
		return;

	cvar = nogame_cvar;
	cvar_string = nogame_cvar_string;
	game_cvar_initialized = 0;
}

void game_cvar_init() {
	if (game_cvar_initialized)
		game_cvar_deinit();

	nogame_cvar = cvar;
	nogame_cvar_string = cvar_string;
	game_cvar_prefix = MapInfo_String_FromType(MapInfo_CurrentGametype());
	cvar = game_cvar;
	cvar_string = game_cvar_string;
	game_cvar_initialized = 1;
}
