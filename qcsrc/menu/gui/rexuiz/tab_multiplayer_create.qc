void(entity me) rexuiz_gui_tab_multiplayer_create_fill;
void(entity me) rexuiz_gui_tab_multiplayer_create_type_change;

entity(void) rexuiz_gui_tab_multiplayer_create_spawn {
	entity me = gui_rexuiz_tab_spawn();
	me.fill = rexuiz_gui_tab_multiplayer_create_fill;
	me.gameTypeChangeNotify = rexuiz_gui_tab_multiplayer_create_type_change;
	me.title = _("Create");
	me.intendedWidth = 0.9;
	me.rows = 22;
	me.columns = 6.5;
	me.isSinglePlayer = 0;
	me.mapListBox = NULL;
	me.sliderFraglimit = NULL;
	me.sliderTimelimit = NULL;
	me.sliderTeams = NULL;
	me.checkboxFraglimit = NULL;
	me.classname = "NexuizServerCreateTab";
	return me;
}

entity(float single) rexuiz_gui_tab_multiplayer_create_make {
	entity me;
	me = rexuiz_gui_tab_multiplayer_create_spawn();
	me.isSinglePlayer = single;
	me.configureDialog(me);
	return me;
}

void(entity input, entity ignore) nexuizServerCreateTabPINCodeOnChange {
	float i, n = strlen(input.text);
	for (i = 0; i < n; i++) {
		if (strstrofs("0123456789", str_sub(input.text, i, 1), 0) < 0) {
				gui_inputbox_set(input, strcat(str_sub(input.text, 0, i), str_sub(input.text, i + 1, -1)));
				n = strlen(input.text);
				i--;
		}
	}
}

void(entity me) rexuiz_gui_tab_multiplayer_create_fill {
	entity e, selected;
	float n;
	float i;
	n = 6;
	selected = NULL;
	for (i = GAME_TYPE_DEATHMATCH; i < GAME_TYPE_SINGLE; i++) {
		if (mod(i - 1, n) == 0)
			me.TR(me);

		me.TD(me, 1, me.columns / n, e = gui_rexuiz_gametypebutton_make(1, game_type_name(i), game_type_name_long(i)));
			if not(selected)
				selected = e;
			else if(e.checked)
				selected = e;
	}
	if (selected) {
		//print("NO CHECK\n");
		selected.setChecked(selected, 1);
	}
	me.TR(me);
	me.TR(me);
		me.mapListBox = gui_rexuiz_maplist_make(me.isSinglePlayer);
		me.TD(me, 1, 3, e = gui_rexuiz_textlabel_make(0, _("Map list:")));
			gui_make_callback(e, me.mapListBox, me.mapListBox.refilterCallback);
	me.TR(me);
		me.TD(me, me.rows - 9, 3, me.mapListBox);
	me.gotoRC(me, me.rows - 3, 0);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1, e = gui_rexuiz_button_make(_("All"), '0 0 0'));
			e.onClick = gui_rexuiz_maplist_all;
			e.onClickEntity = me.mapListBox;
		me.TD(me, 1, 1, e = gui_rexuiz_button_make(_("None"), '0 0 0'));
			e.onClick = gui_rexuiz_maplist_none;
			e.onClickEntity = me.mapListBox;
	me.gotoRC(me, 4, 3.5); me.setFirstColumn(me, me.currentColumn);
	me.TR(me);
		me.TD(me, 1, 3, e = gui_rexuiz_textlabel_make(0, _("Match settings:")));
	if (!me.isSinglePlayer) {
		me.TR(me);
			me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Server mode:")));
			me.TD(me, 1, 2, e = gui_rexuiz_textslider_make("menu_public"));
			e.addValue(e, _("Single player"), "-1");
			e.addValue(e, _("Private"), "0");
			e.addValue(e, _("Public"), "1");
			e.configureNexuizTextSliderValues(e);
		me.TR(me);
			me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("PIN-code:")));
			me.TD(me, 1, 1, e = gui_rexuiz_inputbox_make(0, "sv_pin_code"));
			e.onChange = nexuizServerCreateTabPINCodeOnChange;
			me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("* Digits only")));
			e.colorL = SKINCOLOR_TEXT_WARNING;
			e.fontSize = e.fontSize * 0.6;
	}
	me.TR(me);
		me.sliderTimelimit = gui_rexuiz_slider_make(1.0, 60.0, 0.5, "g_timelimit");
		me.TD(me, 1, 1, e = gui_rexuiz_checkbox_slider_make(0, 1, me.sliderTimelimit, _("Time limit:")));
		me.TD(me, 1, 2, me.sliderTimelimit);
	me.TR(me);
		me.sliderFraglimit = gui_rexuiz_slider_make(1.0, 2000.0, 5, "g_scorelimit");
		me.TD(me, 1, 1, e = gui_rexuiz_checkbox_slider_make(0, 1, me.sliderFraglimit, _("Point limit:")));
			me.checkboxFraglimit = e;
		me.TD(me, 1, 2, me.sliderFraglimit);
	if not(me.isSinglePlayer) {
		me.TR(me);
			me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Player slots:")));
			me.TD(me, 1, 2, gui_rexuiz_slider_make(1, 64, 1, "menu_maxplayers"));
		me.TR(me);
			me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Minimal amount of human and bots:")));
		me.TR(me);
			me.TDempty(me, 1);
			me.TD(me, 1, 2, gui_rexuiz_slider_make(0, 32, 1, "menu_minplayers"));
	}
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, (me.isSinglePlayer ? _("Number of bots:") :_("Additional number of bots:"))));
	me.TR(me);
		me.TDempty(me, 1);
		me.TD(me, 1, 2, gui_rexuiz_slider_make(0, 32, 1, "bot_number"));
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_textlabel_make(0, _("Bot skill:")));
		me.TD(me, 1, 2, e = gui_rexuiz_textslider_make("skill"));
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
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = gui_rexuiz_textlabel_make(0, _("Teams:")));
		me.TD(me, 1, 2, me.sliderTeams = e = gui_rexuiz_textslider_make("g_tdm_teams"));
			e.addValue(e, _("Default"), "0");
			e.addValue(e, _("2 teams"), "2");
			e.addValue(e, _("3 teams"), "3");
			e.addValue(e, _("4 teams"), "4");
			e.configureNexuizTextSliderValues(e);
		gui_make_multi(e, "g_dom_teams g_kh_teams");
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_button_make(_("Mutators..."), '0 0 0'));
			e.onClick = gui_modalcontroller_open_click;
			e.onClickEntity = main.mutatorsDialog;
		me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, NULL));
			e.textEntity = main.mutatorsDialog;
			e.allowCut = 1;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_button_make(_("Old mutators..."), '0 0 0'));
			e.onClick = gui_modalcontroller_open_click;
			e.onClickEntity = main.oldMutatorsDialog;
		me.TD(me, 1, 2, e = gui_rexuiz_textlabel_make(0, NULL));
			e.textEntity = main.oldMutatorsDialog;
			e.allowCut = 1;
	me.TR(me);
		me.TD(me, 1, 1, e = gui_rexuiz_checkbox_make(0, "rm", _("RocketMinsta")));
	me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, 2, e = makeNexuizModButton("Multiplayer_Create"));
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make((me.isSinglePlayer ? _("Start Game!") : _("Start Multiplayer!")), '0 0 0'));
			e.onClick = gui_rexuiz_maplist_start;
			e.onClickEntity = me.mapListBox;
			me.mapListBox.startButton = e;
	me.gameTypeChangeNotify(me);
}

void(entity me) rexuiz_gui_tab_multiplayer_create_type_change {
	// tell the map list to update
	float gt;
	entity e, l, t;
	gt = game_type_current();
	e = me.sliderFraglimit;
	l = me.checkboxFraglimit;
	t = me.sliderTeams;
	l.disabled = FALSE;
	switch(gt) {
	case GAME_TYPE_CATF: l.setText(l, _("Win limit:")); e.configureNexuizSlider(e, 1, 20, 1, "g_catf_scorelimit"); break;
	case GAME_TYPE_CTFT: l.setText(l, _("Win limit:")); e.configureNexuizSlider(e, 1, 20, 1, "g_ctft_scorelimit"); break;
	case GAME_TYPE_CTF: l.setText(l, _("Capture limit:")); e.configureNexuizSlider(e, 1, 20, 1, "g_ctf_scorelimit"); break;
	case GAME_TYPE_DOMINATION: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 50, 500, 10, "g_dom_scorelimit"); break;
	case GAME_TYPE_KEYHUNT: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 200, 1500, 50, "g_kh_scorelimit"); break;
	case GAME_TYPE_KEYHUNT_CA: l.setText(l, _("Win limit:")); e.configureNexuizSlider(e, 1, 30, 1, "g_khca_scorelimit"); break;
	case GAME_TYPE_KEYHUNT_FT: l.setText(l, _("Win limit:")); e.configureNexuizSlider(e, 1, 30, 1, "g_khft_scorelimit"); break;
	case GAME_TYPE_RACE: l.setText(l, _("Laps:")); e.configureNexuizSlider(e, 1, 25, 1, "g_race_scorelimit"); break;
	case GAME_TYPE_NEXBALL: l.setText(l, _("Goals:")); e.configureNexuizSlider(e, 1, 50, 1, "g_nexball_scorelimit"); break;
	case GAME_TYPE_ONSLAUGHT: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_no_point_limit"); break;
	case GAME_TYPE_CTS: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_no_point_limit"); break;
	case GAME_TYPE_FREEZETAG: l.setText(l, _("Win limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_ft_scorelimit"); break;
	case GAME_TYPE_CLANARENA: l.setText(l, _("Win limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_ca_scorelimit"); break;
	case GAME_TYPE_SURVIVE: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_no_point_limit"); break;
	case GAME_TYPE_COOP: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_no_point_limit"); break;
	case GAME_TYPE_CHESS: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_no_point_limit"); break;
	case GAME_TYPE_CONQUEST: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_no_point_limit"); break;
	case GAME_TYPE_SHOOTINGRANGE: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 1, 50, 1, "g_no_point_limit"); break;
	case GAME_TYPE_TEAM_DEATHMATCH: l.setText(l, _("Frag limit:")); e.configureNexuizSlider(e, 5, 200, 5, "g_tdm_scorelimit"); break;
	default: l.setText(l, _("Point limit:")); e.configureNexuizSlider(e, 5, 100, 5, "g_scorelimit"); break;
	}
	e.disabled = l.disabled = (e.cvarName == "g_no_point_limit");
	t.disabled = FALSE;
	switch(gt) {
	case GAME_TYPE_DOMINATION: t.configureNexuizTextSlider(t, "g_dom_teams"); break;
	case GAME_TYPE_KEYHUNT:
	case GAME_TYPE_KEYHUNT_CA:
	case GAME_TYPE_KEYHUNT_FT: t.configureNexuizTextSlider(t, "g_kh_teams"); break;
	case GAME_TYPE_TEAM_DEATHMATCH:
	case GAME_TYPE_FREEZETAG:
	case GAME_TYPE_CLANARENA: t.configureNexuizTextSlider(t, "g_tdm_teams"); break;
	default:
		t.disabled = TRUE;
	}
	me.mapListBox.refilter(me.mapListBox);
}
