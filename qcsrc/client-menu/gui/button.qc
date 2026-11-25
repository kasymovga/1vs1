void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_button_resize;
void(entity me, string txt, float sz, string gfx) gui_button_configure;
float(entity me, float key, float ascii, float shift) gui_button_key_down;
float(entity me, vector pos) gui_button_mouse_drag;
float(entity me, vector pos) gui_button_press;
float(entity me, vector pos) gui_button_mouse_release;
void(entity me) gui_button_draw;

entity(void) gui_button_spawn {
	entity me; me = gui_label_spawn();
	me.configureButton = gui_button_configure;
	me.draw = gui_button_draw;
	me.showNotify = gui_button_show;
	me.resizeNotify = gui_button_resize;
	me.keyDown = gui_button_key_down;
	me.mousePress = gui_button_press;
	me.mouseDrag = gui_button_mouse_drag;
	me.mouseRelease = gui_button_mouse_release;
	me.onClick = NULL;
	me.onClickEntity = NULL;
	me.src = NULL;
	me.srcSuffix = NULL;
	me.src2 = NULL; // is centered, same aspect, and stretched to label size
	me.src2scale = 1;
	me.srcMulti = 1; // 0: button square left, text right; 1: button stretched, text over it
	me.buttonLeftOfText = 0;
	me.focusable = 1;
	me.pressed = 0;
	me.clickTime = 0;
	me.disabled = 0;
	me.disabledAlpha = 0.3;
	me.forcePressed = 0;
	me.color = '1 1 1';
	me.colorC = '1 1 1';
	me.colorF = '1 1 1';
	me.colorD = '1 1 1';
	me.color2 = '1 1 1';
	me.alpha2 = 1;
	me.origin = '0 0 0';
	me.size = '0 0 0';
	me.classname = "Button";
	return me;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_button_resize {
	if (me.srcMulti)
		me.keepspaceLeft = 0;
	else
		me.keepspaceLeft = min(0.8, absSize_y / absSize_x);

	resizeNotifyLabel(me, relOrigin, relSize, absOrigin, absSize);
}

void(entity me, string txt, float sz, string gfx) gui_button_configure {
	configureLabelLabel(me, txt, sz, me.srcMulti ? 0.5 : 0);
	me.src = gfx;
}

float(entity me, float key, float ascii, float shift) gui_button_key_down {
	if (key == VM_K_ENTER || key == VM_K_SPACE) {
		me.clickTime = 0.1; // delayed for effect
		return 1;
	}
	return 0;
}

float(entity me, vector pos) gui_button_mouse_drag {
	me.pressed = 1;
	if(pos_x < 0) me.pressed = 0;
	if(pos_y < 0) me.pressed = 0;
	if(pos_x >= 1) me.pressed = 0;
	if(pos_y >= 1) me.pressed = 0;
	return 1;
}

float(entity me, vector pos) gui_button_press {
	me.mouseDrag(me, pos); // verify coordinates
	return 1;
}

float(entity me, vector pos) gui_button_mouse_release {
	me.mouseDrag(me, pos); // verify coordinates
	if (me.pressed) {
		if not(me.disabled)
			me.onClick(me, me.onClickEntity);

		me.pressed = 0;
	}
	return 1;
}

void(entity me) gui_button_show {
	me.focusable = !me.disabled;
}

void(entity me) gui_button_draw {
	vector bOrigin, bSize;
	float save;
	me.focusable = !me.disabled;
	save = gui_draw_alpha;
	if (me.disabled)
		gui_draw_alpha *= me.disabledAlpha;

	if (me.src != "") {
		if (me.srcMulti) {
			bOrigin = '0 0 0';
			bSize = '1 1 0';
			if(me.disabled)
				gui_draw_button_picture(bOrigin, strcat(me.src, "_d", me.srcSuffix), bSize, me.colorD, 1);
			else if(me.forcePressed || me.pressed || me.clickTime > 0)
				gui_draw_button_picture(bOrigin, strcat(me.src, "_c", me.srcSuffix), bSize, me.colorC, 1);
			else if(me.focused)
				gui_draw_button_picture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1);
			else
				gui_draw_button_picture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color, 1);
		} else {
			if (me.realFontSize_y == 0) {
				bOrigin = '0 0 0';
				bSize = '1 1 0';
			} else {
				bOrigin = eY * (0.5 * (1 - me.realFontSize_y)) + eX * (0.5 * (me.keepspaceLeft - me.realFontSize_x));
				bSize = me.realFontSize;
			}
			if (me.disabled)
				gui_draw_picture(bOrigin, strcat(me.src, "_d", me.srcSuffix), bSize, me.colorD, 1);
			else if (me.forcePressed || me.pressed || me.clickTime > 0)
				gui_draw_picture(bOrigin, strcat(me.src, "_c", me.srcSuffix), bSize, me.colorC, 1);
			else if (me.focused)
				gui_draw_picture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1);
			else
				gui_draw_picture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color, 1);
		}
	}
	if (me.src2 != "") {
		bOrigin = me.keepspaceLeft * eX;
		bSize = eY + eX * (1 - me.keepspaceLeft);
		bOrigin += bSize * (0.5 - 0.5 * me.src2scale);
		bSize = bSize * me.src2scale;
		gui_draw_picture(bOrigin, me.src2, bSize, me.color2, me.alpha2);
	}
	gui_draw_alpha = save;
	drawLabel(me);
	if (me.clickTime > 0 && me.clickTime <= frametime) {
		// keyboard click timer expired? Fire the event then.
		if not(me.disabled)
			me.onClick(me, me.onClickEntity);
	}
	me.clickTime -= frametime;
}
