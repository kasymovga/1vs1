#ifdef INTERFACE
CLASS(NexuizRMSettingsDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizRMSettingsDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizRMSettingsDialog, title, string, "RM Settings")
	ATTRIB(NexuizRMSettingsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizRMSettingsDialog, intendedWidth, float, 0.5)
	ATTRIB(NexuizRMSettingsDialog, rows, float, 15)
	ATTRIB(NexuizRMSettingsDialog, columns, float, 5.5)
	ATTRIB(NexuizRMSettingsDialog, name, string, "RMSettings")
ENDCLASS(NexuizRMSettingsDialog)
#endif

#ifdef IMPLEMENTATION
void fillNexuizRMSettingsDialog(entity me) {
	entity e;
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_nobigtext", _("No big text")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_hidebigcomments", _("Hide big commentaries")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_showrankings", _("Show top players in the HUD")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_crosshealth", _("Crosshair health color")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, _("Crosshair ring size:")));
		me.TD(me, 1, 3, e = makeNexuizSlider(0, 10, 0.05, "rm_hud_crosshair_ring_size"));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, _("Crosshair ring opacity:")));
		me.TD(me, 1, 3, e = makeNexuizSlider(0, 1, 0.05, "rm_hud_crosshair_ring_alpha"));
	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, _("Crosshair ring opacity:")));
		me.TD(me, 1, 3, e = makeNexuizSlider(0, 1, 0.05, "rm_hud_crosshair_ring_alpha"));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(1, "rm_notimer", _("\"time\" column in scoreboard")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_visualscore", _("Scoring notifications in the HUD")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_shownadgetregen", _("Show Nadget regeneration in seconds")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_hud_healthcolor", _("Health-colored HUD")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_showspec", _("Show spectators")));
	me.TR(me);
		me.TD(me, 1, 5, e = makeNexuizCheckBox(0, "rm_anonspec", _("Spectate anonymously")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, makeNexuizCommandButton("Apply immediately", '0 0 0', ";sendcvar rm_showspec;sendcvar rm_anonspec\n", COMMANDBUTTON_CLOSE));
}
#endif
