void(entity me) gui_rexuiz_demolist_configure;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_demolist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_demolist_item_draw;
void(entity me) gui_rexuiz_demolist_show;
void(entity me) gui_rexuiz_demolist_start;
void(entity me, float i, vector where, float doubleclick) gui_rexuiz_demolist_item_click;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_demolist_key_down;
string(entity me, float i ) gui_rexuiz_demolist_name;
void(entity me) gui_rexuiz_demolist_get;
void(entity me) gui_rexuiz_demolist_destroy;

entity(void) gui_rexuiz_demolist_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.configureNexuizDemoList = gui_rexuiz_demolist_configure;
	me.rowsPerItem = 1;
	me.resizeNotify = gui_rexuiz_demolist_resize;
	me.drawListBoxItem = gui_rexuiz_demolist_item_draw;
	me.getDemos = gui_rexuiz_demolist_get;
	me.startDemo = gui_rexuiz_demolist_start;
	me.demoName = gui_rexuiz_demolist_name;
	me.clickListBoxItem = gui_rexuiz_demolist_item_click;
	me.keyDown = gui_rexuiz_demolist_key_down;
	me.destroy = gui_rexuiz_demolist_destroy;
	me.showNotify = gui_rexuiz_demolist_show;
	me.listDemo = -1;
	me.realFontSize = '0 0 0';
	me.columnNameOrigin = 0;
	me.columnNameSize = 0;
	me.realUpperMargin = 0;
	me.origin = '0 0 0';
	me.itemAbsSize = '0 0 0';
	me.filterString = NULL;
	me.classname = "NexuizDemoList";
	return me;
}

entity(void) gui_rexuiz_demolist_make {
	entity me;
	me = gui_rexuiz_demolist_spawn();
	me.configureNexuizDemoList(me);
	return me;
}

void(entity me) gui_rexuiz_demolist_configure {
	me.configureNexuizListBox(me);
	me.getDemos(me);
}

string(entity me, float i ) gui_rexuiz_demolist_name {
	string s;
	s = search_getfilename(me.listDemo, i);
	s = str_sub(s, 6, strlen(s) - 6 - 4); // demos/, .dem
	return s;
}

void(entity me) gui_rexuiz_demolist_get {
	string s;
	if (me.filterString)
		s = strcat("demos/*", me.filterString, "*.dem");
	else
		s = "demos/*.dem";

	if (me.listDemo >= 0)
		search_end(me.listDemo);

	me.listDemo = search_begin(s, FALSE, TRUE);
	if (me.listDemo < 0)
		me.nItems=0;
	else
		me.nItems=search_getsize(me.listDemo);
}

void(entity me) gui_rexuiz_demolist_destroy {
	if (me.listDemo >= 0)
		search_end(me.listDemo);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_demolist_resize {
	me.itemAbsSize = '0 0 0';
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
	me.columnNameOrigin = me.realFontSize_x;
	me.columnNameSize = 1 - 2 * me.realFontSize_x;
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_demolist_item_draw {
	string s;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = me.demoName(me,i);
	s = gui_draw_text_shorten_to_width(s, me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

void(entity me) gui_rexuiz_demolist_show {
	me.getDemos(me);
}

void(entity box, entity me) gui_rexuiz_demolist_filter_change {
	str_unzone_ifneeded(me.filterString);
	me.filterString = str_zone_ifneeded(box.text);
	me.getDemos(me);
}

void(entity me) gui_rexuiz_demolist_start {
	string s;
	s = me.demoName(me,me.selectedItem);
	demo_play(strcat("demos/", s, ".dem"));
}

void(entity btn, entity me) gui_rexuiz_demolist_start_click {
	me.startDemo(me);
}

void(entity btn, entity me) gui_rexuiz_demolist_timedemo_click {
	string s;
	s = me.demoName(me,me.selectedItem);
	localcmd("timedemo demos/", s, ".dem\nwait\ntogglemenu\n");
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_demolist_item_click {
	if (doubleclick)
		me.startDemo(me);
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_demolist_key_down {
	if (scan == VM_K_ENTER) {
		me.startDemo(me);
		return 1;
	} else
		return keyDownListBox(me, scan, ascii, shift);
}
