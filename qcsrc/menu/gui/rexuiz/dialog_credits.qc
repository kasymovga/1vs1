entity spawnNexuizCreditsDialog() {
	entity me; me = gui_rexuiz_dialog_spawn();
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
		me.TD(me, me.rows - 1, me.columns, me.creditsList = gui_rexuiz_credits_make());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("OK"), '0 0 0'));
			e.onClick = gui_dialog_close;
			e.onClickEntity = me;
}
void focusEnterNexuizCreditsDialog(entity me)
{
	me.creditsList.scrolling = time + 1;
}
