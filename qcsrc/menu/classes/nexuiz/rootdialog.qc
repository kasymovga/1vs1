entity spawnNexuizRootDialog() {
	entity me; me = gui_rexuiz_dialog_spawn();
	// still to be customized by user
	/*
	ATTRIB(NexuizDialog, closable, float, 1)
	ATTRIB(NexuizDialog, title, string, "Form1") // ;)
	ATTRIB(NexuizDialog, color, vector, '1 0.5 1')
	ATTRIB(NexuizDialog, intendedWidth, float, 0)
	ATTRIB(NexuizDialog, rows, float, 3)
	ATTRIB(NexuizDialog, columns, float, 2)
	*/
	me.close = closeNexuizRootDialog;
	me.classname = "NexuizRootDialog";
	return me;
}
void(entity me) closeNexuizRootDialog {
	menu_goto(NULL);
}
