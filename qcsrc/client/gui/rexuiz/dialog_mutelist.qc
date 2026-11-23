entity spawnNexuizMuteListDialog() {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = fillNexuizMuteListDialog; // to be overridden by user to fill the dialog with controls
	me.title = _("Mute list");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.8;
	me.rows = 16;
	me.columns = 10;
	me.name = "MuteListMenu";
	me.voteList = NULL;
	me.classname = "NexuizMuteListDialog";
	return me;
}
void muteMuteListDialog(entity btn, entity me) {
	mute_add(btn.onClickEntity.selectedItem + 1);
}
void unmuteMuteListDialog(entity btn, entity me) {
	mute_remove(btn.onClickEntity.selectedItem + 1);
}
void fillNexuizMuteListDialog(entity me) {
	entity e, list;
	me.TR(me);
		me.TD(me, 14, 10, list = makeNexuizMuteList());
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
	me.TR(me); // ???
	me.TR(me);
		me.TD(me, 1, 5, e = gui_rexuiz_button_make(_("Mute"), '0 0 0'));
		e.onClick = muteMuteListDialog;
		e.onClickEntity = list;
		me.TD(me, 1, 5, e = gui_rexuiz_button_make(_("Unmute"), '0 0 0'));
		e.onClick = unmuteMuteListDialog;
		e.onClickEntity = list;
	me.TR(me);
		me.TD(me, 1, 10, e = gui_rexuiz_commandbutton_make(_("Close"), '0 0 0', "", 1));
}
