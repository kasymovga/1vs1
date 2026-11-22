entity spawnNexuizReportDialog() {
	entity me; me = spawnNexuizRootDialog();
	me.fill = fillNexuizReportDialog; // to be overridden by user to fill the dialog with controls
	me.title = _("Report a player");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.8;
	me.rows = 15;
	me.columns = 20;
	me.name = "ReportMenu";
	me.classname = "NexuizReportDialog";
	return me;
}
entity typeNexuizReportDialog;
entity playerNexuizReportDialog;
void(entity btn, entity me) reportNexuizReportDialog {
	float type = typeNexuizReportDialog.selectedItem;
	string type_s = report_reasons[type];
	if (type_s != "") {
		float player = playerNexuizReportDialog.selectedItem;
		localcmd("cmd report ", type_s, " ", ftos(player + 1), "\n");
		GUI_Hide();
		GUI_Hide();
	}
}
void(entity me) fillNexuizReportDialog {
	entity e;
	me.TR(me);
		me.TD(me, 1, 10, e = makeNexuizTextLabel(0, _("Naughty behaviour:")));
		me.TD(me, 1, 10, e = makeNexuizTextLabel(0, _("Player:")));
	me.TR(me);
		me.TD(me, 13, 10, e = makeNexuizReportTypeList());
		typeNexuizReportDialog = e;
						  me.TD(me, 13, 10, e = makeNexuizReportPlayerList());
		playerNexuizReportDialog = e;
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 10, e = makeNexuizButton(_("Report"), '0 0 0'));
				e.onClick = reportNexuizReportDialog;
				e.onClickEntity = me;
		me.TD(me, 1, 10, e = makeNexuizCommandButton(_("Cancel"), '0 0 0', "", 1));
}
