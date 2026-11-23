void(entity me) gui_rexuiz_dialog_vcall_fill;

entity(void) gui_rexuiz_dialog_vcall_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_vcall_fill;
	me.title = _("Call a vote");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.8;
	me.rows = 16;
	me.columns = 20;
	me.name = "VcallMenu";
	me.voteList = NULL;
	me.classname = "NexuizVcallDialog";
	return me;
}

void(entity btn, entity me) gui_rexuiz_dialog_vcall_do {
	localcmd("cmd vote call ", cvar_string("_menu_vote_string"), "\n");
	btn.onClickEntity.close(btn.onClickEntity);
}

void(entity me) gui_rexuiz_dialog_vcall_fill {
	entity e, vlist;
	me.TR(me);
		me.TD(me, 1, 10, e = gui_rexuiz_textlabel_make(0, _("Available votes:")));
		me.TD(me, 1, 10, e = gui_rexuiz_textlabel_make(0, _("Possible arguments:")));
	me.TR(me);
		me.TD(me, 13, 10, vlist = makeNexuizVoteList());
		me.TD(me, 13, 10, vlist.voteArgsList = makeNexuizVoteArgsList());
		vlist.voteArgsList.nexuizFont = 1;
		vlist.voteArgsList.voteList = vlist;
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
			me.TD(me, 1, 20, e = gui_rexuiz_inputbox_make(1, "_menu_vote_string"));
			//e.saveImmediately = 1;
			vlist.textBox = e;
			vlist.voteArgsList.textBox = e;
		me.TR(me);
			me.TD(me, 1, 10, e = gui_rexuiz_button_make(_("Call the vote"), '0 0 0'));
				e.onClick = gui_rexuiz_dialog_vcall_do;
				e.onClickEntity = me;
			me.TD(me, 1, 10, e = gui_rexuiz_commandbutton_make(_("Cancel"), '0 0 0', "", 1));
		me.voteList = vlist;
}
