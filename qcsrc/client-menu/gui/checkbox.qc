void(entity me, float val) gui_checkbox_set;
string(entity me) gui_checkbox_to_string;
void(entity me, string txt, float sz, string gfx) gui_checkbox_configure;
void(entity me) drawCheckBox;

entity(void) gui_checkbox_spawn {
	entity me = gui_button_spawn();
	me.configureCheckBox = gui_checkbox_configure;
	me.draw = drawCheckBox;
	me.toString = gui_checkbox_to_string;
	me.setChecked = gui_checkbox_set;
	me.useDownAsChecked = 0;
	me.checked = 0;
	me.onClick = gui_checkbox_click;
	me.srcMulti = 0;
	me.disabled = 0;
	me.classname = "CheckBox";
	return me;
}

void(entity me, float val) gui_checkbox_set {
	me.checked = val;
}

void(entity me, entity thOther) gui_checkbox_click {
	me.setChecked(me, !me.checked);
}

string(entity me) gui_checkbox_to_string {
	return strcat(gui_label_to_string(me), ", ", me.checked ? "checked" : "unchecked");
}

void(entity me, string txt, float sz, string gfx) gui_checkbox_configure {
	me.configureButton(me, txt, sz, gfx);
	me.align = 0;
}

void(entity me) drawCheckBox {
	float s;
	s = me.pressed;
	if (me.useDownAsChecked) {
		me.srcSuffix = NULL;
		me.forcePressed = me.checked;
	} else
		me.srcSuffix = (me.checked ? "1" : "0");

	gui_button_draw(me);
	me.pressed = s;
}
