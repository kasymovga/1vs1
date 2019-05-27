#define CVAR_INHERITANCE_DEEP 4
string cvar_game_prefix[CVAR_INHERITANCE_DEEP];
float cvar_game_prefix_len;
string cvar_profile_prefix[CVAR_INHERITANCE_DEEP];
float cvar_profile_prefix_len;
var float(string s) cvar_orig;
var string(string s) cvar_string_orig;

float cvar_ext(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return cvar_orig(cvarname);

	string s;
	float i, j;
	for (i = 0; i < cvar_profile_prefix_len; i++) {
		for (j = 0; j < cvar_game_prefix_len; j++) {
			s = strcat(cvar_profile_prefix[i], "_", cvar_game_prefix[j], "_", cvarname);
			if (cvar_string_orig(s) != "")
				return cvar_orig(s);
		}
		s = strcat(cvar_profile_prefix[i], "_", cvarname);
		if (cvar_string_orig(s) != "")
			return cvar_orig(s);
	}
	for (j = 0; j < cvar_game_prefix_len; j++) {
		s = strcat(cvar_game_prefix[j], "_", cvarname);
		if (cvar_string_orig(s) != "")
			return cvar_orig(s);
	}
	return cvar_orig(cvarname);
}

string cvar_string_ext(string cvarname) {
	if (substring(cvarname, 0, 2) != "g_")
		return cvar_string_orig(cvarname);

	string s, val;
	float i, j;
	for (i = 0; i < cvar_profile_prefix_len; i++) {
		for (j = 0; j < cvar_game_prefix_len; j++) {
			s = strcat(cvar_profile_prefix[i], "_", cvar_game_prefix[j], "_", cvarname);
			val = cvar_string_orig(s);
			if (val != "")
				return val;
		}
		s = strcat(cvar_profile_prefix[i], "_", cvarname);
		val = cvar_string_orig(s);
		if (val != "")
			return val;
	}
	for (j = 0; j < cvar_game_prefix_len; j++) {
		s = strcat(cvar_game_prefix[j], "_", cvarname);
		val = cvar_string_orig(s);
		if (val != "")
			return val;
	}
	return cvar_string_orig(cvarname);
}

float cvar_initialized;
void cvar_deinit() {
	if not(cvar_initialized)
		return;

	float i;
	for (i = 1; i < CVAR_INHERITANCE_DEEP; i++) {
		unzone_ifneeded(cvar_profile_prefix[i]);
		unzone_ifneeded(cvar_game_prefix[i]);
	}
	cvar = cvar_orig;
	cvar_string = cvar_string_orig;
	unzone_ifneeded(cvar_profile_prefix);
	cvar_initialized = 0;
}

void cvar_init(string profile) {
	if (cvar_initialized)
		cvar_deinit();

	float i;
	string s;
	cvar_orig = cvar;
	cvar_string_orig = cvar_string;
	cvar_game_prefix[0] = GametypeNameFromType(MapInfo_CurrentGametype());
	s = strcat(cvar_game_prefix[0], "_inherit");
	string game_inherit = cvar_string_orig(s);
	cvar_game_prefix_len = 1;
	for (i = 1; i < CVAR_INHERITANCE_DEEP; i++) {
		s = car(game_inherit);
		if (s == "")
			break;

		cvar_game_prefix[i] = strzone(s);
		cvar_game_prefix_len++;
		game_inherit = cdr(game_inherit);
	}
	cvar_profile_prefix_len = 0;
	if (profile != "") {
		cvar_profile_prefix[0] = strzone(profile);
		cvar_profile_prefix_len = 1;
		string profile_inherit = cvar_string_orig(strcat(profile, "_inherit"));
		for (i = 1; i < CVAR_INHERITANCE_DEEP; i++) {
			s = car(profile_inherit);
			if (s == "")
				break;

			cvar_profile_prefix[i] = strzone(s);
			cvar_profile_prefix_len++;
			profile_inherit = cdr(profile_inherit);
		}
	}
	cvar = cvar_ext;
	cvar_string = cvar_string_ext;
	cvar_initialized = 1;
}

