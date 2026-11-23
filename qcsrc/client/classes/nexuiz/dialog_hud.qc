entity spawnNexuizHudDialog() {
	entity me; me = spawnNexuizRootDialog();
	me.fill = fillNexuizHudDialog; // to be overridden by user to fill the dialog with controls
	me.title = _("HUD selection");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.6;
	me.rows = 10;
	me.columns = 4;
	me.name = "HudMenu";
	me.classname = "NexuizVcallDialog";
	return me;
}
entity skinListNexuizHudDialog;
entity hudListNexuizHudDialog;
void(entity btn, entity me) applyNexuizHudDialog {
	if (hudListNexuizHudDialog.selectedItem >= 0)
		hudListNexuizHudDialog.clickListBoxItem(hudListNexuizHudDialog, hudListNexuizHudDialog.selectedItem, '0 0 0', 1); //emulate double click
	if (skinListNexuizHudDialog.selectedItem >= 0)
		skinListNexuizHudDialog.clickListBoxItem(skinListNexuizHudDialog, skinListNexuizHudDialog.selectedItem, '0 0 0', 1); //emulate double click
	GUI_Hide();
	GUI_Hide();
	GUI_Hide();
}
void(entity me) saveCvarsUseRMHUDNexuizHudDialog {
	saveCvarsNexuizTextSlider(me);
	float i = cvar("cl_rm_hud");
	if (i > 0)
		rm_skin_load(cvar_string("cl_rm_skin"));
	else if (i < 0)
		rm_skin_unload();
	else if (strstrofs(strcat(" ", dlc_list, " "), " rm_skins ", 0) >= 0) {
		rm_skin_load(cvar_string("cl_rm_skin"));
	}
}
void(entity me) fillNexuizHudDialog {
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
				e.saveCvars = saveCvarsUseRMHUDNexuizHudDialog;
	me.TR(me);
		me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, _("Available HUDs:")));
	me.TR(me);
		me.TD(me, 6, 2, e = makeNexuizHudList());
		hudListNexuizHudDialog = e;
	me.gotoRC(me, 2, 3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 6, 2, e = makeNexuizSkinList());
		skinListNexuizHudDialog = e;
	me.gotoRC(me, me.rows - 1, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2, e = gui_rexuiz_button_make(_("Apply"), '0 0 0'));
				e.onClick = applyNexuizHudDialog;
		me.TD(me, 1, 2, e = gui_rexuiz_commandbutton_make(_("Cancel"), '0 0 0', "", 1));
}
