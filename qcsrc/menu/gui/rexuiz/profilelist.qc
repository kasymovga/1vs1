void(entity me) gui_rexuiz_profilelist_load;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_profilelist_item_draw;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_profilelist_resize;
string(entity me) gui_rexuiz_profilelist_to_string;

entity(void) gui_rexuiz_profilelist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.toString = gui_rexuiz_profilelist_to_string;
	me.rowsPerItem = 1;
	me.drawListBoxItem = gui_rexuiz_profilelist_item_draw;
	me.resizeNotify = gui_rexuiz_profilelist_resize;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.loadCvars = gui_rexuiz_profilelist_load;
	me.classname = "NexuizProfileList";
	return me;
}

entity() gui_rexuiz_profilelist_make {
	entity me = gui_rexuiz_profilelist_spawn();
	me.configureNexuizListBox(me);
	gui_rexuiz_profilelist_load(me);
	return me;
}

string gui_rexuiz_profilelist[GUI_REXUIZ_PROFILELIST_MAX];

string(entity me) gui_rexuiz_profilelist_to_string {
	if (me.selectedItem < 0 || me.selectedItem >= GUI_REXUIZ_PROFILELIST_MAX) return "";
	return gui_rexuiz_profilelist[me.selectedItem];
}

void(entity me) gui_rexuiz_profilelist_load {
	string s = cvar_string("g_profile");
	string s2;
	float i;
	for (i = 0; i < GUI_REXUIZ_PROFILELIST_MAX; i++) {
		str_unzone_ifneeded(gui_rexuiz_profilelist[i]);
		gui_rexuiz_profilelist[i] = NULL;
	}
	float n = 0;
	while ((s2 = str_car(s)) != "") {
		s = str_cdr(s);
		gui_rexuiz_profilelist[n] = str_zone_ifneeded(s2);
		n++;
		if (n == GUI_REXUIZ_PROFILELIST_MAX) break;
	}
	me.nItems = n;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_profilelist_resize {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_profilelist_item_draw {
	entity e;
	if (i > me.nItems) return;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	gui_draw_text(me.realUpperMargin * eY, gui_rexuiz_profilelist[i], me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
