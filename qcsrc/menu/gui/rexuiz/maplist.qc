void(entity me) gui_rexuiz_maplist_destroy;
void(entity me) gui_rexuiz_maplist_configure;
void(entity me) gui_rexuiz_maplist_load;
float(entity me, float i) gui_rexuiz_maplist_cache_query;
void(entity me, float i) gui_rexuiz_maplist_cache_toggle;
void(entity me) gui_rexuiz_maplist_draw;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_maplist_item_draw;
void(entity me) gui_rexuiz_maplist_refilter;
void(entity me, entity cb) gui_rexuiz_maplist_refilter_callback;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_maplist_key_down;
void(entity me, float i, vector where, float doubleclick) gui_rexuiz_maplist_item_click;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_maplist_resize;

entity(void) gui_rexuiz_maplist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.configureNexuizMapList = gui_rexuiz_maplist_configure;
	me.rowsPerItem = 4;
	me.draw = gui_rexuiz_maplist_draw;
	me.drawListBoxItem = gui_rexuiz_maplist_item_draw;
	me.clickListBoxItem = gui_rexuiz_maplist_item_click;
	me.resizeNotify = gui_rexuiz_maplist_resize;
	me.refilter = gui_rexuiz_maplist_refilter;
	me.refilterCallback = gui_rexuiz_maplist_refilter_callback;
	me.keyDown = gui_rexuiz_maplist_key_down;
	me.realFontSize = '0 0 0';
	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = 0;
	me.columnNameOrigin = 0;
	me.columnNameSize = 0;
	me.checkMarkOrigin = '0 0 0';
	me.checkMarkSize = '0 0 0';
	me.realUpperMargin1 = 0;
	me.realUpperMargin2 = 0;
	me.lastGametype = 0;
	me.isSinglePlayer = 0;
	me.origin = '0 0 0';
	me.itemAbsSize = '0 0 0';
	me.g_maplistCache = NULL;
	me.g_maplistCacheToggle = gui_rexuiz_maplist_cache_toggle;
	me.g_maplistCacheQuery = gui_rexuiz_maplist_cache_query;
	me.startButton = NULL;
	me.loadCvars = gui_rexuiz_maplist_load;
	me.typeToSearchString = NULL;
	me.typeToSearchTime = 0;
	me.destroy = gui_rexuiz_maplist_destroy;
	me.classname = "NexuizMapList";
	return me;
}

void(entity me) gui_rexuiz_maplist_destroy {
	map_info_shutdown();
}

entity(float single) gui_rexuiz_maplist_make {
	entity me;
	me = gui_rexuiz_maplist_spawn();
	me.isSinglePlayer = single;
	me.configureNexuizMapList(me);
	return me;
}

void(entity me) gui_rexuiz_maplist_configure {
	me.configureNexuizListBox(me);
	me.refilter(me);
}

void(entity me) gui_rexuiz_maplist_load {
	me.refilter(me);
}

float(entity me, float i) gui_rexuiz_maplist_cache_query {
	return stof(str_sub(me.g_maplistCache, i, 1));
}

void(entity me, float i) gui_rexuiz_maplist_cache_toggle {
	string a, b, c, s, bspname;
	float n;
	s = me.g_maplistCache;
	if not(s)
		return;

	b = str_sub(s, i, 1);
	if (b == "0")
		b = "1";
	else if (b == "1")
		b = "0";
	else
		return; // nothing happens

	a = str_sub(s, 0, i);
	c = str_sub(s, i+1, strlen(s) - (i+1));
	str_unzone_ifneeded(s);
	me.g_maplistCache = str_zone_ifneeded(strcat(a, b, c));
	// TODO also update the actual cvar
	if not((bspname = map_info_bsp_name_by_id(i)))
		return;

	if (b == "1")
		cvar_set("g_maplist", strcat(bspname, " ", cvar_string("g_maplist")));
	else {
		s = "";
		n = tokenize_console(cvar_string("g_maplist"));
		for(i = 0; i < n; ++i)
			if(argv(i) != bspname)
				s = strcat(s, " ", argv(i));

		cvar_set("g_maplist", str_sub(s, 1, strlen(s) - 1));
	}
}

void(entity me) gui_rexuiz_maplist_draw {
	if (me.startButton)
		me.startButton.disabled = ((me.selectedItem < 0) || (me.selectedItem >= me.nItems));

	gui_listbox_draw(me);
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_maplist_resize {
	me.itemAbsSize = '0 0 0';
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin1 = 0.5 * (1 - 2.5 * me.realFontSize_y);
	me.realUpperMargin2 = me.realUpperMargin1 + 1.5 * me.realFontSize_y;
	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = me.itemAbsSize_y / me.itemAbsSize_x * 4 / 3;
	me.columnNameOrigin = me.columnPreviewOrigin + me.columnPreviewSize + me.realFontSize_x;
	me.columnNameSize = 1 - me.columnPreviewSize - 2 * me.realFontSize_x;
	me.checkMarkSize = (eX * (me.itemAbsSize_y / me.itemAbsSize_x) + eY) * 0.5;
	me.checkMarkOrigin = eY + eX * (me.columnPreviewOrigin + me.columnPreviewSize) - me.checkMarkSize;
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_maplist_item_click {
	if (doubleclick) {
		if (where_x >= me.columnNameOrigin)
			if (where_x <= 1) {
				// DOUBLE CLICK!
				// pop up map info screen
				main.mapInfoDialog.loadMapInfo(main.mapInfoDialog, me.selectedItem, me);
				gui_modalcontroller_origin_open_click(NULL, main.mapInfoDialog, me.origin + eX * (me.columnNameOrigin * me.size_x) + eY * ((me.itemHeight * me.selectedItem - me.scrollPos) * me.size_y), eY * me.itemAbsSize_y + eX * (me.itemAbsSize_x * me.columnNameSize));
				return;
			}
	} else {
		if (where_x <= me.columnPreviewOrigin + me.columnPreviewSize) {
			if(where_x >= 0)
				me.g_maplistCacheToggle(me, i);
		}
	}
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_maplist_item_draw {
	// layout: Ping, Map name, Map name, NP, TP, MP
	string s;
	float p = 0;
	float theAlpha;
	float included;
	if (!map_info_get_by_id(i))
		return;

	included = me.g_maplistCacheQuery(me, i);
	if (included || isSelected)
		theAlpha = SKINALPHA_MAPLIST_INCLUDEDFG;
	else
		theAlpha = SKINALPHA_MAPLIST_NOTINCLUDEDFG;

	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(included)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_MAPLIST_INCLUDEDBG, SKINALPHA_MAPLIST_INCLUDEDBG);

	s = ftos(p);
	gui_draw_picture(me.columnPreviewOrigin * eX, strcat("/", map_info_map_image), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	if (included)
		gui_draw_picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);

	s = gui_draw_text_shorten_to_width(strcat(map_info_map_bspname, ": ", map_info_map_title), me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, SKINCOLOR_MAPLIST_TITLE, theAlpha, 0);
	s = gui_draw_text_shorten_to_width(map_info_map_author, me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 1.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, SKINCOLOR_MAPLIST_AUTHOR, theAlpha, 0);
	map_info_clear_temps();
}

void(entity me) gui_rexuiz_maplist_refilter {
	float i, j, n;
	string s;
	float gt;
	gt = game_type_current();
	map_info_filter_game_type(map_info_type_from_game_type(gt), map_info_required_flags(), map_info_forbidden_flags(), 0);
	me.nItems = map_info_count;
	str_unzone_ifneeded(me.g_maplistCache);
	s = "0";
	for (i = 1; i < map_info_count; i *= 2)
		s = strcat(s, s);

	n = tokenize_console(cvar_string("g_maplist"));
	for (i = 0; i < n; ++i) {
		j = map_info_find_name(argv(i));
		if (j >= 0)
			s = strcat(
					str_sub(s, 0, j),
					"1",
					str_sub(s, j+1, map_info_count - (j+1))
					);
	}
	me.g_maplistCache = str_zone_ifneeded(s);
	if (gt != me.lastGametype) {
		me.lastGametype = gt;
		me.setSelected(me, 0);
	}
}

void(entity me, entity cb) gui_rexuiz_maplist_refilter_callback {
	me.refilter(me);
}

void(entity btn, entity me) gui_rexuiz_maplist_all {
	float i;
	string s;
	map_info_filter_game_type(MAP_INFO_TYPE_ALL, 0, MAP_INFO_FLAG_FORBIDDEN, 0); // all
	s = "";
	for (i = 0; i < map_info_count; ++i)
		s = strcat(s, " ", map_info_bsp_name_by_id(i));

	cvar_set("g_maplist", str_sub(s, 1, strlen(s) - 1));
	me.refilter(me);
}

void(entity btn, entity me) gui_rexuiz_maplist_none {
	cvar_set("g_maplist", "");
	me.refilter(me);
}

void(entity btn, entity me) gui_rexuiz_maplist_start {
	string m;
	float i;
	i = me.selectedItem;
	if (btn.parent.instanceOfNexuizMapInfoDialog) {
		i = btn.parent.currentMapIndex;
		gui_dialog_button_close(btn, btn.parent);
	}
	if (i >= me.nItems || i < 0)
		return;

	m = map_info_bsp_name_by_id(i);
	if not(m) {
		print("Huh? Can't play this (m is NULL). Refiltering so this won't happen again.\n");
		return;
	}
	if (map_info_check_map(m)) {
		if (me.isSinglePlayer) {
			cvar_set("sv_public", "-1");
			cvar_set("minplayers", "0");
		} else {
			cvar_set("sv_public", ftos(cvar("menu_public")));
			cvar_set("minplayers", ftos(cvar("menu_minplayers")));
		}
		localcmd("\ndisconnect; wait; g_campaign 0; maxplayers ", ftos(max(max(cvar("bot_number") + 1, cvar("minplayers")), cvar("menu_maxplayers"))), "; g_maplist_shufflenow\n");
		if (cvar("menu_use_default_hostname"))
			localcmd("hostname \"", strdecolorize(cvar_string("_cl_name")), "'s Rexuiz server\"\n");

		map_info_load_map(m);
	} else {
		print("Huh? Can't play this (invalid game type). Refiltering so this won't happen again.\n");
		me.refilter(me);
	}
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_maplist_key_down {
	string ch, save;
	if (scan == VM_K_ENTER) {
		// pop up map info screen
		main.mapInfoDialog.loadMapInfo(main.mapInfoDialog, me.selectedItem, me);
		gui_modalcontroller_origin_open_click(NULL, main.mapInfoDialog, me.origin + eX * (me.columnNameOrigin * me.size_x) + eY * ((me.itemHeight * me.selectedItem - me.scrollPos) * me.size_y), eY * me.itemAbsSize_y + eX * (me.itemAbsSize_x * me.columnNameSize));
	} else if (scan == VM_K_SPACE) {
		me.g_maplistCacheToggle(me, me.selectedItem);
	} else if (ascii == 43) { // +
		if not(me.g_maplistCacheQuery(me, me.selectedItem))
			me.g_maplistCacheToggle(me, me.selectedItem);
	} else if (ascii == 45) { // -
		if(me.g_maplistCacheQuery(me, me.selectedItem))
			me.g_maplistCacheToggle(me, me.selectedItem);
	} else if (scan == VM_K_BACKSPACE) {
		if (time < me.typeToSearchTime) {
			save = str_sub(me.typeToSearchString, 0, strlen(me.typeToSearchString) - 1);
			str_unzone_ifneeded(me.typeToSearchString);
			me.typeToSearchString = str_zone_ifneeded(save);
			me.typeToSearchTime = time + 0.5;
			if (strlen(me.typeToSearchString)) {
				map_info_find_name(me.typeToSearchString);
				if (map_info_find_name_first_result >= 0)
					me.setSelected(me, map_info_find_name_first_result);
			}
		}
	} else if (ascii >= 32 && ascii != 127) {
		ch = chr(ascii);
		if (time > me.typeToSearchTime)
			save = ch;
		else
			save = strcat(me.typeToSearchString, ch);

		str_unzone_ifneeded(me.typeToSearchString);
		me.typeToSearchString = str_zone_ifneeded(save);
		me.typeToSearchTime = time + 0.5;
		map_info_find_name(me.typeToSearchString);
		if (map_info_find_name_first_result >= 0)
			me.setSelected(me, map_info_find_name_first_result);
	} else
		return gui_listbox_key_down(me, scan, ascii, shift);

	return 1;
}
