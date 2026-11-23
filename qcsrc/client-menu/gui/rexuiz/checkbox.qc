entity(void) gui_rexuiz_checkbox_spawn {
	entity me; me = gui_checkbox_spawn();
	me.configureNexuizCheckBox = configureNexuizCheckBoxNexuizCheckBox;
	me.setChecked = setCheckedNexuizCheckBox;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_CHECKBOX;
	me.yesValue = 1;
	me.noValue = 0;
	me.color = SKINCOLOR_CHECKBOX_N;
	me.colorC = SKINCOLOR_CHECKBOX_C;
	me.colorF = SKINCOLOR_CHECKBOX_F;
	me.colorD = SKINCOLOR_CHECKBOX_D;
	me.cvarName = NULL;
	me.loadCvars = loadCvarsNexuizCheckBox;
	me.saveCvars = saveCvarsNexuizCheckBox;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizCheckBox";
	return me;
}

entity(float isInverted, string theCvar, string theText) gui_rexuiz_checkbox_make {
	float y, n;
	if(isInverted > 1)
	{
		n = isInverted - 1;
		y = -n;
	}
	else if(isInverted < -1)
	{
		n = isInverted + 1;
		y = -n;
	}
	else if(isInverted == 1)
	{
		n = 1;
		y = 0;
	}
	else
	{
		n = 0;
		y = 1;
	}
	return gui_rexuiz_checkbox_make2(y, n, theCvar, theText);
}

entity(float theYesValue, float theNoValue, string theCvar, string theText) gui_rexuiz_checkbox_make2 {
	entity me;
	me = gui_rexuiz_checkbox_spawn();
	me.configureNexuizCheckBox(me, theYesValue, theNoValue, theCvar, theText);
	return me;
}
void configureNexuizCheckBoxNexuizCheckBox(entity me, float theYesValue, float theNoValue, string theCvar, string theText)
{
	me.yesValue = theYesValue;
	me.noValue = theNoValue;
	me.checked = 0;
	if(theCvar)
	{
		me.cvarName = theCvar;
		me.loadCvars(me);
	}
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void setCheckedNexuizCheckBox(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void loadCvarsNexuizCheckBox(entity me)
{
	float m, d;
	if not(me.cvarName)
		return;
	m = (me.yesValue + me.noValue) * 0.5;
	d = (cvar(me.cvarName) - m) / (me.yesValue - m);
	me.checked = (d > 0);
}
void saveCvarsNexuizCheckBox(entity me)
{
	if not(me.cvarName)
		return;
	if(me.checked)
		cvar_set(me.cvarName, ftos(me.yesValue));
	else
		cvar_set(me.cvarName, ftos(me.noValue));
}
