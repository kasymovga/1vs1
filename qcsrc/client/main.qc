void(float ignore) main_init_read;

// CSQC_Init : Called every time the CSQC code is initialized (essentially at map load)
// Useful for precaching things
void(void) CSQC_Init {
	if (!cvar("con_chat"))
		cvar_set("con_chat", "5");
	else if (cvar("con_chat") > 99)
		cvar_set("con_chat", "0");

	read_cvars_init();
	extension_init();
	if (file_exists("rexuiz.cfg")) {
		if (extension_ALL && (cvar_type("collision_triangle_directional") & CVAR_TYPEFLAG_ENGINE) && (cvar_type("collision_surfaceflagsmerge") & CVAR_TYPEFLAG_ENGINE))
			localcmd("\ncmd gameclient newrexuiz\n");
		else
			localcmd("\ncmd gameclient rexuiz\n");
	} else if (autocvar_autocvar_check) {
		localcmd("\ncmd gameclient nexuiz\n");
		if not(cvar("mod_alias_force_animated")) {
			localcmd("\nseta mod_alias_force_animated 1; r_restart\n");
		}
	} else {
		localcmd("\ncmd gameclient oldnexuiz\n");
		entity e = noteline_new("^1WARNING: ^3Your client is outdated!\n^3Updated client available here: ^2http://rexuiz.com^7");
		e.think = stdproc_remove;
		e.nextthink = time + 30;
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
	db_binds = db_create();
	db_temp = db_create();
	net_compress_vector_init();
	view_crosshairdot_tex = "gfx/crosshair6";
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
	registercmd("+showscores");registercmd("-showscores");
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
	main_isdemo = isdemo();
#ifndef CAMERATEST
	if(main_isdemo) {
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
	game_type = 0;
	sbar_gametype_init();
	// sbar_fields uses strunzone on the titles!
	for(i = 0; i < SBAR_FIELDS_MAX; ++i)
		sbar_title[i] = strzone("(null)");

	main_calledhooks = 0;
	team_list = spawn();
	player_list = spawn();
	team_get(TEAM_COLOR_SPECTATOR, TRUE); // add specs first
	cvar_clientsettemp("_supports_weaponpriority", "1");
	weapon_register_weapons();
	world_get_min_max(1); // try the CLEVER way first
	waypointsprite_init();
	projectile_precache();
	gib_precache();
	casing_precache();
	damage_info_precache();
	warpzone_init();
	map_shortname = mapname;
	if (!strcasecmp(substring(map_shortname, 0, 5), "maps/"))
		map_shortname = substring(map_shortname, 5, strlen(map_shortname) - 5);

	if (!strcasecmp(substring(map_shortname, strlen(map_shortname) - 4, 4), ".bsp"))
		map_shortname = substring(map_shortname, 0, strlen(map_shortname) - 4);

	map_shortname = strzone(map_shortname);
	teamradar_minimapname = strcat("gfx/", map_shortname, "_radar");
	if (precache_pic(teamradar_minimapname) == "") {
		// but maybe we have a non-clever minimap
		teamradar_minimapname = strcat("gfx/", map_shortname, "_mini");
		if (precache_pic(teamradar_minimapname) == "")
			teamradar_minimapname = ""; // FAIL
		else
			world_get_min_max(0); // load new texcoords
	}
	teamradar_init();
	teamradar_minimapname = strzone(teamradar_minimapname);
	csqc_entity_init();
	draw_init();
	ui_con_width_height_set();
	sbar_font = FONT_USER+1;
	sbar_bigfont = FONT_USER+2;
	sbar_fontsize = '1 1 0';
	string s = strcat(cvar_string("cmdline"), " ", cvar_string("gl_info_renderer"), " ", cvar_string("gl_info_version"));
	s = strcat(s, " ", cvar_string("vid_width"), "x", cvar_string("vid_height"));
	s = strcat(s, " ", ftos(ceil(cvar("sys_memsize_physical") / 512) * 512));
	s = strreplace(";", "", s);
	s = strreplace("\n", "", s);
	s = strreplace("$", "", s);
	s = strreplace("\"", "", s);
	localcmd(strcat("\ncmd sysinfo ", s, "\n"));
	if not(cvar("cl_movement")) {
		localcmd("seta cl_movement 1\n"); //Some people disable it because their don't understand what is it. Fixing.
	}
	precache_sound("misc/hit.wav");
	mute_init();
}

// CSQC_Shutdown : Called every time the CSQC code is shutdown (changing maps, quitting, etc)
void(void) CSQC_Shutdown {
	remove(team_list);
	remove(player_list);
	db_close(db_binds);
	db_close(db_temp);

	cvar_clientsettemp_restore();
	gui_chat_restore();
	if(view_camera_active)
		cvar_set("chase_active",ftos(view_chase_active_backup));

	if not(main_isdemo) {
		if not(main_calledhooks & MAIN_HOOK_START)
			localcmd("\n_cl_hook_gamestart nop;");

		if not(main_calledhooks & MAIN_HOOK_END)
			localcmd("\ncl_hook_gameend;");
	}
	trip_shutdown();
	mute_shutdown();
}

// CSQC_Parse_StuffCmd : Provides the stuffcmd string in the first parameter that the server provided.  To execute standard behavior, simply execute localcmd with the string.
void(string strMessage) CSQC_Parse_StuffCmd {
	localcmd(strMessage);
}

// CSQC_Parse_Print : Provides the print string in the first parameter that the server provided.  To execute standard behavior, simply execute print with the string.
void(string strMessage) CSQC_Parse_Print {
	if (mute_list != "")
	if (substring(strMessage, 0, 1) == "\{1}")
	if (mute_check(strMessage))
		return;

	print(strMessage);
}

void(float ignore) main_init_read {
	float i;
	self.classname = "ent_client_init";
	float sf = net_read_byte();
	if (sf & 1) {
		for(i = 0; i < 24; ++i)
			weapon_impulses[i] = net_read_byte() - 1;
	}
	if (sf & 2) {
		i = net_read_byte();
		main_campaign = i & 1;
		main_localgame = i & 4;
		input_hook_use_swapped = i & 8;
		input_button_attack2_allowed = !(i & 16);
		view_recoil_mode = (i & 32);
	}
	if (sf & 4) {
		str_unzone_ifneeded(fog_settings);
		fog_settings = str_zone_ifneeded(net_read_string());
	}
	if (sf & 8)
		vote_commands_read();

	if (sf & 16)
		game_menu_read();

	if (sf & 32) {
		team_mode = net_read_byte();
		if not(team_mode) {
			team_get(0, TRUE);
		}
		entity o;
		if (SP_TEAM_BIT)
			for(o = player_list.sort_next; o; o = o.sort_next)
				if (o.gotscores)
					team_set(o, o.scores[SP_TEAM_FIELD]);

		registercvar("_teams_available", "0");
		cvar_set("_teams_available", ftos(net_read_byte()));
	}
	if (sf & 64) {
		projectile_info_read();
	}
	if (sf & 128) {
		str_unzone_ifneeded(map_description);
		map_description = str_zone_ifneeded(net_read_string());
		str_unzone_ifneeded(server_motd);
		server_motd = str_zone_ifneeded(net_read_string());
	}
}
