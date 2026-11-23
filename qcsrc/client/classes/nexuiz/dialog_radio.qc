entity spawnNexuizRadioDialog() {
	entity me; me = spawnNexuizRootDialog();
	me.fill = fillNexuizRadioDialog; // to be overridden by user to fill the dialog with controls
	me.title = _("Radio");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.3;
	me.rows = 4;
	me.columns = 2;
	me.name = "Radio";
	me.classname = "NexuizRadioDialog";
	return me;
}
void fillNexuizRadioDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_commandbutton_make(_("On"), '0 1 0', "cmd radiotoggle 1;", 0));
		me.TD(me, 1, 1, e = gui_rexuiz_commandbutton_make(_("Off"), '1 0 0', "cd reset;", 0));
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 2, 1.5, e = gui_rexuiz_checkbox_make(0, "_radio", _("Play next track")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Done"), '0 0 0', "", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
}
