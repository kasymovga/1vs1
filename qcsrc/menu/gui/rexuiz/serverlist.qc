void(entity me) gui_rexuiz_serverlist_configure;
void(entity me, float i) gui_rexuiz_serverlist_select;
void(entity me, float mode) gui_rexuiz_serverlist_refresh;
void(entity me) gui_rexuiz_serverlist_focus_enter;
void(entity me) gui_rexuiz_serverlist_draw;
void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_serverlist_item_draw;
void(entity me, float i, vector where, float doubleclick) gui_rexuiz_serverlist_item_click;
void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_serverlist_resize;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_serverlist_key_down;
void(entity me, float field, float direction) gui_rexuiz_serverlist_sort_order_set;
void(entity me, entity btn, float theOrigin, float theSize, string theTitle, void(entity, entity) theFunc) gui_rexuiz_serverlist_sort_button_position;

entity(void) gui_rexuiz_serverlist_spawn {
	entity me = gui_rexuiz_listbox_spawn();
	me.configureNexuizServerList = gui_rexuiz_serverlist_configure;
	me.rowsPerItem = 1;
	me.draw = gui_rexuiz_serverlist_draw;
	me.drawListBoxItem = gui_rexuiz_serverlist_item_draw;
	me.clickListBoxItem = gui_rexuiz_serverlist_item_click;
	me.resizeNotify = gui_rexuiz_serverlist_resize;
	me.keyDown = gui_rexuiz_serverlist_key_down;
	me.realFontSize = '0 0 0';
	me.realUpperMargin = 0;
	me.columnPingOrigin = 0;
	me.columnPingSize = 0;
	me.columnNameOrigin = 0;
	me.columnNameSize = 0;
	me.columnMapOrigin = 0;
	me.columnMapSize = 0;
	me.columnTypeOrigin = 0;
	me.columnTypeSize = 0;
	me.columnPlayersOrigin = 0;
	me.columnPlayersSize = 0;
	me.selectedServer = NULL; // to restore selected server when needed
	me.setSelected = gui_rexuiz_serverlist_select;
	me.setSortOrder = gui_rexuiz_serverlist_sort_order_set;
	me.filterShowEmpty = 1;
	me.filterShowFull = 1;
	me.filterString = NULL;
	me.controlledTextbox = NULL;
	me.ipAddressBox = NULL;
	me.favoriteButton = NULL;
	me.nextRefreshTime = 0;
	me.refreshServerList = gui_rexuiz_serverlist_refresh; // refresh mode: 0 = just reparametrize, 1 = send new requests, 2 = clear
	me.needsRefresh = 1;
	me.focusEnter = gui_rexuiz_serverlist_focus_enter;
	me.positionSortButton = gui_rexuiz_serverlist_sort_button_position;
	me.sortButton1 = NULL;
	me.sortButton2 = NULL;
	me.sortButton3 = NULL;
	me.sortButton4 = NULL;
	me.sortButton5 = NULL;
	me.connectButton = NULL;
	me.infoButton = NULL;
	me.currentSortOrder = 0;
	me.currentSortField = -1;
	me.ipAddressBoxFocused = -1;
	me.classname = "NexuizServerList";
	return me;
}

float(string srv) gui_rexuiz_serverlist_is_favorite {
	float i, n;
	srv = netaddress_resolve(srv, 26000);
	n = tokenize_console(cvar_string("net_slist_favorites"));
	for (i = 0; i < n; ++i)
		if (srv == netaddress_resolve(argv(i), 26000))
			return TRUE;

	return FALSE;
}

void(string srv) gui_rexuiz_serverlist_favorite_toggle {
	string s, s0, s1, s2, srv_resolved;
	float i, n;
	srv_resolved = netaddress_resolve(srv, 26000);
	s = cvar_string("net_slist_favorites");
	n = tokenize_console(s);
	for (i = 0; i < n; ++i)
		if (srv_resolved == netaddress_resolve(argv(i), 26000)) {
			s0 = s1 = s2 = "";
			if (i > 0)
				s0 = str_sub(s, 0, argv_end_index(i - 1));

			if (i < n-1)
				s2 = str_sub(s, argv_start_index(i + 1), -1);

			if (s0 != "" && s2 != "")
				s1 = " ";

			print("s0 = >>", s0, "<<\ns1 = >>", s1, "<<\ns2 = >>", s2, "<<\n");
			cvar_set("net_slist_favorites", strcat(s0, s1, s2));
			return;
		}
	s1 = "";
	if(s != "")
		s1 = " ";

	cvar_set("net_slist_favorites", strcat(s, " ", srv));
	resorthostcache();
}

entity(void) gui_rexuiz_serverlist_make {
	entity me;
	me = gui_rexuiz_serverlist_spawn();
	me.configureNexuizServerList(me);
	return me;
}

void(entity me) gui_rexuiz_serverlist_configure {
	serverlist_fields_update();
	me.configureNexuizListBox(me);
	me.nItems = 0;
}

void(entity me, float i) gui_rexuiz_serverlist_select {
	float save;
	save = me.selectedItem;
	gui_listbox_select(me, i);
	/*
	if(me.selectedItem == save)
		return;
	*/
	if (me.nItems == 0)
		return;

	if (gethostcachevalue(VM_SLIST_HOSTCACHEVIEWCOUNT) != me.nItems)
		return; // sorry, it would be wrong

	str_unzone_ifneeded(me.selectedServer);
	me.selectedServer = str_zone_ifneeded(gethostcachestring(SERVERLIST_FIELD_CNAME, me.selectedItem));
	me.ipAddressBox.setText(me.ipAddressBox, me.selectedServer);
	me.ipAddressBox.cursorPos = strlen(me.selectedServer);
	me.ipAddressBoxFocused = -1;
}

void(entity me, float mode) gui_rexuiz_serverlist_refresh {
	// 0: just reparametrize
	// 1: also ask for new servers
	// 2: clear
	//print("refresh of type ", ftos(mode), "\n");
	/* if(mode == 2) // borken
	{
		// clear list
		localcmd("net_slist\n");
		me.needsRefresh = 1; // net_slist kills sort order, so we need to restore it later
	}
	else */
	{
		float m, o;
		string s, typestr;
		s = me.filterString;
		m = strstrofs(s, ":", 0);
		if (m >= 0) {
			typestr = str_sub(s, 0, m);
			s = str_sub(s, m + 1, strlen(s) - m - 1);
			while (str_sub(s, 0, 1) == " ")
				s = str_sub(s, 1, strlen(s) - 1);
		} else
			typestr = "";

		m = VM_SLIST_MASK_AND - 1;
		resethostcachemasks();
		if (!me.filterShowFull)
			sethostcachemasknumber(++m, SERVERLIST_FIELD_FREESLOTS, 1, VM_SLIST_TEST_GREATEREQUAL);

		if (!me.filterShowEmpty)
			sethostcachemasknumber(++m, SERVERLIST_FIELD_NUMHUMANS, 1, VM_SLIST_TEST_GREATEREQUAL);

		if (typestr != "")
			sethostcachemaskstring(++m, SERVERLIST_FIELD_QCSTATUS, strcat(typestr, ":"), VM_SLIST_TEST_STARTSWITH);

		m = VM_SLIST_MASK_OR - 1;
		if (s != "") {
			sethostcachemaskstring(++m, SERVERLIST_FIELD_NAME, s, VM_SLIST_TEST_CONTAINS);
			sethostcachemaskstring(++m, SERVERLIST_FIELD_MAP, s, VM_SLIST_TEST_CONTAINS);
			sethostcachemaskstring(++m, SERVERLIST_FIELD_PLAYERS, s, VM_SLIST_TEST_CONTAINS);
			sethostcachemaskstring(++m, SERVERLIST_FIELD_QCSTATUS, strcat(s, ":"), VM_SLIST_TEST_STARTSWITH);
		}
		o = 2; // favorites first
		if (me.currentSortOrder < 0)
			o |= 1; // descending

		sethostcachesort(me.currentSortField, o);
		resorthostcache();
		if (mode >= 1) {
			refreshhostcache();
			if (cvar("sv_udppunchhole")) {
				s = cvar_string("sv_udppunchhole_server");
				if (s != "") {
					extresponse_query(s, "extResponse udppunchhole request");
				}
			}
		}
	}
}

void(entity me) gui_rexuiz_serverlist_focus_enter {
	if (time < me.nextRefreshTime) {
		//print("sorry, no refresh yet\n");
		return;
	}
	me.nextRefreshTime = time + 10;
	me.refreshServerList(me, 1);
}

void(entity me) gui_rexuiz_serverlist_draw {
	float i, found, owned;
	if (me.currentSortField == -1) {
		me.setSortOrder(me, SERVERLIST_FIELD_NUMHUMANS, -1);
		me.refreshServerList(me, 2);
	} else if (me.needsRefresh == 1) {
		me.needsRefresh = 2; // delay by one frame to make sure "slist" has been executed
	} else if (me.needsRefresh == 2) {
		me.needsRefresh = 0;
		me.refreshServerList(me, 0);
	}
	owned = ((me.selectedServer == me.ipAddressBox.text) && (me.ipAddressBox.text != ""));
	float n = gethostcachevalue(VM_SLIST_HOSTCACHEVIEWCOUNT);
	if (me.nItems != n) {
		me.nItems = n;
		gui_rexuiz_serverlist_refresh(me, 0);
	}
	me.connectButton.disabled = ((me.nItems == 0) && (me.ipAddressBox.text == ""));
	me.infoButton.disabled = ((me.nItems == 0) || !owned);
	found = 0;
	if (me.selectedServer) {
		for (i = 0; i < me.nItems; ++i)
			if (gethostcachestring(SERVERLIST_FIELD_CNAME, i) == me.selectedServer) {
			if (i != me.selectedItem) {
				me.selectedItem = i;
			}
			found = 1;
			break;
		}
	}
	if (!found)
		if (me.nItems > 0) {
			if (me.selectedItem >= me.nItems)
				me.selectedItem = me.nItems - 1;

			str_unzone_ifneeded(me.selectedServer);
			me.selectedServer = str_zone_ifneeded(gethostcachestring(SERVERLIST_FIELD_CNAME, me.selectedItem));
		}
	if (owned) {
		if (me.selectedServer != me.ipAddressBox.text) {
			me.ipAddressBox.setText(me.ipAddressBox, me.selectedServer);
			me.ipAddressBox.cursorPos = strlen(me.selectedServer);
			me.ipAddressBoxFocused = -1;
		}
	}
	if (me.ipAddressBoxFocused != me.ipAddressBox.focused) {
		if (me.ipAddressBox.focused || me.ipAddressBoxFocused < 0) {
			if (gui_rexuiz_serverlist_is_favorite(me.ipAddressBox.text))
				me.favoriteButton.setText(me.favoriteButton, _("Remove"));
			else
				me.favoriteButton.setText(me.favoriteButton, _("Bookmark"));
		}
		me.ipAddressBoxFocused = me.ipAddressBox.focused;
	}
	gui_listbox_draw(me);
}

void(entity btn, entity me) gui_rexuiz_serverlist_sort_ping_click {
	me.setSortOrder(me, SERVERLIST_FIELD_PING, +1);
}

void(entity btn, entity me) gui_rexuiz_serverlist_sort_name_click {
	me.setSortOrder(me, SERVERLIST_FIELD_NAME, -1); // why?
}

void(entity btn, entity me) gui_rexuiz_serverlist_sort_map_click {
	me.setSortOrder(me, SERVERLIST_FIELD_MAP, -1); // why?
}

void(entity btn, entity me) gui_rexuiz_serverlist_sort_player_click {
	me.setSortOrder(me, SERVERLIST_FIELD_NUMHUMANS, -1);
}

void(entity btn, entity me) gui_rexuiz_serverlist_sort_type_click {
	string s, t;
	float i, m;
	s = me.filterString;
	m = strstrofs(s, ":", 0);
	if (m >= 0) {
		s = str_sub(s, 0, m);
		while (str_sub(s, m+1, 1) == " ") // skip spaces
				++m;
	} else
		s = "";

	for (i = 1; ; ++i) { // 20 modes ought to be enough for anyone
		t = game_type_name(i);
		if (i > 1)
			if (t == game_type_name(0)) { // it repeats (default case)
			// no type was found
			// choose the first one
				s = t;
				break;
			}
		if (s == game_type_name(i)) {
			// the type was found
			// choose the next one
			s = game_type_name(i + 1);
			if(s == game_type_name(0))
				s = "";

			break;
		}
	}
	if (s != "")
		s = strcat(s, ":");

	s = strcat(s, str_sub(me.filterString, m+1, strlen(me.filterString) - m - 1));
	me.controlledTextbox.setText(me.controlledTextbox, s);
	me.controlledTextbox.keyDown(me.controlledTextbox, VM_K_END, 0, 0);
	me.controlledTextbox.keyUp(me.controlledTextbox, VM_K_END, 0, 0);
	//gui_rexuiz_serverlist_filter_change(me.controlledTextbox, me);
}

void(entity box, entity me) gui_rexuiz_serverlist_filter_change {
	str_unzone_ifneeded(me.filterString);
	if (box.text != "")
		me.filterString = str_zone_ifneeded(box.text);
	else
		me.filterString = NULL;

	me.refreshServerList(me, 0);
	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}

void(entity box, entity me) gui_rexuiz_serverlist_show_empty_click {
	box.setChecked(box, me.filterShowEmpty = !me.filterShowEmpty);
	me.refreshServerList(me, 0);
	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}

void(entity box, entity me) gui_rexuiz_serverlist_show_full_click {
	box.setChecked(box, me.filterShowFull = !me.filterShowFull);
	me.refreshServerList(me, 0);
	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}

void(entity me, float field, float direction) gui_rexuiz_serverlist_sort_order_set {
	if (me.currentSortField == field)
		direction = -me.currentSortOrder;

	me.currentSortOrder = direction;
	me.currentSortField = field;
	me.sortButton1.forcePressed = (field == SERVERLIST_FIELD_PING);
	me.sortButton2.forcePressed = (field == SERVERLIST_FIELD_NAME);
	me.sortButton3.forcePressed = (field == SERVERLIST_FIELD_MAP);
	me.sortButton4.forcePressed = 0;
	me.sortButton5.forcePressed = (field == SERVERLIST_FIELD_NUMHUMANS);
	me.selectedItem = 0;
	str_unzone_ifneeded(me.selectedServer);
	me.selectedServer = NULL;
	me.refreshServerList(me, 0);
}

void(entity me, entity btn, float theOrigin, float theSize, string theTitle, void(entity, entity) theFunc) gui_rexuiz_serverlist_sort_button_position {
	vector originInLBSpace, sizeInLBSpace;
	originInLBSpace = eY * (-me.itemHeight);
	sizeInLBSpace = eY * me.itemHeight + eX * (1 - me.controlWidth);
	vector originInDialogSpace, sizeInDialogSpace;
	originInDialogSpace = gui_box_to_global(originInLBSpace, me.Container_origin, me.Container_size);
	sizeInDialogSpace = gui_box_to_global_size(sizeInLBSpace, me.Container_size);
	btn.Container_origin_x = originInDialogSpace_x + sizeInDialogSpace_x * theOrigin;
	btn.Container_size_x = sizeInDialogSpace_x * theSize;
	btn.setText(btn, theTitle);
	btn.onClick = theFunc;
	btn.onClickEntity = me;
	btn.resized = 1;
}

void(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize) gui_rexuiz_serverlist_resize {
	gui_rexuiz_listbox_resize(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
	me.columnPingOrigin = 0;
	me.columnPingSize = me.realFontSize_x * 4;
	me.columnMapSize = me.realFontSize_x * 12;
	me.columnTypeSize = me.realFontSize_x * 4;
	me.columnPlayersSize = me.realFontSize_x * 6;
	me.columnNameSize = 1 - me.columnPlayersSize - me.columnMapSize - me.columnPingSize - me.columnTypeSize - 4 * me.realFontSize_x;
	me.columnNameOrigin = me.columnPingOrigin + me.columnPingSize + me.realFontSize_x;
	me.columnMapOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize_x;
	me.columnTypeOrigin = me.columnMapOrigin + me.columnMapSize + me.realFontSize_x;
	me.columnPlayersOrigin = me.columnTypeOrigin + me.columnTypeSize + me.realFontSize_x;
	me.positionSortButton(me, me.sortButton1, me.columnPingOrigin, me.columnPingSize, _("Ping"), gui_rexuiz_serverlist_sort_ping_click);
	me.positionSortButton(me, me.sortButton2, me.columnNameOrigin, me.columnNameSize, _("Host name"), gui_rexuiz_serverlist_sort_name_click);
	me.positionSortButton(me, me.sortButton3, me.columnMapOrigin, me.columnMapSize, _("Map"), gui_rexuiz_serverlist_sort_map_click);
	me.positionSortButton(me, me.sortButton4, me.columnTypeOrigin, me.columnTypeSize, _("Type"), gui_rexuiz_serverlist_sort_type_click);
	me.positionSortButton(me, me.sortButton5, me.columnPlayersOrigin, me.columnPlayersSize, _("Players"), gui_rexuiz_serverlist_sort_player_click);
	float f;
	f = me.currentSortField;
	if (f >= 0) {
		me.currentSortField = -1;
		me.setSortOrder(me, f, me.currentSortOrder); // force resetting the sort order
	}
}

void(entity btn, entity me) gui_rexuiz_serverlist_connect_click {
	if (me.ipAddressBox.text == "")
		localcmd("connect ", me.selectedServer, "\n");
	else
		localcmd("connect ", me.ipAddressBox.text, "\n");
}

void(entity btn, entity me) gui_rexuiz_serverlist_favorite_click {
	string ipstr;
	ipstr = netaddress_resolve(me.ipAddressBox.text, 26000);
	if (ipstr != "") {
		gui_rexuiz_serverlist_favorite_toggle(me.ipAddressBox.text);
		me.ipAddressBoxFocused = -1;
	}
}

void(entity btn, entity me) gui_rexuiz_serverlist_info_click {
	me.onClickEntity.loadServerInfo(me.onClickEntity, me.selectedItem);
	gui_modalcontroller_open_click(me, main.serverInfoDialog);
}

void(entity me, float i, vector where, float doubleclick) gui_rexuiz_serverlist_item_click {
	if (doubleclick)
		gui_rexuiz_serverlist_connect_click(NULL, me);
}

void(entity me, float i, vector absSize, float isSelected) gui_rexuiz_serverlist_item_draw {
	// layout: Ping, Server name, Map name, NP, TP, MP
	string s;
	float p;
	vector theColor;
	float theAlpha;
	if (isSelected)
		gui_draw_fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	if (gethostcachenumber(SERVERLIST_FIELD_NUMPLAYERS, i) >= gethostcachenumber(SERVERLIST_FIELD_MAXPLAYERS, i))
		theAlpha = SKINALPHA_SERVERLIST_FULL;
	else if not(gethostcachenumber(SERVERLIST_FIELD_NUMHUMANS, i))
		theAlpha = SKINALPHA_SERVERLIST_EMPTY;
	else
		theAlpha = 1;

	p = gethostcachenumber(SERVERLIST_FIELD_PING, i);
	if (p < 75)
		theColor = SKINCOLOR_SERVERLIST_LOWPING + (SKINCOLOR_SERVERLIST_MEDPING - SKINCOLOR_SERVERLIST_LOWPING) * (p / 75);
	else if (p < 200)
		theColor = SKINCOLOR_SERVERLIST_MEDPING + (SKINCOLOR_SERVERLIST_HIGHPING - SKINCOLOR_SERVERLIST_MEDPING) * ((p - 75) / (200 - 75));
	else if (p < 500) {
		theColor = SKINCOLOR_SERVERLIST_HIGHPING;
		theAlpha *= 1 + (SKINALPHA_SERVERLIST_HIGHPING - 1) * ((p - 200) / (500 - 200));
	} else {
		theColor = eX;
		theAlpha *= SKINALPHA_SERVERLIST_HIGHPING;
	}
	if (gethostcachenumber(SERVERLIST_FIELD_ISFAVORITE, i)) {
		theColor = theColor * (1 - SKINALPHA_SERVERLIST_FAVORITE) + SKINCOLOR_SERVERLIST_FAVORITE * SKINALPHA_SERVERLIST_FAVORITE;
		theAlpha = theAlpha * (1 - SKINALPHA_SERVERLIST_FAVORITE) + SKINALPHA_SERVERLIST_FAVORITE;
	}
	s = ftos(p);
	gui_draw_text(me.realUpperMargin * eY + (me.columnPingSize - gui_text_width(s, 0) * me.realFontSize_x) * eX, s, me.realFontSize, theColor, theAlpha, 0);
	s = gui_draw_text_shorten_to_width(gethostcachestring(SERVERLIST_FIELD_NAME, i), me.columnNameSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);
	s = gui_draw_text_shorten_to_width(gethostcachestring(SERVERLIST_FIELD_MAP, i), me.columnMapSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin * eY + (me.columnMapOrigin + (me.columnMapSize - gui_text_width(s, 0) * me.realFontSize_x) * 0.5) * eX, s, me.realFontSize, theColor, theAlpha, 0);
	s = gethostcachestring(SERVERLIST_FIELD_QCSTATUS, i);
	p = strstrofs(s, ":", 0);
	if (p >= 0)
		s = str_sub(s, 0, p);
	else
		s = "";

	s = gui_draw_text_shorten_to_width(s, me.columnMapSize / me.realFontSize_x, 0);
	gui_draw_text(me.realUpperMargin * eY + (me.columnTypeOrigin + (me.columnTypeSize - gui_text_width(s, 0) * me.realFontSize_x) * 0.5) * eX, s, me.realFontSize, theColor, theAlpha, 0);
	s = strcat(ftos(gethostcachenumber(SERVERLIST_FIELD_NUMHUMANS, i)), "/", ftos(gethostcachenumber(SERVERLIST_FIELD_MAXPLAYERS, i)));
	gui_draw_text(me.realUpperMargin * eY + (me.columnPlayersOrigin + (me.columnPlayersSize - gui_text_width(s, 0) * me.realFontSize_x) * 0.5) * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_serverlist_key_down {
	float i;
	vector org, sz;
	org = gui_box_to_global(eY * (me.selectedItem * me.itemHeight - me.scrollPos), me.origin, me.size);
	sz = gui_box_to_global_size(eY * me.itemHeight + eX * (1 - me.controlWidth), me.size);
	if (scan == VM_K_ENTER) {
		gui_rexuiz_serverlist_connect_click(NULL, me);
		return 1;
	} else if (scan == VM_K_MOUSE2 || scan == VM_K_SPACE) {
		main.serverInfoDialog.loadServerInfo(main.serverInfoDialog, me.selectedItem);
		gui_modalcontroller_origin_open_click(me, main.serverInfoDialog, org, sz);
	} else if (scan == VM_K_INS || scan == VM_K_MOUSE3) {
		i = me.selectedItem;
		if (i < me.nItems) {
			gui_rexuiz_serverlist_favorite_toggle(me.selectedServer);
			me.ipAddressBoxFocused = -1;
		}
	} else if (gui_listbox_key_down(me, scan, ascii, shift))
		return 1;
	else if (!me.controlledTextbox)
		return 0;
	else
		return me.controlledTextbox.keyDown(me.controlledTextbox, scan, ascii, shift);

	return 0;
}
