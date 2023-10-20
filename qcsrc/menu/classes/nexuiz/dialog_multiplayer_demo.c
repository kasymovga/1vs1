#ifdef INTERFACE
CLASS(NexuizDemoBrowserTab) EXTENDS(NexuizTab)
	METHOD(NexuizDemoBrowserTab, fill, void(entity))
	ATTRIB(NexuizDemoBrowserTab, title, string, _("Demo"))
	ATTRIB(NexuizDemoBrowserTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizDemoBrowserTab, rows, float, 22)
	ATTRIB(NexuizDemoBrowserTab, columns, float, 6.5)
	ATTRIB(NexuizDemoBrowserTab, name, string, "DemoBrowser")
ENDCLASS(NexuizDemoBrowserTab)
entity makeNexuizDemoBrowserTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizDemoBrowserTab()
{
	entity me;
	me = spawnNexuizDemoBrowserTab();
	me.configureDialog(me);
	return me;
}
void fillNexuizDemoBrowserTab(entity me)
{
	entity e;
	entity btn;
	entity dlist;

	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCheckBox(0, "cl_autodemo", _("Record demos while playing")));
	me.TR(me);
	dlist = makeNexuizDemoList();
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeNexuizTextLabel(0, _("Filter:")));
		me.TD(me, 1, 0.5, btn = makeNexuizButton(_("Clear"), '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
		me.TD(me, 1, me.columns - 1, e = makeNexuizInputBox(0, NULL));
			e.onChange = DemoList_Filter_Change;
			e.onChangeEntity = dlist;
			btn.onClickEntity = e;
			dlist.controlledTextbox = e;
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, dlist);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns / 2, e = makeNexuizButton(_("Timedemo"), '0 0 0'));
			e.onClick = TimeDemo_Click;
			e.onClickEntity = dlist;
		me.TD(me, 1, me.columns / 2, e = makeNexuizButton(_("Play"), '0 0 0'));
			e.onClick = StartDemo_Click;
			e.onClickEntity = dlist;
}
#endif
