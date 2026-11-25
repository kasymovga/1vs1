entity gui_root;
float gui_mouse_pressed;
vector gui_mouse_pos;
vector gui_mouse_pos_old;
float gui_alpha;
float gui_shift;
float gui_current;
float gui_con_chat_save;
float gui_con_chat_was_changed;
float gui_doubleclick_time;
vector gui_doubleclick_position;

void(entity me) gui_recursive_remove {
	entity e, e_next;
	for (e = me.firstChild; e; e = e_next) {
		e_next = e.nextSibling;
		gui_recursive_remove(e);
	}
	me.destroy(me);
	remove(me);
}

float(float bInputType, float nPrimary, float nSecondary) gui_input_event {
	float r;
	r = FALSE;
	gui_draw_reset();
	gui_mouse_pos = gui_global_to_box_size(mouse_position(), gui_draw_scale);
	if (nPrimary == VM_K_MOUSE1) {
		if (bInputType == 0) { //Key down
			if not(gui_mouse_pressed) {
				gui_root.mousePress(gui_root, gui_mouse_pos);
				gui_mouse_pressed = TRUE;
				if (gui_mouse_pos == gui_doubleclick_position && time < gui_doubleclick_time)
					gui_root.mouseDoubleClick(gui_root, gui_mouse_pos);

				gui_doubleclick_time = time + 0.4;
				gui_doubleclick_position = gui_mouse_pos;
			}
			r = TRUE;
		} else { //Key up
			if (gui_mouse_pressed) {
				gui_root.mouseRelease(gui_root, gui_mouse_pos);
				gui_mouse_pressed = FALSE;
			}
		}
	}
	if (bInputType == 0) {
		if (nPrimary == VM_K_ALT) { gui_shift |= GUI_KEY_STATE_ALT; r = TRUE; }
		if (nPrimary == VM_K_CTRL) { gui_shift |= GUI_KEY_STATE_CTRL; r = TRUE; }
		if (nPrimary == VM_K_SHIFT) { gui_shift |= GUI_KEY_STATE_SHIFT; r = TRUE; }
		if (gui_root.keyDown(gui_root, nPrimary, nSecondary, gui_shift)) {
			return TRUE;
		} else if (nPrimary == VM_K_ESCAPE) {
			gui_hide();
			return TRUE;
		}
	} else {
		if (nPrimary == VM_K_ALT) { gui_shift &= ~(gui_shift & GUI_KEY_STATE_ALT); r = TRUE; }
		if (nPrimary == VM_K_CTRL) { gui_shift &= ~(gui_shift & GUI_KEY_STATE_CTRL); r = TRUE; }
		if (nPrimary == VM_K_SHIFT) { gui_shift &= ~(gui_shift & GUI_KEY_STATE_SHIFT); r = TRUE; }
	}
	if (gui_mouse_pos != gui_mouse_pos_old) {
		if (gui_mouse_pressed) {
			gui_root.mouseDrag(gui_root, gui_mouse_pos);
		} else
			gui_root.mouseMove(gui_root, gui_mouse_pos);

		gui_mouse_pos_old = gui_mouse_pos;
	}
	return r;
}

void() gui_draw_remove {
	if (gui_alpha > 0) {
		gui_alpha -= view_drawframetime * 5;
	} else {
		gui_recursive_remove(gui_root);
		gui_root = NULL;
		if (input_event_callback == gui_input_event)
			input_event_callback = NULL;

		gui_chat_restore();
		return;
	}
	gui_root.focusEnter(gui_root);
	gui_root.showNotify(gui_root);
	gui_draw_reset();
	gui_draw_background(SKINGFX_BACKGROUND_INGAME, gui_alpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, FALSE);
	gui_draw_reset();
	gui_draw_alpha *= gui_alpha;
	gui_root.drawGUI(gui_root);
}

void() gui_draw {
	float timescale = getstatf(VM_STAT_MOVEVARS_TIMESCALE);
	if (gui_alpha < 1) {
		gui_alpha += view_drawframetime * 5;
	}
	gui_conwidth = CVAR(vid_conwidth);
	gui_conheight = CVAR(vid_conheight);
	gui_root.focusEnter(gui_root);
	gui_root.showNotify(gui_root);
	gui_draw_reset();
	gui_draw_background(SKINGFX_BACKGROUND_INGAME, gui_alpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, FALSE);
	gui_draw_reset();
	gui_draw_alpha *= gui_alpha;
	gui_root.drawGUI(gui_root);
	mouse_enable("");
	input_event_callback = gui_input_event;
	gui_input_event(1, 0, 0); //workaround for old engines
}

void() gui_draw_set {
	view_draw2d_post_self = self;
	view_draw2d_post = gui_draw;
}

void(float window) gui_show {
	gui_mouse_pressed = FALSE;
	gui_shift = FALSE;
	gui_current = window;
	if not(gui_root) {
		if (cvar("_backup_con_chatvars_set")) //avoid conflicts with con_chat_maximize
			gui_con_chat_save = cvar("_backup_con_chat");
		else
			gui_con_chat_save = cvar("con_chat");

		gui_con_chat_was_changed = TRUE;
		cvar_set("con_chat", "0");
		skin_init();
		gui_conwidth = CVAR(vid_conwidth);
		gui_conheight = CVAR(vid_conheight);
		gui_draw_reset();
		gui_root = gui_rexuiz_mainwindow_spawn(); gui_root.configureMainWindow(gui_root);
		vector wh;
		wh_x = gui_conwidth;
		wh_y = gui_conheight;
		wh_z = 0;
		gui_root.resizeNotify(gui_root, '0 0 0', wh, '0 0 0', wh);
	}
	gui_root.draw2d = gui_draw_set;
	gui_root.draw2dflag = 1;
	entity e = NULL;
	switch (window) {
	case GUI_TEAMSELECT:
		e = gui_teamselect;
		break;
	case GUI_GAMEMENU:
		e = gui_gamemenu;
		break;
	case GUI_GAMESETTINGS:
		e = gui_gamesettings;
		break;
	case GUI_VCALL:
		e = gui_votecall;
		break;
	case GUI_QUIT:
		e = gui_quit;
		break;
	case GUI_RADIO:
		e = gui_radio;
		break;
	case GUI_SAVELOAD:
		e = gui_saveload;
		break;
	case GUI_HINT:
		e = gui_hint;
		break;
	case GUI_REPORT:
		e = gui_report;
		break;
	case GUI_MUTELIST:
		e = gui_mutelist;
		break;
	case GUI_RECORDLIST:
		e = gui_recordlist;
		break;
	case GUI_HUD:
		e = gui_hud;
		break;
	}
	if not(e) {
		gui_hide();
		return;
	}
	gui_activate_window(e);
	gui_setpointerfocus(e);
	gui_root.focused = 1;
	gui_container_focus_set(gui_root, e);
}

void() gui_hide {
	if (gui_current == GUI_GAMEMENU || gui_current == GUI_TEAMSELECT || gui_current == GUI_SAVELOAD || (gui_current == GUI_HINT && !hint_user)) {
		gui_root.draw2d = gui_draw_remove;
		gui_root.draw2dflag = 1;
	} else if (gui_current == GUI_HUD) {
		gui_show(GUI_GAMESETTINGS);
	} else
		gui_show(GUI_GAMEMENU);
}

void(void) gui_chat_restore {
	if (gui_con_chat_was_changed) {
		gui_con_chat_was_changed = FALSE;
		cvar_set("con_chat", ftos(gui_con_chat_save));
		if (cvar_string("_backup_con_chat") != "")
			cvar_set("_backup_con_chat", ftos(gui_con_chat_save)); //avoid conflicts with con_chat_maximize
	}
}
