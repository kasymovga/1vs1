float SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS = 1;
string redirection_target;
float g_balance_falldamage_deadminspeed;
float g_balance_falldamage_factor;
float g_balance_falldamage_minspeed;
float g_balance_falldamage_maxdamage;
float g_lava_damage_factor;
float g_lava_fire_factor;
float g_lava_fire_time;

void(void) world_precache {
	// gore and miscellaneous sounds
	//precache_sound ("misc/h2ohit.wav");
	precache_sound("misc/armorimpact.wav");
	precache_sound("misc/bodyimpact1.wav");
	precache_sound("misc/bodyimpact2.wav");
	precache_sound("misc/gib.wav");
	sound_random_precache("misc/gib_splat0", 4);
	precache_sound("misc/hit.wav");
	precache_sound("misc/menu2.wav");
	sound_random_precache("misc/hitground", 4);
	sound_random_precache("misc/metalhitground", 4);
	precache_sound("misc/outwater.wav");
	precache_sound("misc/null.wav");
	precache_sound("misc/spawn.wav");
	precache_sound("misc/talk.wav");
	precache_sound("misc/teleport.wav");
	precache_sound("misc/poweroff.wav");
	precache_sound("player/lava.wav");
	precache_sound("player/slime.wav");
	precache_sound("misc/jetpack_fly.wav");
	// announcer sounds - male
	precache_sound("announcer/male/electrobitch.wav");
	precache_sound("announcer/male/airshot.wav");
	precache_sound("announcer/male/03kills.wav");
	precache_sound("announcer/male/05kills.wav");
	precache_sound("announcer/male/10kills.wav");
	precache_sound("announcer/male/15kills.wav");
	precache_sound("announcer/male/20kills.wav");
	precache_sound("announcer/male/25kills.wav");
	precache_sound("announcer/male/30kills.wav");
	precache_sound("announcer/male/botlike.wav");
	precache_sound("announcer/male/yoda.wav");
	precache_sound("announcer/male/amazing.wav");
	precache_sound("announcer/male/awesome.wav");
	precache_sound("announcer/male/headshot.wav");
	precache_sound("announcer/male/impressive.wav");
	// announcer sounds - robotic
	precache_sound("announcer/robotic/prepareforbattle.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/timeoutcalled.wav");
	precache_sound("announcer/robotic/1fragleft.wav");
	precache_sound("announcer/robotic/2fragsleft.wav");
	precache_sound("announcer/robotic/3fragsleft.wav");
	precache_sound("announcer/robotic/terminated.wav");
	precache_sound("announcer/robotic/5minutesremain.wav");
	precache_sound("announcer/robotic/1minuteremains.wav");
	precache_model("models/sprites/0.spr32");
	precache_model("models/sprites/1.spr32");
	precache_model("models/sprites/2.spr32");
	precache_model("models/sprites/3.spr32");
	precache_model("models/sprites/4.spr32");
	precache_model("models/sprites/5.spr32");
	precache_model("models/sprites/6.spr32");
	precache_model("models/sprites/7.spr32");
	precache_model("models/sprites/8.spr32");
	precache_model("models/sprites/9.spr32");
	precache_model("models/sprites/10.spr32");
	precache_sound("announcer/robotic/1.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/4.wav");
	precache_sound("announcer/robotic/5.wav");
	precache_sound("announcer/robotic/6.wav");
	precache_sound("announcer/robotic/7.wav");
	precache_sound("announcer/robotic/8.wav");
	precache_sound("announcer/robotic/9.wav");
	precache_sound("announcer/robotic/10.wav");
	// common weapon precaches
	precache_sound("weapons/weapon_switch.wav");
	precache_sound("weapons/weaponpickup.wav");
	precache_sound("weapons/unavailable.wav");
}


void(void) world_static_init {
	world_dedicated = builtin_cvar("_sv_init");;
	minstagib_init();
	weapon_extra_init();
	item_init();
	warmup_init();
	if not(warmup_active)
		map_starttime = cvar("g_start_delay");

	rune_init();
	walkietalkie_init();
	akimbo_init();
	hat_init();
	Radio_Init();
	badass_init();
	damage_indicator_init();
	monster_monsters_init();
	warpzone_init();
	weapon_selectable_init();
	weapon_two_weapons_init();
	if not(g_campaign) {
		game_type_vote_init();
		udp_chat_init();
		udp_punch_hole_init();
		report_init();
		timeout_init();
	}
	sysinfo_init();
	footsteps_init();
	jetpack_init();
	laser_init();
	teleport_init();
	casing_init();
	warfog_init();
	hint_init();
	ability_init();
	voip_init();
	damage_score_init();
	weapon_score_init();
	IP2C_InitSV();
	cheat_init();
	soulmates_init();
	pin_init();
	handover_init();
}

void(void) world_dynamic_init {
	CVAR_CACHE(g_balance_falldamage_deadminspeed);
	CVAR_CACHE(g_balance_falldamage_factor);
	CVAR_CACHE(g_balance_falldamage_minspeed);
	CVAR_CACHE(g_balance_falldamage_maxdamage);
	CVAR_CACHE(g_lava_damage_factor);
	CVAR_CACHE(g_lava_fire_factor);
	CVAR_CACHE(g_lava_fire_time);
	weapon_init();
	damage_init();
	fire_init();
	physics_init();
	bot_init();
	spawn_init();
	client_initialize();
	spectator_init();
	team_init();
	hook_init(FALSE);
	turret_readcvars();
	marker_Init();
	vote_init();
	push_init();
	player_init();
	backpack_init();
	pinata_init();
	chat_init();
	announce_init();
	waypoint_init();
	slowmo_factor = cvar("g_slowmo");
}

void(void) world_getrecords {
	float i;
	string s = "", s1;
	float f = -1;
	for (i = 0; i < CMD_RECORDS_REPLY_STRINGS_COUNT; i++) {
		str_unzone_ifneeded(cmd_records_reply[i]);
	}
	cmd_records_reply_extra = 0;
	if (cvar("sv_dumprecords")) {
		f = fopen(strcat("records-", game_type_name(game_type), ".txt"), FILE_WRITE);
	}
	for (i = 0; i < map_info_count; ++i)
		if (map_info_get_by_id(i)) {
			s1 = plugin_world_record_for_map(map_info_map_bspname);
			if (strlen(s) + strlen(s1) > 4095) {
				if (cmd_records_reply_extra >= CMD_RECORDS_REPLY_STRINGS_COUNT - 1)
					break;

				cmd_records_reply[cmd_records_reply_extra] = strzone(s);
				cmd_records_reply_extra++;
				s = "";
			}
			s = strcat(s, s1);
			if (f >= 0) {
				fputs(f, s1);
			}
		}
	cmd_records_reply[cmd_records_reply_extra] = strzone(s);
	if (f >= 0)
		fclose(f);

	map_info_clear_temps();
}

void(void) world_end_of_time {
	print_all(PRINT_INFO, "The server has been running for too long. Restart required", "", "", "");
	localcmd("\nrestart\n");
}

void(float mode) world_get_min_max {
	vector mi, ma;
	mi = world.absmin;
	ma = world.absmax;
	world_min = mi;
	world_max = ma;
	// not specified
	if(mode) {
		// be clever
		trace_box('1 0 0' * mi_x,
				 '0 1 0' * mi_y + '0 0 1' * mi_z,
				 '0 1 0' * ma_y + '0 0 1' * ma_z,
				 '1 0 0' * ma_x,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_min_x = trace_endpos_x;

		trace_box('0 1 0' * mi_y,
				 '1 0 0' * mi_x + '0 0 1' * mi_z,
				 '1 0 0' * ma_x + '0 0 1' * ma_z,
				 '0 1 0' * ma_y,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_min_y = trace_endpos_y;

		trace_box('0 0 1' * mi_z,
				 '1 0 0' * mi_x + '0 1 0' * mi_y,
				 '1 0 0' * ma_x + '0 1 0' * ma_y,
				 '0 0 1' * ma_z,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_min_z = trace_endpos_z;

		trace_box('1 0 0' * ma_x,
				 '0 1 0' * mi_y + '0 0 1' * mi_z,
				 '0 1 0' * ma_y + '0 0 1' * ma_z,
				 '1 0 0' * mi_x,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_max_x = trace_endpos_x;

		trace_box('0 1 0' * ma_y,
				 '1 0 0' * mi_x + '0 0 1' * mi_z,
				 '1 0 0' * ma_x + '0 0 1' * ma_z,
				 '0 1 0' * mi_y,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_max_y = trace_endpos_y;

		trace_box('0 0 1' * ma_z,
				 '1 0 0' * mi_x + '0 1 0' * mi_y,
				 '1 0 0' * ma_x + '0 1 0' * ma_y,
				 '0 0 1' * mi_z,
				 TRACE_MOVE_WORLDONLY,
				 world);

		if(!trace_startsolid)
			world_max_z = trace_endpos_z;
	}
}

float world_already_spawned;
void(void) world_init {
	if (world_already_spawned) {
		print("WARNING: world already spawned - you may have EXACTLY ONE worldspawn!");
		return;
	}
	gettaginfo_parent = 0;
	gettaginfo_offset = '0 0 0';
	gettaginfo_forward = '0 0 0';
	gettaginfo_right = '0 0 0';
	gettaginfo_up = '0 0 0';
	//trace_dphittexturename = "";
	float i, j, n;
	string col;
	cvar_preinit();
	registercvar("_masterlist_init_done", "0");
	if (cvar("sv_master_list_sync"))
	if (cvar("sv_public") > 0)
	if not(cvar("_masterlist_init_done")) {
		masterlist_init();
		cvar_set("_masterlist_init_done", "1");
	}
	registercvar("date_day", "");
	registercvar("date_day_of_week", "");
	registercvar("date_month", "");
	registercvar("date_year", "");
	cvar_set("date_day", strftime(TRUE, "%d"));
	cvar_set("date_day_of_week", strftime(TRUE, "%w"));
	cvar_set("date_month", strftime(TRUE, "%m"));
	cvar_set("date_year", strftime(TRUE, "%Y"));
	builtin_cvar_set("deathmatch", "1");
	builtin_cvar_set("coop", "0");
	world_already_spawned = TRUE;
	net_compress_vector_init();
	entity head;
	head = nextent(world);
	client_max_count = 0;
	while(head) {
		++client_max_count;
		head = nextent(head);
	}
	db_init();
	// 0 normal
	lightstyle(0, "m");
	// 1 FLICKER (first variety)
	lightstyle(1, "mmnmmommommnonmmonqnmmo");
	// 2 SLOW STRONG PULSE
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");
	// 3 CANDLE (first variety)
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");
	// 4 FAST STROBE
	lightstyle(4, "mamamamamama");
	// 5 GENTLE PULSE 1
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");
	// 6 FLICKER (second variety)
	lightstyle(6, "nmonqnmomnmomomno");
	// 7 CANDLE (second variety)
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");
	// 8 CANDLE (third variety)
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");
	// 9 SLOW STROBE (fourth variety)
	lightstyle(9, "aaaaaaaazzzzzzzz");
	// 10 FLUORESCENT FLICKER
	lightstyle(10, "mmamammmmammamamaaamammma");
	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");
	// styles 32-62 are assigned by the spawnfunc_light program for switchable lights
	// 63 testing
	lightstyle(63, "a");
	cvar_changes_init();
	campaign_preinit();
	precache_model("null"); // we need this one before game_type_init. or maybe not
	// find out good world mins/maxs bounds
	if (file_exists_image(strcat("gfx/", mapname, "_radar")))
		world_get_min_max(1);
	else
		world_get_min_max(0);

	world.mins = world_min;
	world.maxs = world_max;
	dlc_init();
	rm_init();
	game_type_init();
	rm_buffs_init();
	map_mark_as_recent(mapname);
	// needs to be done so early as they would still spawn
	weapon_register_weapons();
	world_static_init();
	weapon_priority_update(); //must be called after all weapons registered
	world_dynamic_init();
	nadget_init();
	player_count = 0;
	bot_waypoints_for_items = cvar("g_waypoints_for_items");
	if (bot_waypoints_for_items == 1)
		if (self.spawnflags & SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS)
			bot_waypoints_for_items = 0;

	world_precache();
	cvar_set("nextmap", "");
	campaign_postinit();
	ban_init();
	map_info_enumerate();
	map_info_filter_game_type(map_info_type_from_game_type(game_type_current()) | game_type_vote_mapinfo_mask, map_info_required_flags(), map_info_forbidden_flags(), 1);
	addstat(STAT_WEAPONS, STAT_INT, weapons);
	addstat(STAT_SWITCHWEAPON, STAT_INT, switchweapon);
	addstat(STAT_WEAPON, STAT_INT, weapon);
	addstat(STAT_GAMESTARTTIME, STAT_FLOAT, stat_map_starttime);
	ready_nagger_init();
	addstat(STAT_PRESSED_KEYS, STAT_FLOAT, pressedkeys);
	addstat(STAT_FUEL, STAT_INT, ammo_fuel);
	addstat(STAT_DAMAGE_HITS, STAT_INT, damage_hits);
 	addstat(STAT_DAMAGE_FIRED, STAT_INT, maxdamage_fired);
	addstat(STAT_LEADLIMIT, STAT_FLOAT, stat_leadlimit);
	addstat(STAT_BULLETS_LOADED, STAT_INT, ammoclip);
	addstat(STAT_BULLETS_LOADED_MAX, STAT_INT, ammoclipmax);
	addstat(STAT_PLAYER_STATE, STAT_INT, deadflag);
	addstat(STAT_SPECSTATUS, STAT_INT, spectatee_status);
	addstat(STAT_WEAPONS_EXTRA, STAT_INT, weapons_extra);
	cmd_lsmaps_reply = "^7Maps available: ";
	map_list = "";
	for (i = 0, j = 0; i < map_info_count; ++i) {
		if (map_info_get_by_id(i))
			if not(map_info_map_flags & (MAP_INFO_FLAG_HIDDEN | MAP_INFO_FLAG_FORBIDDEN)) {
				if (math_mod(i, 2))
					col = "^2";
				else
					col = "^3";

				++j;
				cmd_lsmaps_reply = strcat(cmd_lsmaps_reply, col, map_info_map_bspname, " ");
				map_list = strcat(map_list, map_info_map_bspname, " ");
			}
	}
	cmd_lsmaps_reply = strzone(strcat(cmd_lsmaps_reply, "\n"));
	map_list = strzone(map_list);
	cmd_maplist_reply = "^7Maps in list: ";
	n = tokenize_console(cvar_string("_g_maplist"));
	for (i = 0, j = 0; i < n; ++i) {
		if (map_info_check_map(argv(i))) {
			if (math_mod(j, 2))
				col = "^2";
			else
				col = "^3";

			cmd_maplist_reply = strcat(cmd_maplist_reply, col, argv(i), " ");
			++j;
		}
	}
	cmd_maplist_reply = strzone(strcat(cmd_maplist_reply, "\n"));
	map_info_clear_temps();
	world_getrecords();
	client_init_spawn();
	random_seed_spawn();
	localcmd("\n_sv_hook_gamestart ", game_type_name(game_type), ";");
	world_initialized = 1;
	infomessages_init();
	defer(20000, world_end_of_time); //prevent bugs with 32bit float time value
}

void(float final) world_dump_stats {
	float file = 0;
	string s;
	float to_console;
	float to_file;
	float i;
	to_console = cvar("sv_logscore_console");
	to_file = cvar("sv_logscore_file");
	if (!final)
		to_console = TRUE; // always print printstats replies

	if (final)
		s = ":scores:";
	else
		s = ":status:";

	s = strcat(s, game_type_name(game_type), "_", mapname, ":", ftos(rint(time)));
	if (to_console)
		print(s, "\n");

	if (to_file) {
		file = fopen(cvar_string("sv_logscore_filename"), FILE_APPEND);
		if (file == -1)
			to_file = FALSE;
		else
			fputs(file, strcat(s, "\n"));
	}
	s = strcat(":labels:player:", score_player_string(world, 0));
	if (to_console)
		print(s, "\n");

	if (to_file)
		fputs(file, strcat(s, "\n"));

	CLIENT_FOR_EACH(other) {
		if ((clienttype(other) == CLIENTTYPE_REAL) || (clienttype(other) == CLIENTTYPE_BOT && cvar("sv_logscore_bots"))) {
			s = strcat(":player:see-labels:", score_player_string(other, 0), ":");
			s = strcat(s, ftos(rint(time - other.jointime)), ":");
			if (other.classname == "player")
				s = strcat(s, ftos(other.team), ":");
			else
				s = strcat(s, "spectator:");

			if (to_console)
				print(s, other.netname, "\n");

			if (to_file)
				fputs(file, strcat(s, other.netname, "\n"));
		}
	}
	if (team_mode) {
		s = strcat(":labels:teamscores:", score_team_string(0, 0));
		if (to_console)
			print(s, "\n");

		if (to_file)
			fputs(file, strcat(s, "\n"));

		for (i = 1; i < 16; ++i) {
			s = strcat(":teamscores:see-labels:", score_team_string(i, 0));
			s = strcat(s, ":", ftos(i));
			if (to_console)
				print(s, "\n");

			if (to_file)
				fputs(file, strcat(s, "\n"));
		}
	}
	if (to_console)
		print(":end\n");

	if (to_file) {
		fputs(file, ":end\n");
		fclose(file);
	}
}

float world_check_rules_equality;
float world_check_rules_suddendeathwarning;
float world_check_rules_suddendeathend;
float world_check_rules_overtimesadded; //how many overtimes have been already added

float(void) world_check_rules_run_out_spawns {
	entity head;
	if (!spawn_have_team_spawns)
		return FALSE;

	if (!spawn_has_been_used)
		return FALSE;

	score_team1 = score_team2 = score_team3 = score_team4 = 0;
	PLAYER_FOR_EACH(head) if (head.deadflag == DEAD_NO) {
		if (head.team == COLOR_TEAM1)
			score_team1 = 1;
		else if (head.team == COLOR_TEAM2)
			score_team2 = 1;
		else if (head.team == COLOR_TEAM3)
			score_team3 = 1;
		else if (head.team == COLOR_TEAM4)
			score_team4 = 1;
	}
	for (head = world; (head = find(head, classname, "info_player_deathmatch")) != world; ) {
		if (head.team == COLOR_TEAM1)
			score_team1 = 1;
		else if (head.team == COLOR_TEAM2)
			score_team2 = 1;
		else if (head.team == COLOR_TEAM3)
			score_team3 = 1;
		else if (head.team == COLOR_TEAM4)
			score_team4 = 1;
	}
	world_winners_clear();
	if (score_team1 + score_team2 + score_team3 + score_team4 == 0) {
		world_check_rules_equality = TRUE;
		return TRUE;
	} else if (score_team1 + score_team2 + score_team3 + score_team4 == 1) {
		float t = 0, i;
		if (score_team1) t = COLOR_TEAM1;
		if (score_team2) t = COLOR_TEAM2;
		if (score_team3) t = COLOR_TEAM3;
		if (score_team4) t = COLOR_TEAM4;
		team_teams_allowed(world);
		for (i = 0; i < SCORE_TEAM_FIELDS_MAX; ++i) {
			if (t != COLOR_TEAM1) if (team1 >= 0) score_team_add_to(COLOR_TEAM1, i, -1000);
			if (t != COLOR_TEAM2) if (team2 >= 0) score_team_add_to(COLOR_TEAM2, i, -1000);
			if (t != COLOR_TEAM3) if (team3 >= 0) score_team_add_to(COLOR_TEAM3, i, -1000);
			if (t != COLOR_TEAM4) if (team4 >= 0) score_team_add_to(COLOR_TEAM4, i, -1000);
		}
		world_winners_add(team, t);
		return TRUE;
	} else
		return FALSE;
}


void(void) world_overtime {
	// Check first whether normal overtimes could be added before initiating suddendeath mode
	// - for this g_timelimit_overtime needs to be >0 of course
	// - also check the winning condition calculated in the previous frame and only add normal overtime
	//   again, if at the point at which timelimit would be extended again, still no winner was found
	if (plugin_OvertimeHandle())
		return;

	float tl;
	if ((world_check_rules_overtimesadded >= 0) && (world_check_rules_overtimesadded < cvar("g_timelimit_overtimes")) && cvar("g_timelimit_overtime")) {
		++world_check_rules_overtimesadded;
		//add one more overtime by simply extending the timelimit
		tl = cvar("timelimit");
		tl += cvar("g_timelimit_overtime");
		cvar_set("timelimit", ftos(tl));
		string minutesPlural;
		if (cvar("g_timelimit_overtime") == 1)
			minutesPlural = " ^3minute";
		else
			minutesPlural = " ^3minutes";

		game_status_set(strcat("^3Now playing ^1OVERTIME^3!\n\n^3Added ^1{1} ", minutesPlural, " to the game!"), 1, ftos(cvar("g_timelimit_overtime")), "", "");
	} else if (!world_check_rules_suddendeathend) {
		tl = cvar("timelimit");
		tl += cvar("g_timelimit_suddendeath");
		world_check_rules_suddendeathend = map_starttime + 60 * tl;
		cvar_set("timelimit", ftos(tl));
	}
}

// set the .winning flag for exactly those players with a given field value
void(.float field, float value) world_winners_set {
	entity head;
	PLAYER_FOR_EACH(head)
		head.winning = (head.field == value);
}

// set the .winning flag for those players with a given field value
void(.float field, float value) world_winners_add {
	entity head;
	PLAYER_FOR_EACH(head)
		if (head.field == value)
			head.winning = 1;
}

// clear the .winning flags
void(void) world_winners_clear {
	entity head;
	PLAYER_FOR_EACH(head)
		head.winning = 0;
}

void(float timelimit) world_check_0min_remaining { }
void(float timelimit) world_check_5min_remaining;
var void(float timelimit) world_check_time_remaining = { world_check_5min_remaining(timelimit); };
void(float timelimit) world_check_1min_remaining {
	if (time + 60 >= timelimit) {
		sound_play2all("announcer/robotic/1minuteremains.wav");
		world_check_time_remaining = world_check_0min_remaining;
	}
}

void(float timelimit) world_check_5min_remaining {
	if (time + 300 >= timelimit) {
		sound_play2all("announcer/robotic/5minutesremain.wav");
		world_check_time_remaining = world_check_1min_remaining;
	}
}

void(void) world_check_rules { // Exit deathmatch games upon conditions
	float timelimit;
	float fraglimit;
	vote_think();
	map_vote_think();
	if (map_finished) { // someone else quit the game already
		if (player_count == 0) // Nobody there? Then let's go to the next map
			map_vote_start();
			// this will actually check the player count in the next frame
			// again, but this shouldn't hurt
		return;
	}
	timelimit = cvar("timelimit");
	timelimit *= 60;
	fraglimit = cvar("fraglimit");
	score_leadlimit = cvar("leadlimit");
	if (g_campaign) {
		float timelimit_real = builtin_cvar("timelimit");
		if (timelimit_real != timelimit) {
			builtin_cvar_set("timelimit", ftos(timelimit));
		}
		float fraglimit_real = builtin_cvar("fraglimit");
		if (fraglimit_real != fraglimit) {
			builtin_cvar_set("fraglimit", ftos(fraglimit));
		}
		float leadlimit_real = builtin_cvar("leadlimit");
		if (leadlimit_real != score_leadlimit) {
			builtin_cvar_set("leadlimit", ftos(score_leadlimit));
		}
	}
	if (warmup_active || time <= map_starttime) { // NOTE: this is <= to prevent problems in the very tic where the game starts
		if (timelimit > 0)
			timelimit = 0; // timelimit is not made for warmup

		if (fraglimit > 0)
			fraglimit = 0; // no fraglimit for now

		score_leadlimit = 0; // no leadlimit for now
	}
	if (timelimit > 0) {
		timelimit += map_starttime;
	} else if (timelimit < 0) {
		// endmatch
		map_finish();
		return;
	}
	if (time < map_starttime + frametime) {
		if (!warmup_active || time + 10 >= map_starttime) {
			float f = map_starttime - time;
			if (f >= 1) {
				if (floor(f - frametime) != floor(f)) {
					if (f < 4)
						sound_play2all(strcat("announcer/robotic/", ftos(floor(f)), ".wav"));

					RM_ELSE({
						rm_bigprint_all(" ", "", 1);
						rm_bigprint_all(strcat(game_type_name_long(game_type), " starts in: ", ftos(floor(f))), "", 1);
					}, {
						game_status_set("^1Game starts in {1} seconds", 2, ftos(floor(f)), "", "");
					})
				}
			}
			if (time >= map_starttime) {
				RM_ELSE({
					rm_bigprint_all("^xFB0Begin!", "It's time to kick some ass!", 1);
				}, {
					game_status_set("^1Begin!", 1, "", "", "");
				})
				sound_play2all("announcer/robotic/begin.wav");
				world_check_time_remaining = world_check_5min_remaining;
			}
		}
	} else if (timelimit)
		world_check_time_remaining(timelimit);

	if (world_check_rules_suddendeathend) {
		cvar_set("timelimit", ftos((world_check_rules_suddendeathend - map_starttime) / 60));
		if (!world_check_rules_suddendeathwarning) {
			world_check_rules_suddendeathwarning = TRUE;
			string sdm = plugin_SuddenDeathMessageMod("^3Now playing ^1OVERTIME^3!\n\n^3Keep fragging until we have a ^1winner^3!");
			if (sdm != "")
				game_status_set(sdm, 1, "", "", "");
		}
	} else {
		if (timelimit)
		if (time >= timelimit) {
			if (plugin_OvertimeAllowed()) {
				if (score_winning_condition_helper_equality) {
					world_overtime();
				} else {
					map_finish();
					return;
				}
			} else {
				map_finish();
				return;
			}
		}
	}
	score_winning_condition_helper();
	if (plugin_winning_condition(fraglimit, score_leadlimit)) {
		map_finish();
		return;
	}
	if (world_check_rules_suddendeathend)
	if (time >= world_check_rules_suddendeathend || !score_winning_condition_helper_equality) {
		map_finish();
		return;
	}
}

void(void) world_frame_end {
	CLIENT_FOR_EACH_REAL(self) {
		if (self.classname == "spectator") {
			if (self.enemy.typehitsound)
				sound_play2(self, "misc/typehit.wav");
			else if (self.enemy.hitsound) {
				msg_entity = self;
				net_write_byte(MSG_ONE, SVC_TEMPENTITY);
				net_write_byte(MSG_ONE, NET_TE_CSQC_HIT);
			}
		} else {
			if (self.typehitsound) {
				sound_play2(self, "misc/typehit.wav");
			} else if (self.hitsound) {
				msg_entity = self;
				net_write_byte(MSG_ONE, SVC_TEMPENTITY);
				net_write_byte(MSG_ONE, NET_TE_CSQC_HIT);
			}
		}
	}
	CLIENT_FOR_EACH(self) {
		self.hitsound = FALSE;
		self.typehitsound = FALSE;
	}
	// add 1 frametime because client shows everything with
	// 1 frame of lag (cl_nolerp 0).
	antilag_record(time + frametime);
}

float redirection_timeout;
float redirection_nextthink;
float(void) world_redirection_think { // returns TRUE if redirecting
	float clients_found;
	if (redirection_target == "")
		return FALSE;

	if (!redirection_timeout) {
		cvar_set("sv_public", "-2");
		redirection_timeout = time + 0.6; // this will only try twice... should be able to keep more clients
		if (redirection_target == "self")
			print_all(PRINT_INFO, "^3SERVER NOTICE:^7 restarting the server", "", "", "");
		else
			print_all(PRINT_INFO, "^3SERVER NOTICE:^7 redirecting everyone to {1}", redirection_target, "", "");
	}
	if (time < redirection_nextthink)
		return TRUE;

	redirection_nextthink = time + 1;
	clients_found = 0;
	CLIENT_FOR_EACH_REAL(self) {
		print("Redirecting: sending connect command to ", self.netname, "\n");
		if (redirection_target == "self")
			stuffcmd(self, "\ndisconnect; reconnect\n");
		else
			stuffcmd(self, strcat("\ndisconnect; connect ", redirection_target, "\n"));

		++clients_found;
	}
	print("Redirecting: ", ftos(clients_found), " clients left.\n");
	if (time > redirection_timeout || clients_found == 0)
		localcmd("\nwait; wait; wait; quit\n");

	return TRUE;
}

void(void) world_wait_local_client {
	entity e;
	CLIENT_FOR_EACH_REAL(e)
		if (e.netaddress == "local") {
			client_send_stuff(e);
			remove(self);
			return;
		}
	self.nextthink = time;
}

//NEH_RESTOREGAME
//idea: Nehahra
//darkplaces implementation: LordHavoc
//engine-called QC prototypes:
//void() RestoreGame;
//description:
//when a savegame is loaded, this function is called
#define world_restore RestoreGame
void(void) world_restore {
	// Loaded from a save game
	// some things then break, so let's work around them...
	db_init();
	// Mapinfo
	map_info_on_restore();
	world_dynamic_init();
	if not(dlc_ready_all())
		dlc_reload();

	game_type_switch(game_type_from_name("single"));
	game_type_readcvars();
	entity e = spawn();
	e.nextthink = time;
	e.think = world_wait_local_client;
}

//DP_SV_SHUTDOWN
//idea: div0
//darkplaces implementation: div0
//A function that gets called just before progs exit. To save persistent data from.
//It is not called on a crash or error.
//void SV_Shutdown();
#define world_shutdown SV_Shutdown
void(void) world_shutdown {
	if (map_finished > 1) // shutting down already?
		return;

	dlc_finish();
	map_finished = 2; // 2 = server shutting down
	if (world_initialized > 0) {
		world_initialized = 0;
		print("Saving persistent data...\n");
		ban_save();
		print("done!\n");
		// tell the bot system the game is ending now
		bot_endgame();
		map_info_shutdown();
		infomessages_shutdown();
		plugin_chain_shutdown();
		db_shutdown();
		campaign_restart();
		cvar_settemp_restore();
	} else if (world_initialized == 0) {
		print("NOTE: crashed before even initializing the world, not saving persistent data\n");
	}
	require_spawnfunc_prefix = 0;
}

void(void) world_creature_frame {
	entity oldself;
	float dm;
	oldself = self;
	self = findfloat(world, iscreature, TRUE);
	while (self) {
		if (self.movetype != MOVETYPE_NOCLIP) {
			if (self.waterlevel) {
				if (!(self.flags & FL_INWATER)) {
					self.flags |= FL_INWATER;
					self.dmgtime = time - 0.1;
				}
				if (self.waterlevel != WATER_LEVEL_SUBMERGED) {
					if (self.air_finished < time + 9) {
						sound(self, CHAN_PLAYER, sound_random_by_str(self.playersound_gasp), VOL_BASE, ATTN_NORM);
						self.nextstep = time + 1.5;
					}
					self.air_finished = time + 12;
					if (self.nextstep < time)
					if (self.waterlevel < WATER_LEVEL_SUBMERGED)
					if (vlen(self.velocity) > 220) {
						self.nextstep = time + 1.5;
						sound(self, CHAN_PLAYER, "misc/outwater.wav", VOL_BASE * 0.25, ATTN_NORM);
					}
				} else if (self.air_finished < time) { // drown!
					if (!self.deadflag)
					if (self.pain_finished < time) {
						damage(self, world, world, 5, DEATH_DROWN, self.origin, '0 0 0');
						self.pain_finished = time + 0.5;
					}
				}
				if (self.dmgtime < time) {
					self.dmgtime = self.dmgtime + 0.1;
					if (self.watertype == CONTENT_LAVA) {
						if (self.watersound_finished < time) {
							self.watersound_finished = time + 0.5;
							sound(self, CHAN_PLAYER, "player/lava.wav", VOL_BASE, ATTN_NORM);
						}
						damage(self, world, world, g_lava_damage_factor * self.waterlevel, DEATH_LAVA, self.origin, '0 0 0');
						fire_add_damage(self, world, g_lava_fire_factor * self.waterlevel, g_lava_fire_time, DEATH_LAVA);
					} else if (self.watertype == CONTENT_SLIME) {
						if (self.watersound_finished < time) {
							self.watersound_finished = time + 0.5;
							sound(self, CHAN_PLAYER, "player/slime.wav", VOL_BASE, ATTN_NORM);
						}
						damage(self, world, world, 2 * self.waterlevel, DEATH_SLIME, self.origin, '0 0 0');
					}
				}
			} else {
				if (self.flags & FL_INWATER) {
					// play leave water sound
					self.flags &= ~FL_INWATER;
					self.dmgtime = 0;
				}
				self.air_finished = time + 12;
			}
			// check for falling damage
			dm = vlen(self.oldvelocity) - vlen(self.velocity);
			if (dm > 0) { // dm is now the velocity DECREASE. Velocity INCREASE should never cause a sound or any damage.
				if (self.deadflag)
					dm = (dm - g_balance_falldamage_deadminspeed) * g_balance_falldamage_factor;
				else
					dm = min((dm - g_balance_falldamage_minspeed) * g_balance_falldamage_factor, g_balance_falldamage_maxdamage);

				if (dm > 0)
					damage(self, world, world, dm, DEATH_FALL, self.origin, '0 0 0');

			}
			self.oldvelocity = self.velocity;
		}
		self = findfloat(self, iscreature, TRUE);
	}
	self = oldself;
}

float world_redirection_think();
void(void) world_frame_start { //called by engine
	extresponse_update();
	slowmo_update();
	projectile_check();
	entity e;
	entity oldself = self;
	for (e = world; (e = findfloat(e, movetype, MOVETYPE_QCWALK)); ) {
		if (e.think)
		if (e.nextthink)
		if (e.nextthink <= time) {
			self = e;
			self.nextthink = 0;
			self.think();
		}
	}
	self = oldself;
	if (world_redirection_think())
		return;

	entity_initialize_run();
	sys_ticrate = cvar("sys_ticrate");
	world_creature_frame();
	world_check_rules();
	plugin_chain_world_frame_start();
	bot_serverframe();
}

void(float dorespawn) world_reset {
	entity oldself;
	oldself = self;
	plugin_world_reset();
	for (self = world; (self = nextent(self)); )
	if (clienttype(self) == CLIENTTYPE_NOTACLIENT) {
		if (self.reset) {
			self.reset();
			continue;
		}
		if (self.team_saved)
			self.team = self.team_saved;
	}
	for (self = world; (self = nextent(self)); )
	if (clienttype(self) == CLIENTTYPE_NOTACLIENT) {
		if (self.reset2) {
			self.reset2();
			continue;
		}
	}
	if (dorespawn)
	CLIENT_FOR_EACH(self) {
		if (self.classname == "player") {
			self.killcount = 0;
			self.velocity = '0 0 0';
			self.avelocity = '0 0 0';
			self.movement = '0 0 0';
			client_put();
		}
	}
	self = oldself;
}
