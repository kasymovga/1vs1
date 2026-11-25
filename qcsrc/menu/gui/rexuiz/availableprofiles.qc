void(entity me) gui_rexuiz_availableprofiles_destroy;
string(entity me) gui_rexuiz_availableprofiles_to_string;
void(entity me) gui_rexuiz_availableprofiles_load;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_availableprofiles_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_availableprofiles_item_draw;

entity(void) gui_rexuiz_availableprofiles_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.toString = gui_rexuiz_availableprofiles_to_string;
	me.rowsPerItem = 1;
	me.drawListBoxItem = gui_rexuiz_availableprofiles_item_draw;
	me.resizeNotify = gui_rexuiz_availableprofiles_resize;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.handle = -1;
	me.destroy = gui_rexuiz_availableprofiles_destroy;
	me.loadCvars = gui_rexuiz_availableprofiles_load;
	me.classname = "NexuizAvailableProfilesList";
	return me;
}

entity() gui_rexuiz_availableprofiles_make {
	entity me = gui_rexuiz_availableprofiles_spawn();
	me.handle = str_array_create();
	me.configureNexuizListBox(me);
	return me;
}

void(entity me) gui_rexuiz_availableprofiles_destroy {
	str_array_delete(me.handle);
}

string(entity me) gui_rexuiz_availableprofiles_to_string {
	string s = str_array_get(me.handle, me.selectedItem);
	s = str_sub(s, 0, strlen(s) - 8);
	return s;
}

void(entity me) gui_rexuiz_availableprofiles_load {
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

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_availableprofiles_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_availableprofiles_item_draw {
	entity e;
	if (i > me.nItems) return;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	string s = str_array_get(me.handle, i);
	s = str_sub(s, 0, strlen(s) - 8);
	gui_draw_text(me.realUpperMargin * eY, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
