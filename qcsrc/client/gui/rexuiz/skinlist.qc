void(entity me, float i, vector where, float doubleclick) gui_rexuiz_skinlist_click;
void(entity me) gui_rexuiz_skinlist_destroy;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_skinlist_resize;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_skinlist_item_draw;

entity(void) gui_rexuiz_skinlist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.drawListBoxItem = gui_rexuiz_skinlist_item_draw;
	me.resizeNotify = gui_rexuiz_skinlist_resize;
	me.destroy = gui_rexuiz_skinlist_destroy;
	me.clickListBoxItem = gui_rexuiz_skinlist_click;
	me.textBox = NULL;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.classname = "NexuizSkinList";
	return me;
}

entity gui_rexuiz_skinlist_current;
float gui_rexuiz_skinlist_search;

void(void) gui_rexuiz_skinlist_update {
	if not(gui_rexuiz_skinlist_current) return;
	if (gui_rexuiz_skinlist_search >= 0)
		search_end(gui_rexuiz_skinlist_search);
	if (!rm_skin_loaded) {
		gui_rexuiz_skinlist_search = -1;
		gui_rexuiz_skinlist_current.nItems = 0;
		return;
	}
	gui_rexuiz_skinlist_search = search_begin("gfx/hud/skins/*/skininfo", TRUE, TRUE);
	if (gui_rexuiz_skinlist_search >= 0) {
		gui_rexuiz_skinlist_current.nItems = search_getsize(gui_rexuiz_skinlist_search);
	} else {
		gui_rexuiz_skinlist_current.nItems = 0;
	}
	string s;
	float i;
	for (i = 0; i < gui_rexuiz_skinlist_current.nItems; i++) {
		s = search_getfilename(gui_rexuiz_skinlist_search, i);
		s = str_sub(s, 14, - 1);
		s = str_sub(s, 0, strstrofs(s, "/", 0));
		if (s == cvar_string("cl_rm_skin")) {
				gui_rexuiz_skinlist_current.selectedItem = i;
		}
	}
}

entity(void) gui_rexuiz_skinlist_make {
	entity me;
	gui_rexuiz_skinlist_current = me = gui_rexuiz_skinlist_spawn();
	gui_rexuiz_skinlist_search = -1;
	me.configureNexuizListBox(me);
	me.selectedItem = -1;
	gui_rexuiz_skinlist_update();
	return me;
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_skinlist_click {
	if (doubleclick) {
		string s;
		if (i >= 0 && gui_rexuiz_skinlist_search >= 0) {
			s = search_getfilename(gui_rexuiz_skinlist_search, i);
			s = str_sub(s, 14, - 1);
			s = str_sub(s, 0, strstrofs(s, "/", 0));
			rm_skin_load(s);
		} else
			return;

		GUI_Hide(); // hud dialog
		GUI_Hide(); // game settings
		GUI_Hide(); // game menu
	}
}
void(entity me) gui_rexuiz_skinlist_destroy {
	if (gui_rexuiz_skinlist_search >= 0)
		search_end(gui_rexuiz_skinlist_search);

	gui_rexuiz_skinlist_search = -1;
	gui_rexuiz_skinlist_current = NULL;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_skinlist_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_skinlist_item_draw {
	string s;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	if (gui_rexuiz_skinlist_search >= 0 && gui_rexuiz_skinlist_search >= 0) {
		s = search_getfilename(gui_rexuiz_skinlist_search, i);
		s = str_sub(s, 14, - 1);
		s = str_sub(s, 0, strstrofs(s, "/", 0));
	} else
		s = "";

	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
