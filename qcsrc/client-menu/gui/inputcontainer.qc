void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_inputcontainer_resize;
void(entity me) gui_inputcontainer_focus_leave;
float(entity me, float scan, float ascii, float shift) gui_inputcontainer_key_down;
float(entity me, vector pos) gui_inputcontainer_focus_xy_change;
float(entity me, vector pos) gui_inputcontainer_mouse_drag;
float(entity me, vector pos) gui_inputcontainer_mouse_move;
float(entity me, vector pos) gui_inputcontainer_mouse_press;
float(entity me, vector pos) gui_inputcontainer_mouse_release;

entity(void) gui_inputcontainer_spawn {
	entity me; me = gui_container_spawn();
	me.keyDown = gui_inputcontainer_key_down;
	me.mouseMove = gui_inputcontainer_mouse_move;
	me.mousePress = gui_inputcontainer_mouse_press;
	me.mouseRelease = gui_inputcontainer_mouse_release;
	me.mouseDrag = gui_inputcontainer_mouse_drag;
	me.focusLeave = gui_inputcontainer_focus_leave;
	me.resizeNotify = gui_inputcontainer_resize;
	me._changeFocusXY = gui_inputcontainer_focus_xy_change;
	me.mouseFocusedChild = NULL;
	me.isTabRoot = 0;
	me.instanceOfInputContainer = 1;
	me.classname = "InputContainer";
	return me;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_inputcontainer_resize {
	gui_container_resize(me, relOrigin, relSize, absOrigin, absSize);
	/*
	if(me.parent.instanceOfInputContainer)
		me.isTabRoot = 0;
	else
		me.isTabRoot = 1;
	*/
}

void(entity me) gui_inputcontainer_focus_leave {
	gui_container_focus_leave(me);
	me.mouseFocusedChild = NULL;
}

float(entity me, float scan, float ascii, float shift) gui_inputcontainer_key_down {
	entity f, ff;
	if (gui_container_key_down(me, scan, ascii, shift))
		return 1;

	if (scan == VM_K_ESCAPE) {
		f = me.focusedChild;
		if (f) {
			me.setFocus(me, NULL);
			return 1;
		}
		return 0;
	}
	if (scan == VM_K_TAB) {
		f = me.focusedChild;
		if (shift & GUI_KEY_STATE_SHIFT) {
			if (f) {
				for (ff = f.prevSibling; ff; ff = ff.prevSibling) {
					if not(ff.focusable)
						continue;

					me.setFocus(me, ff);
					return 1;
				}
			}
			if (!f || me.isTabRoot) {
				for (ff = me.lastChild; ff; ff = ff.prevSibling) {
					if not(ff.focusable)
						continue;

					me.setFocus(me, ff);
					return 1;
				}
				return 0; // AIIIIEEEEE!
			}
		} else {
			if (f) {
				for (ff = f.nextSibling; ff; ff = ff.nextSibling) {
					if not(ff.focusable)
						continue;

					me.setFocus(me, ff);
					return 1;
				}
			}
			if (!f || me.isTabRoot) {
				for (ff = me.firstChild; ff; ff = ff.nextSibling) {
					if not(ff.focusable)
						continue;

					me.setFocus(me, ff);
					return 1;
				}
				return 0; // AIIIIEEEEE!
			}
		}
	}
	return 0;
}

float(entity me, vector pos) gui_inputcontainer_focus_xy_change {
	entity e, ne;
	e = me.mouseFocusedChild;
	ne = me.itemFromPoint(me, pos);
	if(ne)
		if not(ne.focusable)
			ne = NULL;
	me.mouseFocusedChild = ne;
	if (ne)
		if (ne != e) {
			me.setFocus(me, ne);
			if (ne.instanceOfInputContainer) {
				ne.focusedChild = NULL;
				ne._changeFocusXY(e, gui_global_to_box(pos, ne.Container_origin, ne.Container_size));
			}
		}
	return (ne ? TRUE : FALSE);
}

float(entity me, vector pos) gui_inputcontainer_mouse_drag {
	if (gui_container_mouse_drag(me, pos))
		return 1;

	if (pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;

	return 0;
}

float(entity me, vector pos) gui_inputcontainer_mouse_move {
	if (me._changeFocusXY(me, pos))
		if (gui_container_mouse_move(me, pos))
			return 1;

	if (pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;

	return 0;
}

float(entity me, vector pos) gui_inputcontainer_mouse_press {
	me.mouseFocusedChild = NULL; // force focusing
	if (me._changeFocusXY(me, pos))
		if (gui_container_mouse_press(me, pos))
			return 1;

	if (pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;

	return 0;
}

float(entity me, vector pos) gui_inputcontainer_mouse_release {
	float r;
	r = gui_container_mouse_release(me, pos);
	if (me.focused) // am I still eligible for this? (UGLY HACK, but a mouse event could have changed focus away)
		if (me._changeFocusXY(me, pos))
			return 1;

	if (pos_x >= 0 && pos_y >= 0 && pos_x < 1 && pos_y < 1)
		return 1;

	return 0;
}
