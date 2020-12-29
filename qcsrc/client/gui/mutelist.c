#ifdef INTERFACE
CLASS(NexuizMuteList) EXTENDS(NexuizListBox)
	METHOD(NexuizMuteList, configureNexuizMuteList, void(entity))
	METHOD(NexuizMuteList, drawListBoxItem, void(entity, float, vector, float))
	//METHOD(NexuizMuteList, setSelected, void(entity, float))
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
	me.configureNexuizMuteList(me);
	return me;
}

void configureNexuizMuteListNexuizMuteList(entity me) {
	me.nItems = maxclients;
	me.selectedItem = -1;
	me.configureNexuizListBox(me);
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
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	float n = i + 1;
	s = strdecolorize(player_name(i));
	if (mute_listed(n)) {
		draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, "[MUTED]", me.realFontSize, '1.5 0.5 0.5', SKINALPHA_TEXT, 0);
		draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.1 0', strcat("#", ftos(n)), me.realFontSize, '1.2 0.9 0.9', SKINALPHA_TEXT, 0);
		draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.2 0', s, me.realFontSize, '1.2 0.9 0.9', SKINALPHA_TEXT, 0);
	} else {
		draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.1 0', strcat("#", ftos(n)), me.realFontSize, '0.8 1.1 1.1', SKINALPHA_TEXT, 0);
		draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX + '0.2 0', s, me.realFontSize, '0.8 1.1 1.1', SKINALPHA_TEXT, 0);
	}
}

#endif
