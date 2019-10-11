#define CVAR_INHERITANCE_DEEP 4
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
	if(cvar_changes)
		strunzone(cvar_changes);

	cvar_changes = string_null;
	h = buf_create();
	buf_cvarlist(h, "", "_"); // exclude all _ cvars as they are temporary
	n = buf_getsize(h);

	for(i = 0; i < n; ++i) {
		k = bufstr_get(h, i);
		v = cvar_string_builtin(k);
		d = cvar_defstring(k);
		if(v == d)
			continue;

#define BADPREFIX(p) if(substring(k, 0, strlen(p)) == p) continue
#define BADCVAR(p) if(k == p) continue
		// internal
		BADCVAR("gamecfg");
		BADCVAR("g_configversion");
		BADCVAR("halflifebsp");
		BADCVAR("slowmo");
		BADPREFIX("sv_mapformat");
		// client
		BADPREFIX("bgm");
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
		if(strlen(cvar_changes) > 16384) {
			cvar_changes = "// too many settings have been changed to show them here\n";
			break;
		}
	}
	buf_del(h);
	if(cvar_changes == "")
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
void(void) cvar_deinit {
	if not(cvar_initialized)
		return;

	float i;
	for (i = 1; i < CVAR_INHERITANCE_DEEP; i++) {
		str_unzone_ifneeded(cvar_profile_prefix[i]);
		str_unzone_ifneeded(cvar_game_prefix[i]);
	}
	cvar = cvar_orig;
	cvar_string = cvar_string_orig;
	str_unzone_ifneeded(cvar_profile_prefix);
	cvar_initialized = 0;
}

void(string profile) cvar_init {
	if (cvar_initialized)
		cvar_deinit();

	float i;
	string s;
	cvar_orig = cvar;
	cvar_string_orig = cvar_string;
	cvar_game_prefix[0] = gametype_name(MapInfo_CurrentGametype());
	s = strcat(cvar_game_prefix[0], "_inherit");
	string game_inherit = cvar_string_orig(s);
	cvar_game_prefix_len = 1;
	for (i = 1; i < CVAR_INHERITANCE_DEEP; i++) {
		s = str_car(game_inherit);
		if (s == "")
			break;

		cvar_game_prefix[i] = strzone(s);
		cvar_game_prefix_len++;
		game_inherit = str_cdr(game_inherit);
	}
	cvar_profile_prefix_len = 0;
	if (profile != "") {
		cvar_profile_prefix[0] = strzone(profile);
		cvar_profile_prefix_len = 1;
		string profile_inherit = cvar_string_orig(strcat(profile, "_inherit"));
		for (i = 1; i < CVAR_INHERITANCE_DEEP; i++) {
			s = str_car(profile_inherit);
			if (s == "")
				break;

			cvar_profile_prefix[i] = strzone(s);
			cvar_profile_prefix_len++;
			profile_inherit = str_cdr(profile_inherit);
		}
	}
	cvar = cvar_ext;
	cvar_string = cvar_string_ext;
	cvar_initialized = 1;
}

void(void) cvar_preinit {
	cvar = cvar_builtin;
	cvar_string = cvar_string_builtin;
	cvar_set = cvar_set_builtin;
}
