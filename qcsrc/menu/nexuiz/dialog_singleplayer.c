#ifdef INTERFACE
CLASS(NexuizSingleplayerDialog) EXTENDS(NexuizDialog)
	METHOD(NexuizSingleplayerDialog, fill, void(entity))
	ATTRIB(NexuizSingleplayerDialog, title, string, "Singleplayer")
	ATTRIB(NexuizSingleplayerDialog, color, vector, SKINCOLOR_DIALOG_SINGLEPLAYER)
	ATTRIB(NexuizSingleplayerDialog, intendedWidth, float, 0.80)
	ATTRIB(NexuizSingleplayerDialog, rows, float, 24)
	ATTRIB(NexuizSingleplayerDialog, columns, float, 5)
	ATTRIB(NexuizSingleplayerDialog, campaignBox, entity, NULL)
	ATTRIB(NexuizSingleplayerDialog, btnSurv, entity, NULL)
	ATTRIB(NexuizSingleplayerDialog, btnAT, entity, NULL)
	ATTRIB(NexuizSingleplayerDialog, btnSP, entity, NULL)
ENDCLASS(NexuizSingleplayerDialog)
#endif

#ifdef IMPLEMENTATION

void SwitchTo(entity btn, entity me) {
	me.btnSurv.forcePressed = 0;
	me.btnAT.forcePressed = 0;
	btn.forcePressed = 1;
	if (btn == me.btnSurv)
		cvar_set("g_campaign_name", "rexsurvival");
	else if (btn == me.btnAT)
		cvar_set("g_campaign_name", "rexuiz");
	else
		cvar_set("g_campaign_name", "spdemo");

	me.campaignBox.loadCvars(me.campaignBox);
}

void fillNexuizSingleplayerDialog(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 1.5, me.btnSurv = makeNexuizButton("Survival Campaign", '0 0 0'));
		me.btnSurv.onClick = SwitchTo;
		me.btnSurv.onClickEntity = me;
		me.TD(me, 1, 1.5, me.btnAT = makeNexuizButton("Arena Training", '0 0 0'));
		me.btnAT.onClick = SwitchTo;
		me.btnAT.onClickEntity = me;
		me.TD(me, 1, 1.5, me.btnSP = makeNexuizButton("Single Player (Demo)", '0 0 0'));
		me.btnSP.onClick = SwitchTo;
		me.btnSP.onClickEntity = me;
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, me.campaignBox = makeNexuizCampaignList());
	SwitchTo(me.btnSurv, me);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns , e = makeNexuizButton("Start Game!", '0 0 0'));
			e.onClick = CampaignList_LoadMap;
			e.onClickEntity = me.campaignBox;
}
#endif
