entity spawnNexuizAdvancedSettingsTab() {
	entity me; me = gui_rexuiz_tab_spawn();
	me.fill = fillNexuizAdvancedSettingsTab;
	me.title = _("Advanced");
	me.intendedWidth = 0.9;
	me.rows = 22;
	me.columns = 6.5;
	me.showNotify = showNotifyNexuizAdvancedSettingsTab;
	me.classname = "NexuizAdvancedSettingsTab";
	return me;
}
entity makeNexuizAdvancedSettingsTab();
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
		me.TD(me, 1, 1, e = gui_rexuiz_checkbox_make(0, "integration_discord_enable", _("Discord status")));
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_checkbox_make(0, "sv_threaded", _("Server thread")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 0.5, 2, e = gui_rexuiz_textlabel_make(0, _("* Good for local game performance, but may be unstable")));
		e.colorL = SKINCOLOR_TEXT_WARNING;
		e.fontSize = e.fontSize * 0.6;
	me.gotoRC(me, 0, 3); me.setFirstColumn(me, me.currentColumn);
	cvarlist = makeNexuizCvarList();
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Cvar filter:")));
		me.TD(me, 1, 0.5, btn = gui_rexuiz_button_make(_("Clear"), '0 0 0'));
		me.TD(me, 1, 1.5, e = gui_rexuiz_inputbox_make(0, NULL));
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
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Setting:")));
		me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, NULL));
				cvarlist.cvarNameBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Type:")));
		me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, NULL));
				cvarlist.cvarTypeBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Value:")));
		me.TD(me, 1, 1, e = gui_rexuiz_inputbox_make(0, NULL));
				cvarlist.cvarValueBox = e;
				e.onChange = CvarList_Value_Change;
				e.onChangeEntity = cvarlist;
		me.TD(me, 1, 1, e = gui_rexuiz_button_make(NULL, SKINCOLOR_CVARLIST_REVERTBUTTON));
				cvarlist.cvarDefaultBox = e;
				e.onClick = CvarList_Revert_Click;
				e.onClickEntity = cvarlist;
				e.allowCut = 1;
				e.marginLeft = e.marginRight = 0.5;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Description:")));
		me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, NULL));
				cvarlist.cvarDescriptionBox = e;
				e.allowWrap = 1;
}
