#ifdef INTERFACE
CLASS(NexuizMapList) EXTENDS(NexuizListBox)
	METHOD(NexuizMapList, configureNexuizMapList, void(entity))
	ATTRIB(NexuizMapList, rowsPerItem, float, 4)
	METHOD(NexuizMapList, draw, void(entity))
	METHOD(NexuizMapList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizMapList, clickListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizMapList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(NexuizMapList, refilter, void(entity))
	METHOD(NexuizMapList, refilterCallback, void(entity, entity))
	METHOD(NexuizMapList, keyDown, float(entity, float, float, float))
	ATTRIB(NexuizMapList, realFontSize, vector, '0 0 0')
	ATTRIB(NexuizMapList, columnPreviewOrigin, float, 0)
	ATTRIB(NexuizMapList, columnPreviewSize, float, 0)
	ATTRIB(NexuizMapList, columnNameOrigin, float, 0)
	ATTRIB(NexuizMapList, columnNameSize, float, 0)
	ATTRIB(NexuizMapList, checkMarkOrigin, vector, '0 0 0')
	ATTRIB(NexuizMapList, checkMarkSize, vector, '0 0 0')
	ATTRIB(NexuizMapList, realUpperMargin1, float, 0)
	ATTRIB(NexuizMapList, realUpperMargin2, float, 0)

	ATTRIB(NexuizMapList, lastGametype, float, 0)
	ATTRIB(NexuizMapList, isSinglePlayer, float, 0)

	ATTRIB(NexuizMapList, origin, vector, '0 0 0')
	ATTRIB(NexuizMapList, itemAbsSize, vector, '0 0 0')

	ATTRIB(NexuizMapList, g_maplistCache, string, NULL)
	METHOD(NexuizMapList, g_maplistCacheToggle, void(entity, float))
	METHOD(NexuizMapList, g_maplistCacheQuery, float(entity, float))

	ATTRIB(NexuizMapList, startButton, entity, NULL)

	METHOD(NexuizMapList, loadCvars, void(entity))

	ATTRIB(NexuizMapList, typeToSearchString, string, NULL)
	ATTRIB(NexuizMapList, typeToSearchTime, float, 0)

	METHOD(NexuizMapList, destroy, void(entity))
ENDCLASS(NexuizMapList)
entity makeNexuizMapList(float single);
void MapList_All(entity btn, entity me);
void MapList_None(entity btn, entity me);
void MapList_LoadMap(entity btn, entity me);
#endif

#ifdef IMPLEMENTATION
void destroyNexuizMapList(entity me)
{
	map_info_shutdown();
}

entity makeNexuizMapList(float single) {
	entity me;
	me = spawnNexuizMapList();
	me.isSinglePlayer = single;
	me.configureNexuizMapList(me);
	return me;
}

void configureNexuizMapListNexuizMapList(entity me)
{
	me.configureNexuizListBox(me);
	me.refilter(me);
}

void loadCvarsNexuizMapList(entity me)
{
	me.refilter(me);
}

float g_maplistCacheQueryNexuizMapList(entity me, float i)
{
	return stof(substring(me.g_maplistCache, i, 1));
}
void g_maplistCacheToggleNexuizMapList(entity me, float i)
{
	string a, b, c, s, bspname;
	float n;
	s = me.g_maplistCache;
	if not(s)
		return;
	b = substring(s, i, 1);
	if(b == "0")
		b = "1";
	else if(b == "1")
		b = "0";
	else
		return; // nothing happens
	a = substring(s, 0, i);
	c = substring(s, i+1, strlen(s) - (i+1));
	strunzone(s);
	me.g_maplistCache = strzone(strcat(a, b, c));
	// TODO also update the actual cvar
	if not((bspname = map_info_bsp_name_by_id(i)))
		return;
	if(b == "1")
		cvar_set("g_maplist", strcat(bspname, " ", cvar_string("g_maplist")));
	else
	{
		s = "";
		n = tokenize_console(cvar_string("g_maplist"));
		for(i = 0; i < n; ++i)
			if(argv(i) != bspname)
				s = strcat(s, " ", argv(i));
		cvar_set("g_maplist", substring(s, 1, strlen(s) - 1));
	}
}

void drawNexuizMapList(entity me)
{
	if(me.startButton)
		me.startButton.disabled = ((me.selectedItem < 0) || (me.selectedItem >= me.nItems));
	drawListBox(me);
}

void resizeNotifyNexuizMapList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

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

void clickListBoxItemNexuizMapList(entity me, float i, vector where, float doubleclick)
{
	if (doubleclick) {
		if(where_x >= me.columnNameOrigin)
			if(where_x <= 1) {
				// DOUBLE CLICK!
				// pop up map info screen
				main.mapInfoDialog.loadMapInfo(main.mapInfoDialog, me.selectedItem, me);
				DialogOpenButton_Click_withCoords(NULL, main.mapInfoDialog, me.origin + eX * (me.columnNameOrigin * me.size_x) + eY * ((me.itemHeight * me.selectedItem - me.scrollPos) * me.size_y), eY * me.itemAbsSize_y + eX * (me.itemAbsSize_x * me.columnNameSize));
				return;
			}
	} else {
		if(where_x <= me.columnPreviewOrigin + me.columnPreviewSize) {
			if(where_x >= 0)
				me.g_maplistCacheToggle(me, i);
		}
	}
}

void drawListBoxItemNexuizMapList(entity me, float i, vector absSize, float isSelected)
{
	// layout: Ping, Map name, Map name, NP, TP, MP
	string s;
	float p = 0;
	float theAlpha;
	float included;
	if (!map_info_get_by_id(i))
		return;

	included = me.g_maplistCacheQuery(me, i);
	if(included || isSelected)
		theAlpha = SKINALPHA_MAPLIST_INCLUDEDFG;
	else
		theAlpha = SKINALPHA_MAPLIST_NOTINCLUDEDFG;

	if(isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(included)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_MAPLIST_INCLUDEDBG, SKINALPHA_MAPLIST_INCLUDEDBG);

	s = ftos(p);
	gui_draw_picture(me.columnPreviewOrigin * eX, strcat("/", map_info_map_image), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	if(included)
		gui_draw_picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);

	s = gui_draw_text_shorten_to_width(strcat(map_info_map_bspname, ": ", map_info_map_title), me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, SKINCOLOR_MAPLIST_TITLE, theAlpha, 0);
	s = gui_draw_text_shorten_to_width(map_info_map_author, me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 1.00 * (me.columnNameSize - gui_text_width(s, 0) * me.realFontSize_x)) * eX, s, me.realFontSize, SKINCOLOR_MAPLIST_AUTHOR, theAlpha, 0);
	map_info_clear_temps();
}

void refilterNexuizMapList(entity me)
{
	float i, j, n;
	string s;
	float gt;
	gt = game_type_current();
	map_info_filter_game_type(map_info_type_from_game_type(gt), map_info_required_flags(), map_info_forbidden_flags(), 0);
	me.nItems = map_info_count;
	if(me.g_maplistCache)
		strunzone(me.g_maplistCache);
	s = "0";
	for(i = 1; i < map_info_count; i *= 2)
		s = strcat(s, s);
	n = tokenize_console(cvar_string("g_maplist"));
	for(i = 0; i < n; ++i)
	{
		j = map_info_find_name(argv(i));
		if(j >= 0)
			s = strcat(
				substring(s, 0, j),
				"1",
				substring(s, j+1, map_info_count - (j+1))
			);
	}
	me.g_maplistCache = strzone(s);
	if(gt != me.lastGametype)
	{
		me.lastGametype = gt;
		me.setSelected(me, 0);
	}
}

void refilterCallbackNexuizMapList(entity me, entity cb)
{
	me.refilter(me);
}

void MapList_All(entity btn, entity me)
{
	float i;
	string s;
	map_info_filter_game_type(MAP_INFO_TYPE_ALL, 0, MAP_INFO_FLAG_FORBIDDEN, 0); // all
	s = "";
	for(i = 0; i < map_info_count; ++i)
		s = strcat(s, " ", map_info_bsp_name_by_id(i));
	cvar_set("g_maplist", substring(s, 1, strlen(s) - 1));
	me.refilter(me);
}

void MapList_None(entity btn, entity me)
{
	cvar_set("g_maplist", "");
	me.refilter(me);
}

void MapList_LoadMap(entity btn, entity me)
{
	string m;
	float i;

	i = me.selectedItem;

	if(btn.parent.instanceOfNexuizMapInfoDialog)
	{
		i = btn.parent.currentMapIndex;
		Dialog_Close(btn, btn.parent);
	}

	if(i >= me.nItems || i < 0)
		return;

	m = map_info_bsp_name_by_id(i);
	if not(m)
	{
		print("Huh? Can't play this (m is NULL). Refiltering so this won't happen again.\n");
		return;
	}
	if(map_info_check_map(m))
	{
		if (me.isSinglePlayer) {
			cvar_set("sv_public", "-1");
			cvar_set("minplayers", "0");
		} else {
			cvar_set("sv_public", ftos(cvar("menu_public")));
			cvar_set("minplayers", ftos(cvar("menu_minplayers")));
		}
		localcmd("\ndisconnect; wait; g_campaign 0; maxplayers ", ftos(max(max(cvar("bot_number") + 1, cvar("minplayers")), cvar("menu_maxplayers"))), "; g_maplist_shufflenow\n");
		if(cvar("menu_use_default_hostname"))
			localcmd("hostname \"", strdecolorize(cvar_string("_cl_name")), "'s Rexuiz server\"\n");
		map_info_load_map(m);
	}
	else
	{
		print("Huh? Can't play this (invalid game type). Refiltering so this won't happen again.\n");
		me.refilter(me);
	}
}

float keyDownNexuizMapList(entity me, float scan, float ascii, float shift)
{
	string ch, save;
	if(scan == K_ENTER)
	{
		// pop up map info screen
		main.mapInfoDialog.loadMapInfo(main.mapInfoDialog, me.selectedItem, me);
		DialogOpenButton_Click_withCoords(NULL, main.mapInfoDialog, me.origin + eX * (me.columnNameOrigin * me.size_x) + eY * ((me.itemHeight * me.selectedItem - me.scrollPos) * me.size_y), eY * me.itemAbsSize_y + eX * (me.itemAbsSize_x * me.columnNameSize));
	}
	else if(scan == K_SPACE)
	{
		me.g_maplistCacheToggle(me, me.selectedItem);
	}
	else if(ascii == 43) // +
	{
		if not(me.g_maplistCacheQuery(me, me.selectedItem))
			me.g_maplistCacheToggle(me, me.selectedItem);
	}
	else if(ascii == 45) // -
	{
		if(me.g_maplistCacheQuery(me, me.selectedItem))
			me.g_maplistCacheToggle(me, me.selectedItem);
	}
	else if(scan == K_BACKSPACE)
	{
		if(time < me.typeToSearchTime)
		{
			save = substring(me.typeToSearchString, 0, strlen(me.typeToSearchString) - 1);
			if(me.typeToSearchString)
				strunzone(me.typeToSearchString);
			me.typeToSearchString = strzone(save);
			me.typeToSearchTime = time + 0.5;
			if(strlen(me.typeToSearchString))
			{
				map_info_find_name(me.typeToSearchString);
				if(map_info_find_name_first_result >= 0)
					me.setSelected(me, map_info_find_name_first_result);
			}
		}
	}
	else if(ascii >= 32 && ascii != 127)
	{
		ch = chr(ascii);
		if(time > me.typeToSearchTime)
			save = ch;
		else
			save = strcat(me.typeToSearchString, ch);
		if(me.typeToSearchString)
			strunzone(me.typeToSearchString);
		me.typeToSearchString = strzone(save);
		me.typeToSearchTime = time + 0.5;
		map_info_find_name(me.typeToSearchString);
		if(map_info_find_name_first_result >= 0)
			me.setSelected(me, map_info_find_name_first_result);
	}
	else
		return keyDownListBox(me, scan, ascii, shift);
	return 1;
}

#endif
