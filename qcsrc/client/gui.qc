entity mainWindow;
float GUI_mouseButtonsPressed;
vector GUI_mouse_pos;
vector GUI_mouse_pos_old;
float GUI_alpha;
float GUI_shiftState;
float GUI_currentWindow;
float gui_con_chat_save;
float gui_con_chat_was_changed;
float gui_doubleclick_time;
vector gui_doubleclick_position;

void GUI_RemoveRecursive(entity me) {
	entity e, e_next;
	for(e = me.firstChild; e; e = e_next) {
		e_next = e.nextSibling;
		GUI_RemoveRecursive(e);
	}
	me.destroy(me);
	remove(me);
}

float GUI_InputEvent(float bInputType, float nPrimary, float nSecondary) {
	float r;
	r = FALSE;
	gui_draw_reset();
	GUI_mouse_pos = gui_global_to_box_size(mouse_position(), gui_draw_scale);
	if (nPrimary == K_MOUSE1) {
		if (bInputType == 0) { //Key down
			if not(GUI_mouseButtonsPressed) {
				mainWindow.mousePress(mainWindow, GUI_mouse_pos);
				GUI_mouseButtonsPressed = TRUE;
				if (GUI_mouse_pos == gui_doubleclick_position && time < gui_doubleclick_time)
					mainWindow.mouseDoubleClick(mainWindow, GUI_mouse_pos);

				gui_doubleclick_time = time + 0.4;
				gui_doubleclick_position = GUI_mouse_pos;
			}
			r = TRUE;
		} else { //Key up
			if (GUI_mouseButtonsPressed) {
				mainWindow.mouseRelease(mainWindow, GUI_mouse_pos);
				GUI_mouseButtonsPressed = FALSE;
			}
		}
	}
	if (bInputType == 0) {
		if(nPrimary == K_ALT) { GUI_shiftState |= GUI_KEY_STATE_ALT; r = TRUE; }
		if(nPrimary == K_CTRL) { GUI_shiftState |= GUI_KEY_STATE_CTRL; r = TRUE; }
		if(nPrimary == K_SHIFT) { GUI_shiftState |= GUI_KEY_STATE_SHIFT; r = TRUE; }
		if (mainWindow.keyDown(mainWindow, nPrimary, nSecondary, GUI_shiftState)) {
			return TRUE;
		} else if (nPrimary == K_ESCAPE) {
			GUI_Hide();
			return TRUE;
		}
	} else {
		if(nPrimary == K_ALT) { GUI_shiftState &= ~(GUI_shiftState & GUI_KEY_STATE_ALT); r = TRUE; }
		if(nPrimary == K_CTRL) { GUI_shiftState &= ~(GUI_shiftState & GUI_KEY_STATE_CTRL); r = TRUE; }
		if(nPrimary == K_SHIFT) { GUI_shiftState &= ~(GUI_shiftState & GUI_KEY_STATE_SHIFT); r = TRUE; }
	}
	if (GUI_mouse_pos != GUI_mouse_pos_old) {
		if (GUI_mouseButtonsPressed) {
			mainWindow.mouseDrag(mainWindow, GUI_mouse_pos);
		} else
			mainWindow.mouseMove(mainWindow, GUI_mouse_pos);

		GUI_mouse_pos_old = GUI_mouse_pos;
	}
	return r;
}

void GUI_Draw_Remove() {
	float timescale = getstatf(STAT_MOVEVARS_TIMESCALE);
	if (GUI_alpha > 0) {
		if (timescale < 1 || frametime <= 0)
			GUI_alpha -= 0.05;
		else
			GUI_alpha -= frametime * 5;
	} else {
		GUI_RemoveRecursive(mainWindow);
		mainWindow = NULL;
		if (input_event_callback == GUI_InputEvent)
			input_event_callback = NULL;

		gui_chat_restore();
		return;
	}
	mainWindow.focusEnter(mainWindow);
	mainWindow.showNotify(mainWindow);
	gui_draw_reset();
	gui_draw_background(SKINGFX_BACKGROUND_INGAME, GUI_alpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, FALSE);
	gui_draw_reset();
	gui_draw_alpha *= GUI_alpha;
	mainWindow.drawGUI(mainWindow);
}

void GUI_Draw() {
	float timescale = getstatf(STAT_MOVEVARS_TIMESCALE);
	if (GUI_alpha < 1) {
		if (timescale < 1 || frametime <= 0)
			GUI_alpha += 0.05;
		else
			GUI_alpha += frametime * 5;
	}
	gui_conwidth = CVAR(vid_conwidth);
	gui_conheight = CVAR(vid_conheight);
	mainWindow.focusEnter(mainWindow);
	mainWindow.showNotify(mainWindow);
	gui_draw_reset();
	gui_draw_background(SKINGFX_BACKGROUND_INGAME, GUI_alpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, FALSE);
	gui_draw_reset();
	gui_draw_alpha *= GUI_alpha;
	mainWindow.drawGUI(mainWindow);
	mouse_enable("");
	input_event_callback = GUI_InputEvent;
	GUI_InputEvent(1, 0, 0); //workaround for old engines
}

void GUI_Draw_Set() {
	view_draw2d_post_self = self;
	view_draw2d_post = GUI_Draw;
}

void GUI_Show(float window) {
	GUI_mouseButtonsPressed = FALSE;
	GUI_shiftState = FALSE;
	GUI_currentWindow = window;
	if not(mainWindow) {
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
		mainWindow = spawnMainWindow(); mainWindow.configureMainWindow(mainWindow);
		vector wh;
		wh_x = gui_conwidth;
		wh_y = gui_conheight;
		wh_z = 0;
		mainWindow.resizeNotify(mainWindow, '0 0 0', wh, '0 0 0', wh);
	}
	mainWindow.draw2d = GUI_Draw_Set;
	mainWindow.draw2dflag = 1;
	entity e = NULL;
	switch (window) {
	case GUI_TEAMSELECT:
		e = gui_teamSelectDialog;
		break;
	case GUI_GAMEMENU:
		e = gui_gameMenuDialog;
		break;
	case GUI_GAMESETTINGS:
		e = gui_gameSettingsDialog;
		break;
	case GUI_VCALL:
		e = gui_voteCallDialog;
		break;
	case GUI_QUIT:
		e = gui_quitDialog;
		break;
	case GUI_RADIO:
		e = gui_radioDialog;
		break;
	case GUI_SAVELOAD:
		e = gui_saveLoad;
		break;
	case GUI_HINT:
		e = gui_hint;
		break;
	case GUI_REPORT:
		e = gui_report;
		break;
	case GUI_MUTELIST:
		e = gui_muteList;
		break;
	case GUI_RECORDLIST:
		e = gui_recordList;
		break;
	case GUI_HUD:
		e = gui_hud;
		break;
	}
	if not(e) {
		GUI_Hide();
		return;
	}
	gui_activate_window(e);
	gui_setpointerfocus(e);
	mainWindow.focused = 1;
	setFocusContainer(mainWindow, e);
}

void GUI_Hide() {
	if (GUI_currentWindow == GUI_GAMEMENU || GUI_currentWindow == GUI_TEAMSELECT || GUI_currentWindow == GUI_SAVELOAD || (GUI_currentWindow == GUI_HINT && !hint_user)) {
		mainWindow.draw2d = GUI_Draw_Remove;
		mainWindow.draw2dflag = 1;
	} else if (GUI_currentWindow == GUI_HUD) {
		GUI_Show(GUI_GAMESETTINGS);
	} else
		GUI_Show(GUI_GAMEMENU);
}

void(void) gui_chat_restore {
	if (gui_con_chat_was_changed) {
		gui_con_chat_was_changed = FALSE;
		cvar_set("con_chat", ftos(gui_con_chat_save));
		if (cvar_string("_backup_con_chat") != "")
			cvar_set("_backup_con_chat", ftos(gui_con_chat_save)); //avoid conflicts with con_chat_maximize
	}
}
