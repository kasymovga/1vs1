#ifdef INTERFACE
CLASS(NexuizRadioDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizRadioDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizRadioDialog, title, string, "Radio")
	ATTRIB(NexuizRadioDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizRadioDialog, intendedWidth, float, 0.3)
	ATTRIB(NexuizRadioDialog, rows, float, 4)
	ATTRIB(NexuizRadioDialog, columns, float, 2)
	ATTRIB(NexuizRadioDialog, name, string, "Radio")
ENDCLASS(NexuizRadioDialog)
#endif

#ifdef IMPLEMENTATION

void fillNexuizRadioDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCommandButton("On", '0 1 0', "cmd radiotoggle 1;", 0));
		me.TD(me, 1, 1, e = makeNexuizCommandButton("Off", '1 0 0', "cd reset;", 0));
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 2, 1.5, e = makeNexuizCheckBox(0, "_radio", "Play next track"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Done", '0 0 0', "", COMMANDBUTTON_CLOSE));
}
#endif
