float SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS = 1;
string redirection_target;
float world_initialized;
float g_balance_falldamage_deadminspeed;
float g_balance_falldamage_factor;
float g_balance_falldamage_minspeed;
float g_balance_falldamage_maxdamage;

string GetMapname();
string GetGametype();
void GotoNextMap();
void ShuffleMaplist();
float() DoNextMapOverride;
void Map_MarkAsRecent(string m);

void GotoFirstMap()
{
	float n;
	if(cvar("_sv_init"))
	{
		// cvar_set("_sv_init", "0");
		// we do NOT set this to 0 any more, so someone "accidentally" changing
		// to this "init" map on a dedicated server will cause no permanent
		// harm
		if(cvar("g_maplist_shuffle"))
			ShuffleMaplist();
		n = tokenizebyseparator(cvar_string("g_maplist"), " ");
		cvar_set("g_maplist_index", ftos(n - 1)); // jump to map 0 in GotoNextMap

		MapInfo_Enumerate();
		MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);

		if(!DoNextMapOverride())
			GotoNextMap();

		return;
	}

	if(time < 5)
	{
		self.nextthink = time;
	}
	else
	{
		self.nextthink = time + 1;
		print("Waiting for _sv_init being set to 1 by initialization scripts...\n");
	}
}

void cvar_changes_init()
{
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

#define BADPREFIX(p) if(substring(k, 0, strlen(p)) == p) continue
#define BADCVAR(p) if(k == p) continue
		// internal
		BADPREFIX("csqc_");
		BADPREFIX("cvar_check_");
		BADCVAR("gamecfg");
		BADCVAR("g_configversion");
		BADCVAR("g_maplist_index");
		BADCVAR("halflifebsp");

		// client
		BADPREFIX("cl_");
		BADPREFIX("con_");
		BADPREFIX("g_campaign");
		BADPREFIX("gl_");
		BADPREFIX("joy");
		BADPREFIX("menu_");
		BADPREFIX("net_slist_");
		BADPREFIX("r_");
		BADPREFIX("sbar_");
		BADPREFIX("hud_");
		BADPREFIX("scr_");
		BADPREFIX("userbind");
		BADPREFIX("v_");
		BADPREFIX("vid_");
		BADPREFIX("crosshair");
		BADCVAR("mod_q3bsp_lightmapmergepower");
		BADCVAR("mod_q3bsp_nolightmaps");

		// private
		BADPREFIX("g_ban_");
		BADPREFIX("g_chat_flood_");
		BADPREFIX("g_voice_flood_");
		BADPREFIX("rcon_");
		BADPREFIX("settemp_");
		BADPREFIX("sv_allowdownloads_");
		BADPREFIX("sv_autodemo");
		BADPREFIX("sv_curl_");
		BADPREFIX("sv_logscores_");
		BADPREFIX("sv_master");
		BADPREFIX("sv_world");
		BADCVAR("g_banned_list");
		BADCVAR("log_dest_udp");
		BADCVAR("log_file");
		BADCVAR("net_address");
		BADCVAR("port");
		BADCVAR("savedgamecfg");
		BADCVAR("sv_heartbeatperoid");
		BADCVAR("sv_vote_master_password");
		BADCVAR("sys_colortranslation");
		BADCVAR("sys_specialcharactertranslation");
		BADCVAR("timestamps");

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

		v = cvar_string(k);
		d = cvar_defstring(k);
		if(v != d)
		{
			cvar_changes = strcat(cvar_changes, k, " \"", v, "\" // \"", d, "\"\n");
			if(strlen(cvar_changes) > 16384)
			{
				cvar_changes = "// too many settings have been changed to show them here\n";
				break;
			}
		}
	}
	buf_del(h);
	if(cvar_changes == "")
		cvar_changes = "// this server runs at default settings\n";
	else
		cvar_changes = strcat("// this server runs at modified settings:\n", cvar_changes);
	cvar_changes = strzone(cvar_changes);
}

entity randomseed;
float RandomSeed_Send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_RANDOMSEED);
	WriteShort(MSG_ENTITY, self.cnt);
	return TRUE;
}
void RandomSeed_Think()
{
	self.cnt = bound(0, floor(random() * 65536), 65535);
	self.nextthink = time + 5;

	self.SendFlags |= 1;
}
void RandomSeed_Spawn()
{
	randomseed = spawn();
	randomseed.think = RandomSeed_Think;
	Net_LinkEntity(randomseed, FALSE, 0, RandomSeed_Send);

	entity oldself;
	oldself = self;
	self = randomseed;
	self.think(); // sets random seed and nextthink
	self = oldself;
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
	e = spawn();
	e.think = GotoFirstMap;
	e.nextthink = time; // this is usually 1 at this point

	e = spawn();
	e.classname = "info_player_deathmatch"; // safeguard against player joining

	self.classname = "worldspawn"; // safeguard against various stuff ;)

	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
}

void precache()
{
    // gamemode related things
    precache_model ("models/misc/chatbubble.spr");
    precache_model ("models/misc/teambubble.spr");
#ifdef TTURRETS_ENABLED
    if (cvar("g_turrets"))
        turrets_precash();
#endif
    if (g_footsteps)
    {
        precache_randomsound("misc/footstep0", 6);
        precache_randomsound("misc/metalfootstep0", 6);
        precache_sound("ambient/water.wav");
    }

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


void readlevelcvars(void)
{
#ifdef ALLOW_FORCEMODELS
	CACHE_CVAR(sv_clforceplayermodels);
#endif
	CACHE_CVAR(sv_loddistance1);
	CACHE_CVAR(sv_loddistance2);
	if(sv_loddistance2 <= sv_loddistance1)
		sv_loddistance2 = 1073741824; // enough to turn off LOD 2 reliably
	CACHE_CVAR(sv_foginterval);
	CACHE_CVAR(g_footsteps);
	CACHE_CVAR(g_jetpack);
	CACHE_CVAR(g_norecoil);
	CACHE_CVAR(sv_autotaunt);
	CACHE_CVAR(sv_taunt);

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
	CACHE_CVAR(sv_gameplayfix_skipnonsolid);
	if (sv_gameplayfix_skipnonsolid) {
		traceline = traceline_skipnonsolid;
		tracebox = tracebox_skipnonsolid;
		tracetoss = tracetoss_skipnonsolid;
	} else
		tracetoss = tracetoss_wrapper;
	CACHE_CVAR(g_maxpushtime);
	CACHE_CVAR(spawn_debug);
	CACHE_CVAR(spawn_debugview);
	CACHE_CVAR(g_telefrags);
	minstagib_init();
	Items_Init();
	runes_init();
	WalkieTalkie_Init();
	Akimbo_Init();
	Hat_Init();
	Radio_Init();
	BadAss_Init();
	DamageIndicator_Init();
	monsters_init();
	WarpZone_Init();
	SelectableWeapon_Init();
	TwoWeapons_Init();
	UDPChat_Init();
	timeout_init();
	if (cvar("g_buttons_hookuse_swap")) {
		BUTTON_HOOK = buttonuse;
		BUTTON_USE = button6;
	}
	registercvar("connections_xonotic", "0");
	registercvar("connections_rexuiz", "0");
	registercvar("connections_nexuiz", "0");
	registercvar("connections_oldnexuiz", "0");
}

void readdynamiccvars() {
	CACHE_CVAR(g_balance_falldamage_deadminspeed);
	CACHE_CVAR(g_balance_falldamage_factor);
	CACHE_CVAR(g_balance_falldamage_minspeed);
	CACHE_CVAR(g_balance_falldamage_maxdamage);
	W_Init();
	Damage_ReadCvars();
	PhysicReadCvars();
	bot_init();
	Client_ReadCvars();
	spectator_init();
	Teamplay_ReadCvars();
	GrappleHookReadCvars();
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
}

void DB_Init() {
	ServerProgsDB = db_load("server.db");
	TemporaryDB = db_create();
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

	if(cvar_string("cvar_check_default") != "bypass")
	{
		if(cvar_string("cvar_check_default") != CVAR_CHECK_DEFAULT)
			error("Config file mismatch! Please update defaultNexuiz.cfg to match the QuakeC code, and restart the engine!");

		if(cvar_string("cvar_check_balance") != CVAR_CHECK_BALANCE)
			error("Config file mismatch! Please update balance*.cfg to match the QuakeC code, and restart the engine!");
	}

	compressShortVector_init();

	local entity head;
	head = nextent(world);
	maxclients = 0;
	while(head)
	{
		++maxclients;
		head = nextent(head);
	}

	DB_Init();

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

	CACHE_CVAR(g_campaign);
	if(g_campaign)
		CampaignPreInit();

	Map_MarkAsRecent(mapname);

	precache_model("null"); // we need this one before gametype_init. or maybe not
	gametype_init();
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
	RegisterWeapons();
	GameTypeVote_Init();
	readlevelcvars();
	readdynamiccvars();
	HG_Init();

	player_count = 0;
	bot_waypoints_for_items = cvar("g_waypoints_for_items");
	if(bot_waypoints_for_items == 1)
		if(self.spawnflags & SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS)
			bot_waypoints_for_items = 0;

	precache();

	//if (g_domination)
	//	dom_init();

	matchid = strzone(ftos(random()));

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
	Nagger_Init();

	addstat(STAT_PRESSED_KEYS, AS_FLOAT, pressedkeys);
	addstat(STAT_FUEL, AS_INT, ammo_fuel);
	addstat(STAT_DAMAGE_HITS, AS_INT, damage_hits);
 	addstat(STAT_DAMAGE_FIRED, AS_INT, maxdamage_fired);
	addstat(STAT_LEADLIMIT, AS_FLOAT, stat_leadlimit);
	addstat(STAT_BULLETS_LOADED, AS_INT, campingrifle_bulletcounter);
	addstat(STAT_PLAYER_STATE, AS_INT, deadflag);
	addstat(STAT_SPECSTATUS, AS_INT, spectatee_status);

	next_pingtime = time + 5;
	InitializeEntity(self, cvar_changes_init, INITPRIO_CVARS);

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

	records_reply = strzone(getrecords());

	ClientInit_Spawn();
	RandomSeed_Spawn();

	localcmd("\n_sv_hook_gamestart ", GetGametype(), ";");

	world_initialized = 1;
	IRC_Init();
	InfoMessages_Init();
    IP2C_InitSV();
}

void spawnfunc_light (void)
{
	remove(self);
}

string GetGametype()
{
	return GametypeNameFromType(game);
}

string getmapname_stored;
string GetMapname()
{
	return mapname;
}

float Map_Count, Map_Current;
string Map_Current_Name;

// NOTE: this now expects the map list to be already tokenize()d and the count in Map_Count
float GetMaplistPosition()
{
	float pos, idx;
	string map;

	map = GetMapname();
	idx = cvar("g_maplist_index");

	if(idx >= 0)
		if(idx < Map_Count)
			if(map == argv(idx))
				return idx;

	for(pos = 0; pos < Map_Count; ++pos)
		if(map == argv(pos))
			return pos;

	// resume normal maplist rotation if current map is not in g_maplist
	return idx;
}

float MapHasRightSize(string map)
{
	float fh;
	if(currentbots || cvar("bot_number") || player_count < cvar("minplayers"))
	if(cvar("g_maplist_check_waypoints"))
	{
		dprint("checkwp "); dprint(map);
		fh = fopen(strcat("maps/", map, ".waypoints"), FILE_READ);
		if(fh < 0)
		{
			dprint(": no waypoints\n");
			return FALSE;
		}
		dprint(": has waypoints\n");
		fclose(fh);
	}

	// open map size restriction file
	dprint("opensize "); dprint(map);
	fh = fopen(strcat("maps/", map, ".sizes"), FILE_READ);
	if(fh >= 0)
	{
		float mapmin, mapmax;
		dprint(": ok, ");
		mapmin = stof(fgets(fh));
		mapmax = stof(fgets(fh));
		fclose(fh);
		if(player_count < mapmin)
		{
			dprint("not enough\n");
			return FALSE;
		}
		if(player_count > mapmax)
		{
			dprint("too many\n");
			return FALSE;
		}
		dprint("right size\n");
		return TRUE;
	}
	dprint(": not found\n");
	return TRUE;
}

string Map_Filename(float position)
{
	return strcat("maps/", argv(position), ".bsp");
}

string strwords(string s, float w)
{
	float endpos;
	for(endpos = 0; w && endpos >= 0; --w)
		endpos = strstrofs(s, " ", endpos + 1);
	if(endpos < 0)
		return s;
	else
		return substring(s, 0, endpos);
}

float strhasword(string s, string w)
{
	return strstrofs(strcat(" ", s, " "), strcat(" ", w, " "), 0) >= 0;
}

void Map_MarkAsRecent(string m)
{
	cvar_set("g_maplist_mostrecent", strwords(strcat(m, " ", cvar_string("g_maplist_mostrecent")), max(0, cvar("g_maplist_mostrecent_count"))));
}

float Map_IsRecent(string m)
{
	return strhasword(cvar_string("g_maplist_mostrecent"), m);
}

float Map_Check(float position, float pass)
{
	string filename;
	string map_next;
	map_next = argv(position);
	if(pass <= 1)
	{
		if(Map_IsRecent(map_next))
			return 0;
	}
	filename = Map_Filename(position);
	if(MapInfo_CheckMap(map_next))
	{
		if(pass == 2)
			return 1;
		if(MapHasRightSize(map_next))
			return 1;
		return 0;
	}
	else
		dprint( "Couldn't select '", filename, "'..\n" );

	return 0;
}

void Map_Goto_SetStr(string nextmapname)
{
	if(getmapname_stored != "")
		strunzone(getmapname_stored);
	if(nextmapname == "")
		getmapname_stored = "";
	else
		getmapname_stored = strzone(nextmapname);
}

void Map_Goto_SetFloat(float position)
{
	cvar_set("g_maplist_index", ftos(position));
	Map_Goto_SetStr(argv(position));
}

void GameResetCfg()
{
	// settings persist, except...
	localcmd("\nsettemp_restore\n");
};

void Map_Goto()
{
	GameResetCfg();
	MapInfo_LoadMap(getmapname_stored);
}

// return codes of map selectors:
//   -1 = temporary failure (that is, try some method that is guaranteed to succeed)
//   -2 = permanent failure
float() MaplistMethod_Iterate = // usual method
{
	float pass, i;

	for(pass = 1; pass <= 2; ++pass)
	{
		for(i = 1; i < Map_Count; ++i)
		{
			float mapindex;
			mapindex = mod(i + Map_Current, Map_Count);
			if(Map_Check(mapindex, pass))
				return mapindex;
		}
	}
	return -1;
}

float() MaplistMethod_Repeat = // fallback method
{
	if(Map_Check(Map_Current, 2))
		return Map_Current;
	return -2;
}

float() MaplistMethod_Random = // random map selection
{
	float i, imax;

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		float mapindex;
		mapindex = mod(Map_Current + floor(random() * (Map_Count - 1) + 1), Map_Count); // any OTHER map
		if(Map_Check(mapindex, 1))
			return mapindex;
	}
	return -1;
}

float(float exponent) MaplistMethod_Shuffle = // more clever shuffling
// the exponent sets a bias on the map selection:
// the higher the exponent, the less likely "shortly repeated" same maps are
{
	float i, j, imax, insertpos;

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		string newlist;

		// now reinsert this at another position
		insertpos = pow(random(), 1 / exponent);       // ]0, 1]
		insertpos = insertpos * (Map_Count - 1);       // ]0, Map_Count - 1]
		insertpos = ceil(insertpos) + 1;               // {2, 3, 4, ..., Map_Count}
		dprint("SHUFFLE: insert pos = ", ftos(insertpos), "\n");

		// insert the current map there
		newlist = "";
		for(j = 1; j < insertpos; ++j)                 // i == 1: no loop, will be inserted as first; however, i == 1 has been excluded above
			newlist = strcat(newlist, " ", argv(j));
		newlist = strcat(newlist, " ", argv(0));       // now insert the just selected map
		for(j = insertpos; j < Map_Count; ++j)         // i == Map_Count: no loop, has just been inserted as last
			newlist = strcat(newlist, " ", argv(j));
		newlist = substring(newlist, 1, strlen(newlist) - 1);
		cvar_set("g_maplist", newlist);
		Map_Count = tokenizebyseparator(cvar_string("g_maplist"), " ");

		// NOTE: the selected map has just been inserted at (insertpos-1)th position
		Map_Current = insertpos - 1; // this is not really valid, but this way the fallback has a chance of working
		if(Map_Check(Map_Current, 1))
			return Map_Current;
	}
	return -1;
}

void Maplist_Init()
{
	Map_Count = tokenizebyseparator(cvar_string("g_maplist"), " ");
	if(Map_Count == 0)
	{
		bprint( "Maplist is empty!  Resetting it to default map list.\n" );
		cvar_set("g_maplist", MapInfo_ListAllowedMaps(MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags()));
		if(cvar("g_maplist_shuffle"))
			ShuffleMaplist();
		localcmd("\nmenu_cmd sync\n");
		Map_Count = tokenizebyseparator(cvar_string("g_maplist"), " ");
	}
	if(Map_Count == 0)
		error("empty maplist, cannot select a new map");
	Map_Current = bound(0, GetMaplistPosition(), Map_Count - 1);

	if(Map_Current_Name)
		strunzone(Map_Current_Name);
	Map_Current_Name = strzone(argv(Map_Current)); // will be automatically freed on exit thanks to DP
	// this may or may not be correct, but who cares, in the worst case a map
	// isn't chosen in the first pass that should have been
}

string GetNextMap()
{
	float nextMap;

	Maplist_Init();
	nextMap = -1;

	if(nextMap == -1)
		if(cvar("g_maplist_shuffle") > 0)
			nextMap = MaplistMethod_Shuffle(cvar("g_maplist_shuffle") + 1);

	if(nextMap == -1)
		if(cvar("g_maplist_selectrandom"))
			nextMap = MaplistMethod_Random();

	if(nextMap == -1)
		nextMap = MaplistMethod_Iterate();

	if(nextMap == -1)
		nextMap = MaplistMethod_Repeat();

	if(nextMap >= 0)
	{
		Map_Goto_SetFloat(nextMap);
		return getmapname_stored;
	}

	return "";
};

float DoNextMapOverride()
{
	if(g_campaign)
	{
		CampaignPostIntermission();
		if (!campaign_map_transition) {
			alreadychangedlevel = TRUE;
			return TRUE;
		}
	}
	if(cvar("quit_when_empty"))
	{
		if(player_count <= currentbots)
		{
			localcmd("quit\n");
			alreadychangedlevel = TRUE;
			return TRUE;
		}
	}
	if(cvar_string("quit_and_redirect") != "")
	{
		redirection_target = strzone(cvar_string("quit_and_redirect"));
		alreadychangedlevel = TRUE;
		return TRUE;
	}
	if (cvar("samelevel") || GameHook_SameLevel()) // if samelevel is set, stay on same level
	{
		// this does not work because it tries to exec maps/nexdm01.mapcfg (which doesn't exist, it should be trying maps/dm_nexdm01.mapcfg for example)
		//localcmd(strcat("exec \"maps/", mapname, ".mapcfg\"\n"));
		// so instead just restart the current map using the restart command (DOES NOT WORK PROPERLY WITH exit_cfg STUFF)
		localcmd("restart\n");
		//changelevel (mapname);
		alreadychangedlevel = TRUE;
		return TRUE;
	}
	if(cvar_string("nextmap") != "")
		if(MapInfo_CheckMap(cvar_string("nextmap")))
		{
			Map_Goto_SetStr(cvar_string("nextmap"));
			Map_Goto();
			alreadychangedlevel = TRUE;
			return TRUE;
		}
	if(cvar("lastlevel"))
	{
		GameResetCfg();
		localcmd("set lastlevel 0\ntogglemenu\n");
		alreadychangedlevel = TRUE;
		return TRUE;
	}
	return FALSE;
};

void GotoNextMap()
{
	//local string nextmap;
	//local float n, nummaps;
	//local string s;
	if (alreadychangedlevel)
		return;
	alreadychangedlevel = TRUE;

	{
		string nextMap;
		float allowReset;

		for(allowReset = 1; allowReset >= 0; --allowReset)
		{
			nextMap = GetNextMap();
			if(nextMap != "")
				break;

			if(allowReset)
			{
				bprint( "Maplist contains no single playable map!  Resetting it to default map list.\n" );
				cvar_set("g_maplist", MapInfo_ListAllowedMaps(MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags()));
				if(cvar("g_maplist_shuffle"))
					ShuffleMaplist();
				localcmd("\nmenu_cmd sync\n");
			}
			else
			{
				error("Everything is broken - not even the default map list works. Please report this to the developers.");
			}
		}
		Map_Goto();
	}
};


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

void DumpStats(float final)
{
	local float file;
	local string s;
	local float to_console;
	local float to_file;
	local float i;

	to_console = cvar("sv_logscores_console");
	to_file = cvar("sv_logscores_file");

	if(!final)
		to_console = TRUE; // always print printstats replies

	if(final)
		s = ":scores:";
	else
		s = ":status:";
	s = strcat(s, GetGametype(), "_", GetMapname(), ":", ftos(rint(time)));

	if(to_console)
		print(s, "\n");
	if(to_file)
	{
		file = fopen(cvar_string("sv_logscores_filename"), FILE_APPEND);
		if(file == -1)
			to_file = FALSE;
		else
			fputs(file, strcat(s, "\n"));
	}

	s = strcat(":labels:player:", GetPlayerScoreString(world, 0));
	if(to_console)
		print(s, "\n");
	if(to_file)
		fputs(file, strcat(s, "\n"));

	FOR_EACH_CLIENT(other)
	{
		if ((clienttype(other) == CLIENTTYPE_REAL) || (clienttype(other) == CLIENTTYPE_BOT && cvar("sv_logscores_bots")))
		{
			s = strcat(":player:see-labels:", GetPlayerScoreString(other, 0), ":");
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
		s = strcat(":labels:teamscores:", GetTeamScoreString(0, 0));
		if(to_console)
			print(s, "\n");
		if(to_file)
			fputs(file, strcat(s, "\n"));

		for(i = 1; i < 16; ++i)
		{
			s = strcat(":teamscores:see-labels:", GetTeamScoreString(i, 0));
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


/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void NextLevel()
{
	float minTotalFrags;
	float maxTotalFrags;
	float score;
	float f;

	gameover = TRUE;
	game_cvar_deinit();
	string gameover_message;
	gameover_message = "^2Game finished!";
	if (teamplay) {
		if (WinningConditionHelper_winnerteam > 0)
			gameover_message = strcat(gameover_message, "\n", Team_ColorCode(WinningConditionHelper_winnerteam), Team_ColorName(WinningConditionHelper_winnerteam), " Team^2 wins!");
	} else {
		if (WinningConditionHelper_winner)
			gameover_message = strcat(gameover_message, "\nThe winner is ", WinningConditionHelper_winner.netname);
	}
	GameStatus_Set(GameHook_GameOverMessageMod(gameover_message), 30);
	play2all("misc/menu2.wav");

	intermission_running = 1;

// enforce a wait time before allowing changelevel
	if(player_count > 0)
		intermission_exittime = time + cvar("sv_mapchange_delay");
	else
		intermission_exittime = -1;

	/*
	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);
	WriteByte (MSG_ALL, 3);
	// done in FixIntermission
	*/

	//pos = FindIntermission ();

	VoteReset();

	DumpStats(TRUE);

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

	// WriteByte (MSG_ALL, SVC_INTERMISSION);
};

float checkrules_equality;
float checkrules_suddendeathwarning;
float checkrules_suddendeathend;
float checkrules_overtimesadded; //how many overtimes have been already added

void InitiateOvertime()
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

		bcenterprint(
			strcat(
				"^3Now playing ^1OVERTIME^3!\n\n^3Added ^1",
				ftos(cvar("timelimit_overtime")),
				minutesPlural,
				" to the game!"
			)
		);
	} else if (!checkrules_suddendeathend)
		checkrules_suddendeathend = time + 60 * cvar("timelimit_suddendeath");
}

// set the .winning flag for exactly those players with a given field value
void SetWinners(.float field, float value)
{
	entity head;
	FOR_EACH_PLAYER(head)
		head.winning = (head.field == value);
}

// set the .winning flag for those players with a given field value
void AddWinners(.float field, float value)
{
	entity head;
	FOR_EACH_PLAYER(head)
		if(head.field == value)
			head.winning = 1;
}

// clear the .winning flags
void ClearWinners(void)
{
	entity head;
	FOR_EACH_PLAYER(head)
		head.winning = 0;
}

void ShuffleMaplist()
{
	cvar_set("g_maplist", shufflewords(cvar_string("g_maplist")));
}

void check_0min_remaining(float timelimit) { }
var void(float timelimit) check_time_remaining = check_0min_remaining;
void check_1min_remaining(float timelimit) {
	if (time + 60 >= timelimit) {
		play2all("announcer/robotic/1minuteremains.wav");
		check_time_remaining = check_0min_remaining;
	}
}

void check_5min_remaining(float timelimit) {
	if (time + 300 >= timelimit) {
		play2all("announcer/robotic/5minutesremain.wav");
		check_time_remaining = check_1min_remaining;
	}
}

/*
============
CheckRules_World

Exit deathmatch games upon conditions
============
*/
void CheckRules_World()
{
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
		NextLevel();
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
				check_time_remaining = check_5min_remaining;
			}
		}
	} else if (timelimit)
		check_time_remaining(timelimit);

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
				if (WinningConditionHelper_equality) {
					InitiateOvertime();
				} else {
					NextLevel();
					return;
				}
			} else {
				NextLevel();
				return;
			}
		}
	}
	if (GameHook_WinningCondition(fraglimit, leadlimit)) {
		NextLevel();
		return;
	}
	if (checkrules_suddendeathend)
	if (time >= checkrules_suddendeathend || !WinningConditionHelper_equality)
	{
		NextLevel();
		return;
	}
};

string GotoMap(string m)
{
	if not(MapInfo_GetGameTypes(m) & (MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()) | GameTypeVote_Mask()))
		return "The map you chose is not available on this server.";
	cvar_set("nextmap", m);
	cvar_set("timelimit", "-1");
	if(mapvote_initialized || alreadychangedlevel)
	{
		if(DoNextMapOverride())
			return "Map switch initiated.";
		else
			return "Hm... no. For some reason I like THIS map more.";
	}
	else
		return "Map switch will happen after scoreboard.";
}


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
 * RedirectionThink:
 * returns TRUE if redirecting
 */
float redirection_timeout;
float redirection_nextthink;
float RedirectionThink()
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
	DB_Init();
	// Mapinfo
	MapInfo_OnRestore();
	readdynamiccvars();
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
		InfoMessages_Shutdown();
		GameHookChain_Shutdown();
	}
	else if(world_initialized == 0)
	{
		print("NOTE: crashed before even initializing the world, not saving persistent data\n");
	}
	require_spawnfunc_prefix = 0;
}
