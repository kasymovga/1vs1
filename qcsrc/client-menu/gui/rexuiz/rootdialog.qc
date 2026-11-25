void(entity me) gui_rexuiz_rootdialog_close;

entity(void) gui_rexuiz_rootdialog_spawn {
	entity me; me = gui_rexuiz_dialog_spawn();
	me.close = gui_rexuiz_rootdialog_close;
	me.classname = "NexuizRootDialog";
	return me;
}

void(entity me) gui_rexuiz_rootdialog_close {
#ifdef CSQC
	gui_hide();
#endif
#ifdef MENUQC
	menu_goto(NULL);
#endif
}
