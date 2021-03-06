#ifdef INTERFACE
CLASS(NexuizMiscSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizMiscSettingsTab, fill, void(entity))
	ATTRIB(NexuizMiscSettingsTab, title, string, _("Misc"))
	ATTRIB(NexuizMiscSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizMiscSettingsTab, rows, float, 22)
	ATTRIB(NexuizMiscSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizMiscSettingsTab)
entity makeNexuizMiscSettingsTab();
#endif

#ifdef IMPLEMENTATION
void (entity btn, entity me) apply_misc_settings {
	float fs_rescan_needed = FALSE;
	if (cvar_string("menu_cl_simpleitems") != cvar_string("cl_simpleitems")) {
		registercvar("menu_cl_simpleitems", cvar_string("cl_simpleitems"), 0);
		cvar_set("menu_cl_simpleitems", cvar_string("cl_simpleitems"));
		fs_rescan_needed = TRUE;
	}
	if (cvar_string("menu_cl_oldnexmodel") != cvar_string("cl_oldnexmodel")) {
		registercvar("menu_cl_oldnexmodel", cvar_string("cl_oldnexmodel"), 0);
		cvar_set("menu_cl_oldnexmodel", cvar_string("cl_oldnexmodel"));
		fs_rescan_needed = TRUE;
	}
	if (cvar_string("menu_cl_brightskins") != cvar_string("cl_brightskins")) {
		registercvar("menu_cl_brightskins", cvar_string("cl_brightskins"), 0);
		cvar_set("menu_cl_brightskins", cvar_string("cl_brightskins"));
		fs_rescan_needed = TRUE;
	}
	if (fs_rescan_needed)
		localcmd("fs_rescan\n");

	SetSkin_Click(btn, me);
}

entity() makeNexuizMiscSettingsTab {
	registercvar("menu_cl_simpleitems", cvar_string("cl_simpleitems"), 0);
	cvar_set("menu_cl_simpleitems", cvar_string("cl_simpleitems"));
	registercvar("menu_cl_oldnexmodel", cvar_string("cl_oldnexmodel"), 0);
	cvar_set("menu_cl_oldnexmodel", cvar_string("cl_oldnexmodel"));
	registercvar("menu_cl_brightskins", cvar_string("cl_brightskins"), 0);
	cvar_set("menu_cl_brightskins", cvar_string("cl_brightskins"));
	entity me;
	me = spawnNexuizMiscSettingsTab();
	me.configureDialog(me);
	return me;
}

void(entity me) fillNexuizMiscSettingsTab {
	entity e;
	entity sk;
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Menu skins:")));
	me.TR(me);
		me.TD(me, me.rows - 2, 3, sk = makeNexuizSkinList());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Apply immediately"), '0 0 0'));
			e.onClick = apply_misc_settings;
			e.onClickEntity = sk;
	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "showtime", _("Show current time")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "showdate", _("Show current date")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "showfps", _("Show frames per second")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_showspeed", _("Speedometer")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = makeNexuizRadioButton(1, "cl_showspeed_unit", "0", _("qu/s (hidden)")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeNexuizRadioButton(1, "cl_showspeed_unit", "1", _("qu/s")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeNexuizRadioButton(1, "cl_showspeed_unit", "2", _("m/s")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = makeNexuizRadioButton(1, "cl_showspeed_unit", "3", _("km/h")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeNexuizRadioButton(1, "cl_showspeed_unit", "4", _("mph")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeNexuizRadioButton(1, "cl_showspeed_unit", "5", _("knots")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_showacceleration", _("Show accelerometer")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = makeNexuizTextLabel(0, _("Accelerometer scale:")));
			gui_set_dependent(e, "cl_showacceleration", 1, 1);
		me.TD(me, 1, 2.8/2, e = makeNexuizSlider(1, 10, 0.5, "cl_showacceleration_scale"));
			gui_set_dependent(e, "cl_showacceleration", 1, 1);
	me.TR(me);
		me.TD(me, 1, 2.8/2, e = makeNexuizTextLabel(0, _("Simple items:")));
		me.TD(me, 1, 2.8/2, e = makeNexuizTextSlider("cl_simpleitems"));
			e.addValue(e, _("None"), "0");
			e.addValue(e, _("Simple"), "1");
			e.addValue(e, _("Luma"), "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "cl_oldnexmodel", _("Old nex model")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "cl_brightskins", _("Bright player skins")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "integration_discord_enable", _("Discord status")));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeNexuizButton(_("Advanced settings..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
		me.TDempty(me, 0.5);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeNexuizButton(_("Language..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.languageDialog;
}
#endif
