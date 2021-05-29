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

void(string path, string s) checkDefaultNexuizHudList {
	if (file_exists(strcat("data/", path, ".hud"))) return;
	float f = fopen(strcat(path, ".hud"), FILE_WRITE);
	if (f >= 0) {
		fputs(f, s);
		fclose(f);
	}
}

entity(void) makeNexuizHudList {
	entity me;
	checkDefaultNexuizHudList("default1", "sbar_timer_position -18 20 1\n"
			"sbar_timer_scale 1.5\n");
	checkDefaultNexuizHudList("default2", "sbar_weapons_position 0 200 8\n");
	checkDefaultNexuizHudList("default3", "sbar_weapons_position 0 200 8\n"
			"sbar_timer_position -18 20 1\n"
			"sbar_timer_scale 1.5\n");
	checkDefaultNexuizHudList("alternative1", "sbar_ammo_position 0 0 9\n"
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
	checkDefaultNexuizHudList("alternative2", "sbar_ammo_position 0 0 9\n"
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
		string s;
		if (i > 0 && searchHudList >= 0) {
			s = search_getfilename(searchHudList, i - 1);
			sbar_load(s);
		} else if (i == 0) {
			sbar_set_defaults();
		} else
			return;

		GUI_Hide();
		GUI_Hide();
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
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	if (i == 0) {
		s = "[default]";
	} else if (searchHudList >= 0 && searchHudList >= 0)
		s = search_getfilename(searchHudList, i - 1);
	else
		s = "";

	gui_draw_text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
#endif
