#ifdef INTERFACE
CLASS(NexuizSingleplayerDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizSingleplayerDialog, fill, void(entity))
	ATTRIB(NexuizSingleplayerDialog, title, string, "Singleplayer")
	ATTRIB(NexuizSingleplayerDialog, color, vector, SKINCOLOR_DIALOG_SINGLEPLAYER)
	ATTRIB(NexuizSingleplayerDialog, intendedWidth, float, 0.80)
	ATTRIB(NexuizSingleplayerDialog, rows, float, 24)
	ATTRIB(NexuizSingleplayerDialog, columns, float, 5)
	ATTRIB(NexuizSingleplayerDialog, campaignBox, entity, NULL)
	ATTRIB(NexuizSingleplayerDialog, btnGame, entity, NULL)
ENDCLASS(NexuizSingleplayerDialog)
#endif

#ifdef IMPLEMENTATION

void SwitchTo(entity btn, entity me) {
	entity e;
	for (e = me.btnGame; e; e = e.btnGame) {
		e.forcePressed = 0;
	}
	btn.forcePressed = 1;
	cvar_set("g_campaign_name", btn.cvarName);
	me.campaignBox.loadCvars(me.campaignBox);
}

entity addCampaign(entity me, entity e, string _title, string cfg) {
	if not(file_exists(strcat("maps/campaign", cfg, ".txt")))
		return e;

	me.TD(me, 1, 1.1, e.btnGame = makeNexuizButton(_title, '0 0 0'));
	e = e.btnGame;
	e.cvarName = cfg;
	e.onClick = SwitchTo;
	e.onClickEntity = me;
	return e;
}

void fillNexuizSingleplayerDialog(entity me)
{
	entity e;
	me.TR(me);
		e = addCampaign(me, me, "Classic Campaign", "rexclassic");
		e = addCampaign(me, e, "Survival Campaign", "rexsurvival");
		e = addCampaign(me, e, "Arena Training", "rexuiz");
		e = addCampaign(me, e, "Single Player (Demo)", "spdemo");
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 5, me.columns, me.campaignBox = makeNexuizCampaignList());
	me.gotoRC(me, me.rows - 3, 0);
		me.TD(me, 1, 0.5, makeNexuizTextLabel(0, "Difficulty:"));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "0", "Easy"));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "1", "Medium"));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "2", "Hard"));
		me.TD(me, 1, 0.5, makeNexuizRadioButton(1, "menu_campaign_skill", "3", "Insane"));
		me.TD(me, 1, 2.5, e = makeNexuizButton("Load Game...", '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.saveLoadDialog;

	SwitchTo(me.btnGame, me);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns , e = makeNexuizButton("Start Game!", '0 0 0'));
			e.onClick = CampaignList_LoadMap;
			e.onClickEntity = me.campaignBox;
}
#endif
