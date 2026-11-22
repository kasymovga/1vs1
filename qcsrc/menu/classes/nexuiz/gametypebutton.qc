entity spawnNexuizGametypeButton() {
	entity me; me = gui_radiobutton_spawn();
	me.configureNexuizGametypeButton = configureNexuizGametypeButtonNexuizGametypeButton;
	me.setChecked = setCheckedNexuizGametypeButton;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_BUTTON_BIG;
	me.color = SKINCOLOR_BUTTON_N;
	me.colorC = SKINCOLOR_BUTTON_C;
	me.colorF = SKINCOLOR_BUTTON_F;
	me.colorD = SKINCOLOR_BUTTON_D;
	me.srcMulti = 1;
	me.useDownAsChecked = 1;
	me.cvarName = NULL;
	me.loadCvars = loadCvarsNexuizGametypeButton;
	me.saveCvars = saveCvarsNexuizGametypeButton;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizGametypeButton";
	return me;
}
entity makeNexuizGametypeButton(float, string, string);
void GameTypeButton_Click(entity me, entity other);
entity makeNexuizGametypeButton(float theGroup, string theCvar, string theText)
{
	registercvar("_gametype", "dm", 0);
	entity me;
	me = spawnNexuizGametypeButton();
	me.configureNexuizGametypeButton(me, theGroup, theCvar, theText);
	return me;
}
void configureNexuizGametypeButtonNexuizGametypeButton(entity me, float theGroup, string theCvar, string theText)
{
	if(theCvar)
	{
		me.cvarName = theCvar;
		me.loadCvars(me);
	}
	me.configureRadioButton(me, theText, me.fontSize, me.image, theGroup, 0);
	me.align = 0.5;
	me.onClick = GameTypeButton_Click;
	me.onClickEntity = NULL;
}
void setCheckedNexuizGametypeButton(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void loadCvarsNexuizGametypeButton(entity me)
{
	if not(me.cvarName)
		return;
	me.checked = (cvar_string("_gametype") == me.cvarName);
}
void saveCvarsNexuizGametypeButton(entity me)
{
	if not(me.cvarName)
		return;
	cvar_set("_gametype", me.cvarName);
}
void GameTypeButton_Click(entity me, entity other)
{
	gui_radiobutton_click(me, other);
	me.parent.gameTypeChangeNotify(me.parent);
}
