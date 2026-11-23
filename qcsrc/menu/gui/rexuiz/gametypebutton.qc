void(entity me, float theGroup, string theCvar, string theText) gui_rexuiz_gametypebutton_configure;
void(entity me, float val) gui_rexuiz_gametypebutton_set;
void(entity me) gui_rexuiz_gametypebutton_load;
void(entity me) gui_rexuiz_gametypebutton_save;

entity(void) gui_rexuiz_gametypebutton_spawn {
	entity me = gui_radiobutton_spawn();
	me.configureNexuizGametypeButton = gui_rexuiz_gametypebutton_configure;
	me.setChecked = gui_rexuiz_gametypebutton_set;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_BUTTON_BIG;
	me.color = SKINCOLOR_BUTTON_N;
	me.colorC = SKINCOLOR_BUTTON_C;
	me.colorF = SKINCOLOR_BUTTON_F;
	me.colorD = SKINCOLOR_BUTTON_D;
	me.srcMulti = 1;
	me.useDownAsChecked = 1;
	me.cvarName = NULL;
	me.loadCvars = gui_rexuiz_gametypebutton_load;
	me.saveCvars = gui_rexuiz_gametypebutton_save;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizGametypeButton";
	return me;
}

void(entity me, entity other) gui_rexuiz_gametypebutton_click;

entity(float theGroup, string theCvar, string theText) gui_rexuiz_gametypebutton_make {
	registercvar("_gametype", "dm", 0);
	entity me;
	me = gui_rexuiz_gametypebutton_spawn();
	me.configureNexuizGametypeButton(me, theGroup, theCvar, theText);
	return me;
}

void(entity me, float theGroup, string theCvar, string theText) gui_rexuiz_gametypebutton_configure {
	if (theCvar) {
		me.cvarName = theCvar;
		me.loadCvars(me);
	}
	me.configureRadioButton(me, theText, me.fontSize, me.image, theGroup, 0);
	me.align = 0.5;
	me.onClick = gui_rexuiz_gametypebutton_click;
	me.onClickEntity = NULL;
}

void(entity me, float val) gui_rexuiz_gametypebutton_set {
	if (val != me.checked) {
		me.checked = val;
		me.saveCvars(me);
	}
}

void(entity me) gui_rexuiz_gametypebutton_load {
	if not(me.cvarName)
		return;

	me.checked = (cvar_string("_gametype") == me.cvarName);
}
void(entity me) gui_rexuiz_gametypebutton_save {
	if not(me.cvarName)
		return;

	cvar_set("_gametype", me.cvarName);
}
void(entity me, entity other) gui_rexuiz_gametypebutton_click {
	gui_radiobutton_click(me, other);
	me.parent.gameTypeChangeNotify(me.parent);
}
