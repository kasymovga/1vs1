entity spawnNexuizVcallDialog() {
	entity me; me = spawnNexuizRootDialog();
	me.fill = fillNexuizVcallDialog; // to be overridden by user to fill the dialog with controls
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
void VoteCall_f(entity btn, entity me)
{
				localcmd("cmd vote call ", cvar_string("_menu_vote_string"), "\n");
				btn.onClickEntity.close(btn.onClickEntity);
}
void fillNexuizVcallDialog(entity me)
{
	entity e, vlist;
	me.TR(me);
		me.TD(me, 1, 10, e = makeNexuizTextLabel(0, _("Available votes:")));
		me.TD(me, 1, 10, e = makeNexuizTextLabel(0, _("Possible arguments:")));
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
				me.TR(me); // ???
						  me.TD(me, 1, 20, e = makeNexuizInputBox(1, "_menu_vote_string"));
						  //e.saveImmediately = 1;
						  vlist.textBox = e;
						  vlist.voteArgsList.textBox = e;
				me.TR(me);
						  me.TD(me, 1, 10, e = makeNexuizButton(_("Call the vote"), '0 0 0'));
						      e.onClick = VoteCall_f;
						      e.onClickEntity = me;
						  me.TD(me, 1, 10, e = makeNexuizCommandButton(_("Cancel"), '0 0 0', "", 1));
				me.voteList = vlist;
}
