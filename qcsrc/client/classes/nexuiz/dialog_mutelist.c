#ifdef INTERFACE
CLASS(NexuizMuteListDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizMuteListDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizMuteListDialog, title, string, _("Mute list"))
	ATTRIB(NexuizMuteListDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizMuteListDialog, intendedWidth, float, 0.8)
	ATTRIB(NexuizMuteListDialog, rows, float, 16)
	ATTRIB(NexuizMuteListDialog, columns, float, 10)
	ATTRIB(NexuizMuteListDialog, name, string, "MuteListMenu")
	ATTRIB(NexuizMuteListDialog, voteList, entity, NULL)
ENDCLASS(NexuizMuteListDialog)
#endif

#ifdef IMPLEMENTATION
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
		me.TD(me, 1, 5, e = makeNexuizButton(_("Mute"), '0 0 0'));
		e.onClick = muteMuteListDialog;
		e.onClickEntity = list;
		me.TD(me, 1, 5, e = makeNexuizButton(_("Unmute"), '0 0 0'));
		e.onClick = unmuteMuteListDialog;
		e.onClickEntity = list;

	me.TR(me);
		me.TD(me, 1, 10, e = makeNexuizCommandButton(_("Close"), '0 0 0', "", 1));
}
#endif
