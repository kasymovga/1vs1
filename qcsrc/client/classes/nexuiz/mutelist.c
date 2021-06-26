#ifdef INTERFACE
CLASS(NexuizMuteList) EXTENDS(NexuizListBox)
	METHOD(NexuizMuteList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizMuteList, resizeNotify, void(entity, vector, vector, vector, vector))
	ATTRIB(NexuizMuteList, textBox, entity, NULL)
	ATTRIB(NexuizMuteList, realUpperMargin, float, 0)
	ATTRIB(NexuizCvarList, columnNameOrigin, float, 0)
	ATTRIB(NexuizCvarList, voteArgsList, entity, NULL)
ENDCLASS(NexuizMuteList)
entity makeNexuizMuteList();
#endif

#ifdef IMPLEMENTATION

entity makeNexuizMuteList(void) {
	entity me;
	me = spawnNexuizMuteList();
	me.nItems = maxclients;
	me.selectedItem = -1;
	me.configureNexuizListBox(me);
	return me;
}

void resizeNotifyNexuizMuteList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void drawListBoxItemNexuizMuteList(entity me, float i, vector absSize, float isSelected) {
	string s;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	float n = i + 1;
	s = strdecolorize(player_name(i));
	if (mute_listed(n)) {
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, "[MUTED]", me.realFontSize, SKINCOLOR_TEXT_WARNING, SKINALPHA_TEXT, 0);
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.1 0 0', strcat("#", ftos(n)), me.realFontSize, SKINCOLOR_TEXT_WARNING, SKINALPHA_TEXT, 0);
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.2 0 0', s, me.realFontSize, SKINCOLOR_TEXT_WARNING, SKINALPHA_TEXT, 0);
	} else {
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.1 0 0', strcat("#", ftos(n)), me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
		gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.2 0 0', s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
	}
}

#endif
