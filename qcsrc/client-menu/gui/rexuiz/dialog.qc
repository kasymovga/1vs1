entity(void) gui_rexuiz_dialog_spawn {
	entity me; me = gui_dialog_spawn();
	// still to be customized by user
	/*
	ATTRIB(NexuizDialog, closable, float, 1)
	ATTRIB(NexuizDialog, title, string, "Form1") // ;)
	ATTRIB(NexuizDialog, color, vector, '1 0.5 1')
	ATTRIB(NexuizDialog, intendedWidth, float, 0)
	ATTRIB(NexuizDialog, rows, float, 3)
	ATTRIB(NexuizDialog, columns, float, 2)
	*/
	me.marginTop = SKINMARGIN_TOP; // pixels
	me.marginBottom = SKINMARGIN_BOTTOM; // pixels
	me.marginLeft = SKINMARGIN_LEFT; // pixels
	me.marginRight = SKINMARGIN_RIGHT; // pixels
	me.columnSpacing = SKINMARGIN_COLUMNS; // pixels
	me.rowSpacing = SKINMARGIN_ROWS; // pixels
	me.rowHeight = SKINFONTSIZE_NORMAL * SKINHEIGHT_NORMAL; // pixels
	me.titleHeight = SKINFONTSIZE_TITLE * SKINHEIGHT_TITLE; // pixels
	me.titleFontSize = SKINFONTSIZE_TITLE; // pixels
	me.backgroundImage = SKINGFX_DIALOGBORDER;
	me.borderLines = SKINHEIGHT_DIALOGBORDER;
	me.closeButtonImage = SKINGFX_CLOSEBUTTON;
	me.zoomedOutTitleBarPosition = SKINHEIGHT_ZOOMEDTITLE * 0.5 - 0.5;
	me.zoomedOutTitleBar = SKINHEIGHT_ZOOMEDTITLE != 0;
	me.alpha = SKINALPHA_TEXT;
	me.configureDialog = configureDialogNexuizDialog;
	me.classname = "NexuizDialog";
	return me;
}
entity currentDialog;
void configureDialogNexuizDialog(entity me)
{
	currentDialog = me;
	configureDialogDialog(me);
}
