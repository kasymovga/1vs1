void(entity me) gui_rexuiz_dialog_hud_fill;

entity(void) gui_rexuiz_dialog_hud_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_hud_fill;
	me.title = _("HUD selection");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.6;
	me.rows = 10;
	me.columns = 4;
	me.name = "HudMenu";
	me.classname = "NexuizVcallDialog";
	return me;
}

entity gui_rexuiz_dialog_hud_skinlist;
entity gui_rexuiz_dialog_hud_list;

void(entity btn, entity me) gui_rexuiz_dialog_hud_apply {
	if (gui_rexuiz_dialog_hud_list.selectedItem >= 0)
		gui_rexuiz_dialog_hud_list.clickListBoxItem(gui_rexuiz_dialog_hud_list, gui_rexuiz_dialog_hud_list.selectedItem, '0 0 0', 1); //emulate double click

	if (gui_rexuiz_dialog_hud_skinlist.selectedItem >= 0)
		gui_rexuiz_dialog_hud_skinlist.clickListBoxItem(gui_rexuiz_dialog_hud_skinlist, gui_rexuiz_dialog_hud_skinlist.selectedItem, '0 0 0', 1); //emulate double click

	gui_hide();
	gui_hide();
	gui_hide();
}

void(entity me) gui_rexuiz_dialog_hud_rm_save {
	gui_rexuiz_textslider_save(me);
	float i = cvar("cl_rm_hud");
	if (i > 0)
		rm_skin_load(cvar_string("cl_rm_skin"));
	else if (i < 0)
		rm_skin_unload();
	else if (strstrofs(strcat(" ", dlc_list, " "), " rm_skins ", 0) >= 0) {
		rm_skin_load(cvar_string("cl_rm_skin"));
	}
}

void(entity me) gui_rexuiz_dialog_hud_fill {
	entity e;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Show radar:")));
		me.TD(me, 1, 1.5, e = gui_rexuiz_textslider_make("cl_teamradar"));
			e.addValue(e, _("Never"), "0");
			e.addValue(e, _("Teamplay"), "1");
			e.addValue(e, _("Always"), "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Use RM HUD:")));
		me.TD(me, 1, 1.5, e = gui_rexuiz_textslider_make("cl_rm_hud"));
			e.addValue(e, "Never", "-1");
			e.addValue(e, "When requested", "0");
			e.addValue(e, "Always", "1");
			e.configureNexuizTextSliderValues(e);
			e.saveCvars = gui_rexuiz_dialog_hud_rm_save;
	me.TR(me);
		me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, _("Available HUDs:")));
	me.TR(me);
		me.TD(me, 6, 2, e = gui_rexuiz_hudlist_make());
			gui_rexuiz_dialog_hud_list = e;
	me.gotoRC(me, 2, 3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 6, 2, e = gui_rexuiz_skinlist_make());
			gui_rexuiz_dialog_hud_skinlist = e;
	me.gotoRC(me, me.rows - 1, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2, e = gui_rexuiz_button_make(_("Apply"), '0 0 0'));
			e.onClick = gui_rexuiz_dialog_hud_apply;
		me.TD(me, 1, 2, e = gui_rexuiz_commandbutton_make(_("Cancel"), '0 0 0', "", 1));
}
