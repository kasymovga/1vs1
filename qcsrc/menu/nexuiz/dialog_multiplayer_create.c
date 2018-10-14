#ifdef INTERFACE
CLASS(NexuizServerCreateTab) EXTENDS(NexuizTab)
	METHOD(NexuizServerCreateTab, fill, void(entity))
	METHOD(NexuizServerCreateTab, gameTypeChangeNotify, void(entity))
	ATTRIB(NexuizServerCreateTab, title, string, "Create")
	ATTRIB(NexuizServerCreateTab, intendedWidth, float, 0.9)
	ATTRIB(NexuizServerCreateTab, rows, float, 22)
	ATTRIB(NexuizServerCreateTab, columns, float, 6.5)

	ATTRIB(NexuizServerCreateTab, mapListBox, entity, NULL)
	ATTRIB(NexuizServerCreateTab, sliderFraglimit, entity, NULL)
	ATTRIB(NexuizServerCreateTab, sliderTimelimit, entity, NULL)
	ATTRIB(NexuizServerCreateTab, checkboxFraglimit, entity, NULL)
	ATTRIB(NexuizServerCreateTab, checkboxFraglimitMapinfo, entity, NULL)
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
	for (i = GAME_DEATHMATCH; i < GAME_SINGLE; i++) {
		if (mod(i - 1, n) == 0)
			me.TR(me);

		me.TD(me, 1, me.columns / n, e = makeNexuizGametypeButton(1, MapInfo_GetGameTypeCvar(i), MapInfo_HumanString_FromType(i)));
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
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, "Map list:"));
			makeCallback(e, me.mapListBox, me.mapListBox.refilterCallback);
	me.TR(me);
		me.TD(me, me.rows - 8, 3, me.mapListBox);
	me.gotoRC(me, me.rows - 3, 0);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1, e = makeNexuizButton("All", '0 0 0'));
			e.onClick = MapList_All;
			e.onClickEntity = me.mapListBox;
		me.TD(me, 1, 1, e = makeNexuizButton("None", '0 0 0'));
			e.onClick = MapList_None;
			e.onClickEntity = me.mapListBox;
		me.TDempty(me, 0.5);

	me.gotoRC(me, 3, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, "Match settings:"));
	me.TR(me);
		me.sliderTimelimit = makeNexuizSlider(1.0, 60.0, 0.5, "timelimit_override");
		me.TD(me, 1, 1, e = makeNexuizSliderCheckBox(0, 1, me.sliderTimelimit, "Time limit:"));
		me.TD(me, 1, 2, me.sliderTimelimit);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeNexuizSliderCheckBox(-1, 0, me.sliderTimelimit, "Use map specified default"));
	me.TR(me);
		me.sliderFraglimit = makeNexuizSlider(1.0, 2000.0, 5, "fraglimit_override");
		me.TD(me, 1, 1, e = makeNexuizSliderCheckBox(0, 1, me.sliderFraglimit, "Point limit:"));
			me.checkboxFraglimit = e;
		me.TD(me, 1, 2, me.sliderFraglimit);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeNexuizSliderCheckBox(-1, 0, me.sliderFraglimit, "Use map specified default"));
			me.checkboxFraglimitMapinfo = e;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Player slots:"));
		me.TD(me, 1, 2, makeNexuizSlider(1, 32, 1, "menu_maxplayers"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Number of bots:"));
		me.TD(me, 1, 2, makeNexuizSlider(0, 9, 1, "bot_number"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeNexuizTextLabel(0, "Bot skill:"));
			setDependent(e, "bot_number", 0, -1);
		me.TD(me, 1, 2, e = makeNexuizTextSlider("skill"));
			e.addValue(e, "Botlike", "0");
			e.addValue(e, "Beginner", "4");
			e.addValue(e, "You will win", "8");
			e.addValue(e, "You can win", "12");
			e.addValue(e, "You might win", "16");
			e.addValue(e, "Advanced", "20");
			e.addValue(e, "Expert", "24");
			e.addValue(e, "Pro", "28");
			e.addValue(e, "Assassin", "32");
			e.addValue(e, "Unhuman", "36");
			e.addValue(e, "Godlike", "40");
			e.configureNexuizTextSliderValues(e);
			setDependent(e, "bot_number", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeNexuizTextLabel(0, "Bot names:"));
		me.TD(me, 1, 0.7, e = makeNexuizInputBox(1, "bot_prefix"));
			setDependent(e, "bot_number", 0, -1);
		me.TD(me, 1, 0.6, e = makeNexuizTextLabel(0.5, "Shadow"));
			setDependent(e, "bot_number", 0, -1);
		me.TD(me, 1, 0.7, e = makeNexuizInputBox(1, "bot_suffix"));
			setDependent(e, "bot_number", 0, -1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, "Map voting:"));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("g_maplist_votable"));
			e.addValue(e, "No voting", "0");
			e.addValue(e, "2 choices", "2");
			e.addValue(e, "3 choices", "3");
			e.addValue(e, "4 choices", "4");
			e.addValue(e, "5 choices", "5");
			e.addValue(e, "6 choices", "6");
			e.addValue(e, "7 choices", "7");
			e.addValue(e, "8 choices", "8");
			e.addValue(e, "9 choices", "9");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBoxEx(0.5, 0, "sv_vote_simple_majority_factor", "Simple majority wins vcall"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeNexuizButton("Advanced settings...", '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.advancedDialog;
			main.advancedDialog.refilterEntity = me.mapListBox;
		me.TR(me);
		me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizButton("Mutators...", '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.mutatorsDialog;
			main.mutatorsDialog.refilterEntity = me.mapListBox;
		me.TD(me, 1, 2, e = makeNexuizTextLabel(0, string_null));
			e.textEntity = main.mutatorsDialog;
			e.allowCut = 1;

	me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, 2, e = makeNexuizModButton("Multiplayer_Create"));
		me.TD(me, 1, me.columns, e = makeNexuizButton("Start Multiplayer!", '0 0 0'));
			e.onClick = MapList_LoadMap;
			e.onClickEntity = me.mapListBox;
			me.mapListBox.startButton = e;

	me.gameTypeChangeNotify(me);
}

void GameType_ConfigureSliders(entity e, entity l, entity l2, string pLabel, float pMin, float pMax, float pStep, string pCvar)
{
	if(pCvar == "")
	{
		e.configureNexuizSlider(e, pMin, pMax, pStep, string_null);
		l.setText(l, pLabel);
		e.disabled = l.disabled = l2.disabled = TRUE;
	}
	else
	{
		e.configureNexuizSlider(e, pMin, pMax, pStep, pCvar);
		l.setText(l, pLabel);
		e.disabled = l.disabled = l2.disabled = FALSE;
	}
}

void gameTypeChangeNotifyNexuizServerCreateTab(entity me)
{
	// tell the map list to update
	float gt;
	entity e, l, l2;
	gt = MapInfo_CurrentGametype();
	e = me.sliderFraglimit;
	l = me.checkboxFraglimit;
	l2 = me.checkboxFraglimitMapinfo;
	switch(gt)
	{
		case GAME_CATF:
		case GAME_CTFT:            GameType_ConfigureSliders(e, l, l2, "Win limit:",   1,   20,  1, "capturelimit_override");    break;
		case GAME_CTF:             GameType_ConfigureSliders(e, l, l2, "Capture limit:",   1,   20,  1, "capturelimit_override");    break;
		case GAME_DOMINATION:      GameType_ConfigureSliders(e, l, l2, "Point limit:",    50,  500, 10, "g_domination_point_limit"); break;
		case GAME_KEYHUNT:         GameType_ConfigureSliders(e, l, l2, "Point limit:",   200, 1500, 50, "g_keyhunt_point_limit");    break;
		case GAME_KEYHUNT_CA:      GameType_ConfigureSliders(e, l, l2, "Win limit:",   1, 30, 1, "g_khca_point_limit");    break;
		case GAME_KEYHUNT_FT:      GameType_ConfigureSliders(e, l, l2, "Win limit:",   1, 30, 1, "g_khft_point_limit");    break;
		case GAME_RUNEMATCH:       GameType_ConfigureSliders(e, l, l2, "Point limit:",    50,  500, 10, "g_runematch_point_limit");  break;
		case GAME_RACE:            GameType_ConfigureSliders(e, l, l2, "Laps:",            1,   25,  1, "g_race_laps_limit");        break;
		case GAME_NEXBALL:         GameType_ConfigureSliders(e, l, l2, "Goals:",           1,   50,  1, "g_nexball_goallimit");      break;
		case GAME_ONSLAUGHT:       GameType_ConfigureSliders(e, l, l2, "Point limit:",    50,  500, 10, "");                         break;
		case GAME_CTS:             GameType_ConfigureSliders(e, l, l2, "Point limit:",    50,  500, 10, "");                         break;
		case GAME_FREEZETAG:       GameType_ConfigureSliders(e, l, l2, "Win limit:",       1,   50,  1, "g_freeze_winlimit");        break;
		case GAME_CLANARENA:       GameType_ConfigureSliders(e, l, l2, "Win limit:",       1,   50,  1, "g_clanarena_winlimit");     break;
		case GAME_TEAM_DEATHMATCH: GameType_ConfigureSliders(e, l, l2, "Frag limit:",      5,  200,  5, "g_tdm_fraglimit");          break;
		default:                           GameType_ConfigureSliders(e, l, l2, "Frag limit:",      5,  100,  5, "fraglimit_override");       break;
	}
	me.mapListBox.refilter(me.mapListBox);
}

#endif
