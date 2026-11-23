void(entity me) gui_rexuiz_dialog_hint_fill;

entity(void) gui_rexuiz_dialog_hint_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_hint_fill;
	me.configureDialog = configureDialogNexuizHintDialog;
	me.title = "Hint";
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.75;
	me.rows = 6;
	me.columns = 4;
	me.name = "Hint";
	me.classname = "NexuizHintDialog";
	return me;
}
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

void(entity me) gui_rexuiz_dialog_hint_fill {
	entity e;
	me.TR(me);
		me.TDempty(me, 0.125);
		me.TD(me, 3, 3.75, e = gui_rexuiz_textlabel_make(0, hint));
		e.allowWrap = 1;
	hint_text_label = e;
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.125);
		me.TD(me, 1, 3.75, e = gui_rexuiz_checkbox_make(0, "cl_hints_skip", _("Skip start hints")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.5, e = gui_rexuiz_button_make(_("<< Previous"), '0 0 0'));
		e.onClick = prevNexuizHintDialog;
		me.TD(me, 1, 1.5, e = gui_rexuiz_button_make(_("Next >>"), '0 0 0'));
		e.onClick = nextNexuizHintDialog;
		me.TD(me, 1, 1, e = gui_rexuiz_button_make(_("Close"), '0 0 0'));
		e.onClick = closeNexuizHintDialog;
}

