entity spawnNexuizCrosshairButton() {
	entity me; me = gui_radiobutton_spawn();
	me.configureNexuizCrosshairButton = configureNexuizCrosshairButtonNexuizCrosshairButton;
	me.setChecked = setCheckedNexuizCrosshairButton;
	me.draw = drawNexuizCrosshairButton;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_CROSSHAIRBUTTON;
	me.useDownAsChecked = 1;
	me.src3 = NULL;
	me.cvarName = NULL;
	me.cvarValueFloat = 0;
	me.loadCvars = loadCvarsNexuizCrosshairButton;
	me.saveCvars = saveCvarsNexuizCrosshairButton;
	me.classname = "NexuizCrosshairButton";
	return me;
}
entity makeNexuizCrosshairButton(float, float);
entity makeNexuizCrosshairButton(float theGroup, float theCrosshair)
{
	entity me;
	me = spawnNexuizCrosshairButton();
	me.configureNexuizCrosshairButton(me, theGroup, theCrosshair);
	return me;
}
void configureNexuizCrosshairButtonNexuizCrosshairButton(entity me, float theGroup, float theCrosshair)
{
	me.cvarName = "crosshair";
	me.cvarValueFloat = theCrosshair;
	me.loadCvars(me);
	if not(file_exists_image(strcat(gui_image_path(me.image), "_c")))
		me.image = "/gfx/menu/default/crosshairbutton";
	me.configureRadioButton(me, NULL, me.fontSize, me.image, theGroup, 0);
	me.srcMulti = 1;
	me.src3 = str_zone_ifneeded(strcat("/gfx/crosshair", ftos(me.cvarValueFloat)));
}
void setCheckedNexuizCrosshairButton(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void loadCvarsNexuizCrosshairButton(entity me)
{
	if not(me.cvarName)
		return;
	me.checked = (cvar(me.cvarName) == me.cvarValueFloat);
}
void saveCvarsNexuizCrosshairButton(entity me)
{
	if not(me.cvarName)
		return;
	if(me.checked)
		cvar_set(me.cvarName, ftos(me.cvarValueFloat));
	// TODO on an apply button, read _cl_color and execute the color command for it
}
void drawNexuizCrosshairButton(entity me)
{
	vector sz, rgb;
	float a;
	rgb = eX * cvar("crosshair_color_red") + eY * cvar("crosshair_color_green") + eZ * cvar("crosshair_color_blue");
	a = cvar("crosshair_color_alpha");
	if(!me.checked && !me.focused)
	{
		a *= me.disabledAlpha;
		rgb = '1 1 1';
	}
	drawCheckBox(me);
	sz = gui_picture_size(me.src3);
	sz = gui_global_to_box_size(sz, gui_draw_scale);
	sz = sz * cvar("crosshair_size");
	if(sz_x > 0.95)
		sz = sz * (0.95 / sz_x);
	if(sz_y > 0.95)
		sz = sz * (0.95 / sz_y);
	gui_draw_picture('0.5 0.5 0' - 0.5 * sz, me.src3, sz, rgb, a);
}
