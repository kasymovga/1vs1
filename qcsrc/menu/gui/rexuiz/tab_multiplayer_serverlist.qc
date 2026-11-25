void(entity me) gui_rexuiz_tab_multiplayer_serverlist_show;
void(entity me) gui_rexuiz_tab_multiplayer_serverlist_fill;
float(entity me, float scan, float ascii, float shift) gui_rexuiz_tab_multiplayer_serverlist_key_down;

entity(void) gui_rexuiz_tab_multiplayer_serverlist_spawn {
	entity me; me = gui_rexuiz_tab_spawn();
	me.fill = gui_rexuiz_tab_multiplayer_serverlist_fill;
	me.title = _("Join");
	me.intendedWidth = 0.9;
	me.rows = 22;
	me.columns = 6.5;
	me.showNotify = gui_rexuiz_tab_multiplayer_serverlist_show;
	me.keyDown = gui_rexuiz_tab_multiplayer_serverlist_key_down;
	me.classname = "NexuizServerListTab";
	return me;
}

entity(void) gui_rexuiz_tab_multiplayer_serverlist_make {
	entity me = gui_rexuiz_tab_multiplayer_serverlist_spawn();
	me.configureDialog(me);
	return me;
}

float gui_rexuiz_tab_multiplayer_serverlist_refresh_next;
void(entity me, entity ignore) gui_rexuiz_tab_multiplayer_serverlist_refresh {
	if (gui_rexuiz_tab_multiplayer_serverlist_refresh_next > time) return;
	gui_rexuiz_tab_multiplayer_serverlist_refresh_next = time + 5;
	refreshhostcache();
}

float gui_rexuiz_tab_multiplayer_serverlist_reload_next;
void(entity me, entity ignore) gui_rexuiz_tab_multiplayer_serverlist_reload {
	if (gui_rexuiz_tab_multiplayer_serverlist_reload_next > time) return;
	gui_rexuiz_tab_multiplayer_serverlist_reload_next = time + 1;
	localcmd("net_slist\n");
	serverlist_reload();
}

void(entity me) gui_rexuiz_tab_multiplayer_serverlist_show {
	gui_rexuiz_tab_multiplayer_serverlist_refresh(me, NULL);
}

float(entity me, float scan, float ascii, float shift) gui_rexuiz_tab_multiplayer_serverlist_key_down {
	if (scan == 'r' && (shift & GUI_KEY_STATE_CTRL)) {
		if (shift & GUI_KEY_STATE_SHIFT)
			gui_rexuiz_tab_multiplayer_serverlist_reload(me, NULL);
		else
			gui_rexuiz_tab_multiplayer_serverlist_refresh(me, NULL);

		return TRUE;
	}
	return gui_container_key_down(me, scan, ascii, shift);
}

void(entity me) gui_rexuiz_tab_multiplayer_serverlist_fill {
	entity e, slist, btn;
	slist = gui_rexuiz_serverlist_make();
	me.TR(me);
		me.TD(me, 1, 0.75, btn = gui_rexuiz_button_make(_("Refresh"), '0 0 0'));
			btn.onClick = gui_rexuiz_tab_multiplayer_serverlist_refresh;
		me.TD(me, 1, 0.75, btn = gui_rexuiz_button_make(_("Reload"), '0 0 0'));
			btn.onClick = gui_rexuiz_tab_multiplayer_serverlist_reload;
		me.TD(me, 1, 0.5, e = gui_rexuiz_textlabel_make(0, _("Filter:")));
		me.TD(me, 1, me.columns - 4, e = gui_rexuiz_inputbox_make(0, NULL));
			e.onChange = gui_rexuiz_serverlist_filter_change;
			e.onChangeEntity = slist;
			slist.controlledTextbox = e;
		me.TD(me, 1, 0.5, btn = gui_rexuiz_button_make(_("Clear"), '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
			btn.onClickEntity = e;
		me.TD(me, 1, 0.5, e = gui_rexuiz_checkbox_make(0, "menu_slist_showempty", _("Empty")));
			slist.filterShowEmpty = e.checked;
			e.onClickEntity = slist;
			e.onClick = gui_rexuiz_serverlist_show_empty_click;
		me.TD(me, 1, 0.5, e = gui_rexuiz_checkbox_make(0, "menu_slist_showfull", _("Full")));
			slist.filterShowFull = e.checked;
			e.onClickEntity = slist;
			e.onClick = gui_rexuiz_serverlist_show_full_click;
		me.TD(me, 1, 0.5, e = gui_rexuiz_checkbox_make(0, "net_slist_pause", _("Pause")));
	me.TR(me);
		me.TD(me, 1, 1, slist.sortButton1 = gui_rexuiz_button_make(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton2 = gui_rexuiz_button_make(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton3 = gui_rexuiz_button_make(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton4 = gui_rexuiz_button_make(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton5 = gui_rexuiz_button_make(NULL, '0 0 0'));
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, slist);
	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, 0.6, e = gui_rexuiz_textlabel_make(0, _("Address:")));
		me.TD(me, 1, 2.9, e = gui_rexuiz_inputbox_make(0, NULL));
			e.onEnter = gui_rexuiz_serverlist_connect_click;
			e.onEnterEntity = slist;
			slist.ipAddressBox = e;
		me.TD(me, 1, 1.5, e = gui_rexuiz_button_make("", '0 0 0'));
			e.onClick = gui_rexuiz_serverlist_favorite_click;
			e.onClickEntity = slist;
			slist.favoriteButton = e;
		me.TD(me, 1, 1.5, e = gui_rexuiz_button_make(_("Info"), '0 0 0'));
			e.onClick = gui_rexuiz_serverlist_info_click;
			e.onClickEntity = slist;
			slist.infoButton = e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Join!"), '0 0 0'));
			e.onClick = gui_rexuiz_serverlist_connect_click;
			e.onClickEntity = slist;
			slist.connectButton = e;
}
