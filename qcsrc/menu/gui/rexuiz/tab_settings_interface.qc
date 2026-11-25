void(entity me) gui_rexuiz_tab_settings_interface_fill;

entity(void) gui_rexuiz_tab_settings_interface_spawn {
	entity me; me = gui_rexuiz_tab_spawn();
	me.fill = gui_rexuiz_tab_settings_interface_fill;
	me.title = _("Interface");
	me.intendedWidth = 0.9;
	me.rows = 22;
	me.columns = 6.5;
	me.classname = "NexuizInterfaceSettingsTab";
	return me;
}

void (entity btn, entity me) gui_rexuiz_tab_settings_interface_apply {
	me.setSkin(me);
	if (cvar("cl_font_iceland") && !dlc_ready("font-iceland")) {
		localcmd(";fs_rescan;saveconfig\n");
	} else if (!cvar("cl_font_iceland") && dlc_ready("font-iceland")) {
		localcmd(";fs_rescan;saveconfig\n");
	}
	if (cvar("cl_showpressedkeys_old") && !dlc_ready("n25keys")) {
		localcmd(";fs_rescan;saveconfig\n");
	} else if (!cvar("cl_showpressedkeys_old") && dlc_ready("n25keys")) {
		localcmd(";fs_rescan;saveconfig\n");
	}
}

entity(void) gui_rexuiz_tab_settings_interface_make {
	entity me = gui_rexuiz_tab_settings_interface_spawn();
	me.configureDialog(me);
	return me;
}

void(entity me) gui_rexuiz_tab_settings_interface_fill {
	entity e;
	entity sk;
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_textlabel_make(0, _("Menu skins:")));
	me.TR(me);
		me.TD(me, me.rows - 2, 3, sk = gui_rexuiz_skinlist_make());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Apply immediately"), '0 0 0'));
			e.onClick = gui_rexuiz_tab_settings_interface_apply;
			e.onClickEntity = sk;
	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "showtime", _("Show current time")));
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "showdate", _("Show current date")));
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "showfps", _("Show frames per second")));
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "cl_showspeed", _("Speedometer")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = gui_rexuiz_radiobutton_make(1, "cl_showspeed_unit", "0", _("qu/s (hidden)")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = gui_rexuiz_radiobutton_make(1, "cl_showspeed_unit", "1", _("qu/s")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = gui_rexuiz_radiobutton_make(1, "cl_showspeed_unit", "2", _("m/s")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = gui_rexuiz_radiobutton_make(1, "cl_showspeed_unit", "3", _("km/h")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = gui_rexuiz_radiobutton_make(1, "cl_showspeed_unit", "4", _("mph")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = gui_rexuiz_radiobutton_make(1, "cl_showspeed_unit", "5", _("knots")));
			gui_set_dependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "cl_showacceleration", _("Show accelerometer")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = gui_rexuiz_textlabel_make(0, _("Accelerometer scale:")));
			gui_set_dependent(e, "cl_showacceleration", 1, 1);
		me.TD(me, 1, 2.8/2, e = gui_rexuiz_slider_make(1, 10, 0.5, "cl_showacceleration_scale"));
			gui_set_dependent(e, "cl_showacceleration", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "cl_font_iceland", _("Use \"Iceland\" font for big messages")));
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_textlabel_make(0, _("Show binds:")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1.05, e = gui_rexuiz_radiobutton_make(1, "sbar_showbinds", "0", _("Actions")));
		me.TD(me, 1, 1.05, e = gui_rexuiz_radiobutton_make(1, "sbar_showbinds", "1", _("Bound keys")));
		me.TD(me, 1, 1.05, e = gui_rexuiz_radiobutton_make(1, "sbar_showbinds", "2", _("Both")));
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_textlabel_make(0, _("Show pressed keys:")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1.05, e = gui_rexuiz_radiobutton_make(2, "cl_showpressedkeys", "0", _("Never")));
		me.TD(me, 1, 1.05, e = gui_rexuiz_radiobutton_make(2, "cl_showpressedkeys", "1", _("In spectating")));
		me.TD(me, 1, 1.05, e = gui_rexuiz_radiobutton_make(2, "cl_showpressedkeys", "2", _("Always")));
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_checkbox_make(0, "cl_showpressedkeys_old", _("Use old key indicator")));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = gui_rexuiz_button_make(_("Language..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.languageDialog;
}
