// --------------------------------------------------------------------------
// BEGIN REQUIRED CSQC FUNCTIONS
//include "main.qh"

#define DP_CSQC_ENTITY_REMOVE_IS_B0RKED

var void(float) ent_parsers[ENT_CLIENT_COUNT];

string available_maps;
float available_maps_count;
float con_chat_save;
float con_chat_was_changed;

void cvar_clientsettemp(string cv, string val)
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		if(e.netname == cv)
			goto saved;
	e = spawn();
	e.classname = "saved_cvar_value";
	e.netname = strzone(cv);
	e.message = strzone(cvar_string(cv));
:saved
	cvar_set(cv, val);
}

void cvar_clientsettemp_restore()
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
			cvar_set(e.netname, e.message);
}

vector mi_picmin; // adjusted mins that map to the picture (square)
vector mi_picmax; // adjusted maxs that map to the picture (square)
vector mi_pictexcoord0; // texcoords of the image corners (after transforming, these are 2D coords too)
vector mi_pictexcoord1; // texcoords of the image corners (after transforming, these are 2D coords too)
vector mi_pictexcoord2; // texcoords of the image corners (after transforming, these are 2D coords too)
vector mi_pictexcoord3; // texcoords of the image corners (after transforming, these are 2D coords too)
void get_mi_min_max_texcoords(float mode)
{
	vector extend;

	world_get_min_max(mode);

	mi_picmin = world_min;
	mi_picmax = world_max;

	// extend mi_picmax to get a square aspect ratio
	// center the map in that area
	extend = mi_picmax - mi_picmin;
	if(extend_y > extend_x)
	{
		mi_picmin_x -= (extend_y - extend_x) * 0.5;
		mi_picmax_x += (extend_y - extend_x) * 0.5;
	}
	else
	{
		mi_picmin_y -= (extend_x - extend_y) * 0.5;
		mi_picmax_y += (extend_x - extend_y) * 0.5;
	}

	// add another some percent
	extend = (mi_picmax - mi_picmin) * (1 / 64.0);
	mi_picmin -= extend;
	mi_picmax += extend;

	// calculate the texcoords
	mi_pictexcoord0 = mi_pictexcoord1 = mi_pictexcoord2 = mi_pictexcoord3 = '0 0 0';
	// first the two corners of the origin
	mi_pictexcoord0_x = (world_min_x - mi_picmin_x) / (mi_picmax_x - mi_picmin_x);
	mi_pictexcoord0_y = (world_min_y - mi_picmin_y) / (mi_picmax_y - mi_picmin_y);
	mi_pictexcoord2_x = (world_max_x - mi_picmin_x) / (mi_picmax_x - mi_picmin_x);
	mi_pictexcoord2_y = (world_max_y - mi_picmin_y) / (mi_picmax_y - mi_picmin_y);
	// then the other corners
	mi_pictexcoord1_x = mi_pictexcoord0_x;
	mi_pictexcoord1_y = mi_pictexcoord2_y;
	mi_pictexcoord3_x = mi_pictexcoord2_x;
	mi_pictexcoord3_y = mi_pictexcoord0_y;
}

#ifdef USE_FTE
float __engine_check;
#endif

void Ent_Error(float ignore) {
	error(strcat("unknown entity type in CSQC_Ent_Update: ", ftos(self.enttype), "\n"));
}

void ClientUpdateMessage_Draw() {
	string msg;
	vector pos;
	pos_z = 0;
	float _alpha = 0.5 + math_mod(time, 2) * 0.5;

	msg = "^1WARNING: ^3Your client is not recommended!";
	pos_y = 10;
	pos_x = 10;
	drawcolorcodedstring(pos, msg, '18 36 0', _alpha, DRAWFLAG_NORMAL);

	pos_y += 32;
	drawcolorcodedstring(pos, self.bgmscript, '18 36 0', _alpha, DRAWFLAG_NORMAL);

	msg = "^3Please download and install Rexuiz from ^2http://rexuiz.top^7";
	pos_y += 32;
	drawcolorcodedstring(pos, msg, '18 36 0', _alpha, DRAWFLAG_NORMAL);
}

void ClientUpdateMessage(string msg, float timeout) {
	entity e = spawn();
	e.draw2d = ClientUpdateMessage_Draw;
	e.draw2dflag = 1;
	e.nextthink = time + timeout;
	e.think = stdproc_remove;
	e.bgmscript = msg;
}

void search_and_precache(string s) {
	float i;
	string pic;
	float glob = search_begin(s, TRUE, TRUE);
	if (glob < 0)
		return;

	for(i = 0; i < search_getsize(glob); ++i) {
		pic = search_getfilename(glob, i);
		//print("Precaching ", pic, "\n");
		precache_pic(pic);
		pic = substring(pic, 0, strstrofs(pic, ".tga", 0));
		//print("Precaching ", pic, "\n");
		precache_pic(pic);
	}
	search_end(glob);
}

void Ent_ReadEntCS(float bIsNewEntity);
void Ent_ScoresInfo(float ignore);
void Ent_ReadPlayerScore(float ignore);
void Ent_ReadTeamScore(float ignore);
void Ent_Nagger(float ignore);
void Ent_RandomSeed(float ignore);
void Ent_Init(float ignore);

// CSQC_Init : Called every time the CSQC code is initialized (essentially at map load)
// Useful for precaching things
void CSQC_Init(void)
{
#ifdef USE_FTE
#pragma target ID
	__engine_check = checkextension("DP_SV_WRITEPICTURE");
	if(!__engine_check)
	{
		print("^3Your engine build is outdated\n^3This Server uses a newer QC VM. Please update!\n");
		localcmd("\ndisconnect\n");
		return;
	}
#pragma target FTE
#endif
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
		ClientUpdateMessage("^3You play with really old Nexuiz client", 10);
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
	if (file_exists("gfx/crosshairdot.tga"))
		crosshairdot_tex = "gfx/crosshairdot.tga";
	else if (file_exists("gfx/crosshairdot.png"))
		crosshairdot_tex = "gfx/crosshairdot.png";

	drawfont = 0;

	for(i = 0; i < 255; ++i)
		if(getplayerkey(i, "viewentity") == "")
			break;
	maxclients = i;

	registercmd("ons_map");
	//registercmd("menu_action");

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

	postinit = false;

	calledhooks = 0;

	teams = spawn();
	player_list = spawn();

	GetTeam(COLOR_SPECTATOR, true); // add specs first

	cvar_clientsettemp("_supports_weaponpriority", "1");
	weapon_register_weapons();
	WaypointSprite_Load();

	Projectile_Precache();
	GibSplash_Precache();
	Casings_Precache();
	DamageInfo_Precache();
	WarpZone_Init();

	get_mi_min_max_texcoords(1); // try the CLEVER way first
	shortmapname = mapname;
	if(!strcasecmp(substring(shortmapname, 0, 5), "maps/"))
		shortmapname = substring(shortmapname, 5, strlen(shortmapname) - 5);

	if(!strcasecmp(substring(shortmapname, strlen(shortmapname) - 4, 4), ".bsp"))
		shortmapname = substring(shortmapname, 0, strlen(shortmapname) - 4);

	shortmapname = strzone(shortmapname);
	minimapname = strcat("gfx/", shortmapname, "_radar.tga");

	if(precache_pic(minimapname) == "")
	{
		// but maybe we have a non-clever minimap
		minimapname = strcat("gfx/", shortmapname, "_mini.tga");
		if(precache_pic(minimapname) == "")
			minimapname = ""; // FAIL
		else
			get_mi_min_max_texcoords(0); // load new texcoords
	}

	mi_center = (world_min + world_max) * 0.5;
	mi_scale = world_max - world_min;
	minimapname = strzone(minimapname);
	ext_DP_CSQC_QUERYRENDERENTITY = checkextension("DP_CSQC_QUERYRENDERENTITY");
	ext_DP_RM_SETRENDERENTITY = checkextension("DP_RM_SETRENDERENTITY");

	search_and_precache("gfx/num_*");
	search_and_precache("gfx/inv_*");
	search_and_precache("gfx/crosshair*");
	search_and_precache("gfx/sb_*");
	search_and_precache("gfx/hud/*.tga");
	search_and_precache("gfx/hud/keys/*.tga");
	search_and_precache("gfx/teamradar_*.tga");
	search_and_precache("models/sprites/wpn-*_frame*");
	for (i = 0; i < ENT_CLIENT_COUNT; i++) {
		ent_parsers[i] = Ent_Error;
	}
	ent_parsers[ENT_CLIENT_ENTCS] = Ent_ReadEntCS;
	ent_parsers[ENT_CLIENT_SCORES_INFO] = Ent_ScoresInfo;
	ent_parsers[ENT_CLIENT_SCORES] = Ent_ReadPlayerScore;
	ent_parsers[ENT_CLIENT_TEAMSCORES] = Ent_ReadTeamScore;
	ent_parsers[ENT_CLIENT_POINTPARTICLES] = Ent_PointParticles;
	ent_parsers[ENT_CLIENT_RAINSNOW] = Ent_RainOrSnow;
	ent_parsers[ENT_CLIENT_LASER] = Ent_Laser;
	ent_parsers[ENT_CLIENT_NAGGER] = Ent_Nagger;
	ent_parsers[ENT_CLIENT_WAYPOINT] = Ent_WaypointSprite;
	ent_parsers[ENT_CLIENT_RADARLINK] = Ent_RadarLink;
	ent_parsers[ENT_CLIENT_PROJECTILE] = Ent_Projectile;
	ent_parsers[ENT_CLIENT_GIBSPLASH] = Ent_GibSplash;
	ent_parsers[ENT_CLIENT_DAMAGEINFO] = Ent_DamageInfo;
	ent_parsers[ENT_CLIENT_CASING] = Ent_Casing;
	ent_parsers[ENT_CLIENT_INIT] = Ent_Init;
	ent_parsers[ENT_CLIENT_MAPVOTE] = Ent_MapVote;
	ent_parsers[ENT_CLIENT_RANDOMSEED] = Ent_RandomSeed;
	ent_parsers[ENT_CLIENT_WALL] = Ent_Wall;
	ent_parsers[ENT_CLIENT_MODELEFFECT] = Ent_ModelEffect;
	ent_parsers[ENT_CLIENT_PHYSICS] = Ent_Physic;
	ent_parsers[ENT_CLIENT_PHYSICS_SPIDERBOT] = Ent_PhysicSpiderbot;
	ent_parsers[ENT_CLIENT_PHYSICS_AIRCRAFT] = Ent_PhysicAircraft;
	ent_parsers[ENT_CLIENT_PHYSICS_CAR] = Ent_PhysicCar;
	ent_parsers[ENT_CLIENT_GAMESTATUS] = Ent_GameStatus;
	ent_parsers[ENT_CLIENT_MENU] = Ent_Menu;
	ent_parsers[ENT_CLIENT_PROGRESSBAR] = Ent_ProgressBar;
	ent_parsers[ENT_CLIENT_LOCATION_REQUEST] = Ent_LocationRequest;
	ent_parsers[ENT_CLIENT_DLC_LIST] = Ent_DLCList;
	ent_parsers[ENT_CLIENT_ZAPPER] = Zapper_Read_Beam;
	ent_parsers[ENT_CLIENT_ZAPPER_SHIELD] = Zapper_Read_Shield;
	ent_parsers[ENT_CLIENT_DMG_INDICATOR] = Ent_DamageIndicator;
	ent_parsers[ENT_CLIENT_INIT_IP2C] = inline void(void) { sv_ip2country = TRUE; };
	ent_parsers[ENT_CLIENT_WARPZONE] = WarpZone_Read;
	ent_parsers[ENT_CLIENT_FUNC_CAMERA] = func_camera_read;
	ent_parsers[ENT_CLIENT_WARPZONE_TELEPORTED] = WarpZone_Teleported_Read;
	ent_parsers[ENT_CLIENT_NOTELINE] = Ent_NoteLine;
	ent_parsers[ENT_CLIENT_HOOK] = Ent_GrapplingHook;
	ent_parsers[ENT_CLIENT_PHYSICS_HOOK] = hook_physics_read;
	ent_parsers[ENT_CLIENT_DLC_SOUND] = Ent_DLCSound;
	ent_parsers[ENT_CLIENT_PHYSICS_JETPACK] = jetpack_read;
	ent_parsers[ENT_CLIENT_LMS_SPHERE] = sphere_read;
	ent_parsers[ENT_CLIENT_ICE] = ice_read;
	SetConWidthHeight();
	sbar_font = FONT_USER+1;
	sbar_bigfont = FONT_USER+2;
	sbar_fontsize = '1 1 0';
	string s = strcat(cvar_string("cmdline"), " ", cvar_string("gl_info_renderer"), " ", cvar_string("gl_info_version"));
	s = strcat(s, " ", cvar_string("vid_width"), "x", cvar_string("vid_height"));
	s = strcat(s, " ", ftos(ceil(cvar("sys_memsize_physical") / 512) * 512));
	localcmd(strcat("\ncmd sysinfo ", s, "\n"));
}

// CSQC_Shutdown : Called every time the CSQC code is shutdown (changing maps, quitting, etc)
void CSQC_Shutdown(void)
{
#ifdef USE_FTE
#pragma TARGET id
	if(!__engine_check)
		return 0;
#pragma TARGET fte
#endif

	remove(teams);
	remove(player_list);
	db_close(binddb);
	db_close(tempdb);

	cvar_clientsettemp_restore();
	if (con_chat_was_changed)
		cvar_set("con_chat", ftos(con_chat_save));

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

.float has_team;
float SetTeam(entity o, float Team)
{
	entity tm;
	if (Team != -1)
	if (teamplay || Team)
	if not(GetTeam(Team, false))
		Team = COLOR_SPECTATOR;

	if(Team == -1) // leave
	{
		if(o.has_team)
		{
			//print("(DISCONNECT) leave team ", ftos(o.team), "\n");
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
			o.has_team = 0;
			return TRUE;
		}
	}
	else
	{
		if not(o.has_team)
		{
			//print("(CONNECT) enter team ", ftos(o.team), "\n");
			o.has_team = 1;
		}
		else if(Team != o.team)
		{
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
		} else
			return FALSE;

		tm = GetTeam(Team, false);
		if not(tm) {
			tm = GetTeam(COLOR_SPECTATOR, false);
			Team = COLOR_SPECTATOR;
		}
		o.team = Team;
		tm.team_size += 1;
		return TRUE;
	}
	return FALSE;
}

void PostInit(void)
{
	print(strcat("PostInit\n    maxclients = ", ftos(maxclients), "\n"));
	localcmd(strcat("\ncl_cmd sbar_columns_set ", cvar_string("sbar_columns"), ";\n"));
	postinit = true;
}

// CSQC_ConsoleCommand : Used to parse commands in the console that have been registered with the "registercmd" function
// Return value should be 1 if CSQC handled the command, otherwise return 0 to have the engine handle it.
float button_zoom;
void Cmd_Sbar_SetFields(float);
void Cmd_Sbar_Help(float);
float CSQC_ConsoleCommand(string strMessage)
{
	float argc;
	// Tokenize String
	//argc = tokenize(strMessage);
	argc = tokenize_console(strMessage);

	// Acquire Command
	local string strCmd;
	strCmd = argv(0);

	if(strCmd == "+button4") { // zoom
		// return false, because the message shall be sent to the server anyway (for demos/speccing)
		if(ignore_plus_zoom)
		{
			--ignore_plus_zoom;
			return false;
		}
		button_zoom = 1;
		return false;
	} else if(strCmd == "-button4") { // zoom
		if(ignore_minus_zoom)
		{
			--ignore_minus_zoom;
			return false;
		}
		button_zoom = 0;
		return false;
	} else if(strCmd == "+button3") { // secondary
		button_attack2 = 1;
		return false;
	} else if(strCmd == "-button3") { // secondary
		button_attack2 = 0;
		return false;
	} else if(strCmd == "+showscores") {
		sb_showscores = true;
		return true;
	} else if(strCmd == "-showscores") {
		sb_showscores = false;
		return true;
	} else if(strCmd == "+showaccuracy") {
		sb_showaccuracy = true;
		return true;
	} else if(strCmd == "-showaccuracy") {
		sb_showaccuracy = false;
		return true;
	}

	if(camera_active)
	if(strCmd == "+forward" || strCmd == "-back") {
		++camera_direction_x;
		return true;
	} else if(strCmd == "-forward" || strCmd == "+back") {
		--camera_direction_x;
		return true;
	} else if(strCmd == "+moveright" || strCmd == "-moveleft") {
		--camera_direction_y;
		return true;
	} else if(strCmd == "-moveright" || strCmd == "+moveleft") {
		++camera_direction_y;
		return true;
	} else if(strCmd == "+moveup" || strCmd == "-movedown") {
		++camera_direction_z;
		return true;
	} else if(strCmd == "-moveup" || strCmd == "+movedown") {
		--camera_direction_z;
		return true;
	} else if(strCmd == "+roll_right" || strCmd == "-roll_left") {
		++camera_roll;
		return true;
	} else if(strCmd == "+roll_left" || strCmd == "-roll_right") {
		--camera_roll;
		return true;
	}

	return false;
}

.vector view_ofs;

entity spawnentity;
void spawnentity_Draw() {
	R_AddEntity(self);
}

void GameCommand(string msg)
{
	float argc;
	argc = tokenize_console(msg);

	if(argv(0) == "help" || argc == 0)
	{
		print("Usage: cl_cmd COMMAND..., where possible commands are:\n");
		print("  settemp cvar value\n");
		print("  radar\n");
		print("  sbar_columns_set ...\n");
		print("  sbar_columns_help\n");
		return;
	}
	string cmd;
	cmd = argv(0);
	if(cmd == "mv_download") {
		Cmd_MapVote_MapDownload(argc);
	}
	else if(cmd == "settemp") {
		cvar_clientsettemp(argv(1), argv(2));
	}
	else if(cmd == "radar") {
		ons_showmap = !ons_showmap;
	}
	else if(cmd == "sbar_columns_set") {
		Cmd_Sbar_SetFields(argc);
	}
	else if(cmd == "sbar_columns_help") {
		Cmd_Sbar_Help(argc);
	}
#ifdef BLURTEST
	else if(cmd == "blurtest") {
		blurtest_time0 = time;
		blurtest_time1 = time + stof(argv(1));
		blurtest_radius = stof(argv(2));
		blurtest_power = stof(argv(3));
	}
#endif
	else if(cmd == "sendcvar") {
	}
	else if(cmd == "handlevote") {
		localcmd(strcat("cmd vote ", argv(1), "\n"));
	} else if(cmd == "modelprecache") {
		precache_model(argv(1));
	}
	else if(cmd == "spawnentity") {
		if (spawnentity)
			remove(spawnentity);

		spawnentity = spawn();
		spawnentity.draw = spawnentity_Draw;
		setorigin(spawnentity, view_origin + view_forward * 100);
		precache_model(argv(1));
		setmodel(spawnentity, argv(1));
		spawnentity.frame = stof(argv(2));
	} else if(cmd == "showradio") {
		GUI_Show(GUI_RADIO);
	} else
	{
		print("Invalid command '", cmd, "'. For a list of supported commands, try cl_cmd help.\n");
	}

	return;
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
	bSkipKey = false;
	if (CSQC_InputEvent_Callback) {
		bSkipKey = CSQC_InputEvent_Callback(bInputType, nPrimary, nSecondary);
		CSQC_InputEvent_Callback = CSQC_InputEvent_Callback_null;
		if (bSkipKey)
			return true;
	}
	if (bInputType == 0)
	if (nPrimary == K_ESCAPE)
	if not(isdemo_flag)
	{
		GUI_Show(GUI_GAMEMENU);
		return true;
	}

	return bSkipKey;
}

// END REQUIRED CSQC FUNCTIONS
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// BEGIN OPTIONAL CSQC FUNCTIONS
void Ent_ReadEntCS(float bIsNewEntity)
{
	float f = ReadByte();

	if (f & 1) {
		self.sv_entnum = ReadByte() - 1;
		self.shownames_entnum = ReadShort() - 1;
	}
	if (f & 64) {
		if (f & 2) {
			self.origin_x = ReadShort();
			self.origin_y = ReadShort();
		}
		if (f & 4) {
			self.origin_z = ReadShort();
			self.angles_y = ReadShort();
		}
		if (self.cnt)
			self.cnt = FALSE;
	} else {
		if not(self.cnt)
			self.cnt = TRUE;
	}
	if (f & 8) {
		self.maxs_x = self.maxs_y = 0;
		self.maxs_z = ReadShort();
	}

	if (teamplay)
		Shownames_UpdateTeamBubble(self, f & 32);

	if (f & 128) {
		if (f & 16) {
			self.health = ReadByte();
			self.armorvalue = ReadByte();
		}
	} else
		self.health = 0;

	self.classname = "entcs_receiver";
	if (bIsNewEntity)
		Shownames_Init(self);
}

void Ent_Remove();

void Ent_RemovePlayerScore()
{
	float i;

	if(self.owner)
	{
		SetTeam(self.owner, -1);
		player_remove(self.owner);
		self.owner.gotscores = 0;
		for(i = 0; i < MAX_SCORE; ++i)
			self.owner.(scores[i]) = 0; // clear all scores
	}
}

void Ent_ReadPlayerScore(float ignore)
{
	float i, n;
	float isNew;
	entity o;

	// damnit -.- don't want to go change every single .sv_entnum in sbar.qc AGAIN
	// (no I've never heard of M-x replace-string, sed, or anything like that)
	isNew = !self.owner; // workaround for DP bug
	n = ReadByte()-1;

#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(!isNew && n != self.sv_entnum)
	{
		//print("A CSQC entity changed its owner!\n");
		isNew = true;
		Ent_Remove();
		self.enttype = ENT_CLIENT_SCORES;
	}
#endif

	self.sv_entnum = n;

	if not(playerslots[self.sv_entnum])
		playerslots[self.sv_entnum] = spawn();
	o = self.owner = playerslots[self.sv_entnum];
	o.sv_entnum = self.sv_entnum;
	o.gotscores = 1;

	if not(o.sort_prev)
		player_register(o);

	float sf, lf;
#if MAX_SCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#else
	sf = ReadShort();
	lf = ReadShort();
#endif
	float p;
	for(i = 0, p = 1; i < MAX_SCORE; ++i, p *= 2)
		if(sf & p)
		{
			if(lf & p)
				o.(scores[i]) = net_read_int24();
			else
				o.(scores[i]) = ReadChar();
		}

	if (sf & SP_TEAM_BIT) {
		float t = o.scores[SP_TEAM_FIELD];
		if (t < 0)
			t = COLOR_SPECTATOR;

		SetTeam(o, t);
	}

	if(o.sort_prev)
		Sbar_UpdatePlayerPos(o); // if not registered, we cannot do this yet!

	self.entremove = Ent_RemovePlayerScore;
}

void Ent_ReadTeamScore(float ignore)
{
	float i, t;
	entity o;

	self.team = ReadByte();
	o = self.owner = GetTeam(self.team, true); // these team numbers can always be trusted

	float sf, lf;
#if MAX_TEAMSCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#else
	sf = ReadShort();
	lf = ReadShort();
#endif
	float p;
	for(i = 0, p = 1; i < MAX_TEAMSCORE; ++i, p *= 2)
		if(sf & p)
		{
			if(lf & p)
				o.(teamscores[i]) = net_read_int24();
			else
				o.(teamscores[i]) = ReadChar();
		}

	Sbar_UpdateTeamPos(o);
	if (SP_TEAM_BIT)
		for(o = player_list.sort_next; o; o = o.sort_next)
			if (o.gotscores) {
				t = o.scores[SP_TEAM_FIELD];
				if (t < 0)
					t = COLOR_SPECTATOR;

				SetTeam(o, t);
			}
}

void Net_Reset()
{
}

void Ent_Nagger(float ignore)
{
	float nags, i, j, b, f;

	nags = ReadByte();

	if(nags & 1)
	{
		for(i = 1; i <= maxclients; i += 8)
		{
			f = ReadByte();
			for(j = i-1, b = 1; b < 256; b *= 2, ++j)
				if(playerslots[j]) {
					if (f & b)
						playerslots[j].ready = 1;
					else
						playerslots[j].ready = 0;
				}
		}
	} else
		for(i = 0; i < maxclients; i++)
			if(playerslots[i])
				playerslots[i].ready = 0;
}

void Ent_RandomSeed(float ignore)
{
	float s;
	prandom_debug();
	s = ReadShort();
	psrandom(s);
}

// CSQC_Ent_Update : Called every frame that the server has indicated an update to the SSQC / CSQC entity has occured.
// The only parameter reflects if the entity is "new" to the client, meaning it just came into the client's PVS.
void(float bIsNewEntity) CSQC_Ent_Update =
{
	float t;
	float savetime;
	t = ReadByte();

	// set up the "time" global for received entities to be correct for interpolation purposes
	savetime = time;
	if(servertime)
	{
		time = servertime;
	}
	else
	{
		serverprevtime = time;
		serverdeltatime = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
		time = serverprevtime + serverdeltatime;
	}
	clienttime = time;
#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(self.enttype)
		if(t != self.enttype)
		{
			//print("A CSQC entity changed its type!\n");
			Ent_Remove();
			bIsNewEntity = 1;
		}
#endif
	if (t >= ENT_CLIENT_COUNT)
		Ent_Error(0);

	self.enttype = t;
	ent_parsers[t](bIsNewEntity);
	time = savetime;
};
// Destructor, but does NOT deallocate the entity by calling remove(). Also
// used when an entity changes its type. For an entity that someone interacts
// with others, make sure it can no longer do so.
void Ent_Remove()
{
	if(self.entremove)
		self.entremove();

	self.enttype = 0;
	self.classname = "";
	self.draw = world.draw;
	self.entremove = world.entremove;
	// TODO possibly set more stuff to defaults
}
// CSQC_Ent_Remove : Called when the server requests a SSQC / CSQC entity to be removed.  Essentially call remove(self) as well.
void CSQC_Ent_Remove()
{
	if(self.enttype)
		Ent_Remove();
	remove(self);
}

void Gamemode_Init()
{
	if(gametype == GAME_ONSLAUGHT)
		search_and_precache("gfx/ons-*");

	if not(isdemo_flag)
	{
		localcmd("\n_cl_hook_gamestart ", gametype_name(gametype), ";");
		calledhooks |= HOOK_START;
	}
	Sbar_GameType_Init();
}
// CSQC_Parse_StuffCmd : Provides the stuffcmd string in the first parameter that the server provided.  To execute standard behavior, simply execute localcmd with the string.
void CSQC_Parse_StuffCmd(string strMessage)
{
	localcmd(strMessage);
}
// CSQC_Parse_Print : Provides the print string in the first parameter that the server provided.  To execute standard behavior, simply execute print with the string.
void CSQC_Parse_Print(string strMessage)
{
	print(str_color_translate_rgb(strMessage));
}

#define GAMEMENU_ITEMS_COUNT_MAX 16
string gamemenu_items[GAMEMENU_ITEMS_COUNT_MAX];
string gamemenu_commands[GAMEMENU_ITEMS_COUNT_MAX];
float gamemenu_commands_count;

void GameMenu_Read() {
	float i;
	string s;
	for (i = 0; i < GAMEMENU_ITEMS_COUNT_MAX; i++) {
		if (gamemenu_items[i] != "") {
			strunzone(gamemenu_items[i]);
			strunzone(gamemenu_commands[i]);
		}
	}
	for (i = 0; i < GAMEMENU_ITEMS_COUNT_MAX; i++) {
		s = ReadString();
		if (s == "")
			break;

		gamemenu_items[i] = strzone(s);
		gamemenu_commands[i] = strzone(ReadString());
	}
	gamemenu_commands_count = i;
}

#define VOTE_COMMANDS_COUNT 16
string vote_commands[VOTE_COMMANDS_COUNT];
float vote_commands_count;

void VoteCommands_Read() {
	string s = ReadString();
	string head, tail;
	float i;
	for (i = 0; i < vote_commands_count; i++) {
		strunzone(vote_commands[i]);
	}
	vote_commands_count = 0;
	for (head = str_car(s), tail = str_cdr(s); ; head = str_car(tail), tail = str_cdr(tail)) {
		if (head == "") {
			if (tail == "")
				break;

			continue;
		}
		vote_commands[vote_commands_count] = strzone(head);
		vote_commands_count++;
		if (vote_commands_count >= VOTE_COMMANDS_COUNT)
			return;
	}
}

void Gamemode_Init();
void Ent_ScoresInfo(float ignore)
{
	float i, j, t;
	entity o;
	self.classname = "ent_client_scores_info";
	gametype = ReadByte();
	string s;
	for(i = 0; i < MAX_SCORE; ++i)
	{
		s = strzone(ReadString());
		if (s == "country")
			SP_COUNTRY_FIELD = i;
		else if (s == "kills")
			SP_KILLS_FIELD = i;
		else if (s == "bestwep")
			SP_BESTWEP_FIELD = i;
		else if (s == "suicides")
			SP_SUICIDES_FIELD = i;
		else if (s == "deaths")
			SP_DEATHS_FIELD = i;
		else if (s == "team") {
			SP_TEAM_BIT = 1;
			SP_TEAM_FIELD = i;
			for (j = 0; j < i; j++) SP_TEAM_BIT = SP_TEAM_BIT * 2;
			for (o = player_list.sort_next; o; o = o.sort_next)
				if (o.gotscores) {
					t = o.scores[SP_TEAM_FIELD];
					if (t < 0)
						t = COLOR_SPECTATOR;

					SetTeam(o, t);
				}
		} else if (s == "status")
			SP_STATUS_FIELD = i;

		scores_label[i] = s;
		scores_flags[i] = ReadByte();
	}
	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		teamscores_label[i] = strzone(ReadString());
		teamscores_flags[i] = ReadByte();
	}
	Sbar_InitScores();
	Gamemode_Init();
}

void Ent_Init(float ignore)
{
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
		sv_spectate = i & 2;
		localgame = i & 4;
		hook_use_swapped = i & 8;
		button_attack2_allowed = !(i & 16);
	}

	if (sf & 4) {
		str_unzone_ifneeded(fog_settings);
		fog_settings = str_zone_ifneeded(ReadString());
	}
	if (sf & 8)
		VoteCommands_Read();

	if (sf & 16)
		GameMenu_Read();

	if (sf & 32) {
		teamplay = ReadByte();
		if not(teamplay) {
			GetTeam(0, true);
		}
		entity o;
		if (SP_TEAM_BIT)
			for(o = player_list.sort_next; o; o = o.sort_next)
				if (o.gotscores)
					SetTeam(o, o.scores[SP_TEAM_FIELD]);

		registercvar("_teams_available", "0");
		cvar_set("_teams_available", ftos(ReadByte()));
		Sbar_InitScores();
	}

	if (sf & 64) {
		projectile_read();
	}

	if (sf & 128) {
		str_unzone_ifneeded(map_description);
		map_description = str_zone_ifneeded(ReadString());
		str_unzone_ifneeded(motd);
		motd = str_zone_ifneeded(ReadString());
	}

	if(!postinit)
		PostInit();
}

void Net_ReadRace()
{
	float b;

	b = ReadByte();

	switch(b)
	{
		case RACE_NET_CHECKPOINT_HIT_QUALIFYING:
			race_checkpoint = ReadByte();
			race_time = net_read_int24();
			race_previousbesttime = net_read_int24();
			if(race_previousbestname)
				strunzone(race_previousbestname);
			race_previousbestname = strzone(str_color_translate_rgb(ReadString()));

			race_checkpointtime = time;

			if(race_checkpoint == 0 || race_checkpoint == 254)
			{
				race_penaltyaccumulator = 0;
				race_laptime = time; // valid
			}

			break;

		case RACE_NET_CHECKPOINT_CLEAR:
			race_laptime = 0;
			race_checkpointtime = 0;
			break;

		case RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING:
			race_laptime = ReadCoord();
			race_checkpointtime = -99999;
			// fall through
		case RACE_NET_CHECKPOINT_NEXT_QUALIFYING:
			race_nextcheckpoint = ReadByte();

			race_nextbesttime = net_read_int24();
			if(race_nextbestname)
				strunzone(race_nextbestname);
			race_nextbestname = strzone(str_color_translate_rgb(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = ReadByte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = net_read_int24();
			race_mycheckpointlapsdelta = ReadByte();
			if(race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;
			if(race_mycheckpointenemy)
				strunzone(race_mycheckpointenemy);
			race_mycheckpointenemy = strzone(str_color_translate_rgb(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = ReadByte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = net_read_int24();
			race_othercheckpointlapsdelta = ReadByte();
			if(race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;
			if(race_othercheckpointenemy)
				strunzone(race_othercheckpointenemy);
			race_othercheckpointenemy = strzone(str_color_translate_rgb(ReadString()));
			break;

		case RACE_NET_PENALTY_RACE:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			//race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;

		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;
	}
}

void Net_ReadSpawn()
{
}

// CSQC_Parse_TempEntity : Handles all temporary entity network data in the CSQC layer.
// You must ALWAYS first acquire the temporary ID, which is sent as a byte.
// Return value should be 1 if CSQC handled the temporary entity, otherwise return 0 to have the engine process the event.
float CSQC_Parse_TempEntity()
{
	float bHandled;
	bHandled = true;
	// Acquire TE ID
	float nTEID = ReadByte();
	// NOTE: Could just do return instead of break...
	switch(nTEID)
	{
		case TE_CSQC_SPAWN:
			Net_ReadSpawn();
			break;
		case TE_CSQC_ZCURVEPARTICLES:
			Net_ReadZCurveParticles();
			break;
		case TE_CSQC_NEXGUNBEAMPARTICLE:
			Net_ReadNexgunBeamParticle();
			break;
        case TE_CSQC_LIGHTNINGARC:
            Net_ReadLightningarc();
            break;
        case TE_CSQC_BIGLIGHTNINGARC:
            Net_ReadBigLightningarc();
            break;
        case TE_CSQC_ZAPPERLIGHTNING:
            Zapper_ReadLightning();
            break;
		case TE_CSQC_BLAST:
			Net_ReadBlast();
			break;
		case TE_CSQC_ANNOUNCE_PRINT:
			announce_print();
			break;
		case TE_CSQC_WEAPONLIST:
			weapontime = time;
			break;
		case TE_CSQC_RADIO:
			Net_ReadRadio();
			break;
        case TE_CSQC_NADGETSELECT:
			Net_ReadNadgetSelect();
            break;
		case TE_CSQC_WEAPONSELECT:
			Net_ReadWeaponSelect();
			break;
		case TE_CSQC_PICTURE:
			Net_MapVote_Picture();
			break;
		case TE_CSQC_RACE:
			Net_ReadRace();
			break;
		case TE_CSQC_TEAMSELECT:
			if not(isdemo_flag)
				GUI_Show(GUI_TEAMSELECT);

			break;
		case TE_CSQC_GAMEOVER:
			if(calledhooks & HOOK_START)
			{
				localcmd("\ncl_hook_gameend;");
				calledhooks |= HOOK_END;
			}
			break;
		case TE_CSQC_MAPLIST:
			str_unzone_ifneeded(available_maps);
			available_maps = str_zone_ifneeded(ReadString());
			string s = available_maps;
			available_maps_count = 0;
			while (s != "") {
				s = str_cdr(s);
				available_maps_count++;
			}
			break;
		case TE_CSQC_TRIP:
			trip_net_read();
			break;
		case TE_CSQC_HINT:
			hint_net_read();
			break;
		default:
			// No special logic for this temporary entity; return 0 so the engine can handle it
			bHandled = false;
			break;
	}

	return bHandled;
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
