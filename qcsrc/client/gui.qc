entity mainWindow;
float GUI_mouseButtonsPressed;
vector GUI_mouse_pos;
vector GUI_mouse_pos_old;
float GUI_alpha;

void GUI_RemoveRecursive(entity me) {
	entity e;
	for(e = me.firstChild; e; e = e.nextSibling)
		if(e.Container_alpha > 0)
			e.showNotify(e);

	me.destroy(me);
	remove(me);
}

float GUI_InputEvent(float bInputType, float nPrimary, float nSecondary) {
	draw_reset();
	GUI_mouse_pos = globalToBoxSize(mouse_pos, draw_scale);
	if (bInputType == 0 && nPrimary == K_MOUSE1) {
		if not(GUI_mouseButtonsPressed) {
			mainWindow.mousePress(mainWindow, GUI_mouse_pos);
			GUI_mouseButtonsPressed = TRUE;
		}
		GUI_mouseButtonsPressed = TRUE;
	} else {
		if (GUI_mouseButtonsPressed) {
			mainWindow.mouseRelease(mainWindow, GUI_mouse_pos);
		}
		GUI_mouseButtonsPressed = FALSE;
	}
	if (GUI_mouse_pos != GUI_mouse_pos_old) {
		if (GUI_mouseButtonsPressed) {
			mainWindow.mouseDrag(mainWindow, GUI_mouse_pos);
		} else
			mainWindow.mouseMove(mainWindow, GUI_mouse_pos);

		GUI_mouse_pos_old = GUI_mouse_pos;
	}
	return FALSE;
}

void GUI_Draw_Remove() {
	if (GUI_alpha > 0)
		GUI_alpha -= frametime;
	else {
		GUI_RemoveRecursive(mainWindow);
		mainWindow = world;
		return;
	}
	mainWindow.focusEnter(mainWindow);
	mainWindow.showNotify(mainWindow);
	draw_reset();
	draw_alpha *= GUI_alpha;
	mainWindow.drawGUI(mainWindow);
	sb_hidescores = TRUE;
	draw_crosshair = FALSE;
}
void GUI_Draw() {
	if (GUI_alpha < 1)
		GUI_alpha += frametime;

	mainWindow.focusEnter(mainWindow);
	mainWindow.showNotify(mainWindow);
	draw_reset();
	draw_alpha *= GUI_alpha;
	mainWindow.drawGUI(mainWindow);
	sb_hidescores = TRUE;
	draw_crosshair = FALSE;
	Mouse_Enable();
	CSQC_InputEvent_Callback = GUI_InputEvent;
}

void GUI_Show(float window) {
	SkinInit();
	if (mainWindow)
		GUI_RemoveRecursive(mainWindow);

	mainWindow = spawnMainWindow(); mainWindow.configureMainWindow(mainWindow);
	mainWindow.resizeNotify(mainWindow, '0 0 0', eX * CVAR(vid_conwidth) + eY * CVAR(vid_conheight), '0 0 0', eX * CVAR(vid_conwidth) + eY * CVAR(vid_conheight));
	mainWindow.draw2d = GUI_Draw;
	entity e;
	switch (window) {
	case GUI_TEAMSELECT:
		e = mainWindow.teamSelectDialog;
		break;
	}
	if not(e) {
		GUI_Hide();
		return;
	}

	m_activate_window(e);
	m_setpointerfocus(e);
	mainWindow.focused = 1;
	setFocusContainer(mainWindow, e);
}

void GUI_Hide() {
	mainWindow.draw2d = GUI_Draw_Remove;
}
