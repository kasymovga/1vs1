void(entity me) gui_rexuiz_dialog_recordlist_fill;

entity(void) gui_rexuiz_dialog_recordlist_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_recordlist_fill; // to be overridden by user to fill the dialog with controls
	me.title = _("Map records");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.6;
	me.rows = 20;
	me.columns = 20;
	me.name = "RecordList";
	me.classname = "NexuizRecordListDialog";
	return me;
}

void(entity btn, entity me) gui_rexuiz_dialog_recordlist_vote {
	if (me.selectedItem >= 0) {
		string s = recordlist_get(me.selectedItem);
		if (s == _("[Loading]..."))
			return;

		s = str_car(s);
		if (s == map_shortname)
			return;

		localcmd(strcat("cmd vote call gotomap ", s, ";"));
		GUI_Hide();
		GUI_Hide();
	}
}

void(entity me) gui_rexuiz_dialog_recordlist_fill {
	entity e, record_list;
	me.TR(me);
		me.TD(me, me.rows - 1, 20, record_list = makeNexuizRecordList());
		record_list.nexuizFont = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, 10, e = gui_rexuiz_button_make(_("Call a vote for this map"), '0 0 0'));
			e.onClick = gui_rexuiz_dialog_recordlist_vote;
			e.onClickEntity = record_list;
		record_list.onClickEntity = e;
		me.TD(me, 1, 10, e = gui_rexuiz_commandbutton_make(_("Close"), '0 0 0', "", 1));
}
