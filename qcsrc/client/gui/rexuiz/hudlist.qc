void(entity me) gui_hudlist_destroy;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_hudlist_resize;
void(entity, float, vector, float) gui_rexuiz_hudlist_draw_item;
void(entity, float, vector, float) gui_rexuiz_hudlist_click_item;

entity(void) gui_rexuiz_hudlist_spawn {
	entity me; me = gui_rexuiz_listbox_spawn();
	me.drawListBoxItem = gui_rexuiz_hudlist_draw_item;
	me.resizeNotify = gui_rexuiz_hudlist_resize;
	me.destroy = gui_hudlist_destroy;
	me.clickListBoxItem = gui_rexuiz_hudlist_click_item;
	me.textBox = NULL;
	me.realUpperMargin = 0;
	me.columnNameOrigin = 0;
	me.classname = "NexuizHudList";
	return me;
}

entity gui_rexuiz_hudlist_current;
float gui_rexuiz_hudlist_search;

void(string path, string s) gui_rexuiz_hudlist_default {
	if (file_exists(strcat("data/", path, ".hud"))) return;
	float f = fopen(strcat(path, ".hud"), FILE_WRITE);
	if (f >= 0) {
		fputs(f, s);
		fclose(f);
	}
}

void(void) gui_rexuiz_hudlist_update {
	if not(gui_rexuiz_hudlist_current) return;
	gui_rexuiz_hudlist_current.selectedItem = -1;
	if (gui_rexuiz_hudlist_search >= 0) {
		search_end(gui_rexuiz_hudlist_search);
	}
	if (rm_skin_loaded) {
		gui_rexuiz_hudlist_search = -1;
		gui_rexuiz_hudlist_current.nItems = 2;
		if (CVAR(cl_rm_hud_alt))
				gui_rexuiz_hudlist_current.selectedItem = 0;
		else
				gui_rexuiz_hudlist_current.selectedItem = 1;
	} else {
		gui_rexuiz_hudlist_search = search_begin("data/*.hud", TRUE, TRUE);
		if (gui_rexuiz_hudlist_search >= 0)
				gui_rexuiz_hudlist_current.nItems = search_getsize(gui_rexuiz_hudlist_search) + 1;
		else
				gui_rexuiz_hudlist_current.nItems = 1;
	}
}

entity(void) gui_rexuiz_hudlist_make {
	entity me;
	gui_rexuiz_hudlist_default("default1", "sbar_timer_position -18 20 1\n"
				"sbar_timer_scale 1.5\n");
	gui_rexuiz_hudlist_default("default2", "sbar_weapons_position 0 200 8\n");
	gui_rexuiz_hudlist_default("default3", "sbar_weapons_position 0 200 8\n"
				"sbar_timer_position -18 20 1\n"
				"sbar_timer_scale 1.5\n");
	gui_rexuiz_hudlist_default("alternative1", "sbar_ammo_position 0 0 9\n"
		"sbar_armor_position 140 5 9\n"
		"sbar_gameinfo_position 0 0 2\n"
		"sbar_health_position -140 5 9\n"
		"sbar_nadget_position 0 9 8\n"
		"sbar_nadget2_position 74 9 8\n"
		"sbar_powerups_position 0 336 10\n"
		"sbar_score_position 0 8 10\n"
		"sbar_score_scale 0.75\n"
		"sbar_timer_position -18 20 1\n"
		"sbar_timer_scale 1.5\n"
		"sbar_weapons_position 0 100 10\n");
	gui_rexuiz_hudlist_default("alternative2", "sbar_ammo_position 0 0 9\n"
		"sbar_armor_position 140 5 9\n"
		"sbar_gameinfo_position 0 0 2\n"
		"sbar_health_position -140 5 9\n"
		"sbar_nadget_position 0 9 8\n"
		"sbar_nadget2_position 74 9 8\n"
		"sbar_powerups_position 0 336 10\n"
		"sbar_score_position 0 8 10\n"
		"sbar_score_scale 0.75\n"
		"sbar_timer_position -18 20 1\n"
		"sbar_timer_scale 1.5\n"
		"sbar_weapons_position 0 200 0\n");
	me = gui_rexuiz_hudlist_spawn();
	me.configureNexuizListBox(me);
	gui_rexuiz_hudlist_current = me;
	gui_rexuiz_hudlist_search = -1;
	gui_rexuiz_hudlist_update();
	return me;
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_hudlist_click_item {
	if (doubleclick) {
		if (rm_skin_loaded) {
			if (i == 0) {
				cvar_set("cl_rm_hud_alt", "1");
			} else if (i == 1) {
				cvar_set("cl_rm_hud_alt", "0");
			}
		} else {
			string s;
			if (i > 0 && gui_rexuiz_hudlist_search >= 0) {
				s = search_getfilename(gui_rexuiz_hudlist_search, i - 1);
				sbar_load(s);
			} else if (i == 0) {
				sbar_set_defaults();
			} else
				return;
		}
		GUI_Hide(); //close hud dialog
		GUI_Hide(); //close game settings dialog
		GUI_Hide(); //close menu
	}
}

void(entity me) gui_hudlist_destroy {
	if (gui_rexuiz_hudlist_search >= 0)
		search_end(gui_rexuiz_hudlist_search);
	gui_rexuiz_hudlist_search = -1;
	gui_rexuiz_hudlist_current = NULL;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_hudlist_resize {
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_hudlist_draw_item {
	string s;
	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	if (rm_skin_loaded) {
		if (i == 1)
			s = "[RM Classic]";
		else
			s = "[RM Alternative]";
	} else {
		if (i == 0) {
			s = "[default]";
		} else if (gui_rexuiz_hudlist_search >= 0)
			s = search_getfilename(gui_rexuiz_hudlist_search, i - 1);
		else
			s = "";
	}
	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
}
