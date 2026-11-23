entity(void) gui_rexuiz_inputbox_spawn {
	entity me; me = gui_inputbox_spawn();
	me.configureNexuizInputBox = configureNexuizInputBoxNexuizInputBox;
	me.focusLeave = focusLeaveNexuizInputBox;
	me.setText = setTextNexuizInputBox;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_INPUTBOX;
	me.onChange = NULL;
	me.onChangeEntity = NULL;
	me.onEnter = NULL;
	me.onEnterEntity = NULL;
	me.marginLeft = SKINMARGIN_INPUTBOX_CHARS;
	me.marginRight = SKINMARGIN_INPUTBOX_CHARS;
	me.color = SKINCOLOR_INPUTBOX_N;
	me.colorF = SKINCOLOR_INPUTBOX_F;
	me.alpha = SKINALPHA_TEXT;
	me.cvarName = NULL;
	me.loadCvars = loadCvarsNexuizInputBox;
	me.saveCvars = saveCvarsNexuizInputBox;
	me.keyDown = keyDownNexuizInputBox;
	me.classname = "NexuizInputBox";
	return me;
}

entity(float doEditColorCodes, string theCvar) gui_rexuiz_inputbox_make {
	entity me;
	me = gui_rexuiz_inputbox_spawn();
	me.configureNexuizInputBox(me, doEditColorCodes, theCvar);
	return me;
}
void configureNexuizInputBoxNexuizInputBox(entity me, float doEditColorCodes, string theCvar)
{
	me.configureInputBox(me, "", 0, me.fontSize, me.image);
	me.editColorCodes = doEditColorCodes;
	if(theCvar)
	{
		me.cvarName = theCvar;
		me.loadCvars(me);
	}
	me.cursorPos = strlen(me.text);
}
void focusLeaveNexuizInputBox(entity me)
{
	me.saveCvars(me);
}
void setTextNexuizInputBox(entity me, string new)
{
	if(me.text != new)
	{
		setTextInputBox(me, new);
		if (me.onChange)
			me.onChange(me, me.onChangeEntity);
	}
	else
		setTextInputBox(me, new);
}
void loadCvarsNexuizInputBox(entity me)
{
	if not(me.cvarName)
		return;
	setTextInputBox(me, cvar_string(me.cvarName));
}
void saveCvarsNexuizInputBox(entity me)
{
	if not(me.cvarName)
		return;
	cvar_set(me.cvarName, me.text);
}
float keyDownNexuizInputBox(entity me, float key, float ascii, float shift)
{
	float r;
	r = 0;
	if(key == VM_K_ENTER)
	{
		if(me.cvarName)
		{
			me.saveCvars(me);
			r = 1;
		}
		if (me.onEnter)
			me.onEnter(me, me.onEnterEntity);
	}
	if(keyDownInputBox(me, key, ascii, shift))
		r = 1;
	return r;
}
