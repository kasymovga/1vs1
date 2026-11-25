void(entity me) gui_item_destroy;
void(entity me) gui_item_focus_relinquish;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_item_resize;
void(entity me) gui_item_draw;
void(entity me) gui_item_show;
void(entity me) gui_item_hide;
float(entity me, float scan, float ascii, float shift) gui_item_key_down;
float(entity me, float scan, float ascii, float shift) gui_item_key_up;
float(entity me, vector pos) gui_item_mouse_move;
float(entity me, vector pos) gui_item_mouse_press;
float(entity me, vector pos) gui_item_mouse_drag;
float(entity me, vector pos) gui_item_mouse_release;
void(entity me) focusEnterItem;
void(entity me) focusLeaveItem;
string(entity me) toStringItem;

entity(void) gui_item_spawn {
	entity me = gui_object_spawn();
	me.draw = gui_item_draw;
	me.keyDown = gui_item_key_down;
	me.keyUp = gui_item_key_up;
	me.mouseMove = gui_item_mouse_move;
	me.mousePress = gui_item_mouse_press;
	me.mouseDrag = gui_item_mouse_drag;
	me.mouseRelease = gui_item_mouse_release;
	me.focusEnter = focusEnterItem;
	me.focusLeave = focusLeaveItem;
	me.resizeNotify = gui_item_resize;
	me.relinquishFocus = gui_item_focus_relinquish;
	me.showNotify = gui_item_show;
	me.hideNotify = gui_item_hide;
	me.toString = toStringItem;
	me.destroy = gui_item_destroy;
	me.nexuizFont = 0;
	me.focused = 0;
	me.focusable = 0;
	me.parent = NULL;
	me.preferredFocusPriority = 0;
	me.origin = '0 0 0';
	me.size = '0 0 0';
	me.classname = "Item";
	return me;
}
void(entity me) gui_item_destroy {
	// free memory associated with me
}

void(entity me) gui_item_focus_relinquish {
	if (me.parent)
		if (me.parent.instanceOfContainer)
			me.parent.setFocus(me.parent, NULL);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_item_resize {
	me.origin = absOrigin;
	me.size = absSize;
}

void(entity me) gui_item_draw {
}

void(entity me) gui_item_show {
}

void(entity me) gui_item_hide {
}

float(entity me, float scan, float ascii, float shift) gui_item_key_down {
	return 0; // unhandled
}

float(entity me, float scan, float ascii, float shift) gui_item_key_up {
	return 0; // unhandled
}

float(entity me, vector pos) gui_item_mouse_move {
	return 0; // unhandled
}

float(entity me, vector pos) gui_item_mouse_press {
	return 0; // unhandled
}

float(entity me, vector pos) gui_item_mouse_drag {
	return 0; // unhandled
}

float(entity me, vector pos) gui_item_mouse_release {
	return 0; // unhandled
}

void(entity me) focusEnterItem {
}

void(entity me) focusLeaveItem {
}

string(entity me) toStringItem {
	return NULL;
}
