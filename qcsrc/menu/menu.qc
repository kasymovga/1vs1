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

float URI_GET_SERVERLIST;
#define SERVERLIST_URIS_COUNT 2
var float serverlist_uri_index = 0;
string serverlist_uris[SERVERLIST_URIS_COUNT] = {
	"http://nexuiz.mooo.com/serverlist.txt",
	"http://nexuiz.trafflow.com/serverlist.txt",
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

void(float nodownload) menu_dlc_reload {
	string s = strcat(DLC_BASE_LIST " ", cvar_defstring("menu_dlc_extra"));
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
}

void() m_init =
{
	cvar_set("_menu_alpha", "0");
	if (cvar("sys_first_run"))
		cvar_set("vid_desktopfullscreen", "1");

	string s;
	float i;
	URI_GET_SERVERLIST = uri_register_handler(ServerList_URI_Get_Callback);
	uri_get(serverlist_uris[0], URI_GET_SERVERLIST);

	// list all game dirs (TEST)
	if(cvar("developer"))
	{
		for(i = 0; ; ++i)
		{
			s = getgamedirinfo(i, GETGAMEDIRINFO_NAME);
			if not(s)
				break;
			print(s, ": ", getgamedirinfo(i, GETGAMEDIRINFO_DESCRIPTION));
		}
	}
	menu_dlc_reload(TRUE);
	udppunchhole_extresponse_handler_register();
	ui_con_width_height_set();
}

void UpdateConWidthHeight()
{
	float conwidth_s, conheight_s;
	conwidth_s = conwidth;
	conheight_s = conheight;
	conwidth = cvar("vid_conwidth");
	conheight = cvar("vid_conheight");
	if(conwidth < 800)
	{
		conheight *= 800 / conwidth;
		conwidth = 800;
	}
	if(conheight < 600)
	{
		conwidth *= 600 / conheight;
		conheight = 600;
	}
	if(main)
	{
		if(conwidth_s != conwidth || conheight_s != conheight)
		{
			draw_reset();
			main.resizeNotify(main, '0 0 0', eX * conwidth + eY * conheight, '0 0 0', eX * conwidth + eY * conheight);
		}
	}
}

float dlc_wait_frame;
void() m_init_delayed =
{
	menuInitialized = 0;
	if (dlc_ready_all()) {
		//print("dlc loading finished\n");
		//print("dlc_wait_frame=", ftos(dlc_wait_frame), "\n");
	} else if (dlc_wait_frame < 10) {
		dlc_wait_frame++;
		preMenuInit();
		return;
	} else {
		dlc_set_repos(cvar_string("sv_dlc_repository"));
		menu_dlc_reload(FALSE);
	}
	if(!preMenuInit())
		return;
	menuInitialized = 1;
	GameCommand_Init();
	weapon_register_weapons();
	SkinInit();
	draw_setMousePointer(SKINGFX_CURSOR, SKINSIZE_CURSOR, SKINOFFSET_CURSOR);

	conwidth = conheight = -1;
	draw_reset();
	UpdateConWidthHeight();

	main = spawnMainWindow(); main.configureMainWindow(main);

	main.resizeNotify(main, '0 0 0', eX * conwidth + eY * conheight, '0 0 0', eX * conwidth + eY * conheight);
	main.focused = 1;
	menuShiftState = 0;
	menuMousePos = '0.5 0.5 0';

	if(Menu_Active)
		m_display(); // delayed menu display
};

float(void) menu_mouse_update {
	float changed = 0;
	if(menuMouseMode)
	{
		vector newMouse;
		newMouse = globalToBoxSize(getmousepos(), draw_scale);
		if(newMouse != '0 0 0')
			if(newMouse != menuMousePos)
			{
				menuMousePos = newMouse;
				changed = 1;
			}
	}
	else
	{
		if(frametime > 0)
		{
			vector dMouse;
			dMouse = getmousepos() * (frametime / menuRealFrametime); // for capturevideo
			if(dMouse != '0 0 0')
			{
				dMouse = globalToBoxSize(dMouse, draw_scale);
				menuMousePos += dMouse * cvar("menu_mouse_speed");
				menuMousePos_x = bound(0, menuMousePos_x, 1);
				menuMousePos_y = bound(0, menuMousePos_y, 1);
				changed = 1;
			}
		}
	}
	return changed;
}

void(float key, float ascii) m_keyup =
{
	if(!menuInitialized)
		return;
	if(!Menu_Active)
		return;
	draw_reset();
	main.keyUp(main, key, ascii, menuShiftState);
	if(key >= K_MOUSE1 && key <= K_MOUSE3)
	{
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
	if(key == K_ALT) menuShiftState -= (menuShiftState & S_ALT);
	if(key == K_CTRL) menuShiftState -= (menuShiftState & S_CTRL);
	if(key == K_SHIFT) menuShiftState -= (menuShiftState & S_SHIFT);
};

void(float key, float ascii) m_keydown =
{
	if(!menuInitialized)
		return;
	if(!Menu_Active)
		return;
	if(keyGrabber)
	{
		entity e;
		e = keyGrabber;
		keyGrabber = NULL;
		e.keyGrabbed(e, key, ascii);
	}
	else
	{
		draw_reset();
		if(key >= K_MOUSE1 && key <= K_MOUSE3) {
			menu_mouse_update();
			if(!mouseButtonsPressed)
				main.mousePress(main, menuMousePos);

			if (key == K_MOUSE1) {
				if (time < menu_doubleclick_time && menu_doubleclick_position == menuMousePos)
					main.mouseDoubleClick(main, menuMousePos);

				menu_doubleclick_position = menuMousePos;
				menu_doubleclick_time = time + 0.4;
			}
		}
		if(!main.keyDown(main, key, ascii, menuShiftState))
			if(key == K_ESCAPE)
				if(gamestatus & (GAME_ISSERVER | GAME_CONNECTED)) // don't back out to console only
					m_hide(); // disable menu on unhandled ESC
	}
	if(key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		++mouseButtonsPressed;
		if(mouseButtonsPressed > 10)
		{
			mouseButtonsPressed = 10;
			print("Warning: pressed an already pressed button\n");
		}
	}
	if(key == K_ALT) menuShiftState |= S_ALT;
	if(key == K_CTRL) menuShiftState |= S_CTRL;
	if(key == K_SHIFT) menuShiftState |= S_SHIFT;
};

void() m_draw =
{
	float t;

	menuMouseMode = cvar("menu_mouse_absolute");

	if(main)
		UpdateConWidthHeight();

	if(!menuInitialized)
	{
		// TODO draw an info image about this situation
		if not(cvar("utf8_enable"))
			cvar_set("utf8_enable", "1");

		if (cvar("r_font_disable_freetype")) {
			cvar_set("r_font_disable_freetype", "0");
			localcmd("\nr_restart\n");
		}
		m_init_delayed();
		return;
	}
	if(!menuNotTheFirstFrame)
	{
		menuNotTheFirstFrame = 1;
		if(Menu_Active)
		if(!cvar("menu_video_played"))
		{
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
	if(t)
	{
		frametime *= t;
		menuRealFrametime *= t;
	}
	else
		t = 1;

	if(Menu_Active)
	{
		entity e, oldself;
		oldself = self;
		for(e = findflags(world, nextthink, 0xFFFFFFFF); e; e = findflags(e, nextthink, 0xFFFFFFFF)) {
			self = e;
			self.nextthink = 0;
			self.think();
		}
		self = oldself;
		if(getmousetarget() == (menuMouseMode ? MT_CLIENT : MT_MENU) && (getkeydest() == KEY_MENU || getkeydest() == KEY_MENU_GRABBED))
			setkeydest(keyGrabber ? KEY_MENU_GRABBED : KEY_MENU);
		else
			m_hide();
	}

	if(cvar("cl_capturevideo"))
		frametime = t / cvar("cl_capturevideo_fps"); // make capturevideo work smoothly

	gamestatus = 0;
	if(isserver())
		gamestatus = gamestatus | GAME_ISSERVER;
	if(clientstate() == CS_CONNECTED)
		gamestatus = gamestatus | GAME_CONNECTED;
	if(cvar("developer"))
		gamestatus = gamestatus | GAME_DEVELOPER;

	prevMenuAlpha = menuAlpha;
	if(Menu_Active)
	{
		if(menuAlpha == 0 && menuLogoAlpha < 2)
		{
			menuLogoAlpha = menuLogoAlpha + frametime * 2;
		}
		else
		{
			menuAlpha = min(1, menuAlpha + frametime * 5);
			menuLogoAlpha = 2;
		}
	}
	else
	{
		menuAlpha = max(0, menuAlpha - frametime * 5);
		menuLogoAlpha = 2;
	}

	draw_reset();

	if(!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)))
	{
		if(menuLogoAlpha > 0)
		{
			drawBackground(SKINGFX_BACKGROUND, bound(0, menuLogoAlpha, 1), SKINALIGN_BACKGROUND, TRUE);
			if(menuAlpha <= 0 && SKINALPHA_CURSOR_INTRO > 0)
			{
				draw_alpha = SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1);
				draw_drawMousePointer(menuMousePos);
				draw_alpha = 1;
			}
		}
	}
	else if(SKINALPHA_BACKGROUND_INGAME)
	{
		if(menuAlpha > 0)
			drawBackground(SKINGFX_BACKGROUND_INGAME, menuAlpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, FALSE);
	}

	if(menuAlpha != prevMenuAlpha)
		cvar_set("_menu_alpha", ftos(menuAlpha));

	draw_reset();
	preMenuDraw();
	draw_reset();

	if(menuAlpha <= 0)
	{
		if(prevMenuAlpha > 0)
			main.initializeDialog(main, main.firstChild);
		draw_reset();
		postMenuDraw();
		return;
	}

	draw_alpha *= menuAlpha;
	if (menu_mouse_update()) {
		if(mouseButtonsPressed)
			main.mouseDrag(main, menuMousePos);
		else
			main.mouseMove(main, menuMousePos);
	}
	main.draw(main);
	draw_alpha = max(draw_alpha, SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1));

	draw_drawMousePointer(menuMousePos);

	draw_reset();
	postMenuDraw();

	frametime = 0;
};

void() m_display =
{
	Menu_Active = TRUE;
	setkeydest(KEY_MENU);
	setmousetarget((menuMouseMode ? MT_CLIENT : MT_MENU));

	if(!menuInitialized)
		return;

	if(mouseButtonsPressed)
		main.mouseRelease(main, menuMousePos);
	mouseButtonsPressed = 0;

	main.focusEnter(main);
	main.showNotify(main);
};

void() m_hide =
{
	Menu_Active = FALSE;
	setkeydest(KEY_GAME);
	setmousetarget(MT_CLIENT);

	if(!menuInitialized)
		return;

	main.focusLeave(main);
	main.hideNotify(main);
};

void() m_toggle =
{
	if(Menu_Active)
		m_hide();
	else
		m_display();
};

void() m_shutdown =
{
	entity e;

	m_hide();
	for(e = NULL; (e = nextent(e)) != NULL; )
	{
		if(e.destroy)
			e.destroy(e);
	}
};

void(string itemname) m_goto =
{
	entity e;
	if(!menuInitialized)
		return;
	if(itemname == "") // this can be called by GameCommand
	{
		if(gamestatus & (GAME_ISSERVER | GAME_CONNECTED))
			m_hide();
		else
		{
			m_activate_window(main.mainNexposee);
			m_display();
		}
	}
	else
	{
		e = findstring(NULL, name, itemname);
		if(e)
		{
			m_hide();
			m_activate_window(e);
			m_setpointerfocus(e);
			m_display();
		}
	}
}

void() m_goto_skin_selector =
{
	if(!menuInitialized)
		return;
	// TODO add code to switch back to the skin selector (no idea how to do it now)
	m_goto("skinselector");
}
