void(entity me, string txt, float sz, string gfx, float theGroup, float doAllowDeselect) gui_radiobutton_configure;

entity(void) gui_radiobutton_spawn {
	entity me; me = gui_checkbox_spawn();
	me.configureRadioButton = gui_radiobutton_configure;
	me.checked = 0;
	me.group = 0;
	me.allowDeselect = 0;
	me.onClick = gui_radiobutton_click;
	me.classname = "RadioButton";
	return me;
}

void(entity me, string txt, float sz, string gfx, float theGroup, float doAllowDeselect) gui_radiobutton_configure {
	me.configureCheckBox(me, txt, sz, gfx);
	me.align = 0;
	me.group = theGroup;
	me.allowDeselect = doAllowDeselect;
}

void(entity me, entity theOther) gui_radiobutton_click {
	if (me.checked) {
		if (me.allowDeselect)
			me.setChecked(me, 0);
	} else {
		entity e;
		for (e = me.parent.firstChild; e; e = e.nextSibling)
			if (e != me)
				if (e.group == me.group)
					e.setChecked(e, 0);

		me.setChecked(me, 1);
	}
}
