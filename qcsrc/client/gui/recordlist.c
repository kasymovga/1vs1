#ifdef INTERFACE
CLASS(NexuizRecordList) EXTENDS(NexuizListBox)
	METHOD(NexuizRecordList, configureNexuizRecordList, void(entity))
	METHOD(NexuizRecordList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizRecordList, setSelected, void(entity, float))
	METHOD(NexuizRecordList, resizeNotify, void(entity, vector, vector, vector, vector))
	ATTRIB(NexuizRecordList, realUpperMargin, float, 0)
	ATTRIB(NexuizRecordList, columnNameOrigin, float, 0)
	ATTRIB(NexuizRecordList, voteList, entity, NULL)
ENDCLASS(NexuizRecordList)
entity makeNexuizRecordList();
#endif

#ifdef IMPLEMENTATION
entity makeNexuizRecordList(void)
{
	entity me;
	me = spawnNexuizRecordList();
	me.configureNexuizRecordList(me);
	me.nItems = 1;
	return me;
}

void configureNexuizRecordListNexuizRecordList(entity me)
{
	me.configureNexuizListBox(me);
}

void setSelectedNexuizRecordList(entity me, float i) {
	setSelectedListBox(me, i);
	if (i >= me.nItems)
		return;
}

void resizeNotifyNexuizRecordList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void drawListBoxItemNexuizRecordList(entity me, float i, vector absSize, float isSelected) {
	if (isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = recordlist_get(i);
	string record_map = str_car(s);
	s = str_cdr(s);
	float trim = 0;
	while (substring(s, trim, 1) == " ")
		trim++;

	s = substring(s, trim, -1);
	string record_time = str_car(s);
	string record_name = str_cdr(s);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, record_map, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.4 0 0', record_time, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.6 0 0', record_name, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 1);
	me.nItems = max(1, recordlist_size);
}
#endif
