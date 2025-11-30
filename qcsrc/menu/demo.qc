vector demo_hud_control_pos;
vector demo_hud_button_size;
string demo_hud_name;
#define DEMO_HUD_TITLE_SIZE 0.5
#define DEMO_HUD_WIDTH 7
float demo_hud_dragging;
vector demo_hud_dragging_start;
vector demo_hud_dragging_mouse_start;
float demo_cvar_save_cl_capturevideo_game;

void(void) demo_stop {
	if (demo_hud_enabled) {
		cvar_set("cl_capturevideo", "0");
		cvar_set("menu_no_hide_chat", "0");;
		cvar_set("cl_capturevideo_game_only", ftos(demo_cvar_save_cl_capturevideo_game));
		demo_hud_enabled = FALSE;
	}
	localcmd("disconnect\n");
}

void(string s) demo_play {
	if (strstrofs(s, "\t", 0) >= 0 || strstrofs(s, "\n", 0) >= 0 ||
			strstrofs(s, " ", 0) >= 0 || strstrofs(s, ";", 0) >= 0 ||
			strstrofs(s, "\"", 0) >= 0 || strstrofs(s, "\\", 0) >= 0) {
		print("Bad demo name\n");
		return;
	}
	localcmd("playdemo ", s, "\n");
	str_unzone_ifneeded(demo_hud_name);
	if (substring(s, 0, 6) == "demos/") s = substring(s, 6, -1);
	float n = strlen(s);
	if (n > 4 && substring(s, n - 4, 4) == ".dem") s = substring(s, 0, n - 4);
	demo_hud_name = str_zone_ifneeded(s);
	if (cvar("menu_demo_hud")) {
		if not(demo_hud_enabled) {
			localcmd("prvm_globalset menu demo_hud_enabled 1\n");
			gui_setpointerfocus(main);
			demo_cvar_save_cl_capturevideo_game = cvar("cl_capturevideo_game_only");
			cvar_set("cl_capturevideo_game_only", "1");
			cvar_set("menu_no_hide_chat", "1");;
		}
	} else
		localcmd("togglemenu\n");
}

void(float dir) demo_track {
	float s = search_begin("demos/*.dem", FALSE, TRUE);
	if (s < 0) return;
	float n = search_getsize(s);
	float i;
	string cur = cvar_string("_demo");
	for (i = 0; i < n; i++) {
		if (search_getfilename(s, i) == cur) {
			if (dir >= 0) {
				if (i + 1 < n)
					demo_play(search_getfilename(s, i + 1));
				else
					demo_play(search_getfilename(s, 0));
			} else {
				if (i > 0)
					demo_play(search_getfilename(s, i - 1));
				else
					demo_play(search_getfilename(s, n - 1));
			}
		}
	}
	search_end(s);
}

float demo_mouse_pressed;
float(float key, float down) demo_input_event {
	if not(isdemo()) {
		demo_hud_enabled = FALSE;
		return FALSE;
	}
	if (key == K_ESCAPE && !down) {
		demo_stop();
	} else if (key == K_MOUSE1) {
		demo_mouse_pressed = down;
		menu_mouse_update();
		if (down) {
			if (!demo_hud_dragging &&
					demo_hud_control_pos_y - demo_hud_button_size_y * DEMO_HUD_TITLE_SIZE <= menu_mouse_pos_y &&
					menu_mouse_pos_y < demo_hud_control_pos_y &&
					demo_hud_control_pos_x <= menu_mouse_pos_x &&
					menu_mouse_pos_x <= demo_hud_control_pos_x + demo_hud_button_size_x * DEMO_HUD_WIDTH) {
				demo_hud_dragging = TRUE;
				demo_hud_dragging_start = demo_hud_control_pos;
				demo_hud_dragging_mouse_start = menu_mouse_pos;
			}
		} else {
			demo_hud_dragging = FALSE;
			if (!demo_hud_dragging && demo_hud_control_pos_y <= menu_mouse_pos_y &&
					menu_mouse_pos_y < demo_hud_control_pos_y + demo_hud_button_size_y &&
					demo_hud_control_pos_x <= menu_mouse_pos_x) {
				float i;
				vector pos = demo_hud_control_pos;
				for (i = 0; i < DEMO_HUD_WIDTH; i++) {
					pos_x += demo_hud_button_size_x;
					if (menu_mouse_pos_x < pos_x) {
						switch (i) {
						case 0: demo_track(-1); break;
						case 1: localcmd("snd_startnonloopingsounds 0;rewind -30;wait;snd_startnonloopingsounds 1\n"); break;
						case 2:
							if (cvar("slowmo")) {
								cvar_set("slowmo", "0");
								localcmd("cd pause\n");
							} else {
								cvar_set("slowmo", "1");
								localcmd("cd resume\n");
							}
							break;
						case 3: localcmd("snd_startnonloopingsounds 0;rewind +30;wait;snd_startnonloopingsounds 1\n"); break;
						case 4: demo_track(1); break;
						case 5:
							demo_stop();
							break;
						case 6:
							if (cvar("cl_capturevideo")) {
								cvar_set("cl_capturevideo", "0");
							} else {
								cvar_set("cl_capturevideo", "1");
							}
							break;
						}
						break;
					}
				}
			}
		}
	}
	return TRUE;
}

void(vector pos, vector sz, string txt, float rec) demo_hud_button_draw {
	vector pos2 = pos + sz;
	float selected = FALSE;
	if (pos_x <= menu_mouse_pos_x && menu_mouse_pos_x < pos2_x)
	if (pos_y <= menu_mouse_pos_y && menu_mouse_pos_y < pos2_y)
		selected = TRUE;

	if (rec) {
		if (cvar("cl_capturevideo"))
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_c"), sz, SKINCOLOR_BUTTON_C, SKINALPHA_TEXT);
		else if (selected)
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_f"), sz, SKINCOLOR_BUTTON_F, SKINALPHA_TEXT);
		else
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_n"), sz, SKINCOLOR_BUTTON_N, SKINALPHA_TEXT);
	} else if (selected) {
		if (demo_mouse_pressed)
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_c"), sz, SKINCOLOR_BUTTON_C, SKINALPHA_TEXT);
		else
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_f"), sz, SKINCOLOR_BUTTON_F, SKINALPHA_TEXT);
	} else {
		gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_n"), sz, SKINCOLOR_BUTTON_N, SKINALPHA_TEXT);
	}
	if (rec)
		gui_draw_picture(pos, txt, sz, SKINCOLOR_TEXT_WARNING, SKINALPHA_TEXT);
	else
		gui_draw_picture(pos, txt, sz, SKINCOLOR_TEXT, SKINALPHA_TEXT);

	cvar_set("_menu_alpha", "0");
	menu_alpha_previous = -1;
}

float(void) demo_hud_draw {
	if not(isdemo()) {
		demo_hud_enabled = FALSE;
		return FALSE;
	}
	if (menu_alpha <= 0) return TRUE;
	gui_draw_reset();
	menu_mouse_update();
	vector sz = '0.05 0.05 0';
	sz_x *= cvar("vid_conheight") / cvar("vid_conwidth");
	demo_hud_button_size = sz;
	vector pos = demo_hud_control_pos;
	if (demo_hud_dragging) {
		pos = demo_hud_dragging_start + (menu_mouse_pos - demo_hud_dragging_mouse_start);
	}
	if (pos_y > 1 - sz_y) {
		pos_y = 1 - sz_y;
	}
	if (pos_x > 1 - sz_x * DEMO_HUD_WIDTH) {
		pos_x = 1 - sz_x * DEMO_HUD_WIDTH;
	}
	if (pos_y < sz_y * DEMO_HUD_TITLE_SIZE) {
		pos_y = sz_y * DEMO_HUD_TITLE_SIZE;
	}
	if (pos_x < 0) {
		pos_x = 0;
	}
	demo_hud_control_pos = pos;
	pos = demo_hud_control_pos - '0 1 0' * sz_y * DEMO_HUD_TITLE_SIZE;
	gui_draw_picture_border(pos, SKINGFX_DIALOGBORDER,
			'1 0 0' * DEMO_HUD_WIDTH * sz_x + '0 1.5 0' * sz_y, '1 1 1', 1,
			SKINHEIGHT_DIALOGBORDER * sz * DEMO_HUD_TITLE_SIZE);
	gui_draw_text(pos + '1 0 0' * sz_x * DEMO_HUD_TITLE_SIZE + '0 0.2 0' * DEMO_HUD_TITLE_SIZE * sz_y,
			gui_draw_text_shorten_to_width(demo_hud_name, (DEMO_HUD_WIDTH - DEMO_HUD_TITLE_SIZE * 2) / (DEMO_HUD_TITLE_SIZE * 0.6), FALSE),
			sz * DEMO_HUD_TITLE_SIZE * 0.6, SKINCOLOR_TEXT, SKINALPHA_TEXT, FALSE);
	pos = demo_hud_control_pos;
	demo_hud_button_draw(pos, sz, "/gfx/demo_previoustrack", FALSE);
	pos_x += sz_x;
	demo_hud_button_draw(pos, sz, "/gfx/demo_fastbackward", FALSE);
	pos_x += sz_x;
	if (cvar("slowmo"))
		demo_hud_button_draw(pos, sz, "/gfx/demo_pause", FALSE);
	else
		demo_hud_button_draw(pos, sz, "/gfx/demo_play", FALSE);

	pos_x += sz_x;
	demo_hud_button_draw(pos, sz, "/gfx/demo_fastforward", FALSE);
	pos_x += sz_x;
	demo_hud_button_draw(pos, sz, "/gfx/demo_nexttrack", FALSE);
	pos_x += sz_x;
	demo_hud_button_draw(pos, sz, "/gfx/demo_stop", FALSE);
	pos_x += sz_x;
	demo_hud_button_draw(pos, sz, "/gfx/demo_record", TRUE);
	gui_draw_mouse_pointer(menu_mouse_pos);
	return TRUE;
}
