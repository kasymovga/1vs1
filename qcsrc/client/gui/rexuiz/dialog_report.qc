void(entity me) gui_rexuiz_dialog_report_fill;

entity(void) gui_rexuiz_dialog_report_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_report_fill;
	me.title = _("Report a player");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.8;
	me.rows = 15;
	me.columns = 20;
	me.name = "ReportMenu";
	me.classname = "NexuizReportDialog";
	return me;
}

entity gui_rexuiz_dialog_report_typelist;
entity gui_rexuiz_dialog_report_playerlist;

void(entity btn, entity me) gui_rexuiz_dialog_report_send {
	float type = gui_rexuiz_dialog_report_typelist.selectedItem;
	string type_s = report_reasons[type];
	if (type_s != "") {
		float player = gui_rexuiz_dialog_report_playerlist.selectedItem;
		localcmd("cmd report ", type_s, " ", ftos(player + 1), "\n");
		gui_hide();
		gui_hide();
	}
}

void(entity me) gui_rexuiz_dialog_report_fill {
	entity e;
	me.TR(me);
		me.TD(me, 1, 10, e = gui_rexuiz_textlabel_make(0, _("Naughty behaviour:")));
		me.TD(me, 1, 10, e = gui_rexuiz_textlabel_make(0, _("Player:")));
	me.TR(me);
		me.TD(me, 13, 10, e = gui_rexuiz_reporttypelist_make());
			gui_rexuiz_dialog_report_typelist = e;
		me.TD(me, 13, 10, e = gui_rexuiz_reportplayerlist_make());
			gui_rexuiz_dialog_report_playerlist = e;
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
		me.TD(me, 1, 10, e = gui_rexuiz_button_make(_("Report"), '0 0 0'));
			e.onClick = gui_rexuiz_dialog_report_send;
			e.onClickEntity = me;
		me.TD(me, 1, 10, e = gui_rexuiz_commandbutton_make(_("Cancel"), '0 0 0', "", 1));
}
