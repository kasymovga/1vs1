entity spawnNexuizServerListTab() {
	entity me; me = spawnNexuizTab();
	me.fill = fillNexuizServerListTab;
	me.title = _("Join");
	me.intendedWidth = 0.9;
	me.rows = 22;
	me.columns = 6.5;
	me.showNotify = showNotifyNexuizServerListTab;
	me.keyDown = keyDownNexuizServerListTab;
	me.classname = "NexuizServerListTab";
	return me;
}
entity makeNexuizServerListTab();
entity makeNexuizServerListTab()
{
	entity me;
	me = spawnNexuizServerListTab();
	me.configureDialog(me);
	return me;
}
float refreshNexuizServerListTab_next;
void(entity me, entity ignore) refreshNexuizServerListTab {
	if (refreshNexuizServerListTab_next > time) return;
	refreshNexuizServerListTab_next = time + 5;
	refreshhostcache();
}
float reloadNexuizServerListTab_next;
void(entity me, entity ignore) reloadNexuizServerListTab {
	if (reloadNexuizServerListTab_next > time) return;
	reloadNexuizServerListTab_next = time + 1;
	localcmd("net_slist\n");
	serverlist_reload();
}
void(entity me) showNotifyNexuizServerListTab {
	refreshNexuizServerListTab(me, NULL);
}
float(entity me, float scan, float ascii, float shift) keyDownNexuizServerListTab {
	if (scan == 'r' && (shift & GUI_KEY_STATE_CTRL)) {
		if (shift & GUI_KEY_STATE_SHIFT)
				reloadNexuizServerListTab(me, NULL);
		else
				refreshNexuizServerListTab(me, NULL);
		return TRUE;
	}
	return keyDownContainer(me, scan, ascii, shift);
}
void fillNexuizServerListTab(entity me)
{
	entity e, slist, btn;
	slist = makeNexuizServerList();
	me.TR(me);
		me.TD(me, 1, 0.75, btn = gui_rexuiz_button_make(_("Refresh"), '0 0 0'));
				btn.onClick = refreshNexuizServerListTab;
		me.TD(me, 1, 0.75, btn = gui_rexuiz_button_make(_("Reload"), '0 0 0'));
				btn.onClick = reloadNexuizServerListTab;
		me.TD(me, 1, 0.5, e = gui_rexuiz_textlabel_make(0, _("Filter:")));
		me.TD(me, 1, me.columns - 4, e = gui_rexuiz_inputbox_make(0, NULL));
				e.onChange = ServerList_Filter_Change;
				e.onChangeEntity = slist;
				slist.controlledTextbox = e;
		me.TD(me, 1, 0.5, btn = gui_rexuiz_button_make(_("Clear"), '0 0 0'));
				btn.onClick = InputBox_Clear_Click;
				btn.onClickEntity = e;
		me.TD(me, 1, 0.5, e = gui_rexuiz_checkbox_make(0, "menu_slist_showempty", _("Empty")));
				slist.filterShowEmpty = e.checked;
				e.onClickEntity = slist;
				e.onClick = ServerList_ShowEmpty_Click;
		me.TD(me, 1, 0.5, e = gui_rexuiz_checkbox_make(0, "menu_slist_showfull", _("Full")));
				slist.filterShowFull = e.checked;
				e.onClickEntity = slist;
				e.onClick = ServerList_ShowFull_Click;
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
				e.onEnter = ServerList_Connect_Click;
				e.onEnterEntity = slist;
				slist.ipAddressBox = e;
		me.TD(me, 1, 1.5, e = gui_rexuiz_button_make("", '0 0 0'));
				e.onClick = ServerList_Favorite_Click;
				e.onClickEntity = slist;
				slist.favoriteButton = e;
		me.TD(me, 1, 1.5, e = gui_rexuiz_button_make(_("Info"), '0 0 0'));
				e.onClick = ServerList_Info_Click;
				e.onClickEntity = slist;
				slist.infoButton = e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Join!"), '0 0 0'));
				e.onClick = ServerList_Connect_Click;
				e.onClickEntity = slist;
				slist.connectButton = e;
}
