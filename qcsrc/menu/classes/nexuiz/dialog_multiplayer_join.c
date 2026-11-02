#ifdef INTERFACE
CLASS(NexuizServerListTab) EXTENDS(NexuizTab)
	METHOD(NexuizServerListTab, fill, void(entity))
	ATTRIB(NexuizServerListTab, title, string, _("Join"))
	ATTRIB(NexuizServerListTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizServerListTab, rows, float, 22)
	ATTRIB(NexuizServerListTab, columns, float, 6.5)
	METHOD(NexuizServerListTab, showNotify, void(entity))
	METHOD(NexuizServerListTab, keyDown, float(entity me, float scan, float ascii, float shift))
ENDCLASS(NexuizServerListTab)
entity makeNexuizServerListTab();
#endif

#ifdef IMPLEMENTATION

entity makeNexuizServerListTab()
{
	entity me;
	me = spawnNexuizServerListTab();
	me.configureDialog(me);
	return me;
}

void(entity me, entity ignore) refreshNexuizServerListTab {
	refreshhostcache();
}

void(entity me, entity ignore) reloadNexuizServerListTab {
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
	slist  = makeNexuizServerList();
	me.TR(me);
		me.TD(me, 1, 0.75, btn = makeNexuizButton(_("Refresh"), '0 0 0'));
			btn.onClick = refreshNexuizServerListTab;
		me.TD(me, 1, 0.75, btn = makeNexuizButton(_("Reload"), '0 0 0'));
			btn.onClick = reloadNexuizServerListTab;
		me.TD(me, 1, 0.5, e = makeNexuizTextLabel(0, _("Filter:")));
		me.TD(me, 1, me.columns - 4, e = makeNexuizInputBox(0, NULL));
			e.onChange = ServerList_Filter_Change;
			e.onChangeEntity = slist;
			slist.controlledTextbox = e;
		me.TD(me, 1, 0.5, btn = makeNexuizButton(_("Clear"), '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
			btn.onClickEntity = e;
		me.TD(me, 1, 0.5, e = makeNexuizCheckBox(0, "menu_slist_showempty", _("Empty")));
			slist.filterShowEmpty = e.checked;
			e.onClickEntity = slist;
			e.onClick = ServerList_ShowEmpty_Click;
		me.TD(me, 1, 0.5, e = makeNexuizCheckBox(0, "menu_slist_showfull", _("Full")));
			slist.filterShowFull = e.checked;
			e.onClickEntity = slist;
			e.onClick = ServerList_ShowFull_Click;
		me.TD(me, 1, 0.5, e = makeNexuizCheckBox(0, "net_slist_pause", _("Pause")));

	me.TR(me);
		me.TD(me, 1, 1, slist.sortButton1 = makeNexuizButton(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton2 = makeNexuizButton(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton3 = makeNexuizButton(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton4 = makeNexuizButton(NULL, '0 0 0'));
		me.TD(me, 1, 1, slist.sortButton5 = makeNexuizButton(NULL, '0 0 0'));
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, slist);

	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, 0.6, e = makeNexuizTextLabel(0, _("Address:")));
		me.TD(me, 1, 2.9, e = makeNexuizInputBox(0, NULL));
			e.onEnter = ServerList_Connect_Click;
			e.onEnterEntity = slist;
			slist.ipAddressBox = e;
		me.TD(me, 1, 1.5, e = makeNexuizButton("", '0 0 0'));
			e.onClick = ServerList_Favorite_Click;
			e.onClickEntity = slist;
			slist.favoriteButton = e;
		me.TD(me, 1, 1.5, e = makeNexuizButton(_("Info"), '0 0 0'));
			e.onClick = ServerList_Info_Click;
			e.onClickEntity = slist;
			slist.infoButton = e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Join!"), '0 0 0'));
			e.onClick = ServerList_Connect_Click;
			e.onClickEntity = slist;
			slist.connectButton = e;
}
#endif
