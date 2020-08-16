#ifdef INTERFACE
CLASS(NexuizSettingsDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizSettingsDialog, fill, void(entity))
	ATTRIB(NexuizSettingsDialog, title, string, _("Settings"))
	ATTRIB(NexuizSettingsDialog, color, vector, SKINCOLOR_DIALOG_SETTINGS)
	ATTRIB(NexuizSettingsDialog, intendedWidth, float, 0.96)
	ATTRIB(NexuizSettingsDialog, rows, float, 19)
	ATTRIB(NexuizSettingsDialog, columns, float, 6)
ENDCLASS(NexuizSettingsDialog)
#endif

#ifdef IMPLEMENTATION
void fillNexuizSettingsDialog(entity me)
{
	entity mc;
	mc = makeNexuizTabController(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Input"),   makeNexuizInputSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Video"),   makeNexuizVideoSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Effects"), makeNexuizEffectsSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Audio"),   makeNexuizAudioSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Network"), makeNexuizNetworkSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Misc"),    makeNexuizMiscSettingsTab()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
#endif
