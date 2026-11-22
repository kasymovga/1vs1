entity spawnNexuizQuitDialog() {
	entity me; me = spawnNexuizDialog();
	me.fill = fillNexuizQuitDialog;
	me.title = _("Quit");
	me.color = SKINCOLOR_DIALOG_QUIT;
	me.intendedWidth = 0.5;
	me.rows = 3;
	me.columns = 2;
	me.classname = "NexuizQuitDialog";
	return me;
}
void fillNexuizQuitDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeNexuizTextLabel(0.5, _("Are you sure you want to quit?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCommandButton(_("Yes"), '1 0 0', "quit", 0));
		me.TD(me, 1, 1, e = makeNexuizButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
