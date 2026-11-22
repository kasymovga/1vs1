entity spawnNexuizReportTypeList() {
	entity me; me = spawnNexuizListBox();
	me.drawListBoxItem = drawListBoxItemNexuizReportTypeList;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.resizeNotify = resizeNotifyNexuizReportTypeList;
	me.classname = "NexuizReportTypeList";
	return me;
}
entity makeNexuizReportTypeList();
entity makeNexuizReportTypeList(void)
{
	entity me;
	me = spawnNexuizReportTypeList();
	me.configureNexuizListBox(me);
	me.nItems = REPORT_REASONS_COUNT_MAX;
	return me;
}
void resizeNotifyNexuizReportTypeList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}
void drawListBoxItemNexuizReportTypeList(entity me, float i, vector absSize, float isSelected)
{
	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	string s = report_reasons[i];
	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
