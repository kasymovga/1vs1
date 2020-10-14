// --------------------------------------------------------------------------
// BEGIN REQUIRED CSQC FUNCTIONS
//include "main.qh"

string available_maps;
float available_maps_count;

void(float ignore) main_init_read;

// CSQC_Init : Called every time the CSQC code is initialized (essentially at map load)
// Useful for precaching things
void CSQC_Init(void)
{
	if (!cvar("con_chat"))
		cvar_set("con_chat", "5");
	else if (cvar("con_chat") > 99)
		cvar_set("con_chat", "0");

	read_cvars_init();
	if (file_exists("rexuiz.cfg")) {
		localcmd("\ncmd gameclient rexuiz\n");
	} else if (autocvar_autocvar_check) {
		localcmd("\ncmd gameclient nexuiz\n");
		if not(cvar("mod_alias_force_animated")) {
			localcmd("\nseta mod_alias_force_animated 1; r_restart\n");
		}
	} else {
		localcmd("\ncmd gameclient oldnexuiz\n");
		update_message("^3You play with really old Nexuiz client", 20);
	}
	if (cvar("cl_maxfps_alwayssleep")) {
		localcmd("\nseta cl_maxfps_alwayssleep 0\n");
	}
	if (cvar_string("sv_master2") == "")
	if (cvar_string("sv_masterextra1") == "") {
		localcmd("\nseta sv_master2 107.161.23.68\n");
	}
	if (cvar("cl_effects_lightningarc_segmentlength") == 24)
	if not(cvar("cl_effects_lightningarc_simple")) {
		cvar_set("cl_effects_lightningarc_segmentlength", "64");
		cvar_set("cl_effects_lightningarc_drift_start", "0.45");
		cvar_set("cl_effects_lightningarc_drift_end", "0.1");
		cvar_set("cl_effects_lightningarc_branchfactor_start", "0.25");
		cvar_set("cl_effects_lightningarc_branchfactor_add", "0.1");
	}
	float i;
	binddb = db_create();
	tempdb = db_create();
	net_compress_vector_init();
	crosshairdot_tex = "gfx/crosshair6";
	if (file_exists("gfx/crosshairdot") || file_exists("gfx/crosshairdot.png"))
		crosshairdot_tex = "gfx/crosshairdot";

	drawfont = 0;

	for(i = 0; i < 255; ++i)
		if(getplayerkey(i, "viewentity") == "")
			break;
	maxclients = i;
	registercmd("+button3");
	registercmd("-button3");
	registercmd("+button4");
	registercmd("-button4");
	registercmd("+showaccuracy");registercmd("-showaccuracy");

	registercvar("crosshair_supershotgun", "shotgun", CVAR_SAVE);
	registercvar("crosshair_supershotgun_size", "1", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_blue", "0", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_red", "1", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_green", "0.5", CVAR_SAVE);
	registercvar("crosshair_supershotgun_color_alpha", "1", CVAR_SAVE);
	registercvar("crosshair_zapper", "", CVAR_SAVE);
	registercvar("crosshair_zapper_size", "1", CVAR_SAVE);
	registercvar("crosshair_zapper_color_blue", "1", CVAR_SAVE);
	registercvar("crosshair_zapper_color_red", "0", CVAR_SAVE);
	registercvar("crosshair_zapper_color_green", "0.7", CVAR_SAVE);
	registercvar("crosshair_zapper_color_alpha", "1", CVAR_SAVE);
	registercvar("crosshair_axe", "", CVAR_SAVE);
	registercvar("crosshair_axe_size", "0.4", CVAR_SAVE);
	registercvar("crosshair_axe_color_red", "1", CVAR_SAVE);
	registercvar("crosshair_axe_color_green", "0.35", CVAR_SAVE);
	registercvar("crosshair_axe_color_blue", "0.2", CVAR_SAVE);
	registercvar("crosshair_axe_color_alpha", "0.75", CVAR_SAVE);
	registercvar("crosshair_dot_color", "1 1 1", CVAR_SAVE);
	registercvar("_menu_vote_string", "", 0);
	isdemo_flag = isdemo();

#ifndef CAMERATEST
	if(isdemo_flag)
	{
#endif
		registercmd("+forward");registercmd("-forward");
		registercmd("+back");registercmd("-back");
		registercmd("+moveup");registercmd("-moveup");
		registercmd("+movedown");registercmd("-movedown");
		registercmd("+moveright");registercmd("-moveright");
		registercmd("+moveleft");registercmd("-moveleft");
		registercmd("+roll_right");registercmd("-roll_right");
		registercmd("+roll_left");registercmd("-roll_left");
#ifndef CAMERATEST
	}
#endif
	registercvar("sbar_usecsqc", "1");
	registercvar("sbar_columns", "default", CVAR_SAVE);
	localcmd("alias +nadget2 +button9\n");
	localcmd("alias -nadget2 -button9\n");

	gametype = 0;
	Sbar_GameType_Init();

	// sbar_fields uses strunzone on the titles!
	for(i = 0; i < MAX_SBAR_FIELDS; ++i)
		sbar_title[i] = strzone("(null)");

	calledhooks = 0;

	team_list = spawn();
	player_list = spawn();

	team_get(COLOR_SPECTATOR, TRUE); // add specs first

	cvar_clientsettemp("_supports_weaponpriority", "1");
	weapon_register_weapons();
	waypointsprite_init();
	projectile_precache();
	gib_precache();
	casing_precache();
	damage_info_precache();
	WarpZone_Init();
	world_get_min_max(1); // try the CLEVER way first
	shortmapname = mapname;
	if (!strcasecmp(substring(shortmapname, 0, 5), "maps/"))
		shortmapname = substring(shortmapname, 5, strlen(shortmapname) - 5);

	if (!strcasecmp(substring(shortmapname, strlen(shortmapname) - 4, 4), ".bsp"))
		shortmapname = substring(shortmapname, 0, strlen(shortmapname) - 4);

	shortmapname = strzone(shortmapname);
	minimapname = strcat("gfx/", shortmapname, "_radar");
	if (precache_pic(minimapname) == "") {
		// but maybe we have a non-clever minimap
		minimapname = strcat("gfx/", shortmapname, "_mini");
		if (precache_pic(minimapname) == "")
			minimapname = ""; // FAIL
		else
			world_get_min_max(0); // load new texcoords
	}
	teamradar_init();
	minimapname = strzone(minimapname);
	ext_DP_CSQC_QUERYRENDERENTITY = checkextension("DP_CSQC_QUERYRENDERENTITY");
	ext_DP_RM_SETRENDERENTITY = checkextension("DP_RM_SETRENDERENTITY");
	csqc_entity_init();
	ui_con_width_height_set();
	sbar_font = FONT_USER+1;
	sbar_bigfont = FONT_USER+2;
	sbar_fontsize = '1 1 0';
	string s = strcat(cvar_string("cmdline"), " ", cvar_string("gl_info_renderer"), " ", cvar_string("gl_info_version"));
	s = strcat(s, " ", cvar_string("vid_width"), "x", cvar_string("vid_height"));
	s = strcat(s, " ", ftos(ceil(cvar("sys_memsize_physical") / 512) * 512));
	localcmd(strcat("\ncmd sysinfo ", s, "\n"));
	if not(cvar("cl_movement")) {
		localcmd("seta cl_movement 1\n"); //Some people disable it because their don't understand what is it. Fixing.
	}
	precache_sound("misc/hit.wav");
}

// CSQC_Shutdown : Called every time the CSQC code is shutdown (changing maps, quitting, etc)
void CSQC_Shutdown(void)
{
	remove(team_list);
	remove(player_list);
	db_close(binddb);
	db_close(tempdb);

	cvar_clientsettemp_restore();
	gui_chat_restore();
	if(camera_active)
		cvar_set("chase_active",ftos(chase_active_backup));

	if not(isdemo_flag)
	{
		if not(calledhooks & HOOK_START)
			localcmd("\n_cl_hook_gamestart nop;");
		if not(calledhooks & HOOK_END)
			localcmd("\ncl_hook_gameend;");
	}
	trip_shutdown();
}

// CSQC_InputEvent : Used to perform actions based on any key pressed, key released and mouse on the client.
// Return value should be 1 if CSQC handled the input, otherwise return 0 to have the input passed to the engine.
// All keys are in ascii.
// bInputType = 0 is key pressed, 1 is key released, 2 is mouse input.
// In the case of keyboard input, nPrimary is the ascii code, and nSecondary is 0.
// In the case of mouse input, nPrimary is xdelta, nSecondary is ydelta.
var float(float bInputType, float nPrimary, float nSecondary) CSQC_InputEvent_Callback_null;
float CSQC_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	local float bSkipKey;
	bSkipKey = FALSE;
	if (CSQC_InputEvent_Callback) {
		bSkipKey = CSQC_InputEvent_Callback(bInputType, nPrimary, nSecondary);
		CSQC_InputEvent_Callback = CSQC_InputEvent_Callback_null;
		if (bSkipKey)
			return TRUE;
	}
	if (bInputType == 0)
	if (nPrimary == K_ESCAPE)
	if not(isdemo_flag)
	{
		GUI_Show(GUI_GAMEMENU);
		return TRUE;
	}

	return bSkipKey;
}

// CSQC_Parse_StuffCmd : Provides the stuffcmd string in the first parameter that the server provided.  To execute standard behavior, simply execute localcmd with the string.
void CSQC_Parse_StuffCmd(string strMessage)
{
	localcmd(strMessage);
}
// CSQC_Parse_Print : Provides the print string in the first parameter that the server provided.  To execute standard behavior, simply execute print with the string.
void CSQC_Parse_Print(string strMessage)
{
	print(strMessage);
}

void(float ignore) main_init_read {
	float i;
	self.classname = "ent_client_init";
	float sf = ReadByte();
	if (sf & 1) {
		for(i = 0; i < 24; ++i)
			weaponimpulse[i] = ReadByte() - 1;
	}
	if (sf & 2) {
		i = ReadByte();
		g_campaign = i & 1;
		localgame = i & 4;
		hook_use_swapped = i & 8;
		button_attack2_allowed = !(i & 16);
	}
	if (sf & 4) {
		str_unzone_ifneeded(fog_settings);
		fog_settings = str_zone_ifneeded(ReadString());
	}
	if (sf & 8)
		vote_commands_read();

	if (sf & 16)
		gamemenu_read();

	if (sf & 32) {
		team_mode = ReadByte();
		if not(team_mode) {
			team_get(0, TRUE);
		}
		entity o;
		if (SP_TEAM_BIT)
			for(o = player_list.sort_next; o; o = o.sort_next)
				if (o.gotscores)
					team_set(o, o.scores[SP_TEAM_FIELD]);

		registercvar("_teams_available", "0");
		cvar_set("_teams_available", ftos(ReadByte()));
	}
	if (sf & 64) {
		projectile_info_read();
	}
	if (sf & 128) {
		str_unzone_ifneeded(map_description);
		map_description = str_zone_ifneeded(ReadString());
		str_unzone_ifneeded(motd);
		motd = str_zone_ifneeded(ReadString());
	}
}

string getcommandkey(string text, string command)
{
	string keys;
	float n, j, k, l;

	if (!CVAR(sbar_showbinds))
		return text;

	keys = db_get(binddb, command);
	if (!keys)
	{
		n = tokenize(findkeysforcommand(command)); // uses '...' strings
		for(j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if(k != -1)
			{
				if ("" == keys)
					keys = keynumtostring(k);
				else
					keys = strcat(keys, ", ", keynumtostring(k));

				++l;
				if (CVAR(sbar_showbinds_limit) > 0 && CVAR(sbar_showbinds_limit) >= l) break;
			}

		}
		db_put(binddb, command, keys);
	}

	if ("" == keys) {
		if (CVAR(sbar_showbinds) > 1)
			return strcat(text, " (not bound)");
		else
			return text;
	}
	else if (CVAR(sbar_showbinds) > 1)
		return strcat(text, " (", keys, ")");
	else
		return keys;
}
