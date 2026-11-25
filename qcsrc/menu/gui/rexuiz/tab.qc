void(entity me) gui_rexuiz_tab_show;

entity(void) gui_rexuiz_tab_spawn {
	entity me; me = gui_tab_spawn();
	me.showNotify = gui_rexuiz_tab_show;
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

void(entity me) gui_rexuiz_tab_show {
	gui_load_all_cvars(me);
	gui_container_show(me);
}
