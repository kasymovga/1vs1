#ifdef INTERFACE
CLASS(NexuizServerCreateTab) EXTENDS(NexuizTab)
	METHOD(NexuizServerCreateTab, fill, void(entity))
	METHOD(NexuizServerCreateTab, gameTypeChangeNotify, void(entity))
	ATTRIB(NexuizServerCreateTab, title, string, _("Create"))
	ATTRIB(NexuizServerCreateTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizServerCreateTab, rows, float, 22)
	ATTRIB(NexuizServerCreateTab, columns, float, 6.5)

	ATTRIB(NexuizServerCreateTab, mapListBox, entity, NULL)
	ATTRIB(NexuizServerCreateTab, sliderFraglimit, entity, NULL)
	ATTRIB(NexuizServerCreateTab, sliderTimelimit, entity, NULL)
	ATTRIB(NexuizServerCreateTab, checkboxFraglimit, entity, NULL)
ENDCLASS(NexuizServerCreateTab)
entity makeNexuizServerCreateTab();
#endif

#ifdef IMPLEMENTATION

entity makeNexuizServerCreateTab()
{
	entity me;
	me = spawnNexuizServerCreateTab();
	me.configureDialog(me);
	return me;
}

void fillNexuizServerCreateTab(entity me)
{
	entity e, selected;
	float n;

	float i;
	n = 6;
	selected = NULL;
	for (i = GAME_TYPE_DEATHMATCH; i < GAME_TYPE_SINGLE; i++) {
		if (mod(i - 1, n) == 0)
			me.TR(me);

		me.TD(me, 1, me.columns / n, e = makeNexuizGametypeButton(1, game_type_name(i), game_type_name_long(i)));
			if not(selected)
				selected = e;
			else if(e.checked)
				selected = e;
	}
	if(selected)
	{
		//print("NO CHECK\n");
		selected.setChecked(selected, 1);
	}
	me.TR(me);
	me.TR(me);
		me.mapListBox = makeNexuizMapList();
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Map list:")));
			gui_make_callback(e, me.mapListBox, me.mapListBox.refilterCallback);
	me.TR(me);
		me.TD(me, me.rows - 9, 3, me.mapListBox);
	me.gotoRC(me, me.rows - 3, 0);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1, e = makeNexuizButton(_("All"), '0 0 0'));
			e.onClick = MapList_All;
			e.onClickEntity = me.mapListBox;
		me.TD(me, 1, 1, e = makeNexuizButton(_("None"), '0 0 0'));
			e.onClick = MapList_None;
			e.onClickEntity = me.mapListBox;
		me.TDempty(me, 0.5);

	me.gotoRC(me, 4, 3.5); me.setFirstColumn(me, me.currentColumn);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Match settings:")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Server mode:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("sv_public"));
			e.addValue(e, _("Single player"), "-1");
			e.addValue(e, _("Private"), "0");
			e.addValue(e, _("Public"), "1");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.sliderTimelimit = makeNexuizSlider(1.0, 60.0, 0.5, "g_timelimit");
		me.TD(me, 1, 1, e = makeNexuizSliderCheckBox(0, 1, me.sliderTimelimit, _("Time limit:")));
		me.TD(me, 1, 2, me.sliderTimelimit);
	me.TR(me);
		me.sliderFraglimit = makeNexuizSlider(1.0, 2000.0, 5, "g_scorelimit");
		me.TD(me, 1, 1, e = makeNexuizSliderCheckBox(0, 1, me.sliderFraglimit, _("Point limit:")));
			me.checkboxFraglimit = e;
		me.TD(me, 1, 2, me.sliderFraglimit);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Player slots:")));
		me.TD(me, 1, 2, makeNexuizSlider(1, 64, 1, "menu_maxplayers"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Minimal amount of human and bots:")));
	me.TR(me);
		me.TDempty(me, 1);
		me.TD(me, 1, 2, makeNexuizSlider(0, 32, 1, "minplayers"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Additional number of bots:")));
	me.TR(me);
		me.TDempty(me, 1);
		me.TD(me, 1, 2, makeNexuizSlider(0, 32, 1, "bot_number"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeNexuizTextLabel(0, _("Bot skill:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("skill"));
			e.addValue(e, _("Botlike"), "0");
			e.addValue(e, _("Beginner"), "4");
			e.addValue(e, _("You will win"), "8");
			e.addValue(e, _("You can win"), "12");
			e.addValue(e, _("You might win"), "16");
			e.addValue(e, _("Advanced"), "20");
			e.addValue(e, _("Expert"), "24");
			e.addValue(e, _("Pro"), "28");
			e.addValue(e, _("Assassin"), "32");
			e.addValue(e, _("Unhuman"), "36");
			e.addValue(e, _("Godlike"), "40");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeNexuizButton(_("Advanced settings..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.advancedDialog;
			main.advancedDialog.refilterEntity = me.mapListBox;
		me.TR(me);
		me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizButton(_("Mutators..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.mutatorsDialog;
			main.mutatorsDialog.refilterEntity = me.mapListBox;
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, NULL));
			e.textEntity = main.mutatorsDialog;
			e.allowCut = 1;

	me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, 2, e = makeNexuizModButton("Multiplayer_Create"));
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Start Multiplayer!"), '0 0 0'));
			e.onClick = MapList_LoadMap;
			e.onClickEntity = me.mapListBox;
			me.mapListBox.startButton = e;

	me.gameTypeChangeNotify(me);
}

void GameType_ConfigureSliders(entity e, entity l, string pLabel, float pMin, float pMax, float pStep, string pCvar)
{
	if(pCvar == "")
	{
		e.configureNexuizSlider(e, pMin, pMax, pStep, NULL);
		l.setText(l, pLabel);
		e.disabled = l.disabled = TRUE;
	}
	else
	{
		e.configureNexuizSlider(e, pMin, pMax, pStep, pCvar);
		l.setText(l, pLabel);
		e.disabled = l.disabled = FALSE;
	}
}

void gameTypeChangeNotifyNexuizServerCreateTab(entity me)
{
	// tell the map list to update
	float gt;
	entity e, l;
	gt = game_type_current();
	e = me.sliderFraglimit;
	l = me.checkboxFraglimit;
	switch(gt)
	{
		case GAME_TYPE_CATF:            GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   20,  1, "g_catf_scorelimit");    break;
		case GAME_TYPE_CTFT:            GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   20,  1, "g_ctft_scorelimit");    break;
		case GAME_TYPE_CTF:             GameType_ConfigureSliders(e, l, _("Capture limit:"),   1,   20,  1, "c_ctf_scorelimit");     break;
		case GAME_TYPE_DOMINATION:      GameType_ConfigureSliders(e, l, _("Point limit:"),    50,  500, 10, "g_dom_scorelimit");     break;
		case GAME_TYPE_KEYHUNT:         GameType_ConfigureSliders(e, l, _("Point limit:"),   200, 1500, 50, "g_kh_scorelimit");      break;
		case GAME_TYPE_KEYHUNT_CA:      GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   30,  1, "g_khca_scorelimit");    break;
		case GAME_TYPE_KEYHUNT_FT:      GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   30,  1, "g_khft_scorelimit");    break;
		case GAME_TYPE_RACE:            GameType_ConfigureSliders(e, l, _("Laps:"),            1,   25,  1, "g_race_scorelimit");    break;
		case GAME_TYPE_NEXBALL:         GameType_ConfigureSliders(e, l, _("Goals:"),           1,   50,  1, "g_nexball_scorelimit"); break;
		case GAME_TYPE_ONSLAUGHT:       GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_TYPE_CTS:             GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_TYPE_FREEZETAG:       GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   50,  1, "g_ft_scorelimit");      break;
		case GAME_TYPE_CLANARENA:       GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   50,  1, "g_ca_scorelimit");      break;
		case GAME_TYPE_SURVIVE:         GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_TYPE_COOP:            GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_TYPE_SHOOTINGRANGE:   GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_TYPE_TEAM_DEATHMATCH: GameType_ConfigureSliders(e, l, _("Frag limit:"),      5,  200,  5, "g_tdm_scorelimit");     break;
		default:                   GameType_ConfigureSliders(e, l, _("Frag limit:"),      5,  100,  5, "g_scorelimit");         break;
	}
	me.mapListBox.refilter(me.mapListBox);
}

#endif
