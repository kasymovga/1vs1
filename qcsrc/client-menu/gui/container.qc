void(entity me) gui_container_hide;
void(entity me, entity theOther, float theAlpha) gui_container_alpha_set;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize, .vector originField, .vector sizeField) gui_container_lie_resize;
entity(entity me, vector pos) gui_container_item_from_point;
void(entity me) gui_container_draw;
float(entity me, vector pos) gui_container_mouse_doubleclick;
void(entity me, entity theOther, vector theSize, float theAlpha) gui_container_item_centered_add;
void(entity me, entity theOther) gui_container_item_remove;
void(entity me, entity theOther, entity dest) gui_container_item_after_move;
entity(entity me) gui_container_preferred_focused_grand_child;

entity(void) gui_container_spawn {
	entity me; me = gui_item_spawn();
	me.draw = gui_container_draw;
	me.keyUp = gui_container_key_up;
	me.keyDown = gui_container_key_down;
	me.mouseMove = gui_container_mouse_move;
	me.mousePress = gui_container_mouse_press;
	me.mouseDoubleClick = gui_container_mouse_doubleclick;
	me.mouseDrag = gui_container_mouse_drag;
	me.mouseRelease = gui_container_mouse_release;
	me.focusLeave = gui_container_focus_leave;
	me.resizeNotify = gui_container_resize;
	me.resizeNotifyLie = gui_container_lie_resize;
	me.addItem = gui_container_item_add;
	me.addItemCentered = gui_container_item_centered_add;
	me.moveItemAfter = gui_container_item_after_move;
	me.removeItem = gui_container_item_remove;
	me.setFocus = gui_container_focus_set;
	me.setAlphaOf = gui_container_alpha_set;
	me.itemFromPoint = gui_container_item_from_point;
	me.showNotify = gui_container_show;
	me.hideNotify = gui_container_hide;
	me.preferredFocusedGrandChild = gui_container_preferred_focused_grand_child;
	me.focusable = 0;
	me.firstChild = NULL;
	me.lastChild = NULL;
	me.focusedChild = NULL;
	me.shown = 0;
	me.instanceOfContainer = 1;
	me.classname = "Container";
	return me;
}

.entity nextSibling;
.entity prevSibling;
.float resized;
.vector Container_origin;
.vector Container_size;
.float Container_alpha;

void(entity me) gui_container_show {
	entity e;
	if (me.shown)
		return;

	me.shown = 1;
	for (e = me.firstChild; e; e = e.nextSibling)
		if (e.Container_alpha > 0)
			e.showNotify(e);
}

void(entity me) gui_container_hide {
	entity e;
	if not(me.shown)
		return;

	me.shown = 0;
	for (e = me.firstChild; e; e = e.nextSibling)
		if (e.Container_alpha > 0)
			e.hideNotify(e);
}

void(entity me, entity theOther, float theAlpha) gui_container_alpha_set {
	if (theAlpha <= 0) {
		if (theOther.Container_alpha > 0)
			theOther.hideNotify(theOther);
	} else { // value > 0
		if (theOther.Container_alpha <= 0)
			theOther.showNotify(theOther);
	}
	theOther.Container_alpha = theAlpha;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize, .vector originField, .vector sizeField) gui_container_lie_resize {
	entity e;
	vector o, s;
	float d;
	for (e = me.firstChild; e; e = e.nextSibling) {
		o = e.originField;
		s = e.sizeField;
		e.resizeNotify(e, o, s, gui_box_to_global(o, absOrigin, absSize), gui_box_to_global_size(s, absSize));
	}
	do {
		d = 0;
		for (e = me.firstChild; e; e = e.nextSibling)
			if (e.resized) {
				e.resized = 0;
				d = 1;
				o = e.originField;
				s = e.sizeField;
				e.resizeNotify(e, o, s, gui_box_to_global(o, absOrigin, absSize), gui_box_to_global_size(s, absSize));
			}
	} while (d);
	resizeNotifyItem(me, relOrigin, relSize, absOrigin, absSize);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_container_resize {
	me.resizeNotifyLie(me, relOrigin, relSize, absOrigin, absSize, Container_origin, Container_size);
}

entity(entity me, vector pos) gui_container_item_from_point {
	entity e;
	vector o, s;
	for (e = me.lastChild; e; e = e.prevSibling) {
		o = e.Container_origin;
		s = e.Container_size;
		if (pos_x < o_x) continue;
		if (pos_y < o_y) continue;
		if (pos_x >= o_x + s_x) continue;
		if (pos_y >= o_y + s_y) continue;
		return e;
	}
	return NULL;
}

void(entity me) gui_container_draw {
	vector oldshift;
	vector oldscale;
	float oldalpha;
	entity e;
	float odf = drawfont;
	oldshift = gui_draw_shift;
	oldscale = gui_draw_scale;
	oldalpha = gui_draw_alpha;
	me.focusable = 0;
	for (e = me.firstChild; e; e = e.nextSibling) {
		if (e.focusable)
			me.focusable += 1;

		if (e.Container_alpha < 0.003) // can't change color values anyway
			continue;

		gui_draw_shift = gui_box_to_global(e.Container_origin, oldshift, oldscale);
		gui_draw_scale = gui_box_to_global_size(e.Container_size, oldscale);
		gui_draw_alpha *= e.Container_alpha;
		if (e.nexuizFont)
		if (cvar("utf8_oldfont_for_oldchars"))
		if (cvar("font3_is_unicode_compat"))
			drawfont = FONT_USER + 0;

		e.draw(e);
		drawfont = odf;
		gui_draw_shift = oldshift;
		gui_draw_scale = oldscale;
		gui_draw_alpha = oldalpha;
	}
}

void(entity me) gui_container_focus_leave {
	me.setFocus(me, NULL);
}

float(entity me, float scan, float ascii, float shift) gui_container_key_up {
	entity f;
	f = me.focusedChild;
	if (f)
		return f.keyUp(f, scan, ascii, shift);

	return 0;
}

float(entity me, float scan, float ascii, float shift) gui_container_key_down {
	entity f;
	f = me.focusedChild;
	if (f)
		return f.keyDown(f, scan, ascii, shift);

	return 0;
}

float(entity me, vector pos) gui_container_mouse_move {
	entity f;
	f = me.focusedChild;
	if (f)
		return f.mouseMove(f, gui_global_to_box(pos, f.Container_origin, f.Container_size));

	return 0;
}

float(entity me, vector pos) gui_container_mouse_press {
	entity f;
	f = me.focusedChild;
	if (f)
		return f.mousePress(f, gui_global_to_box(pos, f.Container_origin, f.Container_size));

	return 0;
}
float(entity me, vector pos) gui_container_mouse_doubleclick {
	entity f = me.focusedChild;
	if (f && f.mouseDoubleClick)
		return f.mouseDoubleClick(f, gui_global_to_box(pos, f.Container_origin, f.Container_size));

	return 0;
}

float(entity me, vector pos) gui_container_mouse_drag {
	entity f;
	f = me.focusedChild;
	if(f)
		return f.mouseDrag(f, gui_global_to_box(pos, f.Container_origin, f.Container_size));
	return 0;
}

float(entity me, vector pos) gui_container_mouse_release {
	entity f;
	f = me.focusedChild;
	if (f)
		return f.mouseRelease(f, gui_global_to_box(pos, f.Container_origin, f.Container_size));

	return 0;
}

void(entity me, entity theOther, vector theSize, float theAlpha) gui_container_item_centered_add {
	me.addItem(me, theOther, '0.5 0.5 0' - 0.5 * theSize, theSize, theAlpha);
}

void(entity me, entity theOther, vector theOrigin, vector theSize, float theAlpha) gui_container_item_add {
	if (theOther.parent)
		error("Can't add already added item!");

	if (theOther.focusable)
		me.focusable += 1;

	if (theSize_x > 1) {
		theOrigin_x -= 0.5 * (theSize_x - 1);
		theSize_x = 1;
	}
	if (theSize_y > 1) {
		theOrigin_y -= 0.5 * (theSize_y - 1);
		theSize_y = 1;
	}
	theOrigin_x = bound(0, theOrigin_x, 1 - theSize_x);
	theOrigin_y = bound(0, theOrigin_y, 1 - theSize_y);
	theOther.parent = me;
	theOther.Container_origin = theOrigin;
	theOther.Container_size = theSize;
	me.setAlphaOf(me, theOther, theAlpha);
	entity f, l;
	f = me.firstChild;
	l = me.lastChild;
	if (l)
		l.nextSibling = theOther;
	else
		me.firstChild = theOther;

	theOther.prevSibling = l;
	theOther.nextSibling = NULL;
	me.lastChild = theOther;
}

void(entity me, entity theOther) gui_container_item_remove {
	if (theOther.parent != me)
		error("Can't remove from wrong container!");

	if (theOther.focusable)
		me.focusable -= 1;

	theOther.parent = NULL;
	entity n, p, f, l;
	f = me.firstChild;
	l = me.lastChild;
	n = theOther.nextSibling;
	p = theOther.prevSibling;
	if (p)
		p.nextSibling = n;
	else
		me.firstChild = n;

	if (n)
		n.prevSibling = p;
	else
		me.lastChild = p;
}

void(entity me, entity theOther) gui_container_focus_set {
	if (theOther)
		if not(me.focused)
			error("Trying to set focus in a non-focused control!");

	if (me.focusedChild == theOther)
		return;

	//print(etos(me), ": focus changes from ", etos(me.focusedChild), " to ", etos(theOther), "\n");
	if (me.focusedChild) {
		me.focusedChild.focused = 0;
		me.focusedChild.focusLeave(me.focusedChild);
	}
	if (theOther) {
		theOther.focused = 1;
		theOther.focusEnter(theOther);
	}
	me.focusedChild = theOther;
}

void(entity me, entity theOther, entity dest) gui_container_item_after_move {
	// first: remove theOther from the chain
	entity n, p, f, l;
	if (theOther.parent != me)
		error("Can't move in wrong container!");

	f = me.firstChild;
	l = me.lastChild;
	n = theOther.nextSibling;
	p = theOther.prevSibling;
	if(p)
		p.nextSibling = n;
	else
		me.firstChild = n;

	if(n)
		n.prevSibling = p;
	else
		me.lastChild = p;

	// now theOther got removed. Insert it behind dest now.
	theOther.prevSibling = dest;
	if (dest)
		theOther.nextSibling = dest.nextSibling;
	else
		theOther.nextSibling = me.firstChild;

	if (dest)
		dest.nextSibling = theOther;
	else
		me.firstChild = theOther;

	if (theOther.nextSibling)
		theOther.nextSibling.prevSibling = theOther;
	else
		me.lastChild = theOther;
}

entity(entity me) gui_container_preferred_focused_grand_child {
	entity e, e2;
	entity best;
	best = NULL;
	for (e = me.firstChild; e; e = e.nextSibling) {
		if (e.instanceOfContainer) {
			e2 = e.preferredFocusedGrandChild(e);
			if (e2)
				if (!best || best.preferredFocusPriority < e2.preferredFocusPriority)
					best = e2;
		}
		if (e)
			if (!best || best.preferredFocusPriority < e.preferredFocusPriority)
				best = e;
	}
	return best;
}
