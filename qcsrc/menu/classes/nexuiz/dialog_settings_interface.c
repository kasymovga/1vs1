#ifdef INTERFACE
CLASS(NexuizInterfaceSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizInterfaceSettingsTab, fill, void(entity))
	ATTRIB(NexuizInterfaceSettingsTab, title, string, _("Interface"))
	ATTRIB(NexuizInterfaceSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizInterfaceSettingsTab, rows, float, 22)
	ATTRIB(NexuizInterfaceSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizInterfaceSettingsTab)
entity makeNexuizInterfaceSettingsTab();
#endif

#ifdef IMPLEMENTATION
void (entity btn, entity me) applyNexuizInterfaceSettingsTab {
	SetSkin_Click(btn, me);
	if (cvar("cl_font_iceland") && !dlc_ready("font-iceland")) {
		localcmd(";fs_rescan\n");
	} else if (!cvar("cl_font_iceland") && dlc_ready("font-iceland")) {
		localcmd(";fs_rescan\n");
	}
}

entity() makeNexuizInterfaceSettingsTab {
	entity me;
	me = spawnNexuizInterfaceSettingsTab();
	me.configureDialog(me);
	return me;
}

void(entity me) fillNexuizInterfaceSettingsTab {
	entity e;
	entity sk;
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Menu skins:")));
	me.TR(me);
		me.TD(me, me.rows - 2, 3, sk = makeNexuizSkinList());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Apply immediately"), '0 0 0'));
			e.onClick = applyNexuizInterfaceSettingsTab;
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
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "cl_font_iceland", _("Use \"Iceland\" font for big messages")));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeNexuizButton(_("Language..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.languageDialog;
}
#endif
