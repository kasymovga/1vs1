#ifdef INTERFACE
CLASS(NexuizHudList) EXTENDS(NexuizListBox)
	METHOD(NexuizHudList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizHudList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(NexuizHudList, destroy, void(entity))
	METHOD(NexuizHudList, clickListBoxItem, void(entity, float, vector, float))
	ATTRIB(NexuizHudList, textBox, entity, NULL)
	ATTRIB(NexuizHudList, realUpperMargin, float, 0)
	ATTRIB(NexuizCvarList, columnNameOrigin, float, 0)
ENDCLASS(NexuizHudList)
entity makeNexuizHudList();
#endif

#ifdef IMPLEMENTATION
float searchHudList;

entity(void) makeNexuizHudList {
	entity me;
	me = spawnNexuizHudList();
	me.configureNexuizListBox(me);
	me.selectedItem = -1;
	me.configureNexuizListBox(me);
	searchHudList = search_begin("data/*.hud", TRUE, TRUE);
	if (searchHudList >= 0)
		me.nItems = search_getsize(searchHudList) + 1;
	else
		me.nItems = 1;

	return me;
}

void clickListBoxItemNexuizHudList(entity me, float i, vector where, float doubleclick) {
	if (doubleclick) {
		print("i = ", ftos(i), "\n");
		string s;
		if (i > 0 && searchHudList >= 0) {
			s = search_getfilename(searchHudList, i - 1);
			sbar_load(s);
		} else if (i == 0) {
			sbar_set_defaults();
		} else
			return;

		GUI_Hide();
	}
}

void(entity me) destroyNexuizHudList {
	search_end(searchHudList);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) resizeNotifyNexuizHudList {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) drawListBoxItemNexuizHudList {
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	if (i == 0) {
		s = "[default]";
	} else if (searchHudList >= 0 && searchHudList >= 0)
		s = search_getfilename(searchHudList, i - 1);
	else
		s = "";

	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
#endif
