#ifdef INTERFACE
CLASS(NexuizHintDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizHintDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizHintDialog, configureDialog, void(entity))
	ATTRIB(NexuizHintDialog, title, string, "Hint")
	ATTRIB(NexuizHintDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizHintDialog, intendedWidth, float, 0.75)
	ATTRIB(NexuizHintDialog, rows, float, 6)
	ATTRIB(NexuizHintDialog, columns, float, 4)
	ATTRIB(NexuizHintDialog, name, string, "Hint")
ENDCLASS(NexuizHintDialog)
#endif

#ifdef IMPLEMENTATION
void(entity me) configureDialogNexuizHintDialog {
	configureDialogNexuizDialog(me); //Parent method
}

void(entity ignore, entity ignore2) nextNexuizHintDialog {
	localcmd(hint_cmd_next);
}

void(entity ignore, entity ignore2) prevNexuizHintDialog {
	localcmd(hint_cmd_prev);
}

void(entity ignore, entity ignore2) closeNexuizHintDialog {
	GUI_Hide();
}

void fillNexuizHintDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TDempty(me, 0.125);
		me.TD(me, 3, 3.75, e = makeNexuizTextLabel(0, hint));
		e.allowWrap = 1;
	hint_text_label = e;
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.125);
		me.TD(me, 1, 3.75, e = makeNexuizCheckBox(0, "cl_hints_skip", _("Skip start hints")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeNexuizButton(_("<< Previous"), '0 0 0'));
		e.onClick = prevNexuizHintDialog;
		me.TD(me, 1, 1.5, e = makeNexuizButton(_("Next >>"), '0 0 0'));
		e.onClick = nextNexuizHintDialog;
		me.TD(me, 1, 1, e = makeNexuizButton(_("Close"), '0 0 0'));
		e.onClick = closeNexuizHintDialog;
}
#endif
