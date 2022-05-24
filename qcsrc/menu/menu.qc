///////////////////////////////////////////////
// Menu Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all menu functions (especially the required ones)
///////////////////////////////////////////////

float menu_mouse_button_pressed;
float menu_modkeys_state;
float menu_time_previous;
float menu_alpha;
float menu_logo_alpha;
float menu_alpha_previous;
float menu_initialized;
float menu_not_the_first_frame;
float menu_mouse_mode;
float menu_frametime_real;
float menu_doubleclick_time;
vector menu_doubleclick_position;

float() menu_init_pre;

float MENU_URI_GET_SERVERLIST;
#define MENU_SERVERLIST_URIS_COUNT 3
var float menu_serverlist_uri_index = 0;
string menu_serverlist_uris[MENU_SERVERLIST_URIS_COUNT] = {
	"http://kasymovga.github.io/rexdlc-web/serverlist.txt",
	"http://rexuiz.com/maps/serverlist.txt",
	"http://nexuiz.mooo.com/serverlist.txt",
};
void(float id, float status, string data) menu_server_list_callback {
	float f;
	float d;
	string s;
	cvar_set("net_slist_extra", "");
	if (status) {
		print(menu_serverlist_uris[menu_serverlist_uri_index], " error: ", ftos(status), "\n");
		menu_serverlist_uri_index++;
		if (menu_serverlist_uri_index < MENU_SERVERLIST_URIS_COUNT) {
			uri_get(menu_serverlist_uris[menu_serverlist_uri_index], MENU_URI_GET_SERVERLIST);
			return;
		} else {
			f = fopen("data/serverlistcache.txt", FILE_READ);
			if (f < 0) {
				f = fopen("serverlistbootstrap.txt", FILE_READ);
				if (f < 0)
					return;
				else
					print("Loaded server list from serverlistbootstrap.txt\n");
			} else
				print("Loaded server list cache from data/serverlistcache.txt\n");

			while ((s = fgets(f))) {
				d = strstrofs(s, "/", 0);
				cvar_set("net_slist_extra", strcat(cvar_string("net_slist_extra"), " ", ((d > 0) ? substring(s, 0, d) : s)));
			}
			fclose(f);
		}
		return;
	}
	print(menu_serverlist_uris[menu_serverlist_uri_index], " downloaded successfully\n");
	f = fopen("serverlistcache.txt", FILE_WRITE);
	if not(f < 0) {
		fputs(f, data);
		fclose(f);
	}
	float n = tokenizebyseparator(data, "\n");
	float i;
	for (i = 0; i < n; i++) {
		s = argv(i);
		d = strstrofs(s, "/", 0);
		cvar_set("net_slist_extra", strcat(cvar_string("net_slist_extra"), " ", ((d > 0) ? substring(s, 0, d) : s)));
	}
}

void() menu_init {
	cvar_set("_menu_alpha", "0");
	if (cvar("sys_first_run"))
		cvar_set("vid_desktopfullscreen", "1");

	MENU_URI_GET_SERVERLIST = uri_register_handler(menu_server_list_callback);
	uri_get(menu_serverlist_uris[0], MENU_URI_GET_SERVERLIST);
	dlc_reload(TRUE, FALSE);
	udppunchhole_extresponse_handler_register();
	ui_con_width_height_set();
	time = 1;
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

void(void) menu_time_process {
	float t = gettime();
	menu_frametime_real = frametime = min(0.2, t - menu_time_previous);
	menu_time_previous = t;
	if not(dlc_reloaded)
	if (!menu_initialized || menu_active)
		dlc_think();

	if (menu_active) {
		entity e, oldself;
		oldself = self;
		time += frametime;
		if (time > 20000) localcmd("menu_restart\n");
		for(e = findflags(NULL, nextthink, 0xFFFFFFFF); e; e = findflags(e, nextthink, 0xFFFFFFFF)) { //hack, findflags works only with integer part of float value
			if (e.nextthink < time) {
				self = e;
				self.nextthink = 0;
				self.think();
			}
		}
		self = oldself;
	}
}

void(string m1, string m2) menu_draw_loading {
	vector sz = drawgetimagesize("gfx/loading.tga");
	if (sz != '0 0 0') {
		vector v = cvar("vid_conwidth") * '1 0 0' + cvar("vid_conheight") * '0 1 0';
		float scl = min(v_x / sz_x, v_y / sz_y);
		sz *= scl;
		drawpic((v - sz) * 0.5, "gfx/loading.tga", sz, '1 1 1', 1, DRAWFLAG_NORMAL);
		vector pos;
		pos_y = 100;
		pos_x = (cvar("vid_conwidth") / 2) - stringwidth(m1, FALSE) * 6;
		pos_z = 0;
		drawstring(pos, m1, '12 12 0', '0 1 1', 1, DRAWFLAG_NORMAL);
		pos_y += 20;
		pos_x = (cvar("vid_conwidth") / 2) - stringwidth(m2, FALSE) * 6;
		drawstring(pos, m2, '12 12 0', '0 1 1', 1, DRAWFLAG_NORMAL);
	}
}

void() menu_init_delayed {
	menu_initialized = 0;
	if (!dlc_reloaded && !dlc_failed) {
		if (dlc_downloading) {
			menu_draw_loading("Downloading missing data", "Press ESC to cancel");
		} else {
			menu_draw_loading("Loading data, please wait", "");
		}
		menu_time_process();
		return;
	}
	if (dlc_failed && dlc_mandatory) {
		menu_draw_loading("Data missing and cannot be fetched", "Press ESC to exit");
		menu_time_process();
		return;
	}
	if (!menu_init_pre())
		return;

	if (dlc_mandatory) {
		localcmd("r_restart\n");
	}
	menu_initialized = 1;
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
	menu_modkeys_state = 0;
	menu_mouse_pos = '0.5 0.5 0';
	if(menu_active)
		menu_display(); // delayed menu display
}

float(void) menu_mouse_update {
	float changed = 0;
	if (menu_mouse_mode) {
		vector newMouse = gui_global_to_box_size(getmousepos(), gui_draw_scale);
		if(newMouse != '0 0 0')
			if(newMouse != menu_mouse_pos)
			{
				menu_mouse_pos = newMouse;
				changed = 1;
			}
	} else {
		if(frametime > 0) {
			vector dMouse = getmousepos();
			if (dMouse != '0 0 0') {
				dMouse = gui_global_to_box_size(dMouse, gui_draw_scale);
				menu_mouse_pos += dMouse * bound(0.1, cvar("menu_mouse_speed"), 10);
				menu_mouse_pos_x = bound(0, menu_mouse_pos_x, 1);
				menu_mouse_pos_y = bound(0, menu_mouse_pos_y, 1);
				changed = 1;
			}
		}
	}
	return changed;
}

void(float key, float ascii) menu_keyup {
	if (!menu_initialized)
		return;

	if (!menu_active)
		return;

	gui_draw_reset();
	main.keyUp(main, key, ascii, menu_modkeys_state);
	if (key >= K_MOUSE1 && key <= K_MOUSE3) {
		if (menu_mouse_pos)
			menu_mouse_update();

		--menu_mouse_button_pressed;
		if (!menu_mouse_button_pressed)
			main.mouseRelease(main, menu_mouse_pos);

		if (menu_mouse_button_pressed < 0) {
			menu_mouse_button_pressed = 0;
			print("Warning: released an already released button\n");
		}
	}
	if (key == K_ALT) menu_modkeys_state -= (menu_modkeys_state & GUI_KEY_STATE_ALT);
	if (key == K_CTRL) menu_modkeys_state -= (menu_modkeys_state & GUI_KEY_STATE_CTRL);
	if (key == K_SHIFT) menu_modkeys_state -= (menu_modkeys_state & GUI_KEY_STATE_SHIFT);
}

void(float key, float ascii) menu_keydown {
	if (!menu_initialized) {
		if (dlc_failed || dlc_downloading) {
			if (key == K_ESCAPE)
				localcmd("quit\n");
		}
		return;
	}
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
			if (!menu_mouse_button_pressed)
				main.mousePress(main, menu_mouse_pos);

			if (key == K_MOUSE1) {
				if (time < menu_doubleclick_time && menu_doubleclick_position == menu_mouse_pos)
					main.mouseDoubleClick(main, menu_mouse_pos);

				menu_doubleclick_position = menu_mouse_pos;
				menu_doubleclick_time = time + 0.4;
			}
		}
		if (!main.keyDown(main, key, ascii, menu_modkeys_state))
			if (key == K_ESCAPE)
				if (menu_gamestatus & (GAME_ISSERVER | GAME_CONNECTED)) // don't back out to console only
					menu_hide(); // disable menu on unhandled ESC
	}
	if (key >= K_MOUSE1 && key <= K_MOUSE3) {
		++menu_mouse_button_pressed;
		if (menu_mouse_button_pressed > 10) {
			menu_mouse_button_pressed = 10;
			print("Warning: pressed an already pressed button\n");
		}
	}
	if (key == K_ALT) menu_modkeys_state |= GUI_KEY_STATE_ALT;
	if (key == K_CTRL) menu_modkeys_state |= GUI_KEY_STATE_CTRL;
	if (key == K_SHIFT) menu_modkeys_state |= GUI_KEY_STATE_SHIFT;
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
	if (main)
		menu_update_width_height();

	if (!menu_initialized) {
		// TODO draw an info image about this situation
		if not(cvar("utf8_enable"))
			cvar_set("utf8_enable", "1");

		cvar_set("kex_compat", "0"); //Just in case
		if (cvar("r_font_disable_freetype")) {
			cvar_set("r_font_disable_freetype", "0");
			localcmd("\nr_restart\n");
		}
		menu_init_delayed();
		return;
	}
	if (!menu_not_the_first_frame) {
		menu_not_the_first_frame = 1;
		if (menu_active)
		if (!cvar("menu_video_played")) {
			localcmd("set menu_video_played 1; cd loop $menu_cdtrack\n");
			menu_logo_alpha = -0.8; // no idea why, but when I start this at zero, it jumps instead of fading
		}
	}
	extresponse_update();
	menu_time_process();
	if (menu_active) {
		menu_mouse_mode = (cvar("menu_mouse_absolute") || cvar("vid_touchscreen"));
		if (getmousetarget() == (menu_mouse_mode ? MT_CLIENT : MT_MENU) && (getkeydest() == KEY_MENU || getkeydest() == KEY_MENU_GRABBED))
			setkeydest(keyGrabber ? KEY_MENU_GRABBED : KEY_MENU);
		else
			menu_hide();

		if (cvar("cl_capturevideo"))
			frametime = 1 / cvar("cl_capturevideo_fps"); // make capturevideo work smoothly
	}
	menu_gamestatus = 0;
	if (isserver())
		menu_gamestatus = menu_gamestatus | GAME_ISSERVER;

	if (clientstate() == CS_CONNECTED)
		menu_gamestatus = menu_gamestatus | GAME_CONNECTED;

	menu_alpha_previous = menu_alpha;
	if (menu_active) {
		if (menu_alpha == 0 && menu_logo_alpha < 2) {
			menu_logo_alpha = menu_logo_alpha + frametime * 2;
		} else {
			menu_alpha = min(1, menu_alpha + frametime * 5);
			menu_logo_alpha = 2;
		}
	} else {
		menu_alpha = max(0, menu_alpha - frametime * 5);
		menu_logo_alpha = 2;
	}
	gui_draw_reset();
	if (!(menu_gamestatus & (GAME_CONNECTED | GAME_ISSERVER))) {
		if (menu_logo_alpha > 0) {
			gui_draw_background(SKINGFX_BACKGROUND, bound(0, menu_logo_alpha, 1), SKINALIGN_BACKGROUND, TRUE);
			if (menu_alpha <= 0 && SKINALPHA_CURSOR_INTRO > 0) {
				gui_draw_alpha = SKINALPHA_CURSOR_INTRO * bound(0, menu_logo_alpha, 1);
				gui_draw_mouse_pointer(menu_mouse_pos);
				gui_draw_alpha = 1;
			}
		}
	} else if(SKINALPHA_BACKGROUND_INGAME) {
		if (menu_alpha > 0)
			gui_draw_background(SKINGFX_BACKGROUND_INGAME, menu_alpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, FALSE);
	}
	if (menu_alpha != menu_alpha_previous)
		cvar_set("_menu_alpha", ftos(menu_alpha));

	gui_draw_reset();
	menu_draw_pre();
	gui_draw_reset();
	if (menu_alpha <= 0) {
		if (menu_alpha_previous > 0)
			main.initializeDialog(main, main.firstChild);

		gui_draw_reset();
		return;
	}
	gui_draw_alpha *= menu_alpha;
	if (menu_mouse_update()) {
		if (menu_mouse_button_pressed)
			main.mouseDrag(main, menu_mouse_pos);
		else
			main.mouseMove(main, menu_mouse_pos);
	}
	main.draw(main);
	gui_draw_alpha = max(gui_draw_alpha, SKINALPHA_CURSOR_INTRO * bound(0, menu_logo_alpha, 1));
	gui_draw_mouse_pointer(menu_mouse_pos);
	gui_draw_reset();
	frametime = 0;
}

void(void) menu_display {
	menu_active = TRUE;
	setkeydest(KEY_MENU);
	setmousetarget((menu_mouse_mode ? MT_CLIENT : MT_MENU));
	if (!menu_initialized)
		return;

	if (menu_mouse_button_pressed)
		main.mouseRelease(main, menu_mouse_pos);

	menu_mouse_button_pressed = 0;
	main.focusEnter(main);
	main.showNotify(main);
}

void() menu_hide {
	menu_active = FALSE;
	setkeydest(KEY_GAME);
	setmousetarget(MT_CLIENT);
	if(!menu_initialized)
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
	for (e = NULL; (e = nextent(e)); ) {
		if (e.destroy)
			e.destroy(e);
	}
}

void(string itemname) menu_goto {
	entity e;
	if not(menu_initialized)
		return;

	if (itemname == "") { // this can be called by GameCommand
		if (menu_gamestatus & (GAME_ISSERVER | GAME_CONNECTED))
			menu_hide();
		else {
			gui_activate_window(main.mainNexposee);
			menu_display();
		}
	} else {
		e = findstring(NULL, name, itemname);
		if (e) {
			menu_hide();
			gui_activate_window(e);
			gui_setpointerfocus(e);
			menu_display();
		}
	}
}
