#define CVAR_INHERITANCE_DEEP 8
string cvar_game_prefix[CVAR_INHERITANCE_DEEP];
float cvar_game_prefix_len;
string cvar_profile_prefix[CVAR_INHERITANCE_DEEP];
float cvar_profile_prefix_len;
var float(string s) cvar_orig;
var string(string s) cvar_string_orig;

void(void) cvar_changes_init {
	float h;
	string k, v, d;
	float n, i;
	if (cvar_changes)
		strunzone(cvar_changes);

	cvar_changes = NULL;
	h = buf_create();
	buf_cvarlist(h, "", "_"); // exclude all _ cvars as they are temporary
	n = buf_getsize(h);
	for (i = 0; i < n; ++i) {
		k = bufstr_get(h, i);
		v = builtin_cvar_string(k);
		d = cvar_defstring(k);
		if (v == d)
			continue;

#define BADPREFIX(p) if (substring(k, 0, strlen(p)) == p) continue
#define BADCVAR(p) if (k == p) continue
		// internal
		BADCVAR("gamecfg");
		BADCVAR("g_configversion");
		BADCVAR("halflifebsp");
		BADCVAR("slowmo");
		BADPREFIX("sv_mapformat");
		// client
		BADCVAR("fov");
		BADPREFIX("bgm");
		BADPREFIX("date_");
		BADPREFIX("amb");
		BADPREFIX("snd");
		BADPREFIX("show");
		BADPREFIX("scr");
		BADPREFIX("sens");
		BADPREFIX("cl_");
		BADPREFIX("conn");
		BADPREFIX("cros");
		BADPREFIX("cs");
		BADPREFIX("cu");
		BADPREFIX("cvar");
		BADPREFIX("con");
		BADPREFIX("ch");
		BADPREFIX("g_campaign");
		BADPREFIX("gl_");
		BADPREFIX("joy");
		BADPREFIX("m");
		BADPREFIX("net_slist_");
		BADPREFIX("r_");
		BADPREFIX("sbar_");
		BADPREFIX("hud_");
		BADPREFIX("userbind");
		BADPREFIX("v");
		BADPREFIX("mod");
		// private
		BADPREFIX("g_ban_");
		BADPREFIX("g_chat_flood_");
		BADPREFIX("g_chat_forbidden_");
		BADPREFIX("g_voice_flood_");
		BADPREFIX("rcon_");
		BADPREFIX("settemp_");
		BADPREFIX("sv_allowdownloads_");
		BADPREFIX("sv_autodemo");
		BADPREFIX("sv_curl_");
		BADPREFIX("sv_logscore_");
		BADPREFIX("sv_master");
		BADPREFIX("sv_world");
		BADPREFIX("sv_infomessage");
		BADPREFIX("sv_retard_");
		BADPREFIX("sv_player_mute_namepattern");
		BADPREFIX("sv_ircbot");
		BADPREFIX("sv_udpchat");
		BADCVAR("g_banned_list");
		BADCVAR("log_dest_udp");
		BADCVAR("log_file");
		BADCVAR("savedgamecfg");
		BADCVAR("sv_heartbeatperiod");
		BADCVAR("sv_vote_master_password");
		BADCVAR("sys_colortranslation");
		BADCVAR("sys_first_run");
		BADCVAR("sys_specialcharactertranslation");
		BADCVAR("timestamps");
		BADCVAR("sv_progs");
		BADCVAR("sv_sysinfo_checker");
		// engine physics cvar (overrides by game)
		BADCVAR("sv_stepheight");
		BADCVAR("sv_gravity");
		BADCVAR("sv_maxairspeed");
		BADCVAR("sv_maxspeed");
		BADCVAR("sv_friction");
		BADCVAR("sv_accelerate");
		BADPREFIX("sv_airaccel");
		BADCVAR("sv_stopspeed");
		BADCVAR("sv_airstopaccelerate");
		BADCVAR("sv_airstrafeaccelerate");
		BADCVAR("sv_maxairstrafespeed");
		BADCVAR("sv_aircontrol");
		BADPREFIX("sv_warsowbunny");
		BADCVAR("sv_jumpvelocity");
		BADCVAR("sv_gameplayfix_q2airaccelerate");
		BADPREFIX("sv_water");
		// mapinfo
		BADCVAR("timelimit");
		BADCVAR("fraglimit");
		// long
		BADCVAR("hostname");
		BADCVAR("g_maplist");
		BADCVAR("sv_motd");
#undef BADPREFIX
#undef BADCVAR
		cvar_changes = strcat(cvar_changes, k, " \"", v, "\" // \"", d, "\"\n");
		if (strlen(cvar_changes) > 16384) {
			cvar_changes = "// too many settings have been changed to show them here\n";
			break;
		}
	}
	buf_del(h);
	if (cvar_changes == "")
		cvar_changes = "// this server runs at default settings\n";
	else
		cvar_changes = strcat("// this server runs at modified settings:\n", cvar_changes);

	cvar_changes = strzone(cvar_changes);
}

float(string cvarname) cvar_ext {
	if (substring(cvarname, 0, 2) != "g_")
		return cvar_orig(cvarname);

	string s;
	float i, j;
	s = strcat("force_", "_", cvarname);
	if (cvar_string_orig(s) != "")
		return cvar_orig(s);

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

string(string cvarname) cvar_string_ext {
	if (substring(cvarname, 0, 2) != "g_")
		return cvar_string_orig(cvarname);

	string s, val;
	float i, j;
	if ((s = cvar_string(strcat("force_", "_", cvarname))) != "")
		return s;

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

void(string profile) cvar_profile_add {
	float i;
	string s;
	if (cvar_profile_prefix_len == CVAR_INHERITANCE_DEEP)
		return;

	if ((s = cvar_string_orig(strcat(profile, "_dlc"))) != "") {
		string dlc;
		while (s != "") {
			dlc = str_car(s);
			s = str_cdr(s);
			if (dlc != "")
				dlc_require(dlc);
		}
	}
	for (i = 0; i < cvar_profile_prefix_len; i++) {
		s = cvar_profile_prefix[i];
		if (s == profile)
			return;
	}
	cvar_profile_prefix[cvar_profile_prefix_len] = strzone(profile);
	cvar_profile_prefix_len++;
	string inherit = cvar_string_orig(strcat(profile, "_inherit"));
	while (inherit != "") {
		s = str_car(inherit);
		inherit = str_cdr(inherit);
		if (s != "")
			cvar_profile_add(s);
	}
}

void(string _game) cvar_game_add {
	float i;
	string s;
	if (cvar_game_prefix_len == CVAR_INHERITANCE_DEEP)
		return;

	for (i = 0; i < cvar_game_prefix_len; i++) {
		s = cvar_game_prefix[i];
		if (s == _game)
			return;
	}
	cvar_game_prefix[cvar_game_prefix_len] = strzone(_game);
	cvar_game_prefix_len++;
	string inherit = cvar_string_orig(strcat(_game, "_inherit"));
	while (inherit != "") {
		s = str_car(inherit);
		inherit = str_cdr(inherit);
		if (s != "")
			cvar_game_add(s);
	}
}

float(string profile) cvar_profile_presents {
	float i;
	string s;
	for (i = 0; i < cvar_profile_prefix_len; i++) {
		s = cvar_profile_prefix[i];
		if (s == profile)
			return TRUE;
	}
	return FALSE;
}

void(string profile) cvar_init {
	string s;
	cvar_orig = cvar;
	cvar_string_orig = cvar_string;
	cvar_profile_add("force");
	profile = strreplace("+", " ", profile);
	cvar_game_add(game_type_name(game_type_current()));
	while (profile != "") {
		s = str_car(profile);
		profile = str_cdr(profile);
		if (s != "")
			cvar_profile_add(s);
	}
	cvar = cvar_ext;
	cvar_string = cvar_string_ext;
}

void(void) cvar_preinit {
	cvar = builtin_cvar;
	cvar_string = builtin_cvar_string;
	cvar_set = builtin_cvar_set;
}
