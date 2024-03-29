#ifdef INTERFACE
CLASS(NexuizMultiplayerDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizMultiplayerDialog, fill, void(entity))
	ATTRIB(NexuizMultiplayerDialog, title, string, _("Multiplayer"))
	ATTRIB(NexuizMultiplayerDialog, color, vector, SKINCOLOR_DIALOG_MULTIPLAYER)
	ATTRIB(NexuizMultiplayerDialog, intendedWidth, float, 0.96)
	ATTRIB(NexuizMultiplayerDialog, rows, float, 24)
	ATTRIB(NexuizMultiplayerDialog, columns, float, 6)
ENDCLASS(NexuizMultiplayerDialog)
#endif

#ifdef IMPLEMENTATION
void fillNexuizMultiplayerDialog(entity me)
{
	entity mc, e;
	mc = makeNexuizTabController(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Servers"),  makeNexuizServerListTab()));
			//setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Create"),  makeNexuizServerCreateTab(FALSE)));
			//setDependentStringNotEqual(e, "_cl_name", "Player");
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Demos"),   makeNexuizDemoBrowserTab()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
#endif
