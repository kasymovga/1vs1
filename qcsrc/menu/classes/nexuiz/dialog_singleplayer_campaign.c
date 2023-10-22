#ifdef INTERFACE
CLASS(NexuizCampaignTab) EXTENDS(NexuizTab)
	METHOD(NexuizCampaignTab, fill, void(entity))
	ATTRIB(NexuizCampaignTab, title, string, _("Campaign"))
	ATTRIB(NexuizSingleplayerDialog, campaignBox, entity, NULL)
	ATTRIB(NexuizSingleplayerDialog, btnGame, entity, NULL)
	ATTRIB(NexuizServerCreateTab, rows, float, 22)
	ATTRIB(NexuizServerCreateTab, columns, float, 5)
ENDCLASS(NexuizCampaignTab)
entity makeNexuizCampaignTab();
#endif

#ifdef IMPLEMENTATION
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
	me.TD(me, 1, 1.1, e.btnGame = makeNexuizButton(_title, '0 0 0'));
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
		me.TD(me, me.rows - 6, me.columns, me.campaignBox = makeNexuizCampaignList());
	me.gotoRC(me, me.rows - 4, 0);
		me.TD(me, 1, 0.5, makeNexuizTextLabel(0, _("Difficulty:")));
	me.TR(me);
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "-1", _("Easiest")));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "0", _("Easy")));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "1", _("Medium")));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "2", _("Hard")));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "3", _("Insane")));
		me.TD(me, 1, 2.5, e = makeNexuizButton(_("Load Game..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.saveLoadDialog;

	switchTo(me.btnGame, me);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns , e = makeNexuizButton(_("Start Game!"), '0 0 0'));
			e.onClick = CampaignList_LoadMap;
			e.onClickEntity = me.campaignBox;
}
#endif
