float SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS = 1;
string redirection_target;
float world_initialized;
float g_balance_falldamage_deadminspeed;
float g_balance_falldamage_factor;
float g_balance_falldamage_minspeed;
float g_balance_falldamage_maxdamage;

void() world_cvar_changes_init {
	float h;
	string k, v, d;
	float n, i;

	if(cvar_changes)
		strunzone(cvar_changes);
	cvar_changes = string_null;

	h = buf_create();
	buf_cvarlist(h, "", "_"); // exclude all _ cvars as they are temporary
	n = buf_getsize(h);

	for(i = 0; i < n; ++i)
	{
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
		BADCVAR("g_maplist_index");
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
		BADCVAR("g_maplist_mostrecent");
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

void spawnfunc___init_dedicated_server(void)
{
	// handler for _init/_init map (only for dedicated server initialization)

	world_initialized = -1; // don't complain
	cvar = cvar_builtin;
	cvar_string = cvar_string_builtin;
	cvar_set = cvar_set_builtin;
	dprint_load(); // load dprint status from cvar

	entity e;
	map_goto_first_map();
	e = spawn();
	e.classname = "info_player_deathmatch"; // safeguard against player joining

	self.classname = "worldspawn"; // safeguard against various stuff ;)

	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
}

void() world_precache {
#ifdef TTURRETS_ENABLED
    if (cvar("g_turrets"))
        turrets_precash();

#endif
    // gore and miscellaneous sounds
    //precache_sound ("misc/h2ohit.wav");
    precache_sound ("misc/armorimpact.wav");
    precache_sound ("misc/bodyimpact1.wav");
    precache_sound ("misc/bodyimpact2.wav");
    precache_sound ("misc/gib.wav");
	precache_randomsound("misc/gib_splat0", 4);
    precache_sound ("misc/hit.wav");
	precache_sound ("misc/menu2.wav");
    precache_randomsound("misc/hitground", 4);
    precache_randomsound("misc/metalhitground", 4);
    precache_sound("misc/outwater.wav");
    precache_sound ("misc/null.wav");
    precache_sound ("misc/spawn.wav");
    precache_sound ("misc/talk.wav");
    precache_sound ("misc/teleport.wav");
    precache_sound ("misc/poweroff.wav");
    precache_sound ("player/lava.wav");
    precache_sound ("player/slime.wav");

	precache_sound ("misc/jetpack_fly.wav");

    // announcer sounds - male
    precache_sound ("announcer/male/electrobitch.wav");
    precache_sound ("announcer/male/airshot.wav");
    precache_sound ("announcer/male/03kills.wav");
    precache_sound ("announcer/male/05kills.wav");
    precache_sound ("announcer/male/10kills.wav");
    precache_sound ("announcer/male/15kills.wav");
    precache_sound ("announcer/male/20kills.wav");
    precache_sound ("announcer/male/25kills.wav");
    precache_sound ("announcer/male/30kills.wav");
    precache_sound ("announcer/male/botlike.wav");
    precache_sound ("announcer/male/yoda.wav");
    precache_sound ("announcer/male/amazing.wav");
    precache_sound ("announcer/male/awesome.wav");
    precache_sound ("announcer/male/headshot.wav");
    precache_sound ("announcer/male/impressive.wav");

    // announcer sounds - robotic
    precache_sound ("announcer/robotic/prepareforbattle.wav");
    precache_sound ("announcer/robotic/begin.wav");
    precache_sound ("announcer/robotic/timeoutcalled.wav");
    precache_sound ("announcer/robotic/1fragleft.wav");
    precache_sound ("announcer/robotic/2fragsleft.wav");
    precache_sound ("announcer/robotic/3fragsleft.wav");
    precache_sound ("announcer/robotic/terminated.wav");
	precache_sound ("announcer/robotic/5minutesremain.wav");
	precache_sound ("announcer/robotic/1minuteremains.wav");

    precache_model ("models/sprites/0.spr32");
    precache_model ("models/sprites/1.spr32");
    precache_model ("models/sprites/2.spr32");
    precache_model ("models/sprites/3.spr32");
    precache_model ("models/sprites/4.spr32");
    precache_model ("models/sprites/5.spr32");
    precache_model ("models/sprites/6.spr32");
    precache_model ("models/sprites/7.spr32");
    precache_model ("models/sprites/8.spr32");
    precache_model ("models/sprites/9.spr32");
    precache_model ("models/sprites/10.spr32");
    precache_sound ("announcer/robotic/1.wav");
    precache_sound ("announcer/robotic/2.wav");
    precache_sound ("announcer/robotic/3.wav");
    precache_sound ("announcer/robotic/4.wav");
    precache_sound ("announcer/robotic/5.wav");
    precache_sound ("announcer/robotic/6.wav");
    precache_sound ("announcer/robotic/7.wav");
    precache_sound ("announcer/robotic/8.wav");
    precache_sound ("announcer/robotic/9.wav");
    precache_sound ("announcer/robotic/10.wav");

    // common weapon precaches
    precache_sound ("weapons/weapon_switch.wav");
    precache_sound ("weapons/weaponpickup.wav");
    precache_sound ("weapons/unavailable.wav");
}


void world_static_init(void)
{
#ifdef ALLOW_FORCEMODELS
	CACHE_CVAR(sv_clforceplayermodels);
#endif
	CACHE_CVAR(sv_loddistance1);
	CACHE_CVAR(sv_loddistance2);
	if(sv_loddistance2 <= sv_loddistance1)
		sv_loddistance2 = 1073741824; // enough to turn off LOD 2 reliably
	CACHE_CVAR(sv_foginterval);
	CACHE_CVAR(g_jetpack);
	CACHE_CVAR(g_norecoil);
	Warmup_Init();
	CACHE_CVAR(g_warmup_limit);
	CACHE_CVAR(g_warmup_allguns);
	CACHE_CVAR(g_warmup_allow_timeout);
	if not(inWarmupStage)
		game_starttime = cvar("g_start_delay");

	CACHE_CVAR(g_antilag_bullets);
	CACHE_CVAR(g_casings);
	CACHE_CVAR(g_projectiles_newton_style);
	CACHE_CVAR(g_balance_pause_fuel_regen);
	tracetoss = trace_toss_wrapper;
	skipnonsolid_init();
	CACHE_CVAR(g_maxpushtime);
	CACHE_CVAR(spawn_debug);
	CACHE_CVAR(spawn_debugview);
	CACHE_CVAR(g_telefrags);
	minstagib_init();
	item_init();
	rune_init();
	WalkieTalkie_Init();
	Akimbo_Init();
	hat_init();
	Radio_Init();
	BadAss_Init();
	DamageIndicator_Init();
	monster_monsters_init();
	WarpZone_Init();
	SelectableWeapon_Init();
	TwoWeapons_Init();
	UDPChat_Init();
	timeout_init();
	sysinfo_init();
	footsteps_init();
	if (cvar("g_buttons_hookuse_swap")) {
		BUTTON_HOOK = buttonuse;
		BUTTON_USE = button6;
	}
	registercvar("connections_xonotic", "0");
	registercvar("connections_rexuiz", "0");
	registercvar("connections_nexuiz", "0");
	registercvar("connections_oldnexuiz", "0");
}

void world_dynamic_init() {
	CACHE_CVAR(g_balance_falldamage_deadminspeed);
	CACHE_CVAR(g_balance_falldamage_factor);
	CACHE_CVAR(g_balance_falldamage_minspeed);
	CACHE_CVAR(g_balance_falldamage_maxdamage);
	weapon_init();
	damage_init();
	fire_init();
	physic_init();
	bot_init();
	spawn_init();
	client_initialize();
	spectator_init();
	team_init();
	hook_init(FALSE);
	turret_readcvars();
	WaypointSprite_Init();
	default_player_alpha = cvar("g_player_alpha");
	default_weapon_alpha = cvar("g_weapon_alpha");
	if not(default_player_alpha)
		default_player_alpha = 1;

	if not(default_weapon_alpha)
		default_weapon_alpha = 1;

	Vote_Init();
	push_init();
	player_init();
	backpack_init();
	pinata_init();
	chat_init();
}

void world_db_init() {
	ServerProgsDB = db_load("server.db");
	TemporaryDB = db_create();
}

string world_getrecords() {
    float i;
    string s;
    s = "";
	for (i = 0; i < MapInfo_count; ++i)
		if (MapInfo_Get_ByID(i))
			s = strcat(s, GameHook_RecordForMap(MapInfo_Map_bspname));

    MapInfo_ClearTemps();
    if (s == "")
        return "No records are available on this server.\n";
    else
        return strcat("Records on this server:\n", s);
}

float world_already_spawned;
void spawnfunc_worldspawn (void)
{
	gettaginfo_parent = 0;
	gettaginfo_offset = '0 0 0';
	gettaginfo_forward = '0 0 0';
	gettaginfo_right = '0 0 0';
	gettaginfo_up = '0 0 0';
	//trace_dphittexturename = "";

	float fd, l, i, j, n;
	string s, col;

	cvar = cvar_builtin;
	cvar_string = cvar_string_builtin;
	cvar_set = cvar_set_builtin;
	dprint_load(); // load dprint status from cvar

	if(world_already_spawned)
		error("world already spawned - you may have EXACTLY ONE worldspawn!");
	world_already_spawned = TRUE;
	compressShortVector_init();

	local entity head;
	head = nextent(world);
	maxclients = 0;
	while(head)
	{
		++maxclients;
		head = nextent(head);
	}

	world_db_init();

	/*
	TODO sound pack system
	// initialize sound pack system
	soundpack = cvar_string("g_soundpack");
	if(soundpack != "")
		soundpack = strcat(soundpack, "/");
	soundpack = strzone(soundpack);
	*/

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

	world_cvar_changes_init();
	CACHE_CVAR(g_campaign);
	if(g_campaign)
		CampaignPreInit();

	map_mark_as_recent(mapname);

	precache_model("null"); // we need this one before gametype_init. or maybe not
	gametype_init();
	cvar_init(g_campaign ? "campaign" : cvar_string("g_profile"));
	sv_world_scale = cvar("sv_world_scale");
	if (sv_world_scale <= 0)
		sv_world_scale = 1;
	PL_VIEW_OFS = '0 0 35' * sv_world_scale;
	PL_MIN = '-16 -16 -24' * sv_world_scale;
	PL_MAX = '16 16 45' * sv_world_scale;
	PL_CROUCH_VIEW_OFS = '0 0 15' * sv_world_scale;
	PL_CROUCH_MIN = '-16 -16 -24' * sv_world_scale;
	PL_CROUCH_MAX = '16 16 25' * sv_world_scale;
	dlc_init();
	// needs to be done so early as they would still spawn
	weapon_register_weapons();
	GameTypeVote_Init();
	world_static_init();
	world_dynamic_init();
	HG_Init();

	player_count = 0;
	bot_waypoints_for_items = cvar("g_waypoints_for_items");
	if(bot_waypoints_for_items == 1)
		if(self.spawnflags & SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS)
			bot_waypoints_for_items = 0;

	world_precache();

	//if (g_domination)
	//	dom_init();

	cvar_set("nextmap", "");

	if(g_campaign)
		CampaignPostInit();

	Ban_Init();

	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()) | GameTypeVote_Mask(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1);

	if(whichpack(strcat("maps/", mapname, ".cfg")) != "")
	{
		fd = fopen(strcat("maps/", mapname, ".cfg"), FILE_READ);
		if(fd != -1)
		{
			while((s = fgets(fd)))
			{
				l = tokenize_console(s);
				if(l < 2)
					continue;
				if(argv(0) == "cd")
				{
					print("Found ^1DEPRECATED^7 cd loop command in .cfg file; put this line in mapinfo instead:\n");
					print("  cdtrack ", argv(2), "\n");
				}
				else if(argv(0) == "fog")
				{
					print("Found ^1DEPRECATED^7 fog command in .cfg file; put this line in worldspawn in the .map/.bsp/.ent file instead:\n");
					print("  \"fog\" \"", s, "\"\n");
				}
				else if(argv(0) == "set")
				{
					print("Found ^1DEPRECATED^7 set command in .cfg file; put this line in mapinfo instead:\n");
					print("  clientsettemp_for_type all ", argv(1), " ", argv(2), "\n");
				}
				else if(argv(0) != "//")
				{
					print("Found ^1DEPRECATED^7 set command in .cfg file; put this line in mapinfo instead:\n");
					print("  clientsettemp_for_type all ", argv(0), " ", argv(1), "\n");
				}
			}
			fclose(fd);
		}
	}

	addstat(STAT_WEAPONS, AS_INT, weapons);
	addstat(STAT_SWITCHWEAPON, AS_INT, switchweapon);
	addstat(STAT_GAMESTARTTIME, AS_FLOAT, stat_game_starttime);
	ready_nagger_init();

	addstat(STAT_PRESSED_KEYS, AS_FLOAT, pressedkeys);
	addstat(STAT_FUEL, AS_INT, ammo_fuel);
	addstat(STAT_DAMAGE_HITS, AS_INT, damage_hits);
 	addstat(STAT_DAMAGE_FIRED, AS_INT, maxdamage_fired);
	addstat(STAT_LEADLIMIT, AS_FLOAT, stat_leadlimit);
	addstat(STAT_BULLETS_LOADED, AS_INT, campingrifle_bulletcounter);
	addstat(STAT_PLAYER_STATE, AS_INT, deadflag);
	addstat(STAT_SPECSTATUS, AS_INT, spectatee_status);

	next_pingtime = time + 5;

	lsmaps_reply = "^7Maps available: ";
	lsmaps_reply2 = "";
	for(i = 0, j = 0; i < MapInfo_count; ++i)
	{
		if(MapInfo_Get_ByID(i))
			if not(MapInfo_Map_flags & (MAPINFO_FLAG_HIDDEN | MAPINFO_FLAG_FORBIDDEN))
			{
				if(mod(i, 2))
					col = "^2";
				else
					col = "^3";
				++j;
				lsmaps_reply = strcat(lsmaps_reply, col, MapInfo_Map_bspname, " ");
				lsmaps_reply2 = strcat(lsmaps_reply2, MapInfo_Map_bspname, " ");
			}
	}
	lsmaps_reply = strzone(strcat(lsmaps_reply, "\n"));
	lsmaps_reply2 = strzone(lsmaps_reply2);

	maplist_reply = "^7Maps in list: ";
	n = tokenize_console(cvar_string("g_maplist"));
	for(i = 0, j = 0; i < n; ++i)
	{
		if(MapInfo_CheckMap(argv(i)))
		{
			if(mod(j, 2))
				col = "^2";
			else
				col = "^3";
			maplist_reply = strcat(maplist_reply, col, argv(i), " ");
			++j;
		}
	}
	maplist_reply = strzone(strcat(maplist_reply, "\n"));
	MapInfo_ClearTemps();

	records_reply = zone_ifneeded(world_getrecords());

	client_init_spawn();
	random_seed_spawn();

	localcmd("\n_sv_hook_gamestart ", GametypeNameFromType(game), ";");

	world_initialized = 1;
	IRC_Init();
	infomessages_init();
}

void spawnfunc_light (void)
{
	remove(self);
}


/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
.float autoscreenshot;
float mapvote_initialized;
void IntermissionThink()
{
	FixIntermissionClient(self);

	if(cvar("sv_autoscreenshot"))
	if(self.autoscreenshot > 0)
	if(time > self.autoscreenshot)
	{
		self.autoscreenshot = -1;
		if(clienttype(self) == CLIENTTYPE_REAL)
			stuffcmd(self, "\nscreenshot\necho \"^5A screenshot has been taken at request of the server.\"\n");
		return;
	}

	if (time < intermission_exittime)
		return;

	if (GameTypeVote_Think())
		return;

	if(!mapvote_initialized)
		if (time < intermission_exittime + 10 && !self.BUTTON_ATCK && !self.BUTTON_JUMP && !self.BUTTON_ATCK2 && !self.BUTTON_HOOK && !self.BUTTON_USE)
			return;

	mapvote_start();
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
/*
entity FindIntermission()
{
	local	entity spot;
	local	float cyc;

// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot)
	{	// pick a random one
		cyc = random() * 4;
		while (cyc > 1)
		{
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;

// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

// then look for the start position
	spot = find (world, classname, "info_player_deathmatch");
	if (spot)
		return spot;

	//objerror ("FindIntermission: no spot");
	return world;
};
*/

/*
===============================================================================

RULES

===============================================================================
*/

void world_dump_stats(float final)
{
	local float file;
	local string s;
	local float to_console;
	local float to_file;
	local float i;

	to_console = cvar("sv_logscore_console");
	to_file = cvar("sv_logscore_file");

	if(!final)
		to_console = TRUE; // always print printstats replies

	if(final)
		s = ":scores:";
	else
		s = ":status:";
	s = strcat(s, GametypeNameFromType(game), "_", mapname, ":", ftos(rint(time)));

	if(to_console)
		print(s, "\n");
	if(to_file)
	{
		file = fopen(cvar_string("sv_logscore_filename"), FILE_APPEND);
		if(file == -1)
			to_file = FALSE;
		else
			fputs(file, strcat(s, "\n"));
	}

	s = strcat(":labels:player:", score_player_string(world, 0));
	if(to_console)
		print(s, "\n");
	if(to_file)
		fputs(file, strcat(s, "\n"));

	FOR_EACH_CLIENT(other)
	{
		if ((clienttype(other) == CLIENTTYPE_REAL) || (clienttype(other) == CLIENTTYPE_BOT && cvar("sv_logscore_bots")))
		{
			s = strcat(":player:see-labels:", score_player_string(other, 0), ":");
			s = strcat(s, ftos(rint(time - other.jointime)), ":");
			if(other.classname == "player")
				s = strcat(s, ftos(other.team), ":");
			else
				s = strcat(s, "spectator:");

			if(to_console)
				print(s, other.netname, "\n");
			if(to_file)
				fputs(file, strcat(s, other.netname, "\n"));
		}
	}

	if(teamplay)
	{
		s = strcat(":labels:teamscores:", score_team_string(0, 0));
		if(to_console)
			print(s, "\n");
		if(to_file)
			fputs(file, strcat(s, "\n"));

		for(i = 1; i < 16; ++i)
		{
			s = strcat(":teamscores:see-labels:", score_team_string(i, 0));
			s = strcat(s, ":", ftos(i));
			if(to_console)
				print(s, "\n");
			if(to_file)
				fputs(file, strcat(s, "\n"));
		}
	}

	if(to_console)
		print(":end\n");
	if(to_file)
	{
		fputs(file, ":end\n");
		fclose(file);
	}
}

void FixIntermissionClient(entity e)
{
	string s;
	if(!e.autoscreenshot) // initial call
	{
		e.angles = e.v_angle;
		e.angles_x = -e.angles_x;
		e.autoscreenshot = time + 0.8;	// used for autoscreenshot
		e.solid = SOLID_NOT;
		e.movetype = MOVETYPE_NONE;
		e.takedamage = DAMAGE_NO;
		if(e.weaponentity)
		{
			e.weaponentity.effects = EF_NODRAW;
			if (e.weaponentity.weaponentity)
				e.weaponentity.weaponentity.effects = EF_NODRAW;
		}
		if(clienttype(e) == CLIENTTYPE_REAL)
		{
			stuffcmd(e, "\nscr_printspeed 1000000\n");
			s = cvar_string("sv_intermission_cdtrack");
			if(s != "")
				stuffcmd(e, strcat("\ncd loop ", s, "\n"));
		}
	}

	//e.velocity = '0 0 0';
	//e.fixangle = TRUE;

	// TODO halt weapon animation
}

float checkrules_equality;
float checkrules_suddendeathwarning;
float checkrules_suddendeathend;
float checkrules_overtimesadded; //how many overtimes have been already added

float() world_check_rules_run_out_spawns {
	entity head;

	if(!have_team_spawns)
		return FALSE;

	if(!some_spawn_has_been_used)
		return FALSE;

	team1_score = team2_score = team3_score = team4_score = 0;

	FOR_EACH_PLAYER(head) if(head.deadflag == DEAD_NO)
	{
		if(head.team == COLOR_TEAM1)
			team1_score = 1;
		else if(head.team == COLOR_TEAM2)
			team2_score = 1;
		else if(head.team == COLOR_TEAM3)
			team3_score = 1;
		else if(head.team == COLOR_TEAM4)
			team4_score = 1;
	}

	for(head = world; (head = find(head, classname, "info_player_deathmatch")) != world; )
	{
		if(head.team == COLOR_TEAM1)
			team1_score = 1;
		else if(head.team == COLOR_TEAM2)
			team2_score = 1;
		else if(head.team == COLOR_TEAM3)
			team3_score = 1;
		else if(head.team == COLOR_TEAM4)
			team4_score = 1;
	}

	world_winners_clear();
	if(team1_score + team2_score + team3_score + team4_score == 0)
	{
		checkrules_equality = TRUE;
		return TRUE;
	}
	else if(team1_score + team2_score + team3_score + team4_score == 1)
	{
		float t, i;
		if(team1_score) t = COLOR_TEAM1;
		if(team2_score) t = COLOR_TEAM2;
		if(team3_score) t = COLOR_TEAM3;
		if(team4_score) t = COLOR_TEAM4;
		team_teams_allowed(world);
		for(i = 0; i < MAX_TEAMSCORE; ++i)
		{
			if(t != COLOR_TEAM1) if(c1 >= 0) score_team_add_to(COLOR_TEAM1, i, -1000);
			if(t != COLOR_TEAM2) if(c2 >= 0) score_team_add_to(COLOR_TEAM2, i, -1000);
			if(t != COLOR_TEAM3) if(c3 >= 0) score_team_add_to(COLOR_TEAM3, i, -1000);
			if(t != COLOR_TEAM4) if(c4 >= 0) score_team_add_to(COLOR_TEAM4, i, -1000);
		}

		world_winners_add(team, t);
		return TRUE;
	}
	else
		return FALSE;
}


void world_overtime()
{
	// Check first whether normal overtimes could be added before initiating suddendeath mode
	// - for this timelimit_overtime needs to be >0 of course
	// - also check the winning condition calculated in the previous frame and only add normal overtime
	//   again, if at the point at which timelimit would be extended again, still no winner was found
	if (GameHook_OvertimeHandle())
		return;

	if ((checkrules_overtimesadded >= 0) && (checkrules_overtimesadded < cvar("timelimit_overtimes")) && cvar("timelimit_overtime"))
	{
		++checkrules_overtimesadded;
		//add one more overtime by simply extending the timelimit
		float tl;
		tl = cvar("timelimit");
		tl += cvar("timelimit_overtime");
		cvar_set("timelimit", ftos(tl));
		string minutesPlural;
		if (cvar("timelimit_overtime") == 1)
			minutesPlural = " ^3minute";
		else
			minutesPlural = " ^3minutes";

		GameStatus_Set(strcat("^3Now playing ^1OVERTIME^3!\n\n^3Added ^1", ftos(cvar("timelimit_overtime")), minutesPlural, " to the game!"), 1);
	} else if (!checkrules_suddendeathend)
		checkrules_suddendeathend = time + 60 * cvar("timelimit_suddendeath");
}

// set the .winning flag for exactly those players with a given field value
void(.float field, float value) world_winners_set {
	entity head;
	FOR_EACH_PLAYER(head)
		head.winning = (head.field == value);
}

// set the .winning flag for those players with a given field value
void(.float field, float value) world_winners_add {
	entity head;
	FOR_EACH_PLAYER(head)
		if(head.field == value)
			head.winning = 1;
}

// clear the .winning flags
void(void) world_winners_clear {
	entity head;
	FOR_EACH_PLAYER(head)
		head.winning = 0;
}

void world_check_0min_remaining(float timelimit) { }
var void(float timelimit) world_check_time_remaining = world_check_0min_remaining;
void world_check_1min_remaining(float timelimit) {
	if (time + 60 >= timelimit) {
		play2all("announcer/robotic/1minuteremains.wav");
		world_check_time_remaining = world_check_0min_remaining;
	}
}

void world_check_5min_remaining(float timelimit) {
	if (time + 300 >= timelimit) {
		play2all("announcer/robotic/5minutesremain.wav");
		world_check_time_remaining = world_check_1min_remaining;
	}
}

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() world_gameover {
	float minTotalFrags;
	float maxTotalFrags;
	float score;
	float f;
	gameover = TRUE;
	cvar_deinit();
	string gameover_message;
	gameover_message = "^2Game finished!";
	if (teamplay) {
		if (score_winning_condition_helper_winnerteam > 0)
			gameover_message = strcat(gameover_message, "\n", Team_ColorCode(score_winning_condition_helper_winnerteam), team_color_name(score_winning_condition_helper_winnerteam), " Team^2 wins!");
	} else {
		if (score_winning_condition_helper_winner)
			gameover_message = strcat(gameover_message, "\nThe winner is ", score_winning_condition_helper_winner.netname);
	}
	GameStatus_Set(GameHook_GameOverMessageMod(gameover_message), 30);
	play2all("misc/menu2.wav");
	intermission_running = 1;
// enforce a wait time before allowing changelevel
	if(player_count > 0)
		intermission_exittime = time + cvar("sv_mapchange_delay");
	else
		intermission_exittime = -1;

	VoteReset();
	world_dump_stats(TRUE);
	IRC_Announce_GameOver();
	FOR_EACH_CLIENT(other)
	{
		FixIntermissionClient(other);

		if(other.winning)
			bprint(other.netname, " ^7wins.\n");
	}
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_GAMEOVER);
	minTotalFrags = 0;
	maxTotalFrags = 0;
	FOR_EACH_PLAYER(other)
	{
		if(maxTotalFrags < other.totalfrags)
			maxTotalFrags = other.totalfrags;
		if(minTotalFrags > other.totalfrags)
			minTotalFrags = other.totalfrags;
	}
	if(!currentbots)
	{
		FOR_EACH_PLAYER(other)
		{
			score = (other.totalfrags - minTotalFrags) / max(maxTotalFrags - minTotalFrags, 1);
			f = bound(0, other.play_time / max(time, 1), 1);
			// store some statistics?
		}
	}
	if(g_campaign)
		CampaignPreIntermission();

	localcmd("\nsv_hook_gameend;");
}

/*
============
world_check_rules

Exit deathmatch games upon conditions
============
*/
void() world_check_rules {
	float timelimit;
	float fraglimit;

	VoteThink();
	mapvote_think();
	if (gameover)	// someone else quit the game already
	{
		if(player_count == 0) // Nobody there? Then let's go to the next map
			mapvote_start();
			// this will actually check the player count in the next frame
			// again, but this shouldn't hurt
		return;
	}

	timelimit = cvar("timelimit") * 60;
	fraglimit = cvar("fraglimit");
	leadlimit = cvar("leadlimit");

	if(inWarmupStage || time <= game_starttime) // NOTE: this is <= to prevent problems in the very tic where the game starts
	{
		if(timelimit > 0)
			timelimit = 0; // timelimit is not made for warmup
		if(fraglimit > 0)
			fraglimit = 0; // no fraglimit for now
		leadlimit = 0; // no leadlimit for now
	}

	if(timelimit > 0)
	{
		timelimit += game_starttime;
	}
	else if (timelimit < 0)
	{
		// endmatch
		world_gameover();
		return;
	}

	if (time < game_starttime + frametime) {
		if (!inWarmupStage || time + 10 >= game_starttime) {
			float f = game_starttime - time;
			if (f >= 1) {
				if (floor(f - frametime) != floor(f)) {
					if (f < 4)
						play2all(strcat("announcer/robotic/", ftos(floor(f)), ".wav"));

					GameStatus_Set(strcat("^1Game starts in ", ftos(floor(f)), " seconds"), 2);
				}
			}
			if (time >= game_starttime) {
				GameStatus_Set("^1Begin!", 1);
				play2all("announcer/robotic/begin.wav");
				world_check_time_remaining = world_check_5min_remaining;
			}
		}
	} else if (timelimit)
		world_check_time_remaining(timelimit);

	if(checkrules_suddendeathend) {
		if(!checkrules_suddendeathwarning)
		{
			checkrules_suddendeathwarning = TRUE;
			GameStatus_Set(GameHook_SuddenDeathMessageMod("^3Now playing ^1OVERTIME^3!\n\n^3Keep fragging until we have a ^1winner^3!"), 1);
		}
	} else {
		if (timelimit)
		if (time >= timelimit) {
			if (GameHook_OvertimeAllowed()) {
				if (score_winning_condition_helper_equality) {
					world_overtime();
				} else {
					world_gameover();
					return;
				}
			} else {
				world_gameover();
				return;
			}
		}
	}
	if (GameHook_WinningCondition(fraglimit, leadlimit)) {
		world_gameover();
		return;
	}
	if (checkrules_suddendeathend)
	if (time >= checkrules_suddendeathend || !score_winning_condition_helper_equality)
	{
		world_gameover();
		return;
	}
};

void EndFrame()
{
	FOR_EACH_REALCLIENT(self)
	{
		if(self.classname == "spectator")
		{
			if(self.enemy.typehitsound)
				play2(self, "misc/typehit.wav");
			else if(self.enemy.hitsound && self.cvar_cl_hitsound)
				play2(self, "misc/hit.wav");
		}
		else
		{
			if(self.typehitsound)
				play2(self, "misc/typehit.wav");
			else if(self.hitsound && self.cvar_cl_hitsound)
				play2(self, "misc/hit.wav");
		}
	}
	FOR_EACH_CLIENT(self) {
		self.hitsound = FALSE;
		self.typehitsound = FALSE;
	}
	// add 1 frametime because client shows everything with
	// 1 frame of lag (cl_nolerp 0).
	antilag_record(time + frametime);
}


/*
 * world_redirection_think:
 * returns TRUE if redirecting
 */
float redirection_timeout;
float redirection_nextthink;
float world_redirection_think()
{
	float clients_found;

	if(redirection_target == "")
		return FALSE;

	if(!redirection_timeout)
	{
		cvar_set("sv_public", "-2");
		redirection_timeout = time + 0.6; // this will only try twice... should be able to keep more clients
		if(redirection_target == "self")
			bprint("^3SERVER NOTICE:^7 restarting the server\n");
		else
			bprint("^3SERVER NOTICE:^7 redirecting everyone to ", redirection_target, "\n");
	}

	if(time < redirection_nextthink)
		return TRUE;

	redirection_nextthink = time + 1;

	clients_found = 0;
	FOR_EACH_REALCLIENT(self)
	{
		print("Redirecting: sending connect command to ", self.netname, "\n");
		if(redirection_target == "self")
			stuffcmd(self, "\ndisconnect; reconnect\n");
		else
			stuffcmd(self, strcat("\ndisconnect; connect ", redirection_target, "\n"));
		++clients_found;
	}

	print("Redirecting: ", ftos(clients_found), " clients left.\n");

	if(time > redirection_timeout || clients_found == 0)
		localcmd("\nwait; wait; wait; quit\n");

	return TRUE;
}

void RestoreGame()
{
	// Loaded from a save game
	// some things then break, so let's work around them...

	// Progs DB (capture records)
	world_db_init();
	// Mapinfo
	MapInfo_OnRestore();
	world_dynamic_init();
	if not(dlc_ready_all())
		dlc_reload();
}

void SV_Shutdown()
{
	if(gameover > 1) // shutting down already?
		return;

	dlc_finish();
	gameover = 2; // 2 = server shutting down

	if(world_initialized > 0)
	{
		world_initialized = 0;
		print("Saving persistent data...\n");
		Ban_SaveBans();
		db_save(ServerProgsDB, "server.db");
		if(cvar("developer"))
			db_save(TemporaryDB, "server-temp.db");
		db_close(ServerProgsDB);
		db_close(TemporaryDB);
		print("done!\n");
		// tell the bot system the game is ending now
		bot_endgame();

		MapInfo_Shutdown();
		infomessages_shutdown();
		GameHookChain_Shutdown();
	}
	else if(world_initialized == 0)
	{
		print("NOTE: crashed before even initializing the world, not saving persistent data\n");
	}
	require_spawnfunc_prefix = 0;
}

void CreatureFrame (void)
{
	local entity oldself;
	local float dm;
	oldself = self;
	self = findfloat(world, iscreature, TRUE);
	while (self)
	{
		if (self.movetype != MOVETYPE_NOCLIP)
		{
			if (self.waterlevel)
			{
				if (!(self.flags & FL_INWATER))
				{
					self.flags |= FL_INWATER;
					self.dmgtime = 0;
				}
				if (self.waterlevel != WATERLEVEL_SUBMERGED)
				{
					if(self.air_finished < time + 9)
						sound(self, CHAN_PLAYER, randomsound_bystr(self.playersound_gasp), VOL_BASE, ATTN_NORM);
					self.air_finished = time + 12;
					if (self.nextstep < time)
					if (self.waterlevel < WATERLEVEL_SUBMERGED)
					if (vlen(self.velocity) > 220) {
						self.nextstep = time + 1.5;
						sound(self, CHAN_PLAYER, "misc/outwater.wav", VOL_BASE * 0.25, ATTN_NORM);
					}
				}
				else if (self.air_finished < time)
				{	// drown!
					if (!self.deadflag)
					if (self.pain_finished < time)
					{
						damage(self, world, world, 5, DEATH_DROWN, self.origin, '0 0 0');
						self.pain_finished = time + 0.5;
					}
				}
				if (self.dmgtime < time)
				{
					self.dmgtime = time + 0.1;
					if (self.watertype == CONTENT_LAVA)
					{
						if (self.watersound_finished < time)
						{
							self.watersound_finished = time + 0.5;
							sound (self, CHAN_PLAYER, "player/lava.wav", VOL_BASE, ATTN_NORM);
						}
						damage(self, world, world, 6 * self.waterlevel, DEATH_LAVA, self.origin, '0 0 0');
					}
					else if (self.watertype == CONTENT_SLIME)
					{
						if (self.watersound_finished < time)
						{
							self.watersound_finished = time + 0.5;
							sound (self, CHAN_PLAYER, "player/slime.wav", VOL_BASE, ATTN_NORM);
						}
						damage(self, world, world, 2 * self.waterlevel, DEATH_SLIME, self.origin, '0 0 0');
					}
				}
			}
			else
			{
				if (self.flags & FL_INWATER)
				{
					// play leave water sound
					self.flags &~= FL_INWATER;
					self.dmgtime = 0;
				}
				self.air_finished = time + 12;
			}
			// check for falling damage
			dm = vlen(self.oldvelocity) - vlen(self.velocity); // dm is now the velocity DECREASE. Velocity INCREASE should never cause a sound or any damage.
			if (self.deadflag)
				dm = (dm - g_balance_falldamage_deadminspeed) * g_balance_falldamage_factor;
			else
				dm = min((dm - g_balance_falldamage_minspeed) * g_balance_falldamage_factor, g_balance_falldamage_maxdamage);

			if (dm > 0)
				damage(self, world, world, dm, DEATH_FALL, self.origin, '0 0 0');

			self.oldvelocity = self.velocity;
		}
		self = findfloat(self, iscreature, TRUE);
	}
	self = oldself;
}

void() slowmo_update {
	slowmo = GameHookChain_TempoMod(1);
	cvar_set("slowmo", ftos(slowmo));
}

/*
=============
StartFrame

Called before each frame by the server
=============
*/
float world_redirection_think();
void StartFrame (void)
{
	ER_Update();
	slowmo_update();

#ifdef PROFILING
	if(time > client_cefc_accumulatortime + 1)
	{
		float t, pp, c_seeing, c_seen;
		entity cl;
		t = client_cefc_accumulator / (time - client_cefc_accumulatortime);
		print("CEFC time: ", ftos(t * 1000), "ms; ");
		c_seeing = 0;
		c_seen = 0;
		FOR_EACH_CLIENT(cl)
		{
			if(clienttype(cl) == CLIENTTYPE_REAL)
				++c_seeing;
			if(cl.classname == "player")
				++c_seen;
		}
		print("CEFC calls per second: ", ftos(c_seeing * (c_seen - 1) / t), "; ");
		print("CEFC 100% load at: ", ftos(solve_quadratic(t, -t, -1) * '0 1 0'), "\n");

		client_cefc_accumulatortime = time;
		client_cefc_accumulator = 0;
	}
#endif

	dprint_load(); // load dprint status from cvar

	entity e;
	for(e = world; (e = findfloat(e, csqcprojectile_clientanimate, 1)); )
		projectile_check(e);

	if(world_redirection_think())
		return;

	entity_initialize_run();

	sys_ticrate = cvar("sys_ticrate");

	skill = cvar("skill");

	// if in warmup stage and limit for warmup is hit start match
	if (inWarmupStage)
	if ((g_warmup_limit > 0 && time >= g_warmup_limit)
	 || (g_warmup_limit == 0 && cvar("timelimit") != 0 && time >= cvar("timelimit") * 60))
	{
		ready_restart();
		return;
	}

	CreatureFrame ();
	world_check_rules();

	GameHookChain_ServerFrame();
	bot_serverframe();

	if(spawn_debugview)
	{
		random_selection_init();
		for(self = world; (self = find(self, classname, "player")); )
			random_selection_add(self, 0, string_null, 1, 0);
		self = random_selection_chosen_ent;
		spawn_select(0);
	}
}

string gametype_patterns() {
	string s = cvar_string("sv_gametype_patterns");
	if (s == "") //Trying to guess
	{
		if (teamplay)
		{
			s = "team|ctf";
		}
		else if(cvar("g_maxplayers") == 2)
		{
			s = "tournament|duel";
		}
		else
		{
			s = "ffa";
		}
	}
	return s;
}

.vector originjitter;
.vector anglesjitter;
.float anglejitter;
.string gametypefilter;
.string gametype;
.string not_gametype;
.string cvarfilter;
void SV_OnEntityPreSpawnFunction()
{
	if(!self) //Skip pre-spawn function for world.
		return;
	string s;
	float i, n;
	if(self.gametypefilter != "")
	if not(isGametypeInFilter(game, teamplay, self.gametypefilter))
	{
		remove(self);
		return;
	}
	if (self.gametype != "")
	{
		s = gametype_patterns();
		float matched;
		matched = 0;
		n = tokenizebyseparator(s, "|");
		for (i = 0; i < n; i++)
		{
			s = argv(i);
			if(s == "")
				continue;
			if(strstrofs(self.gametype, s, 0) >= 0)
			{
				print(strcat("Found pattern '", s, "' for entity '", self.classname, "' with gametype '", self.gametype, "'\n"));
				matched = 1;
				break;
			}
		}
		if not(matched)
		{
			print(strcat("Removed entity '", self.classname, "' with gametype '", self.gametype, "' because no patterns found\n"));
			remove(self);
			return;
		}
	}
	if (self.not_gametype != "")
	{
		s = gametype_patterns();
		n = tokenizebyseparator(s, "|");
		for (i = 0; i < n; i++)
		{
			s = argv(i);
			if(s == "")
				continue;
			if(strstrofs(self.not_gametype, s, 0) >= 0)
			{
				print(strcat("Removed entity '", self.classname, "' with not allowed gametype '", self.not_gametype, "' because patterns found\n"));
				remove(self);
				return;
			}
		}
	}
	if(self.cvarfilter != "")
	{
		float o, inv;
		string k, v;
		inv = 0;

		s = self.cvarfilter;
		if(substring(s, 0, 1) == "+")
		{
			s = substring(s, 1, -1);
		}
		else if(substring(s, 0, 1) == "-")
		{
			inv = 1;
			s = substring(s, 1, -1);
		}

		n = tokenize(s);
		for(i = 0; i < n; ++i)
		{
			s = argv(i);
			// syntax:
			// var>x
			// var<x
			// var>=x
			// var<=x
			// var==x
			// var!=x
			// var===x
			// var!==x
			if((o = strstrofs(s, ">=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) < stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "<=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) > stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, ">", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) <= stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "<", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) >= stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "==", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) != stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "!=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) == stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "===", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar_string(k) != v)
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "!==", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar_string(k) == v)
					goto cvar_fail;
			}
			else if(substring(s, 0, 1) == "!")
			{
				k = substring(s, 1, -1);
				if(cvar(k))
					goto cvar_fail;
			}
			else
			{
				k = s;
				if not(cvar(k))
					goto cvar_fail;
			}
		}
		inv = !inv;
:cvar_fail
		// now inv is 1 if we want to keep the item, and 0 if we want to get rid of it
		if not(inv)
		{
			//print("cvarfilter fail\n");
			remove(self);
			return;
		}
	}

	// support special -1 and -2 angle from radiant
	if (self.angles == '0 -1 0')
		self.angles = '-90 0 0';
	else if (self.angles == '0 -2 0')
		self.angles = '+90 0 0';

	if(self.originjitter_x != 0)
		self.origin_x = self.origin_x + (random() * 2 - 1) * self.originjitter_x;
	if(self.originjitter_y != 0)
		self.origin_y = self.origin_y + (random() * 2 - 1) * self.originjitter_y;
	if(self.originjitter_z != 0)
		self.origin_z = self.origin_z + (random() * 2 - 1) * self.originjitter_z;
	if(self.anglesjitter_x != 0)
		self.angles_x = self.angles_x + (random() * 2 - 1) * self.anglesjitter_x;
	if(self.anglesjitter_y != 0)
		self.angles_y = self.angles_y + (random() * 2 - 1) * self.anglesjitter_y;
	if(self.anglesjitter_z != 0)
		self.angles_z = self.angles_z + (random() * 2 - 1) * self.anglesjitter_z;
	if(self.anglejitter != 0)
		self.angles_y = self.angles_y + (random() * 2 - 1) * self.anglejitter;

	string repl = cvar_string(strcat("sv_spawnreplace_", self.classname));
	if(repl != "")
	{
		print("Entity ", self.classname, " replaced with ", repl, "\n");
		self.classname = strzone(repl);
	}
	GameHookChain_EntityPreSpawn();
}

void(float dorespawn) world_reset {
	entity oldself;
	oldself = self;
	GameHook_Reset();
	for(self = world; (self = nextent(self)); )
	if(clienttype(self) == CLIENTTYPE_NOTACLIENT) {
		if(self.reset) {
			self.reset();
			continue;
		}
		if(self.team_saved)
			self.team = self.team_saved;

		if(self.flags & FL_PROJECTILE) // remove any projectiles left
		{
			stopsound(self, CHAN_PAIN);
			remove(self);
		}
	}
	for(self = world; (self = nextent(self)); )
	if(clienttype(self) == CLIENTTYPE_NOTACLIENT)
	{
		if(self.reset2)
		{
			self.reset2();
			continue;
		}
	}
	if(dorespawn)
	FOR_EACH_CLIENT(self) {
		if(self.flags & FL_CLIENT)				// reset all players
		if (self.classname == "player") {
			self.killcount = 0;
			self.velocity = '0 0 0';
			self.avelocity = '0 0 0';
			self.movement = '0 0 0';
			PutClientInServer();
		}
	}
	self = oldself;
}

/*
==================
main

unused but required by the engine
==================
*/
void main (void)
{

}
