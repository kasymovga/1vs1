#ifdef INTERFACE
CLASS(NexuizReportDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizReportDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizReportDialog, title, string, "Report a player")
	ATTRIB(NexuizReportDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizReportDialog, intendedWidth, float, 0.8)
	ATTRIB(NexuizReportDialog, rows, float, 15)
	ATTRIB(NexuizReportDialog, columns, float, 20)
	ATTRIB(NexuizReportDialog, name, string, "ReportMenu")
ENDCLASS(NexuizReportDialog)
#endif

#ifdef IMPLEMENTATION
entity typeNexuizReportDialog;
entity playerNexuizReportDialog;

void(entity btn, entity me) reportNexuizReportDialog {
	float type = typeNexuizReportDialog.selectedItem;
	string type_s;
	switch (type) {
	case 1:
		type_s = "sabotage";
		break;
	case 2:
		type_s = "flood";
		break;
	default:
		type_s = "cheat";
		break;
	}
	float player = playerNexuizReportDialog.selectedItem;
    localcmd("cmd report ", type_s, " ", ftos(player + 1), "\n");
	GUI_Hide();
	GUI_Hide();
}

void(entity me) fillNexuizReportDialog {
	entity e;
	me.TR(me);
		me.TD(me, 1, 10, e = makeNexuizTextLabel(0, "Naughty behaviour:"));
		me.TD(me, 1, 10, e = makeNexuizTextLabel(0, "Player:"));
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
		me.TD(me, 1, 10, e = makeNexuizButton("Report", '0 0 0'));
			e.onClick = reportNexuizReportDialog;
			e.onClickEntity = me;
		me.TD(me, 1, 10, e = makeNexuizCommandButton("Cancel", '0 0 0', "", 1));
}
#endif

