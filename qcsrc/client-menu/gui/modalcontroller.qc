void(entity me, entity root) gui_modalcontroller_initialize;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_modalcontroller_resize;
void(entity me, entity theOther, float theState, float skipAnimation) gui_modalcontroller_state_switch;
void(entity me) gui_modalcontroller_draw;
void(entity me, entity theOther, entity tabButton) gui_modalcontroller_tab_add;
void(entity me, entity theOther, vector theOrigin, vector theSize, float theAlpha) gui_modalcontroller_item_add;
void(entity me, entity theOther, vector theOrigin, vector theSize, float skipAnimation) gui_modalcontroller_child_show;
void(entity me, float skipAnimation) gui_modalcontroller_all_hide;
void(entity me, entity theOther, float skipAnimation) gui_modalcontroller_child_hide;

entity(void) gui_modalcontroller_spawn {
	entity me; me = gui_container_spawn();
	me.resizeNotify = gui_modalcontroller_resize;
	me.draw = gui_modalcontroller_draw;
	me.addItem = gui_modalcontroller_item_add;
	me.showChild = gui_modalcontroller_child_show;
	me.hideChild = gui_modalcontroller_child_hide;
	me.hideAll = gui_modalcontroller_all_hide;
	me.addItem = gui_modalcontroller_item_add;
	me.addTab = gui_modalcontroller_tab_add;
	me.initializeDialog = gui_modalcontroller_initialize;
	me.switchState = gui_modalcontroller_state_switch;
	me.origin = '0 0 0';
	me.size = '0 0 0';
	me.previousButton = NULL;
	me.fadedAlpha = 0.3;
	me.instanceOfModalController = 1;
	me.classname = "ModalController";
	return me;
}

.vector ModalController_initialSize;
.vector ModalController_initialOrigin;
.float ModalController_initialAlpha;
.vector ModalController_buttonSize;
.vector ModalController_buttonOrigin;
.float ModalController_state;
.float ModalController_factor;
.entity ModalController_controllingButton;

void(entity me, entity root) gui_modalcontroller_initialize {
	me.ModalController_initialAlpha = 1;
	me.hideAll(me, 1);
	me.showChild(me, root, '0 0 0', '0 0 0', 1); // someone else animates for us
}

void(entity button, entity tab) gui_modalcontroller_tab_click {
	if (tab.ModalController_state == 1)
		return;

	tab.parent.hideAll(tab.parent, 0);
	button.forcePressed = 1;
	tab.ModalController_controllingButton = button;
	tab.parent.showChild(tab.parent, tab, button.origin, button.size, 0);
}

void(entity button, entity tab) gui_modalcontroller_open_click {
	gui_modalcontroller_origin_open_click(button, tab, button.origin, button.size);
}

void(entity button, entity tab, vector theOrigin, vector theSize) gui_modalcontroller_origin_open_click {
	if (tab.ModalController_state)
		return;

	if (button)
		button.forcePressed = 1;

	tab.ModalController_controllingButton = button;
	tab.parent.showChild(tab.parent, tab, theOrigin, theSize, 0);
}

void(entity button, entity tab) gui_modalcontroller_close_click {
	tab.parent.hideChild(tab.parent, tab, 0);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_modalcontroller_resize {
	me.resizeNotifyLie(me, relOrigin, relSize, absOrigin, absSize, ModalController_initialOrigin, ModalController_initialSize);
}

void(entity me, entity theOther, float theState, float skipAnimation) gui_modalcontroller_state_switch {
	float previousState;
	previousState = theOther.ModalController_state;
	if (theState == previousState && !skipAnimation)
		return;

	theOther.ModalController_state = theState;
	switch(theState) {
	case 0:
		theOther.ModalController_factor = 1 - theOther.Container_alpha / theOther.ModalController_initialAlpha;
		// fading out
		break;
	case 1:
		theOther.ModalController_factor = theOther.Container_alpha / theOther.ModalController_initialAlpha;
		if (previousState == 0 && !skipAnimation) {
			theOther.Container_origin = theOther.ModalController_buttonOrigin;
			theOther.Container_size = theOther.ModalController_buttonSize;
		}
		// zooming in
		break;
	case 2:
		theOther.ModalController_factor = bound(0, (1 - theOther.Container_alpha / theOther.ModalController_initialAlpha) / me.fadedAlpha, 1);
		// fading out halfway
		break;
	}
	if(skipAnimation)
		theOther.ModalController_factor = 1;
}

void(entity me) gui_modalcontroller_draw {
	entity e;
	entity front = NULL;
	float animating;
	float f; // animation factor
	float df; // animation step size
	float prevFactor, targetFactor;
	vector targetOrigin, targetSize; float targetAlpha;
	animating = 0;
	for (e = me.firstChild; e; e = e.nextSibling)
		if (e.ModalController_state) {
			if (front)
				me.switchState(me, front, 2, 0);

			front = e;
		}
	if (front)
		me.switchState(me, front, 1, 0);

	df = frametime * 3; // animation speed
	for (e = me.firstChild; e; e = e.nextSibling) {
		f = (e.ModalController_factor = min(1, e.ModalController_factor + df));
		if (e.ModalController_state)
			if(f < 1)
				animating = 1;

		if (f < 1) {
			prevFactor = (1 - f) / (1 - f + df);
			targetFactor = df / (1 - f + df);
		} else {
			prevFactor = 0;
			targetFactor = 1;
		}
		if (e.ModalController_state == 2) {
			// fading out partially
			targetOrigin = e.Container_origin; // stay as is
			targetSize = e.Container_size; // stay as is
			targetAlpha = me.fadedAlpha * e.ModalController_initialAlpha;
		} else if(e.ModalController_state == 1) {
			// zooming in
			targetOrigin = e.ModalController_initialOrigin;
			targetSize = e.ModalController_initialSize;
			targetAlpha = e.ModalController_initialAlpha;
		} else {
			// fading out
			if (f < 1)
				animating = 1;

			targetOrigin = e.Container_origin; // stay as is
			targetSize = e.Container_size; // stay as is
			targetAlpha = 0;
		}
		if (f == 1) {
			e.Container_origin = targetOrigin;
			e.Container_size = targetSize;
			me.setAlphaOf(me, e, targetAlpha);
		} else {
			e.Container_origin = e.Container_origin * prevFactor + targetOrigin * targetFactor;
			e.Container_size = e.Container_size * prevFactor + targetSize * targetFactor;
			me.setAlphaOf(me, e, e.Container_alpha * prevFactor + targetAlpha * targetFactor);
		}
		// assume: o == to * f_prev + X * (1 - f_prev)
		// make:   o' = to * f  + X * (1 - f)
		// -->
		// X == (o - to * f_prev) / (1 - f_prev)
		// o' = to * f + (o - to * f_prev) / (1 - f_prev) * (1 - f)
		// --> (maxima)
		// o' = (to * (f - f_prev) + o * (1 - f)) / (1 - f_prev)
	}
	if (animating || !me.focused)
		me.setFocus(me, NULL);
	else
		me.setFocus(me, front);

	gui_container_draw(me);
}

void(entity me, entity theOther, entity tabButton) gui_modalcontroller_tab_add {
	me.addItem(me, theOther, '0 0 0', '1 1 1', 1);
	tabButton.onClick = gui_modalcontroller_tab_click;
	tabButton.onClickEntity = theOther;
	theOther.tabSelectingButton = tabButton;
	if (theOther == me.firstChild) {
		tabButton.forcePressed = 1;
		theOther.ModalController_controllingButton = tabButton;
		me.showChild(me, theOther, '0 0 0', '0 0 0', 1);
	}
}

void(entity me, entity theOther, vector theOrigin, vector theSize, float theAlpha) gui_modalcontroller_item_add {
	gui_container_item_add(me, theOther, theOrigin, theSize, (theOther == me.firstChild) ? theAlpha : 0);
	theOther.ModalController_initialSize = theOther.Container_size;
	theOther.ModalController_initialOrigin = theOther.Container_origin;
	theOther.ModalController_initialAlpha = theAlpha; // hope Container never modifies this
}

void(entity me, entity theOther, vector theOrigin, vector theSize, float skipAnimation) gui_modalcontroller_child_show {
	if (theOther.ModalController_state == 0 || skipAnimation) {
		me.setFocus(me, NULL);
		if (!skipAnimation) {
			theOther.ModalController_buttonOrigin = gui_global_to_box(theOrigin, me.origin, me.size);
			theOther.ModalController_buttonSize = gui_global_to_box_size(theSize, me.size);
		}
		me.switchState(me, theOther, 1, skipAnimation);
	} // zoom in from button (factor increases)
}

void(entity me, float skipAnimation) gui_modalcontroller_all_hide {
	entity e;
	for (e = me.firstChild; e; e = e.nextSibling)
		me.hideChild(me, e, skipAnimation);
}

void(entity me, entity theOther, float skipAnimation) gui_modalcontroller_child_hide {
	if (theOther.ModalController_state || skipAnimation) {
		me.setFocus(me, NULL);
		me.switchState(me, theOther, 0, skipAnimation);
		if (theOther.ModalController_controllingButton) {
			theOther.ModalController_controllingButton.forcePressed = 0;
			theOther.ModalController_controllingButton = NULL;
		}
	} // just alpha fade out (factor increases and decreases alpha)
}
