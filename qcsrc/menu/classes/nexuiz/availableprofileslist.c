#ifdef INTERFACE
CLASS(NexuizAvailableProfilesList) EXTENDS(NexuizListBox)
	METHOD(NexuizAvailableProfilesList, toString, string(entity))
	ATTRIB(NexuizAvailableProfilesList, rowsPerItem, float, 1)
	METHOD(NexuizAvailableProfilesList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizAvailableProfilesList, resizeNotify, void(entity, vector, vector, vector, vector))
	ATTRIB(NexuizAvailableProfilesList, realFontSize, vector, '0 0 0')
	ATTRIB(NexuizAvailableProfilesList, realUpperMargin, float, 0)
	ATTRIB(NexuizAvailableProfilesList, handle, float, -1)
	METHOD(NexuizAvailableProfilesList, destroy, void(entity))
	METHOD(NexuizAvailableProfilesList, loadCvars, void(entity))
ENDCLASS(NexuizAvailableProfilesList)
entity makeNexuizAvailableProfilesList();
void AvailableProfilesList_MoveUp_Click(entity btn, entity me);
void AvailableProfilesList_MoveDown_Click(entity box, entity me);
#endif

#ifdef IMPLEMENTATION
void(entity me) destroyNexuizAvailableProfilesList {
	buf_del(me.handle);
}

string(entity me) toStringNexuizAvailableProfilesList {
	string s = bufstr_get(me.handle, me.selectedItem);
	s = substring(s, 0, strlen(s) - 8);
	return s;
}

void(entity me) loadCvarsNexuizAvailableProfilesList {
	buf_cvarlist(me.handle, "*_profile", "g_");
	me.nItems = buf_getsize(me.handle);
	float i, j;
	string s;
	string profile = strcat(" ", strreplace("+", " ", cvar_string("g_profile")), " ");
	for (i = 0; i < me.nItems; i++) {
		string s = bufstr_get(me.handle, i);
		if (s == "") break;
		s = strcat(" ", substring(s, 0, strlen(s) - 8), " ");
		if (strstrofs(profile, s, 0) >= 0) {
			if (me.selectedItem >= i) me.selectedItem--;
			bufstr_free(me.handle, i);
			for (j = i + 1; j < me.nItems; j++) {
				bufstr_set(me.handle, j - 1, bufstr_get(me.handle, j));
			}
			me.nItems--;
			bufstr_free(me.handle, me.nItems);
			i--;
		}
	}
}

entity() makeNexuizAvailableProfilesList {
	entity me;
	me = spawnNexuizAvailableProfilesList();
	me.handle = buf_create();
	loadCvarsNexuizProfileList(me);
	me.configureNexuizListBox(me);
	return me;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) resizeNotifyNexuizAvailableProfilesList {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) drawListBoxItemNexuizAvailableProfilesList {
	entity e;
	if (i > me.nItems) return;
	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = bufstr_get(me.handle, i);
	s = substring(s, 0, strlen(s) - 8);
	gui_draw_text(me.realUpperMargin * eY, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
#endif
