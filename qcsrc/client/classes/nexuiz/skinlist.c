#ifdef INTERFACE
CLASS(NexuizSkinList) EXTENDS(NexuizListBox)
	METHOD(NexuizSkinList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizSkinList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(NexuizSkinList, destroy, void(entity))
	METHOD(NexuizSkinList, clickListBoxItem, void(entity, float, vector, float))
	ATTRIB(NexuizSkinList, textBox, entity, NULL)
	ATTRIB(NexuizSkinList, realUpperMargin, float, 0)
	ATTRIB(NexuizCvarList, columnNameOrigin, float, 0)
ENDCLASS(NexuizSkinList)
entity makeNexuizSkinList();
#endif

#ifdef IMPLEMENTATION
entity selfNexuizSkinList;
float searchNexuizSkinList;
float searchStartedNexuizSkinList;

void(void) updateNexuizSkinList {
	if not(selfNexuizSkinList) return;
	if (searchStartedNexuizSkinList)
		search_end(searchNexuizSkinList);

	searchNexuizSkinList = search_begin("gfx/hud/skins/*/skininfo", TRUE, TRUE);
	if (searchNexuizSkinList >= 0) {
		selfNexuizSkinList.nItems = search_getsize(searchNexuizSkinList);
		searchStartedNexuizSkinList = TRUE;
	} else {
		selfNexuizSkinList.nItems = 0;
		searchStartedNexuizSkinList = FALSE;
	}
	string s;
	float i;
	for (i = 0; i < selfNexuizSkinList.nItems; i++) {
		s = search_getfilename(searchNexuizSkinList, i);
		s = substring(s, 14, - 1);
		s = substring(s, 0, strstrofs(s, "/", 0));
		if (s == cvar_string("cl_rm_skin")) {
			selfNexuizSkinList.selectedItem = i;
		}
	}
}

entity(void) makeNexuizSkinList {
	entity me;
	selfNexuizSkinList = me = spawnNexuizSkinList();
	me.configureNexuizListBox(me);
	me.selectedItem = -1;
	updateNexuizSkinList();
	return me;
}

void clickListBoxItemNexuizSkinList(entity me, float i, vector where, float doubleclick) {
	if (doubleclick) {
		string s;
		if (i >= 0 && searchNexuizSkinList >= 0) {
			s = search_getfilename(searchNexuizSkinList, i);
			s = substring(s, 14, - 1);
			s = substring(s, 0, strstrofs(s, "/", 0));
			rm_skin_load(s);
		} else
			return;

		GUI_Hide();
		GUI_Hide();
		GUI_Hide();
	}
}

void(entity me) destroyNexuizSkinList {
	if (searchStartedNexuizSkinList)
		search_end(searchNexuizSkinList);

	searchStartedNexuizSkinList = FALSE;
	selfNexuizSkinList = NULL;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) resizeNotifyNexuizSkinList {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) drawListBoxItemNexuizSkinList {
	string s;
	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	if (searchNexuizSkinList >= 0 && searchNexuizSkinList >= 0) {
		s = search_getfilename(searchNexuizSkinList, i);
		s = substring(s, 14, - 1);
		s = substring(s, 0, strstrofs(s, "/", 0));
	} else
		s = "";

	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
#endif

