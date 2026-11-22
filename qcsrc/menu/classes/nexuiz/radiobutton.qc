entity spawnNexuizRadioButton() {
	entity me; me = gui_radiobutton_spawn();
	me.configureNexuizRadioButton = configureNexuizRadioButtonNexuizRadioButton;
	me.draw = drawNexuizRadioButton;
	me.setChecked = setCheckedNexuizRadioButton;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_RADIOBUTTON;
	me.color = SKINCOLOR_RADIOBUTTON_N;
	me.colorC = SKINCOLOR_RADIOBUTTON_C;
	me.colorF = SKINCOLOR_RADIOBUTTON_F;
	me.colorD = SKINCOLOR_RADIOBUTTON_D;
	me.cvarName = NULL;
	me.cvarValue = NULL;
	me.cvarOffValue = NULL;
	me.loadCvars = loadCvarsNexuizRadioButton;
	me.saveCvars = saveCvarsNexuizRadioButton;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizRadioButton";
	return me;
}
entity makeNexuizRadioButton(float, string, string, string);
entity makeNexuizRadioButton(float theGroup, string theCvar, string theValue, string theText)
{
	entity me;
	me = spawnNexuizRadioButton();
	me.configureNexuizRadioButton(me, theGroup, theCvar, theValue, theText);
	return me;
}
void configureNexuizRadioButtonNexuizRadioButton(entity me, float theGroup, string theCvar, string theValue, string theText)
{
	if(theCvar)
	{
		me.cvarName = theCvar;
		me.cvarValue = theValue;
		me.loadCvars(me);
	}
	me.configureRadioButton(me, theText, me.fontSize, me.image, theGroup, 0);
}
void setCheckedNexuizRadioButton(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void loadCvarsNexuizRadioButton(entity me)
{
	if(me.cvarName)
		me.checked = (cvar_string(me.cvarName) == me.cvarValue);
}
void drawNexuizRadioButton(entity me)
{
	if not(me.cvarName)
	{
		// this is the "other" option
		// always select this if none other is
		entity e;
		float found;
		found = 0;
		for(e = me.parent.firstChild; e; e = e.nextSibling)
				if(e.group == me.group)
				if(e.checked)
					found = 1;
		if(!found)
				me.setChecked(me, 1);
	}
	drawCheckBox(me);
}
void saveCvarsNexuizRadioButton(entity me)
{
	if(me.cvarName)
	{
		if(me.checked)
				cvar_set(me.cvarName, me.cvarValue);
		else if(me.cvarOffValue)
				cvar_set(me.cvarName, me.cvarOffValue);
	}
}
