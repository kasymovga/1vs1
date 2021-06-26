#ifdef INTERFACE
CLASS(NexuizReportPlayerList) EXTENDS(NexuizListBox)
	METHOD(NexuizReportPlayerList, drawListBoxItem, void(entity, float, vector, float))
	ATTRIB(NexuizReportPlayerList, realUpperMargin, float, 0)
	ATTRIB(NexuizReportPlayerList, columnNameOrigin, float, 0)
	METHOD(NexuizReportPlayerList, resizeNotify, void(entity, vector, vector, vector, vector))
ENDCLASS(NexuizReportPlayerList)
entity makeNexuizReportPlayerList();
#endif

#ifdef IMPLEMENTATION

entity makeNexuizReportPlayerList(void)
{
	entity me;
	me = spawnNexuizReportPlayerList();
	me.configureNexuizListBox(me);
	me.nItems = 255;
	return me;
}

void resizeNotifyNexuizReportPlayerList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void drawListBoxItemNexuizReportPlayerList(entity me, float i, vector absSize, float isSelected)
{
	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = "";
	entity  e = player_slots[i];
	if (e)
		s = strcat("#", ftos(e.sv_entnum + 1), ": ", strdecolorize(player_name(e.sv_entnum)));

	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}

#endif
