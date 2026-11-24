void(entity me, float theGroup, float theColor, float theValue) gui_rexuiz_colorbutton_configure;
void(entity me, float val) gui_rexuiz_colorbutton_set;
void(entity me) gui_rexuiz_colorbutton_load;
void(entity me) gui_rexuiz_colorbutton_save;
void(entity me) gui_rexuiz_colorbutton_draw;

entity(void) gui_rexuiz_colorbutton_spawn {
	entity me = gui_radiobutton_spawn();
	me.configureNexuizColorButton = gui_rexuiz_colorbutton_configure;
	me.setChecked = gui_rexuiz_colorbutton_set;
	me.draw = gui_rexuiz_colorbutton_draw;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_COLORBUTTON;
	me.image2 = SKINGFX_COLORBUTTON_COLOR;
	me.useDownAsChecked = 1;
	me.cvarPart = 0;
	me.cvarName = NULL;
	me.cvarValueFloat = 0;
	me.loadCvars = gui_rexuiz_colorbutton_load;
	me.saveCvars = gui_rexuiz_colorbutton_save;
	me.classname = "NexuizColorButton";
	return me;
}

entity(float theGroup, float theColor, float theValue) gui_rexuiz_colorbutton_make {
	entity me = gui_rexuiz_colorbutton_spawn();
	me.configureNexuizColorButton(me, theGroup, theColor, theValue);
	return me;
}

void(entity me, float theGroup, float theColor, float theValue) gui_rexuiz_colorbutton_configure {
	me.cvarName = "_cl_color";
	me.cvarValueFloat = theValue;
	me.cvarPart = theColor;
	me.loadCvars(me);
	if not(file_exists_image(gui_image_path(me.image2))) {
		me.image2 = "";
		me.srcMulti = 0;
	} else
		me.srcMulti = 1;

	me.configureRadioButton(me, NULL, me.fontSize, me.image, theGroup, 0);
	me.src2 = me.image2;
}

void(entity me, float val) gui_rexuiz_colorbutton_set {
	if (val != me.checked) {
		me.checked = val;
		me.saveCvars(me);
	}
}

void(entity me) gui_rexuiz_colorbutton_load {
	if not(me.cvarName)
		return;

	if (me.cvarPart == 1)
		me.checked = (cvar(me.cvarName) & 240) == me.cvarValueFloat * 16;
	else
		me.checked = (cvar(me.cvarName) & 15) == me.cvarValueFloat;
}

void(entity me) gui_rexuiz_colorbutton_save {
	if not(me.cvarName)
		return;

	if (me.checked) {
		if (me.cvarPart == 1)
			cvar_set(me.cvarName, ftos((cvar(me.cvarName) & 15) + me.cvarValueFloat * 16));
		else
			cvar_set(me.cvarName, ftos((cvar(me.cvarName) & 240) + me.cvarValueFloat));
	}
	// TODO on an apply button, read _cl_color and execute the color command for it
}

void(entity me) gui_rexuiz_colorbutton_draw {
	if (me.image2 == "")
		me.colorF = me.colorC = me.color = colormap_palette_color(me.cvarValueFloat, me.cvarPart);
	else
		me.color2 = colormap_palette_color(me.cvarValueFloat, me.cvarPart);

	drawCheckBox(me);
}
