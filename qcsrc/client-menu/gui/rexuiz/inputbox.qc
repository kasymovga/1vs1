float(entity me, float key, float ascii, float shift) gui_rexuiz_inputbox_key_down;
void(entity me) gui_rexuiz_inputbox_save;
void(entity me) gui_rexuiz_inputbox_load;
void(entity me, string new) gui_rexuiz_inputbox_set;
void(entity me, float doEditColorCodes, string theCvar) gui_rexuiz_inputbox_configure;
void(entity me) gui_rexuiz_inputbox_focus_leave;

entity(void) gui_rexuiz_inputbox_spawn {
	entity me; me = gui_inputbox_spawn();
	me.configureNexuizInputBox = gui_rexuiz_inputbox_configure;
	me.focusLeave = gui_rexuiz_inputbox_focus_leave;
	me.setText = gui_rexuiz_inputbox_set;
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
	me.loadCvars = gui_rexuiz_inputbox_load;
	me.saveCvars = gui_rexuiz_inputbox_save;
	me.keyDown = gui_rexuiz_inputbox_key_down;
	me.classname = "NexuizInputBox";
	return me;
}

entity(float doEditColorCodes, string theCvar) gui_rexuiz_inputbox_make {
	entity me;
	me = gui_rexuiz_inputbox_spawn();
	me.configureNexuizInputBox(me, doEditColorCodes, theCvar);
	return me;
}

void(entity me, float doEditColorCodes, string theCvar) gui_rexuiz_inputbox_configure {
	me.configureInputBox(me, "", 0, me.fontSize, me.image);
	me.editColorCodes = doEditColorCodes;
	if (theCvar) {
		me.cvarName = theCvar;
		me.loadCvars(me);
	}
	me.cursorPos = strlen(me.text);
}

void(entity me) gui_rexuiz_inputbox_focus_leave {
	me.saveCvars(me);
}

void(entity me, string new) gui_rexuiz_inputbox_set {
	if (me.text != new) {
		gui_inputbox_set(me, new);
		if (me.onChange)
			me.onChange(me, me.onChangeEntity);
	} else
		gui_inputbox_set(me, new);
}

void(entity me) gui_rexuiz_inputbox_load {
	if not(me.cvarName)
		return;

	gui_inputbox_set(me, cvar_string(me.cvarName));
}

void(entity me) gui_rexuiz_inputbox_save {
	if not(me.cvarName)
		return;

	cvar_set(me.cvarName, me.text);
}

float(entity me, float key, float ascii, float shift) gui_rexuiz_inputbox_key_down {
	float r;
	r = 0;
	if (key == VM_K_ENTER) {
		if (me.cvarName) {
			me.saveCvars(me);
			r = 1;
		}
		if (me.onEnter)
			me.onEnter(me, me.onEnterEntity);
	}
	if (gui_inputbox_key_down(me, key, ascii, shift))
		r = 1;

	return r;
}
