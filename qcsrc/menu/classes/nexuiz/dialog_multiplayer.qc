entity spawnNexuizMultiplayerDialog() {
	entity me; me = spawnNexuizDialog();
	me.fill = fillNexuizMultiplayerDialog;
	me.title = _("Multiplayer");
	me.color = SKINCOLOR_DIALOG_MULTIPLAYER;
	me.intendedWidth = 0.96;
	me.rows = 24;
	me.columns = 6;
	me.classname = "NexuizMultiplayerDialog";
	return me;
}
void fillNexuizMultiplayerDialog(entity me)
{
	entity mc, e;
	mc = makeNexuizTabController(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Servers"), makeNexuizServerListTab()));
				//setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Create"), makeNexuizServerCreateTab(FALSE)));
				//setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Demos"), makeNexuizDemoBrowserTab()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
