entity(void) gui_tab_spawn {
	entity me = gui_dialog_spawn();
	me.isTabRoot = 0;
	me.closable = 0;
	me.rootDialog = 0;
	me.title = NULL;
	me.titleFontSize = 0; // pixels
	me.intendedWidth = 0;
	me.rows = 3;
	me.columns = 2;
	me.marginTop = 0; // pixels
	me.marginBottom = 0; // pixels
	me.marginLeft = 0; // pixels
	me.marginRight = 0; // pixels
	me.columnSpacing = 0; // pixels
	me.rowSpacing = 0; // pixels
	me.rowHeight = 0; // pixels
	me.titleHeight = 0; // pixels
	me.backgroundImage = NULL;
	me.classname = "Tab";
	return me;
}
