entity spawnNexuizRecordListDialog() {
	entity me; me = spawnNexuizRootDialog();
	me.fill = fillNexuizRecordListDialog; // to be overridden by user to fill the dialog with controls
	me.title = _("Map records");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.6;
	me.rows = 20;
	me.columns = 20;
	me.name = "RecordList";
	me.classname = "NexuizRecordListDialog";
	return me;
}
void gotomapNexuizRecordListDialog(entity btn, entity me) {
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
void fillNexuizRecordListDialog(entity me) {
	entity e, record_list;
	me.TR(me);
		me.TD(me, me.rows - 1, 20, record_list = makeNexuizRecordList());
		record_list.nexuizFont = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, 10, e = makeNexuizButton(_("Call a vote for this map"), '0 0 0'));
				e.onClick = gotomapNexuizRecordListDialog;
				e.onClickEntity = record_list;
		record_list.onClickEntity = e;
		me.TD(me, 1, 10, e = makeNexuizCommandButton(_("Close"), '0 0 0', "", 1));
}
