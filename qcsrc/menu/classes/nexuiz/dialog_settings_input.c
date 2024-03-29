#ifdef INTERFACE
CLASS(NexuizInputSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizInputSettingsTab, fill, void(entity))
	ATTRIB(NexuizInputSettingsTab, title, string, _("Input"))
	ATTRIB(NexuizInputSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizInputSettingsTab, rows, float, 22)
	ATTRIB(NexuizInputSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizInputSettingsTab)
entity makeNexuizInputSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizInputSettingsTab()
{
	entity me;
	me = spawnNexuizInputSettingsTab();
	me.configureDialog(me);
	return me;
}

void(entity e) accelerationLoadCvarsNexuizInputSettingsTab {
	e.value = -cvar(e.cvarName); if (e.value == 1) e.value = 0;
}

void(entity e) accelerationSaveCvarsNexuizInputSettingsTab {
	if (e.value == 0) cvar_set(e.cvarName, "1"); else cvar_set(e.cvarName, ftos(-e.value));
}

void fillNexuizInputSettingsTab(entity me)
{
	entity e;
	entity kb;

	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Key bindings:")));
	me.TR(me);
		me.TD(me, me.rows - 2, 3, kb = makeNexuizKeyBinder());
	me.gotoRC(me, me.rows - 1, 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizButton(_("Change key..."), '0 0 0'));
			e.onClick = KeyBinder_Bind_Change;
			e.onClickEntity = kb;
			kb.keyGrabButton = e;
		me.TD(me, 1, 1, e = makeNexuizButton(_("Edit..."), '0 0 0'));
			e.onClick = KeyBinder_Bind_Edit;
			e.onClickEntity = kb;
			kb.userbindEditButton = e;
			kb.userbindEditDialog = main.userbindEditDialog;
			main.userbindEditDialog.keybindBox = kb;
		me.TD(me, 1, 1, e = makeNexuizButton(_("Clear"), '0 0 0'));
			e.onClick = KeyBinder_Bind_Clear;
			e.onClickEntity = kb;

	me.gotoRC(me, 0, 3.25); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Sensitivity:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0.05, 10, 0.05, "sensitivity"));
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Acceleration:")));
		me.TD(me, 1, 2, e = makeNexuizSlider(0, 0.1, 0.001, "m_accelerate"));
		e.loadCvars = accelerationLoadCvarsNexuizInputSettingsTab;
		e.saveCvars = accelerationSaveCvarsNexuizInputSettingsTab;
	me.TR(me);
		me.TDempty(me, 0.05);
		me.TD(me, 0.5, 3, e = makeNexuizTextLabel(0, _("* Keep this set to 0 until you know what this setting does")));
		e.colorL = SKINCOLOR_TEXT_WARNING;
		e.fontSize = e.fontSize * 0.6;
	if not(cvar("menu_mouse_absolute")) {
		me.TR(me);
			me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("UI mouse speed:")));
			gui_set_dependent(e, "menu_mouse_absolute", 0, 0);
			me.TD(me, 1, 2, e = makeNexuizSlider(0.2, 4.0, 0.1, "menu_mouse_speed"));
			gui_set_dependent(e, "menu_mouse_absolute", 0, 0);
	}
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(1.022, "m_pitch", _("Invert mouse")));
	me.TR(me);
		if(cvar_type("joy_enable") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "joy_enable", _("Use joystick input")));
		else if(cvar_type("joystick") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "joystick", _("Use joystick input")));
	me.TR(me);
		if(cvar_type("vid_dgamouse") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "vid_dgamouse", _("Turn off OS mouse acceleration")));
		else if(cvar_type("apple_mouse_noaccel") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "apple_mouse_noaccel", _("Turn off OS mouse acceleration")));
	if (cvar("vid_touchscreen")) {
		me.TR(me);
		if (cvar_type("vid_touchscreen_sensitivity") & CVAR_TYPEFLAG_ENGINE) {
			me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Touch aim sensitivity:")));
			gui_set_dependent(e, "vid_touchscreen", 1, 1);
			me.TD(me, 1, 2, e = makeNexuizSlider(0.05, 2, 0.05, "vid_touchscreen_sensitivity"));
			gui_set_dependent(e, "vid_touchscreen", 1, 1);
		}
		me.TR(me);
		if (cvar_type("vid_touchscreen_scale") & CVAR_TYPEFLAG_ENGINE) {
			me.TD(me, 1, 1.25, e = makeNexuizTextLabel(0, _("Touch controls scale:")));
			gui_set_dependent(e, "vid_touchscreen", 1, 1);
			me.TD(me, 1, 2, e = makeNexuizSlider(0.3, 1.3, 0.1, "vid_touchscreen_scale"));
			gui_set_dependent(e, "vid_touchscreen", 1, 1);
		}
		me.TR(me);
		if (cvar_type("vid_touchscreen_mirror") & CVAR_TYPEFLAG_ENGINE) {
			me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "vid_touchscreen_mirror", _("Mirror touch controls")));
			gui_set_dependent(e, "vid_touchscreen", 1, 1);
		}
	}
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "con_closeontoggleconsole", _("\"enter console\" also closes")));
}
#endif
