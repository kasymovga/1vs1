void(entity me) gui_slider_draw;
void(entity me) gui_slider_show;
float(entity me, vector pos) gui_slider_mouse_release;
float(entity me, vector pos) gui_slider_mouse_press;
float(entity me, vector pos) gui_slider_mouse_drag;
float(entity me, float key, float ascii, float shift) gui_slider_key_down;
void(entity me, float theValueMin, float theValue, float theValueMax, float theValueStep, float theValueKeyStep, float theValuePageStep) gui_slider_configure;
void(entity me, float sz, float theAlign, float theTextSpace, string gfx) gui_slider_visuals_configure;
string(entity me, float val) gui_slider_value_text;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_slider_resize;
string(entity me) gui_slider_to_string;
void(entity me, float val) gui_slider_set;

entity(void) gui_slider_spawn {
	entity me = gui_label_spawn();
	me.resizeNotify = gui_slider_resize;
	me.configureSliderVisuals = gui_slider_visuals_configure;
	me.configureSliderValues = gui_slider_configure;
	me.draw = gui_slider_draw;
	me.keyDown = gui_slider_key_down;
	me.mousePress = gui_slider_mouse_press;
	me.mouseDrag = gui_slider_mouse_drag;
	me.mouseRelease = gui_slider_mouse_release;
	me.valueToText = gui_slider_value_text;
	me.toString = gui_slider_to_string;
	me.setValue = gui_slider_set;
	me.showNotify = gui_slider_show;
	me.src = NULL;
	me.focusable = 1;
	me.value = 0;
	me.valueMin = 0;
	me.valueMax = 0;
	me.valueStep = 0;
	me.valueDigits = 0;
	me.valueKeyStep = 0;
	me.valuePageStep = 0;
	me.valueDisplayMultiplier = 1.0;
	me.textSpace = 0;
	me.controlWidth = 0;
	me.pressed = 0;
	me.pressOffset = 0;
	me.previousValue = 0;
	me.tolerance = '0 0 0';
	me.disabled = 0;
	me.color = '1 1 1';
	me.color2 = '1 1 1';
	me.colorD = '1 1 1';
	me.colorC = '1 1 1';
	me.colorF = '1 1 1';
	me.disabledAlpha = 0.3;
	me.classname = "Slider";
	return me;
}

float(float a, float b, float c) gui_slider_median {
	if (a < c)
		return bound(a, b, c);

	return bound(c, b, a);
}

void(entity me, float val) gui_slider_set {
	me.value = val;
}

string(entity me) gui_slider_to_string {
	return strcat(ftos(me.value), " (", me.valueToText(me, me.value), ")");
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_slider_resize {
	gui_label_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.controlWidth = absSize_y / absSize_x;
}

float(float a, float b, float c) almostInBoundSlider {
	float eps;
	eps = (max(a, -a) + max(c, -c)) * 0.001;
	return b == gui_slider_median(a - eps, b, c + eps);
}

string(entity me, float val) gui_slider_value_text {
	if (almostInBoundSlider(me.valueMin, val, me.valueMax))
		return str_float_decimals(val * me.valueDisplayMultiplier, me.valueDigits);

	return "";
}

void(entity me, float sz, float theAlign, float theTextSpace, string gfx) gui_slider_visuals_configure {
	gui_label_configure(me, NULL, sz, theAlign);
	me.textSpace = theTextSpace;
	me.keepspaceLeft = (theTextSpace == 0) ? 0 : (1 - theTextSpace);
	me.src = gfx;
}

void(entity me, float theValueMin, float theValue, float theValueMax, float theValueStep, float theValueKeyStep, float theValuePageStep) gui_slider_configure {
	me.value = theValue;
	me.valueStep = theValueStep;
	me.valueMin = theValueMin;
	me.valueMax = theValueMax;
	me.valueKeyStep = theValueKeyStep;
	me.valuePageStep = theValuePageStep;
	me.valueDigits = 3;
	if (me.valueStep >= 1) // about a whole number
		me.valueDigits = 0;
	else if (me.valueStep >= 0.1) // about a whole number of 10ths
		me.valueDigits = 1;
	else if (me.valueStep >= 0.01) // about a whole number of 100ths
		me.valueDigits = 2;
}

float(entity me, float key, float ascii, float shift) gui_slider_key_down {
	float inRange;
	if (me.disabled)
		return 0;

	inRange = (almostInBoundSlider(me.valueMin, me.value, me.valueMax));
	if (key == VM_K_LEFTARROW) {
		if (inRange)
			me.setValue(me, gui_slider_median(me.valueMin, me.value - me.valueKeyStep, me.valueMax));
		else
			me.setValue(me, me.valueMax);
		return 1;
	}
	if (key == VM_K_RIGHTARROW) {
		if (inRange)
			me.setValue(me, gui_slider_median(me.valueMin, me.value + me.valueKeyStep, me.valueMax));
		else
			me.setValue(me, me.valueMin);
		return 1;
	}
	if (key == VM_K_PGUP) {
		if (inRange)
			me.setValue(me, gui_slider_median(me.valueMin, me.value - me.valuePageStep, me.valueMax));
		else
			me.setValue(me, me.valueMax);
		return 1;
	}
	if (key == VM_K_PGDN) {
		if (inRange)
			me.setValue(me, gui_slider_median(me.valueMin, me.value + me.valuePageStep, me.valueMax));
		else
			me.setValue(me, me.valueMin);
		return 1;
	}
	if (key == VM_K_HOME) {
		me.setValue(me, me.valueMin);
		return 1;
	}
	if (key == VM_K_END) {
		me.setValue(me, me.valueMax);
		return 1;
	}
	// TODO more keys
	return 0;
}

float(entity me, vector pos) gui_slider_mouse_drag {
	float hit;
	float v;
	if (me.disabled)
		return 0;
	if (me.pressed) {
		hit = 1;
		if (pos_x < 0 - me.tolerance_x) hit = 0;
		if (pos_y < 0 - me.tolerance_y) hit = 0;
		if (pos_x >= 1 - me.textSpace + me.tolerance_x) hit = 0;
		if (pos_y >= 1 + me.tolerance_y) hit = 0;
		if (hit) {
			v = gui_slider_median(0, (pos_x - me.pressOffset - 0.5 * me.controlWidth) / (1 - me.textSpace - me.controlWidth), 1) * (me.valueMax - me.valueMin) + me.valueMin;
			if (me.valueStep)
				v = floor(0.5 + v / me.valueStep) * me.valueStep;

			me.setValue(me, v);
		} else
			me.setValue(me, me.previousValue);
	}
	return 1;
}

float(entity me, vector pos) gui_slider_mouse_press {
	float controlCenter;
	if (me.disabled)
		return 0;

	if (pos_x < 0) return 0;
	if (pos_y < 0) return 0;
	if (pos_x >= 1 - me.textSpace) return 0;
	if (pos_y >= 1) return 0;
	controlCenter = (me.value - me.valueMin) / (me.valueMax - me.valueMin) * (1 - me.textSpace - me.controlWidth) + 0.5 * me.controlWidth;
	if (fabs(pos_x - controlCenter) <= 0.5 * me.controlWidth) {
		me.pressed = 1;
		me.pressOffset = pos_x - controlCenter;
		me.previousValue = me.value;
		//me.mouseDrag(me, pos);
	} else {
		float clickValue, pageValue, inRange;
		clickValue = gui_slider_median(0, (pos_x - me.pressOffset - 0.5 * me.controlWidth) / (1 - me.textSpace - me.controlWidth), 1) * (me.valueMax - me.valueMin) + me.valueMin;
		inRange = (almostInBoundSlider(me.valueMin, me.value, me.valueMax));
		if (pos_x < controlCenter) {
			pageValue = me.value - me.valuePageStep;
			if (me.valueStep)
				clickValue = floor(clickValue / me.valueStep) * me.valueStep;
			pageValue = max(pageValue, clickValue);
			if (inRange)
				me.setValue(me, gui_slider_median(me.valueMin, pageValue, me.valueMax));
			else
				me.setValue(me, me.valueMax);
		} else {
			pageValue = me.value + me.valuePageStep;
			if (me.valueStep)
				clickValue = ceil(clickValue / me.valueStep) * me.valueStep;
			pageValue = min(pageValue, clickValue);
			if (inRange)
				me.setValue(me, gui_slider_median(me.valueMin, pageValue, me.valueMax));
			else
				me.setValue(me, me.valueMax);
		}
		if (pageValue == clickValue) {
			controlCenter = (me.value - me.valueMin) / (me.valueMax - me.valueMin) * (1 - me.textSpace - me.controlWidth) + 0.5 * me.controlWidth;
			me.pressed = 1;
			me.pressOffset = pos_x - controlCenter;
			me.previousValue = me.value;
			//me.mouseDrag(me, pos);
		}
	}
	return 1;
}

float(entity me, vector pos) gui_slider_mouse_release {
	me.pressed = 0;
	if (me.disabled)
		return 0;

	return 1;
}

void(entity me) gui_slider_show {
	me.focusable = !me.disabled;
}

void(entity me) gui_slider_draw {
	float controlLeft;
	float save;
	me.focusable = !me.disabled;
	save = gui_draw_alpha;
	if (me.disabled)
		gui_draw_alpha *= me.disabledAlpha;
	gui_draw_button_picture('0 0 0', strcat(me.src, "_s"), eX * (1 - me.textSpace) + eY, me.color2, 1);
	if (almostInBoundSlider(me.valueMin, me.value, me.valueMax)) {
		controlLeft = (me.value - me.valueMin) / (me.valueMax - me.valueMin) * (1 - me.textSpace - me.controlWidth);
		if (me.disabled)
			gui_draw_picture(eX * controlLeft, strcat(me.src, "_d"), eX * me.controlWidth + eY, me.colorD, 1);
		else if (me.pressed)
			gui_draw_picture(eX * controlLeft, strcat(me.src, "_c"), eX * me.controlWidth + eY, me.colorC, 1);
		else if (me.focused)
			gui_draw_picture(eX * controlLeft, strcat(me.src, "_f"), eX * me.controlWidth + eY, me.colorF, 1);
		else
			gui_draw_picture(eX * controlLeft, strcat(me.src, "_n"), eX * me.controlWidth + eY, me.color, 1);
	}
	me.setText(me, me.valueToText(me, me.value));
	gui_draw_alpha = save;
	gui_label_draw(me);
	me.text = NULL; // TEMPSTRING!
}
