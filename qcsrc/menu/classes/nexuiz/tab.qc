entity spawnNexuizTab() {
	entity me; me = spawnTab();
	// still to be customized by user
	/*
	ATTRIB(NexuizTab, intendedWidth, float, 0)
	ATTRIB(NexuizTab, rows, float, 3)
	ATTRIB(NexuizTab, columns, float, 2)
	*/
	me.showNotify = showNotifyNexuizTab;
	me.marginTop = 0; // pixels
	me.marginBottom = 0; // pixels
	me.marginLeft = 0; // pixels
	me.marginRight = 0; // pixels
	me.columnSpacing = SKINMARGIN_COLUMNS; // pixels
	me.rowSpacing = SKINMARGIN_ROWS; // pixels
	me.rowHeight = SKINFONTSIZE_NORMAL * SKINHEIGHT_NORMAL; // pixels
	me.titleHeight = SKINFONTSIZE_TITLE * SKINHEIGHT_TITLE; // pixels
	me.backgroundImage = NULL;
	me.classname = "NexuizTab";
	return me;
}
void(entity me) showNotifyNexuizTab {
	gui_load_all_cvars(me);
	showNotifyContainer(me);
}
