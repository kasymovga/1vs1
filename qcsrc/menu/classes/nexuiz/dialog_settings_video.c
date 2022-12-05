#ifdef INTERFACE
CLASS(NexuizVideoSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizVideoSettingsTab, fill, void(entity))
	ATTRIB(NexuizVideoSettingsTab, title, string, _("Video"))
	ATTRIB(NexuizVideoSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizVideoSettingsTab, rows, float, 22)
	ATTRIB(NexuizVideoSettingsTab, columns, float, 6.5)
ENDCLASS(NexuizVideoSettingsTab)
entity makeNexuizVideoSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizVideoSettingsTab()
{
	entity me;
	me = spawnNexuizVideoSettingsTab();
	me.configureDialog(me);
	return me;
}
void fillNexuizVideoSettingsTab(entity me)
{
	entity e;
	entity mc;
	float n;
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, _("Quality preset:")));
		n = 5;
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Low"), '0 0 0', "exec effects-low.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Medium"), '0 0 0', "exec effects-med.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Normal"), '0 0 0', "exec effects-normal.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("High"), '0 0 0', "exec effects-high.cfg", 0));
		me.TD(me, 1, 5.3 / n, e = makeNexuizCommandButton(_("Ultra"), '0 0 0', "exec effects-ultra.cfg", 0));
	me.TR(me);
		mc = makeNexuizTabController(me.rows - 2);
		me.TD(me, 1, 3.25, e = mc.makeTabButton(mc, _("Basic"),  makeNexuizVideoSettingsBasicTab()));
		me.TD(me, 1, 3.25, mc.makeTabButton(mc, _("Advanced"),   makeNexuizVideoSettingsAdvancedTab()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 3, me.columns, mc);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeNexuizCommandButton(_("Apply immediately"), '0 0 0', "vid_restart; menu_cmd ui_con_width_height_set", COMMANDBUTTON_APPLY));
}
#endif
