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
		me.TD(me, 1, 3, e = makeNexuizTextLabel(0, _("Match settings:")));
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
		me.TD(me, 1, 2, makeNexuizSlider(1, 32, 1, "menu_maxplayers"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Number of bots:")));
		me.TD(me, 1, 2, makeNexuizSlider(0, 9, 1, "bot_number"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeNexuizTextLabel(0, _("Bot skill:")));
			setDependent(e, "bot_number", 0, -1);
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
			setDependent(e, "bot_number", 0, -1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeNexuizTextLabel(0, _("Bot names:")));
		me.TD(me, 1, 0.7, e = makeNexuizInputBox(1, "bot_prefix"));
			setDependent(e, "bot_number", 0, -1);
		me.TD(me, 1, 0.6, e = makeNexuizTextLabel(0.5, "Shadow"));
			setDependent(e, "bot_number", 0, -1);
		me.TD(me, 1, 0.7, e = makeNexuizInputBox(1, "bot_suffix"));
			setDependent(e, "bot_number", 0, -1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeNexuizTextLabel(0, _("Map voting:")));
		me.TD(me, 1, 2, e = makeNexuizTextSlider("g_maplist_votable"));
			e.addValue(e, _("No voting"), "0");
			e.addValue(e, _("2 choices"), "2");
			e.addValue(e, _("3 choices"), "3");
			e.addValue(e, _("4 choices"), "4");
			e.addValue(e, _("5 choices"), "5");
			e.addValue(e, _("6 choices"), "6");
			e.addValue(e, _("7 choices"), "7");
			e.addValue(e, _("8 choices"), "8");
			e.addValue(e, _("9 choices"), "9");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizCheckBoxEx(0.5, 0, "sv_vote_simple_majority_factor", _("Simple majority wins vcall")));
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
	gt = MapInfo_CurrentGametype();
	e = me.sliderFraglimit;
	l = me.checkboxFraglimit;
	switch(gt)
	{
		case GAME_CATF:            GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   20,  1, "g_catf_scorelimit");    break;
		case GAME_CTFT:            GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   20,  1, "g_ctft_scorelimit");    break;
		case GAME_CTF:             GameType_ConfigureSliders(e, l, _("Capture limit:"),   1,   20,  1, "c_ctf_scorelimit");     break;
		case GAME_DOMINATION:      GameType_ConfigureSliders(e, l, _("Point limit:"),    50,  500, 10, "g_dom_scorelimit");     break;
		case GAME_KEYHUNT:         GameType_ConfigureSliders(e, l, _("Point limit:"),   200, 1500, 50, "g_kh_scorelimit");      break;
		case GAME_KEYHUNT_CA:      GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   30,  1, "g_khca_scorelimit");    break;
		case GAME_KEYHUNT_FT:      GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   30,  1, "g_khft_scorelimit");    break;
		case GAME_RACE:            GameType_ConfigureSliders(e, l, _("Laps:"),            1,   25,  1, "g_race_scorelimit");    break;
		case GAME_NEXBALL:         GameType_ConfigureSliders(e, l, _("Goals:"),           1,   50,  1, "g_nexball_scorelimit"); break;
		case GAME_ONSLAUGHT:       GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_CTS:             GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_FREEZETAG:       GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   50,  1, "g_ft_scorelimit");      break;
		case GAME_CLANARENA:       GameType_ConfigureSliders(e, l, _("Win limit:"),       1,   50,  1, "g_ca_scorelimit");      break;
		case GAME_SURVIVE:         GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_COOP:            GameType_ConfigureSliders(e, l, _("Point limit:"),     1,   50,  1, "");                     break;
		case GAME_TEAM_DEATHMATCH: GameType_ConfigureSliders(e, l, _("Frag limit:"),      5,  200,  5, "g_tdm_scorelimit");     break;
		default:                   GameType_ConfigureSliders(e, l, _("Frag limit:"),      5,  100,  5, "g_scorelimit");         break;
	}
	me.mapListBox.refilter(me.mapListBox);
}

#endif
