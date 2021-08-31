#ifdef INTERFACE
CLASS(NexuizWinnerDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizWinnerDialog, fill, void(entity))
	ATTRIB(NexuizWinnerDialog, title, string, _("Congratulations!"))
	ATTRIB(NexuizWinnerDialog, color, vector, SKINCOLOR_DIALOG_SINGLEPLAYER)
	ATTRIB(NexuizWinnerDialog, intendedWidth, float, 0.4)
	ATTRIB(NexuizWinnerDialog, rows, float, 12)
	ATTRIB(NexuizWinnerDialog, columns, float, 3)
ENDCLASS(NexuizWinnerDialog)
#endif

#ifdef IMPLEMENTATION

void closeWinnderDialog(entity me, entity button)
{
	Dialog_Close(me, button);
	menu_goto("credits");
}

void fillNexuizWinnerDialog(entity me)
{
	entity e;

	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, me.rows - 3, me.columns - 1, e = makeNexuizImage("/gfx/winner", -1));
	me.gotoRC(me, me.rows - 3, 0);
		me.TD(me, 1, me.columns, e = makeNexuizTextLabel(0, _("You have successfully completed the Single Player Campaign!")));
		e.align = 0.5;
		e.allowWrap = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
			e.onClick = closeWinnderDialog;
			e.onClickEntity = me;
}
#endif
