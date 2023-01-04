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
void(void) updateNexuizSkinList;
#endif

#ifdef IMPLEMENTATION
entity selfNexuizSkinList;
float searchNexuizSkinList;

void(void) updateNexuizSkinList {
	if not(selfNexuizSkinList) return;
	if (searchNexuizSkinList >= 0)
		search_end(searchNexuizSkinList);

	if (!rm_skin_loaded) {
		searchNexuizSkinList = -1;
		selfNexuizSkinList.nItems = 0;
		return;
	}
	searchNexuizSkinList = search_begin("gfx/hud/skins/*/skininfo", TRUE, TRUE);
	if (searchNexuizSkinList >= 0) {
		selfNexuizSkinList.nItems = search_getsize(searchNexuizSkinList);
	} else {
		selfNexuizSkinList.nItems = 0;
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
	searchNexuizSkinList = -1;
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
	if (searchNexuizSkinList >= 0)
		search_end(searchNexuizSkinList);

	searchNexuizSkinList = -1;
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

