#ifdef INTERFACE
CLASS(NexuizRecordListDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizRecordListDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizRecordListDialog, title, string, "Map records")
	ATTRIB(NexuizRecordListDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizRecordListDialog, intendedWidth, float, 0.6)
	ATTRIB(NexuizRecordListDialog, rows, float, 20)
	ATTRIB(NexuizRecordListDialog, columns, float, 20)
	ATTRIB(NexuizRecordListDialog, name, string, "RecordList")
ENDCLASS(NexuizRecordListDialog)
#endif

#ifdef IMPLEMENTATION
void gotomapNexuizRecordListDialog(entity btn, entity me) {
	if (me.selectedItem >= 0) {
		string s = recordlist_get(me.selectedItem);
		if (s == "[Loading]...")
			return;

		s = str_car(s);
		if (s == map_shortname)
			return;

		localcmd("cmd vote call gotomap " + s + ";");
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
		me.TD(me, 1, 10, e = makeNexuizButton("Call a vote for this map", '0 0 0'));
			e.onClick = gotomapNexuizRecordListDialog;
			e.onClickEntity = record_list;

		record_list.onClickEntity = e;
		me.TD(me, 1, 10, e = makeNexuizCommandButton("Close", '0 0 0', "", 1));
}
#endif
