entity spawnNexuizCampaignTab() {
	entity me; me = gui_rexuiz_tab_spawn();
	me.fill = fillNexuizCampaignTab;
	me.title = _("Campaign");
	me.campaignBox = NULL;
	me.btnGame = NULL;
	me.rows = 22;
	me.columns = 5;
	me.intendedWidth = 5;
	me.classname = "NexuizCampaignTab";
	return me;
}
entity makeNexuizCampaignTab();
void switchTo(entity btn, entity me) {
	entity e;
	for (e = me.btnGame; e; e = e.btnGame) {
		e.forcePressed = 0;
	}
	btn.forcePressed = 1;
	cvar_set("g_campaign_name", btn.cvarName);
	me.campaignBox.loadCvars(me.campaignBox);
}
entity addCampaign(entity me, entity e, string _title, string cfg) {
	me.TD(me, 1, 1.1, e.btnGame = gui_rexuiz_button_make(_title, '0 0 0'));
	e = e.btnGame;
	e.cvarName = cfg;
	e.onClick = switchTo;
	e.onClickEntity = me;
	return e;
}
entity makeNexuizCampaignTab() {
	entity me;
	me = spawnNexuizCampaignTab();
	me.configureDialog(me);
	return me;
}
void fillNexuizCampaignTab(entity me) {
	entity e;
	me.TR(me);
		e = addCampaign(me, me, _("Classic Campaign"), "rexclassic");
		e = addCampaign(me, e, _("Survival Campaign"), "rexsurvival");
		e = addCampaign(me, e, _("Arena Training"), "rexuiz");
		e = addCampaign(me, e, _("Single Player (Demo)"), "spdemo");
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 6, me.columns, me.campaignBox = gui_rexuiz_campaign_make());
	me.gotoRC(me, me.rows - 4, 0);
		me.TD(me, 1, 0.5, gui_rexuiz_textlabel_make(0, _("Difficulty:")));
	me.TR(me);
		me.TD(me, 1, 0.7, gui_rexuiz_radiobutton_make(1, "menu_campaign_skill", "-1", _("Easiest")));
		me.TD(me, 1, 0.7, gui_rexuiz_radiobutton_make(1, "menu_campaign_skill", "0", _("Easy")));
		me.TD(me, 1, 0.7, gui_rexuiz_radiobutton_make(1, "menu_campaign_skill", "1", _("Medium")));
		me.TD(me, 1, 0.7, gui_rexuiz_radiobutton_make(1, "menu_campaign_skill", "2", _("Hard")));
		me.TD(me, 1, 0.7, gui_rexuiz_radiobutton_make(1, "menu_campaign_skill", "3", _("Insane")));
		me.TD(me, 1, 1.5, e = gui_rexuiz_button_make(_("Load Game..."), '0 0 0'));
				e.onClick = DialogOpenButton_Click;
				e.onClickEntity = main.saveLoadDialog;
	switchTo(me.btnGame, me);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns , e = gui_rexuiz_button_make(_("Start Game!"), '0 0 0'));
				e.onClick = gui_rexuiz_campaign_map_load;
				e.onClickEntity = me.campaignBox;
}
