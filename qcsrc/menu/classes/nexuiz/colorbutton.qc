entity spawnNexuizColorButton() {
	entity me; me = spawnRadioButton();
	me.configureNexuizColorButton = configureNexuizColorButtonNexuizColorButton;
	me.setChecked = setCheckedNexuizColorButton;
	me.draw = drawNexuizColorButton;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_COLORBUTTON;
	me.image2 = SKINGFX_COLORBUTTON_COLOR;
	me.useDownAsChecked = 1;
	me.cvarPart = 0;
	me.cvarName = NULL;
	me.cvarValueFloat = 0;
	me.loadCvars = loadCvarsNexuizColorButton;
	me.saveCvars = saveCvarsNexuizColorButton;
	me.classname = "NexuizColorButton";
	return me;
}
entity makeNexuizColorButton(float, float, float);
entity makeNexuizColorButton(float theGroup, float theColor, float theValue)
{
	entity me;
	me = spawnNexuizColorButton();
	me.configureNexuizColorButton(me, theGroup, theColor, theValue);
	return me;
}
void configureNexuizColorButtonNexuizColorButton(entity me, float theGroup, float theColor, float theValue)
{
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
void setCheckedNexuizColorButton(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void loadCvarsNexuizColorButton(entity me)
{
	if not(me.cvarName)
		return;
	if(me.cvarPart == 1)
		me.checked = (cvar(me.cvarName) & 240) == me.cvarValueFloat * 16;
	else
		me.checked = (cvar(me.cvarName) & 15) == me.cvarValueFloat;
}
void saveCvarsNexuizColorButton(entity me)
{
	if not(me.cvarName)
		return;
	if(me.checked)
	{
		if(me.cvarPart == 1)
				cvar_set(me.cvarName, ftos((cvar(me.cvarName) & 15) + me.cvarValueFloat * 16));
		else
				cvar_set(me.cvarName, ftos((cvar(me.cvarName) & 240) + me.cvarValueFloat));
	}
	// TODO on an apply button, read _cl_color and execute the color command for it
}
void drawNexuizColorButton(entity me)
{
	if (me.image2 == "")
		me.colorF = me.colorC = me.color = colormap_palette_color(me.cvarValueFloat, me.cvarPart);
	else
		me.color2 = colormap_palette_color(me.cvarValueFloat, me.cvarPart);
	drawCheckBox(me);
}
