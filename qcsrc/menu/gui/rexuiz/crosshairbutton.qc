void(entity me, float theGroup, float theCrosshair) gui_rexuiz_crosshairbutton_configure;
void(entity me, float val) gui_rexuiz_crosshairbutton_set;
void(entity me) gui_rexuiz_crosshairbutton_load;
void(entity me) gui_rexuiz_crosshairbutton_save;
void(entity me) gui_rexuiz_crosshairbutton_draw;

entity(void) gui_rexuiz_crosshairbutton_spawn {
	entity me = gui_radiobutton_spawn();
	me.configureNexuizCrosshairButton = gui_rexuiz_crosshairbutton_configure;
	me.setChecked = gui_rexuiz_crosshairbutton_set;
	me.draw = gui_rexuiz_crosshairbutton_draw;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_CROSSHAIRBUTTON;
	me.useDownAsChecked = 1;
	me.src3 = NULL;
	me.cvarName = NULL;
	me.cvarValueFloat = 0;
	me.loadCvars = gui_rexuiz_crosshairbutton_load;
	me.saveCvars = gui_rexuiz_crosshairbutton_save;
	me.classname = "NexuizCrosshairButton";
	return me;
}

entity(float theGroup, float theCrosshair) gui_rexuiz_crosshairbutton_make {
	entity me = gui_rexuiz_crosshairbutton_spawn();
	me.configureNexuizCrosshairButton(me, theGroup, theCrosshair);
	return me;
}

void(entity me, float theGroup, float theCrosshair) gui_rexuiz_crosshairbutton_configure {
	me.cvarName = "crosshair";
	me.cvarValueFloat = theCrosshair;
	me.loadCvars(me);
	if not(file_exists_image(strcat(gui_image_path(me.image), "_c")))
		me.image = "/gfx/menu/default/crosshairbutton";

	me.configureRadioButton(me, NULL, me.fontSize, me.image, theGroup, 0);
	me.srcMulti = 1;
	me.src3 = str_zone_ifneeded(strcat("/gfx/crosshair", ftos(me.cvarValueFloat)));
}

void(entity me, float val) gui_rexuiz_crosshairbutton_set {
	if (val != me.checked) {
		me.checked = val;
		me.saveCvars(me);
	}
}

void(entity me) gui_rexuiz_crosshairbutton_load {
	if not(me.cvarName)
		return;

	me.checked = (cvar(me.cvarName) == me.cvarValueFloat);
}

void(entity me) gui_rexuiz_crosshairbutton_save {
	if not(me.cvarName)
		return;

	if (me.checked)
		cvar_set(me.cvarName, ftos(me.cvarValueFloat));
	// TODO on an apply button, read _cl_color and execute the color command for it
}

void(entity me) gui_rexuiz_crosshairbutton_draw {
	vector sz, rgb;
	float a;
	rgb = eX * cvar("crosshair_color_red") + eY * cvar("crosshair_color_green") + eZ * cvar("crosshair_color_blue");
	a = cvar("crosshair_color_alpha");
	if (!me.checked && !me.focused) {
		a *= me.disabledAlpha;
		rgb = '1 1 1';
	}
	drawCheckBox(me);
	sz = gui_picture_size(me.src3);
	sz = gui_global_to_box_size(sz, gui_draw_scale);
	sz = sz * cvar("crosshair_size");
	if (sz_x > 0.95)
		sz = sz * (0.95 / sz_x);

	if (sz_y > 0.95)
		sz = sz * (0.95 / sz_y);

	gui_draw_picture('0.5 0.5 0' - 0.5 * sz, me.src3, sz, rgb, a);
}
