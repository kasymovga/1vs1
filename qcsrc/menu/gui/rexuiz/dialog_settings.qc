entity spawnNexuizSettingsDialog() {
	entity me; me = gui_rexuiz_dialog_spawn();
	me.fill = fillNexuizSettingsDialog;
	me.title = _("Settings");
	me.color = SKINCOLOR_DIALOG_SETTINGS;
	me.intendedWidth = 0.96;
	me.rows = 24;
	me.columns = 7;
	me.classname = "NexuizSettingsDialog";
	return me;
}
void fillNexuizSettingsDialog(entity me)
{
	entity e;
	entity mc;
	mc = gui_rexuiz_tabcontroller_make(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Game"), makeNexuizPlayerSettingsTab()));
				if(cvar_string("_cl_name") == "Player")
				e.onClick(e, e.onClickEntity); // lol animation
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Input"), makeNexuizInputSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Video"), makeNexuizVideoSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Audio"), makeNexuizAudioSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Network"), makeNexuizNetworkSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Interface"), makeNexuizInterfaceSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Advanced"), makeNexuizAdvancedSettingsTab()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
