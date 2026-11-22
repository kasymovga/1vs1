entity spawnNexuizAvailableProfilesList() {
	entity me; me = spawnNexuizListBox();
	me.toString = toStringNexuizAvailableProfilesList;
	me.rowsPerItem = 1;
	me.drawListBoxItem = drawListBoxItemNexuizAvailableProfilesList;
	me.resizeNotify = resizeNotifyNexuizAvailableProfilesList;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.handle = -1;
	me.destroy = destroyNexuizAvailableProfilesList;
	me.loadCvars = loadCvarsNexuizAvailableProfilesList;
	me.classname = "NexuizAvailableProfilesList";
	return me;
}
entity makeNexuizAvailableProfilesList();
void AvailableProfilesList_MoveUp_Click(entity btn, entity me);
void AvailableProfilesList_MoveDown_Click(entity box, entity me);
void(entity me) destroyNexuizAvailableProfilesList {
	str_array_delete(me.handle);
}
string(entity me) toStringNexuizAvailableProfilesList {
	string s = str_array_get(me.handle, me.selectedItem);
	s = str_sub(s, 0, strlen(s) - 8);
	return s;
}
void(entity me) loadCvarsNexuizAvailableProfilesList {
	str_array_cvar_list(me.handle, "*_profile", "g_");
	me.nItems = str_array_size(me.handle);
	float i, j;
	string s;
	string profile = strcat(" ", strreplace("+", " ", cvar_string("g_profile")), " ");
	for (i = 0; i < me.nItems; i++) {
		string s = str_array_get(me.handle, i);
		if (s == "") break;
		s = strcat(" ", str_sub(s, 0, strlen(s) - 8), " ");
		if (strstrofs(profile, s, 0) >= 0) {
				if (me.selectedItem >= i) me.selectedItem--;
				for (j = i + 1; j < me.nItems; j++) {
				str_array_set(me.handle, j - 1, str_array_get(me.handle, j));
				}
				me.nItems--;
				str_array_free(me.handle, me.nItems);
				i--;
		}
	}
}
entity() makeNexuizAvailableProfilesList {
	entity me;
	me = spawnNexuizAvailableProfilesList();
	me.handle = str_array_create();
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
	string s = str_array_get(me.handle, i);
	s = str_sub(s, 0, strlen(s) - 8);
	gui_draw_text(me.realUpperMargin * eY, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
