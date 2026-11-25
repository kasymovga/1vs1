void(entity me) gui_rexuiz_dialog_quit_fill;

entity(void) gui_rexuiz_dialog_quit_spawn {
	entity me; me = gui_rexuiz_dialog_spawn();
	me.fill = gui_rexuiz_dialog_quit_fill;
	me.title = _("Quit");
	me.color = SKINCOLOR_DIALOG_QUIT;
	me.intendedWidth = 0.5;
	me.rows = 3;
	me.columns = 2;
	me.classname = "NexuizQuitDialog";
	return me;
}

void(entity me) gui_rexuiz_dialog_quit_fill {
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, gui_rexuiz_textlabel_make(0.5, _("Are you sure you want to quit?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_commandbutton_make(_("Yes"), '1 0 0', "quit", 0));
		me.TD(me, 1, 1, e = gui_rexuiz_button_make(_("No"), '0 1 0'));
			e.onClick = gui_dialog_button_close;
			e.onClickEntity = me;
}

