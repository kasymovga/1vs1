void(entity me) gui_nexposee_calc;
void(entity me, entity theOther, vector scalecenter, float a0, float a1) gui_nexposee_set;
void(entity me) gui_nexposee_draw;
float(entity me, vector pos) gui_nexposee_mouse_press;
float(entity me, vector pos) gui_nexposee_mouse_release;
float(entity me, vector pos) gui_nexposee_mouse_drag;
float(entity me, vector pos) gui_nexposee_mouse_move;
float(entity me, float scan, float ascii, float shift) gui_nexposee_key_up;
float(entity me, float scan, float ascii, float shift) gui_nexposee_key_down;
void(entity me, entity theOther, vector theOrigin, vector theSize, float theAlpha) gui_nexposee_item_add;
void(entity me) gui_nexposee_focus_enter;
void(entity me, entity theOther, vector theAlign) gui_nexposee_pull;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_nexposee_resize;
void(entity me) gui_nexposee_close;

entity(void) gui_nexposee_spawn {
	entity me; me = gui_container_spawn();
	me.draw = gui_nexposee_draw;
	me.keyDown = gui_nexposee_key_down;
	me.keyUp = gui_nexposee_key_up;
	me.mousePress = gui_nexposee_mouse_press;
	me.mouseMove = gui_nexposee_mouse_move;
	me.mouseRelease = gui_nexposee_mouse_release;
	me.mouseDrag = gui_nexposee_mouse_drag;
	me.resizeNotify = gui_nexposee_resize;
	me.focusEnter = gui_nexposee_focus_enter;
	me.close = gui_nexposee_close;
	me.animationState = -1;
	me.animationFactor = 0;
	me.selectedChild = NULL;
	me.mouseFocusedChild = NULL;
	me.addItem = gui_nexposee_item_add;
	me.calc = gui_nexposee_calc;
	me.setNexposee = gui_nexposee_set;
	me.mousePosition = '0 0 0';
	me.pullNexposee = gui_nexposee_pull;
	me.instanceOfNexposee = 1;
	me.classname = "Nexposee";
	return me;
}

.vector Nexposee_initialSize;
.vector Nexposee_initialOrigin;
.float Nexposee_initialAlpha;
.vector Nexposee_smallSize;
.vector Nexposee_smallOrigin;
.float Nexposee_smallAlpha;
.float Nexposee_mediumAlpha;
.vector Nexposee_scaleCenter;
.vector Nexposee_align;
.float Nexposee_animationFactor;

void(entity me) gui_nexposee_close {
	// user must override this
}

void(entity button, entity theOther) gui_nexposee_close_click {
	theOther.selectedChild = theOther.focusedChild;
	theOther.setFocus(theOther, NULL);
	theOther.animationState = 3;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_nexposee_resize {
	me.calc(me);
	me.resizeNotifyLie(me, relOrigin, relSize, absOrigin, absSize, Nexposee_initialOrigin, Nexposee_initialSize);
}

void(entity me, float theScale) gui_nexposee_scale_calc {
	entity e;
	for (e = me.firstChild; e; e = e.nextSibling) {
		e.Nexposee_smallOrigin = (e.Nexposee_initialOrigin - e.Nexposee_scaleCenter) * theScale + e.Nexposee_scaleCenter;
		e.Nexposee_smallSize = e.Nexposee_initialSize * theScale;
		if (e.Nexposee_align_x > 0)
			e.Nexposee_smallOrigin_x = 1 - e.Nexposee_align_x * theScale;

		if (e.Nexposee_align_x < 0)
			e.Nexposee_smallOrigin_x = -e.Nexposee_smallSize_x + e.Nexposee_align_x * theScale;

		if (e.Nexposee_align_y > 0)
			e.Nexposee_smallOrigin_y = 1 - e.Nexposee_align_y * theScale;

		if (e.Nexposee_align_y < 0)
			e.Nexposee_smallOrigin_y = -e.Nexposee_smallSize_y + e.Nexposee_align_y * theScale;
	}
}

void(entity me) gui_nexposee_calc {
	/*
	 * patented by Apple
	 * can't put that here ;)
	 */
	float theScale;
	entity e, e2;
	vector emins, emaxs, e2mins, e2maxs;
	for (theScale = 0.7;; theScale *= 0.99) {
		gui_nexposee_scale_calc(me, theScale);
		for (e = me.firstChild; e; e = e.nextSibling) {
			emins = e.Nexposee_smallOrigin;
			emaxs = emins + e.Nexposee_smallSize;
			for (e2 = e.nextSibling; e2; e2 = e2.nextSibling) {
				e2mins = e2.Nexposee_smallOrigin;
				e2maxs = e2mins + e2.Nexposee_smallSize;
				// two intervals [amins, amaxs] and [bmins, bmaxs] overlap if:
				//   amins < bmins < amaxs < bmaxs
				// for which suffices
				//   bmins < amaxs
				//   amins < bmaxs
				if ((e2mins_x - emaxs_x) * (emins_x - e2maxs_x) > 0) // x overlap
					if ((e2mins_y - emaxs_y) * (emins_y - e2maxs_y) > 0) { // y overlap
						goto have_overlap;
					}
			}
		}
		break;
:have_overlap
	}
	theScale *= 0.95;
	gui_nexposee_scale_calc(me, theScale);
}

void(entity me, entity theOther, vector scalecenter, float a0, float a1) gui_nexposee_set {
	theOther.Nexposee_scaleCenter = scalecenter;
	theOther.Nexposee_smallAlpha = a0;
	me.setAlphaOf(me, theOther, a0);
	theOther.Nexposee_mediumAlpha = a1;
}

void(entity me) gui_nexposee_draw {
	float a;
	float a0;
	entity e;
	float f;
	if (me.animationState == -1) {
		me.animationState = 0;
	}
	//print(ftos(me.animationState), "\n");
	f = min(1, frametime * 5);
	switch(me.animationState) {
	case 0:
		me.animationFactor = 0;
		break;
	case 1:
		me.animationFactor += f;
		if (me.animationFactor >= 1) {
			me.animationFactor = 1;
			me.animationState = 2;
			gui_container_focus_set(me, me.selectedChild);
			#ifdef MENUQC
			gui_load_all_cvars(me);
			#endif
		}
		break;
	case 2:
		me.animationFactor = 1;
		break;
	case 3:
		me.animationFactor -= f;
		me.mouseFocusedChild = me.itemFromPoint(me, me.mousePosition);
		if (me.animationFactor <= 0) {
			me.animationFactor = 0;
			me.animationState = 0;
			me.selectedChild = me.mouseFocusedChild;
		}
		break;
	}
	f = min(1, frametime * 10);
	for (e = me.firstChild; e; e = e.nextSibling) {
		if (e == me.selectedChild) {
			e.Container_origin = e.Nexposee_smallOrigin * (1 - me.animationFactor) + e.Nexposee_initialOrigin * me.animationFactor;
			e.Container_size = e.Nexposee_smallSize * (1 - me.animationFactor) + e.Nexposee_initialSize * me.animationFactor;
			e.Nexposee_animationFactor = me.animationFactor;
			a0 = e.Nexposee_mediumAlpha;
			if (me.animationState == 3)
				if (e != me.mouseFocusedChild)
					a0 = e.Nexposee_smallAlpha;

			a = a0 * (1 - me.animationFactor) + me.animationFactor;
		} else {
			// minimum theSize counts
			e.Container_origin = e.Nexposee_smallOrigin;
			e.Container_size = e.Nexposee_smallSize;
			e.Nexposee_animationFactor = 0;
			a = e.Nexposee_smallAlpha * (1 - me.animationFactor);
		}
		me.setAlphaOf(me, e, e.Container_alpha * (1 - f) + a * f);
	}
	gui_container_draw(me);
	/*
	for(e = me.firstChild; e; e = e.nextSibling)
	{
		vector t, fs;
		a0 = e.Container_alpha;
		if(a0 < e.Nexposee_smallAlpha)
			a = 0.3 * (a0 - 0) / (e.Nexposee_smallAlpha - 0);
		else if(a0 < e.Nexposee_mediumAlpha)
			a = 0.3 + 0.5 * (a0 - e.Nexposee_smallAlpha)  / (e.Nexposee_mediumAlpha - e.Nexposee_smallAlpha);
		else
			a = 0.8 - 0.8 * (a0 - e.Nexposee_mediumAlpha) / (1 - e.Nexposee_mediumAlpha);
		fs = (eX * (1 / draw_scale_x) + eY * (1 / draw_scale_y)) * 36;
		t = gui_text_width(e.title, FALSE) * eX * fs_x + eY * fs_y;
		gui_draw_text(e.Container_origin + (e.Container_size_x * eX - t) * 0.5 - 0.5 * eY * t_y, e.title, fs, e.color, a, FALSE);
	}
	*/
}

float(entity me, vector pos) gui_nexposee_mouse_press {
	if (me.animationState == 0) {
		me.mouseFocusedChild = NULL;
		gui_nexposee_mouse_move(me, pos);
		if (me.mouseFocusedChild) {
			me.animationState = 1;
			gui_container_focus_set(me, NULL);
		} else
			me.close(me);

		return 1;
	} else if(me.animationState == 2) {
		if not(gui_container_mouse_press(me, pos)) {
			me.animationState = 3;
			gui_container_focus_set(me, NULL);
		}
		return 1;
	}
	return 0;
}

float(entity me, vector pos) gui_nexposee_mouse_release {
	if (me.animationState == 2)
		return gui_container_mouse_release(me, pos);

	return 0;
}

float(entity me, vector pos) gui_nexposee_mouse_drag {
	if (me.animationState == 2)
		return gui_container_mouse_drag(me, pos);

	return 0;
}

float(entity me, vector pos) gui_nexposee_mouse_move {
	entity e;
	me.mousePosition = pos;
	e = me.mouseFocusedChild;
	me.mouseFocusedChild = me.itemFromPoint(me, pos);
	if (me.animationState == 2)
		return gui_container_mouse_move(me, pos);

	if (me.animationState == 0) {
		if (me.mouseFocusedChild)
			if (me.mouseFocusedChild != e)
				me.selectedChild = me.mouseFocusedChild;

		return 1;
	}
	return 0;
}

float(entity me, float scan, float ascii, float shift) gui_nexposee_key_up {
	if (me.animationState == 2)
		return gui_container_key_up(me, scan, ascii, shift);

	return 0;
}

float(entity me, float scan, float ascii, float shift) gui_nexposee_key_down {
	float nexposeeKey = 0;
	if (me.animationState == 2)
		if (gui_container_key_down(me, scan, ascii, shift))
			return 1;

	if (scan == VM_K_TAB) {
		if (me.animationState == 0) {
			if (shift & GUI_KEY_STATE_SHIFT) {
				if (me.selectedChild)
					me.selectedChild = me.selectedChild.prevSibling;

				if not(me.selectedChild)
					me.selectedChild = me.lastChild;
			} else {
				if (me.selectedChild)
					me.selectedChild = me.selectedChild.nextSibling;

				if not(me.selectedChild)
					me.selectedChild = me.firstChild;
			}
		}
	}
	switch(me.animationState) {
	case 0:
	case 3:
		nexposeeKey = ((scan == VM_K_SPACE) || (scan == VM_K_ENTER));
		break;
	case 1:
	case 2:
		nexposeeKey = (scan == VM_K_ESCAPE);
		break;
	}
	if (nexposeeKey) {
		switch(me.animationState) {
		case 0:
		case 3:
			me.animationState = 1;
			break;
		case 1:
		case 2:
			me.animationState = 3;
			break;
		}
		if (me.focusedChild)
			me.selectedChild = me.focusedChild;

		if not(me.selectedChild)
			me.animationState = 0;

		gui_container_focus_set(me, NULL);
		return 1;
	}
	return 0;
}

void(entity me, entity theOther, vector theOrigin, vector theSize, float theAlpha) gui_nexposee_item_add {
	gui_container_item_add(me, theOther, theOrigin, theSize, theAlpha);
	theOther.Nexposee_initialSize = theOther.Container_size;
	theOther.Nexposee_initialOrigin = theOther.Container_origin;
	theOther.Nexposee_initialAlpha = theOther.Container_alpha;
}

void(entity me) gui_nexposee_focus_enter {
	if (me.animationState == 2) {
		gui_container_focus_set(me, me.selectedChild);
		#ifdef MENUQC
		gui_load_all_cvars(me);
		#endif
	}
}

void(entity me, entity theOther, vector theAlign) gui_nexposee_pull {
	theOther.Nexposee_align = theAlign;
}
