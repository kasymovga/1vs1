#ifdef INTERFACE
CLASS(NexuizAdvancedSettingsTab) EXTENDS(NexuizTab)
	METHOD(NexuizAdvancedSettingsTab, fill, void(entity))
	ATTRIB(NexuizAdvancedSettingsTab, title, string, _("Advanced"))
	ATTRIB(NexuizAdvancedSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizAdvancedSettingsTab, rows, float, 22)
	ATTRIB(NexuizAdvancedSettingsTab, columns, float, 6.5)
	METHOD(NexuizAdvancedSettingsTab, showNotify, void(entity))
ENDCLASS(NexuizAdvancedSettingsTab)
entity makeNexuizAdvancedSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity() makeNexuizAdvancedSettingsTab {
	entity me;
	me = spawnNexuizAdvancedSettingsTab();
	me.configureDialog(me);
	return me;
}

void(entity me) showNotifyNexuizAdvancedSettingsTab {
	gui_load_all_cvars(me);
}

void(entity me) fillNexuizAdvancedSettingsTab {
	entity e, cvarlist, btn;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "integration_discord_enable", _("Discord status")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizCheckBox(0, "sv_threaded", _("Server thread")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 0.5, 2, e = makeNexuizTextLabel(0, _("* Good for local game performance, but may be unstable")));
		e.colorL = SKINCOLOR_TEXT_WARNING;
		e.fontSize = e.fontSize * 0.6;
	me.gotoRC(me, 0, 3); me.setFirstColumn(me, me.currentColumn);
	cvarlist = makeNexuizCvarList();
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Cvar filter:")));
		me.TD(me, 1, 0.5, btn = makeNexuizButton(_("Clear"), '0 0 0'));
		me.TD(me, 1, 1.5, e = makeNexuizInputBox(0, NULL));
			e.onChange = CvarList_Filter_Change;
			e.onChangeEntity = cvarlist;
			btn.onClick = InputBox_Clear_Click;
			btn.onClickEntity = e;
			cvarlist.controlledTextbox = e; // this COULD also be the Value box, but this leads to accidentally editing stuff
	me.TR(me);
		me.TD(me, 8, 3, cvarlist);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Setting:")));
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, NULL));
			cvarlist.cvarNameBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Type:")));
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, NULL));
			cvarlist.cvarTypeBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Value:")));
		me.TD(me, 1, 1, e = makeNexuizInputBox(0, NULL));
			cvarlist.cvarValueBox = e;
			e.onChange = CvarList_Value_Change;
			e.onChangeEntity = cvarlist;
		me.TD(me, 1, 1, e = makeNexuizButton(NULL, SKINCOLOR_CVARLIST_REVERTBUTTON));
			cvarlist.cvarDefaultBox = e;
			e.onClick = CvarList_Revert_Click;
			e.onClickEntity = cvarlist;
			e.allowCut = 1;
			e.marginLeft = e.marginRight = 0.5;
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Description:")));
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, NULL));
			cvarlist.cvarDescriptionBox = e;
			e.allowWrap = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
