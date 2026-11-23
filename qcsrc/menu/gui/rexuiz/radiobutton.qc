void (entity me, float theGroup, string theCvar, string theValue, string theText) gui_rexuiz_radiobutton_configure;
void(entity me, float val) gui_rexuiz_radiobutton_set;
void(entity me) gui_rexuiz_radiobutton_load;
void(entity me) gui_rexuiz_radiobutton_draw;
void(entity me) gui_rexuiz_radiobutton_save;

entity(void) gui_rexuiz_radiobutton_spawn {
	entity me = gui_radiobutton_spawn();
	me.configureNexuizRadioButton = gui_rexuiz_radiobutton_configure;
	me.draw = gui_rexuiz_radiobutton_draw;
	me.setChecked = gui_rexuiz_radiobutton_set;
	me.fontSize = SKINFONTSIZE_NORMAL;
	me.image = SKINGFX_RADIOBUTTON;
	me.color = SKINCOLOR_RADIOBUTTON_N;
	me.colorC = SKINCOLOR_RADIOBUTTON_C;
	me.colorF = SKINCOLOR_RADIOBUTTON_F;
	me.colorD = SKINCOLOR_RADIOBUTTON_D;
	me.cvarName = NULL;
	me.cvarValue = NULL;
	me.cvarOffValue = NULL;
	me.loadCvars = gui_rexuiz_radiobutton_load;
	me.saveCvars = gui_rexuiz_radiobutton_save;
	me.alpha = SKINALPHA_TEXT;
	me.disabledAlpha = SKINALPHA_DISABLED;
	me.classname = "NexuizRadioButton";
	return me;
}

entity(float theGroup, string theCvar, string theValue, string theText) gui_rexuiz_radiobutton_make {
	entity me = gui_rexuiz_radiobutton_spawn();
	me.configureNexuizRadioButton(me, theGroup, theCvar, theValue, theText);
	return me;
}

void (entity me, float theGroup, string theCvar, string theValue, string theText) gui_rexuiz_radiobutton_configure {
	if (theCvar) {
		me.cvarName = theCvar;
		me.cvarValue = theValue;
		me.loadCvars(me);
	}
	me.configureRadioButton(me, theText, me.fontSize, me.image, theGroup, 0);
}

void(entity me, float val) gui_rexuiz_radiobutton_set {
	if (val != me.checked) {
		me.checked = val;
		me.saveCvars(me);
	}
}

void(entity me) gui_rexuiz_radiobutton_load {
	if (me.cvarName)
		me.checked = (cvar_string(me.cvarName) == me.cvarValue);
}

void(entity me) gui_rexuiz_radiobutton_draw {
	if not(me.cvarName) {
		// this is the "other" option
		// always select this if none other is
		entity e;
		float found;
		found = 0;
		for (e = me.parent.firstChild; e; e = e.nextSibling)
			if (e.group == me.group)
			if (e.checked)
				found = 1;
		if (!found)
			me.setChecked(me, 1);
	}
	drawCheckBox(me);
}

void(entity me) gui_rexuiz_radiobutton_save {
	if (me.cvarName) {
		if (me.checked)
			cvar_set(me.cvarName, me.cvarValue);
		else if(me.cvarOffValue)
			cvar_set(me.cvarName, me.cvarOffValue);
	}
}
