#ifdef INTERFACE
CLASS(NexuizProfileList) EXTENDS(NexuizListBox)
	METHOD(NexuizProfileList, toString, string(entity))
	ATTRIB(NexuizProfileList, rowsPerItem, float, 1)
	METHOD(NexuizProfileList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizProfileList, resizeNotify, void(entity, vector, vector, vector, vector))
	ATTRIB(NexuizProfileList, realFontSize, vector, '0 0 0')
	ATTRIB(NexuizProfileList, realUpperMargin, float, 0)
	METHOD(NexuizProfileList, loadCvars, void(entity))
ENDCLASS(NexuizProfileList)
entity makeNexuizProfileList();

const float PROFILELIST_MAX = 4;
#endif

#ifdef IMPLEMENTATION
string g_profile[PROFILELIST_MAX];

string(entity me) toStringNexuizProfileList {
	if (me.selectedItem < 0 || me.selectedItem >= PROFILELIST_MAX) return "";
	return g_profile[me.selectedItem];
}

entity() makeNexuizProfileList {
	entity me;
	me = spawnNexuizProfileList();
	me.configureNexuizListBox(me);
	loadCvarsNexuizProfileList(me);
	return me;
}

void(entity me) loadCvarsNexuizProfileList {
	string s = cvar_string("g_profile");
	string s2;
	float i;
	for (i = 0; i < PROFILELIST_MAX; i++) {
		str_unzone_ifneeded(g_profile[i]);
		g_profile[i] = NULL;
	}
	float n = 0;
	while ((s2 = str_car(s)) != "") {
		s = str_cdr(s);
		g_profile[n] = strzone(s2);
		n++;
		if (n == PROFILELIST_MAX) break;
	}
	me.nItems = n;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) resizeNotifyNexuizProfileList {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) drawListBoxItemNexuizProfileList {
	entity e;
	if (i > me.nItems) return;
	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	gui_draw_text(me.realUpperMargin * eY, g_profile[i], me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
#endif
