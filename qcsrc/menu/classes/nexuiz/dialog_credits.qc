entity spawnNexuizCreditsDialog() {
	entity me; me = spawnNexuizDialog();
	me.fill = fillNexuizCreditsDialog;
	me.focusEnter = focusEnterNexuizCreditsDialog;
	me.title = _("Credits");
	me.name = "credits";
	me.color = SKINCOLOR_DIALOG_CREDITS;
	me.intendedWidth = SKINWIDTH_CREDITS;
	me.rows = SKINROWS_CREDITS;
	me.columns = 2;
	me.creditsList = NULL;
	me.classname = "NexuizCreditsDialog";
	return me;
}
void fillNexuizCreditsDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, me.creditsList = makeNexuizCreditsList());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
				e.onClick = Dialog_Close;
				e.onClickEntity = me;
}
void focusEnterNexuizCreditsDialog(entity me)
{
	me.creditsList.scrolling = time + 1;
}
