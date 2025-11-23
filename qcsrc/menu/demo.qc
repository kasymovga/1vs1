vector demo_hud_control_pos;
vector demo_hud_button_size;

void(string s) demo_play {
	if (strstrofs(s, "\t", 0) >= 0 || strstrofs(s, "\n", 0) >= 0 ||
			strstrofs(s, " ", 0) >= 0 || strstrofs(s, ";", 0) >= 0 ||
			strstrofs(s, "\"", 0) >= 0 || strstrofs(s, "\\", 0) >= 0) {
		print("Bad demo name\n");
		return;
	}
	localcmd("playdemo ", s, "\n");
	if (cvar("menu_demo_hud")) {
		if not(demo_hud_enabled) {
			localcmd("prvm_globalset menu demo_hud_enabled 1\n");
			gui_setpointerfocus(main);
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
		cvar_set("cl_capturevideo", "0");
		demo_hud_enabled = FALSE;
		localcmd("disconnect\n");
	} else if (key == K_MOUSE1) {
		demo_mouse_pressed = down;
		menu_mouse_update();
		if not(down) {
			if (demo_hud_control_pos_y <= menu_mouse_pos_y &&
					menu_mouse_pos_y < demo_hud_control_pos_y + demo_hud_button_size_y &&
					demo_hud_control_pos_x <= menu_mouse_pos_x) {
				float i;
				vector pos = demo_hud_control_pos;
				for (i = 0; i < 7; i++) {
					pos_x += demo_hud_button_size_x;
					if (menu_mouse_pos_x < pos_x) {
						switch (i) {
						case 0: demo_track(-1); break;
						case 1: localcmd("rewind -30\n"); break;
						case 2:
							if (cvar("slowmo")) {
								cvar_set("slowmo", "0");
								localcmd("cd pause\n");
							} else {
								cvar_set("slowmo", "1");
								localcmd("cd resume\n");
							}
							break;
						case 3: localcmd("rewind +30\n"); break;
						case 4: demo_track(1); break;
						case 5:
							cvar_set("cl_capturevideo", "0");
							demo_hud_enabled = FALSE;
							localcmd("disconnect\n");
							break;
						case 6: localcmd("toggle cl_capturevideo 1\n"); break;
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
		if (selected)
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_f"), sz, SKINCOLOR_BUTTON_F, 1);
		else if (cvar("cl_capturevideo"))
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_c"), sz, SKINCOLOR_BUTTON_C, 1);
		else
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_n"), sz, SKINCOLOR_BUTTON_N, 1);
	} else if (selected) {
		if (demo_mouse_pressed)
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_c"), sz, SKINCOLOR_BUTTON_C, 1);
		else
			gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_f"), sz, SKINCOLOR_BUTTON_F, 1);
	} else {
		gui_draw_picture(pos, strcat(SKINGFX_BUTTON, "_n"), sz, SKINCOLOR_BUTTON_N, 1);
	}
	if (rec)
		gui_draw_picture(pos, txt, sz, SKINCOLOR_TEXT_WARNING, 1);
	else
		gui_draw_picture(pos, txt, sz, SKINCOLOR_TEXT, 1);

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
	vector pos = '0.5 0 0';
	pos_x -= sz_x * 3.5;
	demo_hud_control_pos = pos;
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
	pos_x += sz_x;
	gui_draw_mouse_pointer(menu_mouse_pos);
	return TRUE;
}
