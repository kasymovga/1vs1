///////////////////////////////////////////////
// Menu Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all menu functions (especially the required ones)
///////////////////////////////////////////////

float mouseButtonsPressed;
vector menuMousePos;
float menuShiftState;
float menuPrevTime;
float menuAlpha;
float menuLogoAlpha;
float prevMenuAlpha;
float menuInitialized;
float menuNotTheFirstFrame;
float menuMouseMode;
float menuRealFrametime;
float menu_doubleclick_time;
vector menu_doubleclick_position;

float() menu_init_pre;

float URI_GET_SERVERLIST;
#define SERVERLIST_URIS_COUNT 3
var float serverlist_uri_index = 0;
string serverlist_uris[SERVERLIST_URIS_COUNT] = {
	"http://kasymovga.github.io/rexdlc-web/serverlist.txt",
	"http://rexuiz.com/maps/serverlist.txt",
	"http://nexuiz.mooo.com/serverlist.txt",
};

float(string url, float id) uri_get = #513;


void ParseServerListLine(string s) {
	float d;
	d = strstrofs(s, "/", 0);
	cvar_set("net_slist_extra", strcat(cvar_string("net_slist_extra"), " ", ((d > 0) ? substring(s, 0, d) : s)));
}

void ServerList_URI_Get_Callback(float id, float status, string data) {
	float f;
	if (status) {
		print(serverlist_uris[serverlist_uri_index], " error: ", ftos(status), "\n");
		serverlist_uri_index++;
		if (serverlist_uri_index < SERVERLIST_URIS_COUNT) {
			uri_get(serverlist_uris[serverlist_uri_index], URI_GET_SERVERLIST);
			return;
		} else {
			f = fopen("data/serverlistcache.txt", FILE_READ);
			string s;
			if (f < 0) {
				f = fopen("serverlistbootstrap.txt", FILE_READ);
				if (f < 0)
					return;
				else
					print("Loaded server list from serverlistbootstrap.txt\n");
			} else
				print("Loaded server list cache from data/serverlistcache.txt\n");

			while ((s = fgets(f)))
				ParseServerListLine(s);

			fclose(f);
		}
		return;
	}
	print(serverlist_uris[serverlist_uri_index], " downloaded successfully\n");
	f = fopen("serverlistcache.txt", FILE_WRITE);
	if not(f < 0) {
		fputs(f, data);
		fclose(f);
	}
	cvar_set("net_slist_extra", "");
	float n = tokenizebyseparator(data, "\n");
	float i;
	for (i = 0; i < n; i++)
		ParseServerListLine(argv(i));
}

entity menu_dlc_reload_wait;
void(void) menu_dlc_reload_wait_think {
	if (dlc_ready_all()) {
		if (clientstate() != CS_CONNECTED)
			localcmd("r_restart\n");

	} else if (self.cnt) {
		self.cnt = self.cnt - 1;
		self.nextthink = time + 5;
		return;
	}
	remove(menu_dlc_reload_wait);
	menu_dlc_reload_wait = NULL;
}

void(float nodownload, float renderrestart) menu_dlc_reload {
	string s = strcat(DLC_BASE_LIST " ", cvar_defstring("menu_dlc_extra"));
	dlc_list = "";
	if (cvar("cl_brightskins")) {
		s = strcat(s, " brightskins");
	}
	if not(cvar("cl_oldnexmodel")) {
		s = strcat(s, " newnex");
	}
	if (cvar("cl_simpleitems")) {
		s = strcat(s, " simpleitems");
	}
	string head = "", tail = s;
	while (tail != "") {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head != "") {
			if not(dlc_load(head, nodownload)) {
				if not(nodownload)
					print("Downloading missing pack: ", head, "\n");
			}
		}
	}
	if (renderrestart)
	if not(menu_dlc_reload_wait) {
		menu_dlc_reload_wait = spawn();
		menu_dlc_reload_wait.think = menu_dlc_reload_wait_think;
		menu_dlc_reload_wait.nextthink = time + 1;
		menu_dlc_reload_wait.cnt = 10;
	}
}

void() menu_init {
	cvar_set("_menu_alpha", "0");
	if (cvar("sys_first_run"))
		cvar_set("vid_desktopfullscreen", "1");

	URI_GET_SERVERLIST = uri_register_handler(ServerList_URI_Get_Callback);
	uri_get(serverlist_uris[0], URI_GET_SERVERLIST);
	menu_dlc_reload(TRUE, FALSE);
	udppunchhole_extresponse_handler_register();
	ui_con_width_height_set();
}

void(void) menu_update_width_height {
	float conwidth_s, conheight_s;
	conwidth_s = gui_conwidth;
	conheight_s = gui_conheight;
	gui_conwidth = cvar("vid_conwidth");
	gui_conheight = cvar("vid_conheight");
	if (main) {
		if (conwidth_s != gui_conwidth || conheight_s != gui_conheight) {
			gui_draw_reset();
			main.resizeNotify(main, '0 0 0', eX * gui_conwidth + eY * gui_conheight, '0 0 0', eX * gui_conwidth + eY * gui_conheight);
		}
	}
}

float dlc_wait_frame;
void() menu_init_delayed {
	menuInitialized = 0;
	if (dlc_ready_all()) {
		//print("dlc loading finished\n");
		//print("dlc_wait_frame=", ftos(dlc_wait_frame), "\n");
	} else if (dlc_wait_frame < 10) {
		dlc_wait_frame++;
		menu_init_pre();
		return;
	} else {
		dlc_set_repos(cvar_string("sv_dlc_repository"));
		menu_dlc_reload(FALSE, FALSE);
	}
	if (!menu_init_pre())
		return;

	menuInitialized = 1;
	localcmd("alias qc_cmd \"menu_cmd $*\"\n");
	weapon_register_weapons();
	skin_init();
	gui_set_mouse_pointer(SKINGFX_CURSOR, SKINSIZE_CURSOR, SKINOFFSET_CURSOR);
	gui_conwidth = gui_conheight = -1;
	gui_draw_reset();
	menu_update_width_height();
	main = spawnMainWindow(); main.configureMainWindow(main);
	main.resizeNotify(main, '0 0 0', eX * gui_conwidth + eY * gui_conheight, '0 0 0', eX * gui_conwidth + eY * gui_conheight);
	main.focused = 1;
	menuShiftState = 0;
	menuMousePos = '0.5 0.5 0';
	if(menu_active)
		menu_display(); // delayed menu display
}

float(void) menu_mouse_update {
	float changed = 0;
	if (menuMouseMode) {
		vector newMouse;
		newMouse = gui_global_to_box_size(getmousepos(), gui_draw_scale);
		if(newMouse != '0 0 0')
			if(newMouse != menuMousePos)
			{
				menuMousePos = newMouse;
				changed = 1;
			}
	} else {
		if(frametime > 0) {
			vector dMouse;
			dMouse = getmousepos() * (frametime / menuRealFrametime); // for capturevideo
			if (dMouse != '0 0 0') {
				dMouse = gui_global_to_box_size(dMouse, gui_draw_scale);
				menuMousePos += dMouse * cvar("menu_mouse_speed");
				menuMousePos_x = bound(0, menuMousePos_x, 1);
				menuMousePos_y = bound(0, menuMousePos_y, 1);
				changed = 1;
			}
		}
	}
	return changed;
}

void(float key, float ascii) menu_keyup {
	if (!menuInitialized)
		return;

	if (!menu_active)
		return;

	gui_draw_reset();
	main.keyUp(main, key, ascii, menuShiftState);
	if(key >= K_MOUSE1 && key <= K_MOUSE3) {
		if (menuMousePos)
			menu_mouse_update();

		--mouseButtonsPressed;
		if(!mouseButtonsPressed)
			main.mouseRelease(main, menuMousePos);
		if(mouseButtonsPressed < 0)
		{
			mouseButtonsPressed = 0;
			print("Warning: released an already released button\n");
		}
	}
	if (key == K_ALT) menuShiftState -= (menuShiftState & GUI_KEY_STATE_ALT);
	if (key == K_CTRL) menuShiftState -= (menuShiftState & GUI_KEY_STATE_CTRL);
	if (key == K_SHIFT) menuShiftState -= (menuShiftState & GUI_KEY_STATE_SHIFT);
}

void(float key, float ascii) menu_keydown {
	if (!menuInitialized)
		return;

	if (!menu_active)
		return;

	if (keyGrabber) {
		entity e;
		e = keyGrabber;
		keyGrabber = NULL;
		e.keyGrabbed(e, key, ascii);
	} else {
		gui_draw_reset();
		if (key >= K_MOUSE1 && key <= K_MOUSE3) {
			menu_mouse_update();
			if (!mouseButtonsPressed)
				main.mousePress(main, menuMousePos);

			if (key == K_MOUSE1) {
				if (time < menu_doubleclick_time && menu_doubleclick_position == menuMousePos)
					main.mouseDoubleClick(main, menuMousePos);

				menu_doubleclick_position = menuMousePos;
				menu_doubleclick_time = time + 0.4;
			}
		}
		if (!main.keyDown(main, key, ascii, menuShiftState))
			if (key == K_ESCAPE)
				if (menu_gamestatus & (GAME_ISSERVER | GAME_CONNECTED)) // don't back out to console only
					menu_hide(); // disable menu on unhandled ESC
	}
	if (key >= K_MOUSE1 && key <= K_MOUSE3) {
		++mouseButtonsPressed;
		if(mouseButtonsPressed > 10) {
			mouseButtonsPressed = 10;
			print("Warning: pressed an already pressed button\n");
		}
	}
	if (key == K_ALT) menuShiftState |= GUI_KEY_STATE_ALT;
	if (key == K_CTRL) menuShiftState |= GUI_KEY_STATE_CTRL;
	if (key == K_SHIFT) menuShiftState |= GUI_KEY_STATE_SHIFT;
}

float() menu_init_pre {
	vector sz;
	vector boxA, boxB;
	MapInfo_Cache_Create();
	MapInfo_Enumerate();
	if (!MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 1)) {
		gui_draw_reset();
		sz = eX * 0.025 + eY * 0.025 * (gui_draw_scale_x / gui_draw_scale_y);
		gui_draw_text_center('0.5 0.5 0' - 1.25 * sz_y * eY, "Autogenerating mapinfo for newly added maps...", sz, '1 1 1', 1, 0);
		boxA = '0.05 0.5 0' + 0.25 * sz_y * eY;
		boxB = '0.95 0.5 0' + 1.25 * sz_y * eY;
		gui_draw_fill(boxA, boxB - boxA, '1 1 1', 1);
		boxA += sz * 0.1;
		boxB -= sz * 0.1;
		gui_draw_fill(boxA, boxB - boxA, '0.1 0.1 0.1', 1);
		boxB_x = boxA_x * (1 - MapInfo_progress) + boxB_x * MapInfo_progress;
		gui_draw_fill(boxA, boxB - boxA, '0 0 1', 1);
		return FALSE;
	}
	return TRUE;
}

string menu_campaign_name_previous;
float menu_campaign_won_previous;
void() menu_draw_pre {
	if not(menu_campaign_name_previous)
		menu_campaign_name_previous = strzone(strcat(campaign_name, "x")); // force unequal

	if (campaign_name == menu_campaign_name_previous) {
		if (cvar(strcat("g_campaign", campaign_name, "_won"))) {
			if (!menu_campaign_won_previous) {
				menu_display();
				DialogOpenButton_Click_withCoords(NULL, main.winnerDialog, '0 0 0', eX * gui_conwidth + eY * gui_conheight);
			}
			menu_campaign_won_previous = 1;
		} else
			menu_campaign_won_previous = 0;
	} else {
		strunzone(menu_campaign_name_previous);
		menu_campaign_name_previous = strzone(campaign_name);
		menu_campaign_won_previous = cvar(strcat("g_campaign", campaign_name, "_won"));
	}
}

void(void) menu_draw {
	float t;
	menuMouseMode = cvar("menu_mouse_absolute");
	if (main)
		menu_update_width_height();

	if (!menuInitialized) {
		// TODO draw an info image about this situation
		if not(cvar("utf8_enable"))
			cvar_set("utf8_enable", "1");

		if (cvar("r_font_disable_freetype")) {
			cvar_set("r_font_disable_freetype", "0");
			localcmd("\nr_restart\n");
		}
		menu_init_delayed();
		return;
	}
	if (!menuNotTheFirstFrame) {
		menuNotTheFirstFrame = 1;
		if (menu_active)
		if (!cvar("menu_video_played")) {
			localcmd("set menu_video_played 1; cd loop $menu_cdtrack; play sound/announcer/male/welcome.ogg\n");
			menuLogoAlpha = -0.8; // no idea why, but when I start this at zero, it jumps instead of fading
		}
	}
	extresponse_update();
	t = gettime();
	menuRealFrametime = frametime = min(0.2, t - menuPrevTime);
	menuPrevTime = t;
	time += frametime;
	t = cvar("menu_slowmo");
	if (t) {
		frametime *= t;
		menuRealFrametime *= t;
	} else
		t = 1;

	if (menu_active) {
		entity e, oldself;
		oldself = self;
		for(e = findflags(NULL, nextthink, 0xFFFFFFFF); e; e = findflags(e, nextthink, 0xFFFFFFFF)) { //hack, findflags works only with integer part of float value
			if (e.nextthink < time) {
				self = e;
				self.nextthink = 0;
				self.think();
			}
		}
		self = oldself;
		if (getmousetarget() == (menuMouseMode ? MT_CLIENT : MT_MENU) && (getkeydest() == KEY_MENU || getkeydest() == KEY_MENU_GRABBED))
			setkeydest(keyGrabber ? KEY_MENU_GRABBED : KEY_MENU);
		else
			menu_hide();
	}
	if(cvar("cl_capturevideo"))
		frametime = t / cvar("cl_capturevideo_fps"); // make capturevideo work smoothly

	menu_gamestatus = 0;
	if (isserver())
		menu_gamestatus = menu_gamestatus | GAME_ISSERVER;

	if (clientstate() == CS_CONNECTED)
		menu_gamestatus = menu_gamestatus | GAME_CONNECTED;

	prevMenuAlpha = menuAlpha;
	if (menu_active) {
		if (menuAlpha == 0 && menuLogoAlpha < 2) {
			menuLogoAlpha = menuLogoAlpha + frametime * 2;
		} else {
			menuAlpha = min(1, menuAlpha + frametime * 5);
			menuLogoAlpha = 2;
		}
	} else {
		menuAlpha = max(0, menuAlpha - frametime * 5);
		menuLogoAlpha = 2;
	}
	gui_draw_reset();
	if (!(menu_gamestatus & (GAME_CONNECTED | GAME_ISSERVER))) {
		if (menuLogoAlpha > 0) {
			gui_draw_background(SKINGFX_BACKGROUND, bound(0, menuLogoAlpha, 1), SKINALIGN_BACKGROUND, TRUE);
			if (menuAlpha <= 0 && SKINALPHA_CURSOR_INTRO > 0) {
				gui_draw_alpha = SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1);
				gui_draw_mouse_pointer(menuMousePos);
				gui_draw_alpha = 1;
			}
		}
	} else if(SKINALPHA_BACKGROUND_INGAME) {
		if (menuAlpha > 0)
			gui_draw_background(SKINGFX_BACKGROUND_INGAME, menuAlpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, FALSE);
	}
	if (menuAlpha != prevMenuAlpha)
		cvar_set("_menu_alpha", ftos(menuAlpha));

	gui_draw_reset();
	menu_draw_pre();
	gui_draw_reset();
	if (menuAlpha <= 0) {
		if (prevMenuAlpha > 0)
			main.initializeDialog(main, main.firstChild);

		gui_draw_reset();
		return;
	}
	gui_draw_alpha *= menuAlpha;
	if (menu_mouse_update()) {
		if(mouseButtonsPressed)
			main.mouseDrag(main, menuMousePos);
		else
			main.mouseMove(main, menuMousePos);
	}
	main.draw(main);
	gui_draw_alpha = max(gui_draw_alpha, SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1));
	gui_draw_mouse_pointer(menuMousePos);
	gui_draw_reset();
	frametime = 0;
}

void(void) menu_display {
	menu_active = TRUE;
	setkeydest(KEY_MENU);
	setmousetarget((menuMouseMode ? MT_CLIENT : MT_MENU));
	if (!menuInitialized)
		return;

	if (mouseButtonsPressed)
		main.mouseRelease(main, menuMousePos);

	mouseButtonsPressed = 0;
	main.focusEnter(main);
	main.showNotify(main);
}

void() menu_hide {
	menu_active = FALSE;
	setkeydest(KEY_GAME);
	setmousetarget(MT_CLIENT);
	if(!menuInitialized)
		return;

	main.focusLeave(main);
	main.hideNotify(main);
}

void() menu_toggle {
	if(menu_active)
		menu_hide();
	else
		menu_display();
}

void() menu_shutdown {
	entity e;
	menu_hide();
	for (e = NULL; (e = nextent(e)) != NULL; ) {
		if (e.destroy)
			e.destroy(e);
	}
}

void(string itemname) menu_goto {
	entity e;
	if not(menuInitialized)
		return;

	if (itemname == "") { // this can be called by GameCommand
		if (menu_gamestatus & (GAME_ISSERVER | GAME_CONNECTED))
			menu_hide();
		else {
			m_activate_window(main.mainNexposee);
			menu_display();
		}
	} else {
		e = findstring(NULL, name, itemname);
		if (e) {
			menu_hide();
			m_activate_window(e);
			m_setpointerfocus(e);
			menu_display();
		}
	}
}
