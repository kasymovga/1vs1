void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_reporttypelist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_reporttypelist_item_draw;

entity(void) gui_rexuiz_reporttypelist_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.drawListBoxItem = gui_rexuiz_reporttypelist_item_draw;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.resizeNotify = gui_rexuiz_reporttypelist_resize;
	me.classname = "NexuizReportTypeList";
	return me;
}

entity(void) gui_rexuiz_reporttypelist_make {
	entity me;
	me = gui_rexuiz_reporttypelist_spawn();
	me.configureNexuizListBox(me);
	me.nItems = REPORT_REASONS_COUNT_MAX;
	return me;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_reporttypelist_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_reporttypelist_item_draw {
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = report_reasons[i];
	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
