void(entity me) gui_rexuiz_dialog_mutelist_fill;

entity(void) gui_rexuiz_dialog_mutelist_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_mutelist_fill;
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

void(entity btn, entity me) gui_rexuiz_dialog_mutelist_mute {
	mute_add(btn.onClickEntity.selectedItem + 1);
}
void(entity btn, entity me) gui_rexuiz_dialog_mutelist_unmute {
	mute_remove(btn.onClickEntity.selectedItem + 1);
}

void(entity me) gui_rexuiz_dialog_mutelist_fill {
	entity e, list;
	me.TR(me);
		me.TD(me, 14, 10, list = gui_rexuiz_mutelist_make());
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
			e.onClick = gui_rexuiz_dialog_mutelist_mute;
			e.onClickEntity = list;
		me.TD(me, 1, 5, e = gui_rexuiz_button_make(_("Unmute"), '0 0 0'));
			e.onClick = gui_rexuiz_dialog_mutelist_unmute;
			e.onClickEntity = list;
	me.TR(me);
		me.TD(me, 1, 10, e = gui_rexuiz_commandbutton_make(_("Close"), '0 0 0', "", 1));
}
