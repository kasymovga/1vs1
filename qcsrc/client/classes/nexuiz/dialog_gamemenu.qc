entity spawnNexuizGameMenuDialog() {
	entity me; me = spawnNexuizRootDialog();
	me.fill = fillNexuizGameMenuDialog; // to be overridden by user to fill the dialog with controls
	me.configureDialog = configureDialogNexuizGameMenuDialog;
	me.title = _("Game Menu");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.25;
	me.rows = 12;
	me.columns = 10;
	me.name = "GameMenu";
	me.classname = "NexuizGameMenuDialog";
	return me;
}
/* Click. The c-word is here so you can grep for it :-) */
void ShowGameSettings(entity ignore, entity ignore2) {
	GUI_Show(GUI_GAMESETTINGS);
}
void ShowVcall(entity ignore, entity ignore2) {
	GUI_Show(GUI_VCALL);
}
void ShowQuit(entity ignore, entity ignore2) {
	GUI_Show(GUI_QUIT);
}
void ShowSwitchTeam(entity ignore, entity ignore2) {
	GUI_Show(GUI_TEAMSELECT);
}
void ShowSaveLoad(entity ignore, entity ignore2) {
	GUI_Show(GUI_SAVELOAD);
}
void configureDialogNexuizGameMenuDialog(entity me) {
	if (main_isdemo)
		me.rows = me.rows - 4;
	else {
		if not(main_campaign)
		if (team_teams > 1)
				me.rows = me.rows + 1;
		me.rows = me.rows + game_menu_commands_count;
		if not(main_campaign)
				me.rows = me.rows + 2; //join and spectate
		if (main_localgame)
		if (main_campaign)
		if (game_type == GAME_TYPE_SINGLE) {
				me.rows = me.rows + 1; //save/load
		}
		if (main_campaign)
				me.rows = me.rows - 1; //vote
		if (main_campaign)
				me.rows = me.rows - 1; //mute
	}
	configureDialogNexuizDialog(me); //Parent method
}
void showMuteListGameMenuDialog(entity ignore, entity ignore2) {
	GUI_Show(GUI_MUTELIST);
}
void fillNexuizGameMenuDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Main menu"), '0 0 0', "togglemenu;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Game settings"), '0 0 0'));
		e.onClick = ShowGameSettings;
	if not(main_isdemo) {
		me.TR(me);
		if not(main_campaign) {
				me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Join"), '0 0 0', "cmd join;", COMMANDBUTTON_CLOSE));
		}
		if not(main_campaign)
		if (team_teams > 1) {
				me.TR(me);
				float at = cvar("_teams_available");
				float tc = 0;
				if (at & 1) tc++;
				if (at & 2) tc++;
				if (at & 4) tc++;
				if (at & 8) tc++;
				me.TD(me, 1, me.columns, e = makeNexuizButton(_("Switch team"), '0 0 0'));
				e.onClick = ShowSwitchTeam;
				if (tc <= 1) {
					e.disabled = TRUE;
				}
		}
		float i;
		for (i = 0; i < game_menu_commands_count; i++) {
				me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(game_menu_items[i], '0 0 0', game_menu_commands[i], COMMANDBUTTON_CLOSE));
		}
		if not(main_campaign) {
				me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Spectate"), '0 0 0', "cmd spectate;", COMMANDBUTTON_CLOSE));
		}
		if (main_localgame)
		if (main_campaign)
		if (game_type == GAME_TYPE_SINGLE) {
				me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizButton(_("Save/Load"), '0 0 0'));
				e.onClick = ShowSaveLoad;
		}
		if (!main_campaign) {
				me.TR(me);
				if (vote_commands_count) {
				me.TD(me, 1, me.columns, e = makeNexuizButton(_("Call a vote"), '0 0 0'));
				e.onClick = ShowVcall;
				}
				if (game_type != GAME_TYPE_SINGLE) {
				me.TR(me);
					me.TD(me, 1, me.columns, e = makeNexuizButton(_("Mute list..."), '0 0 0'));
					e.onClick = showMuteListGameMenuDialog;
				}
		}
	}
	me.TR(me);
	if (main_isdemo) {
		me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Stop demo"), '0 0 0', "togglemenu;disconnect;", COMMANDBUTTON_CLOSE));
	} else {
		me.TR(me);
				if (main_localgame)
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Stop game"), '0 0 0', "togglemenu;disconnect;", COMMANDBUTTON_CLOSE));
				else
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Disconnect"), '0 0 0', "togglemenu;disconnect;", COMMANDBUTTON_CLOSE));
		me.TR(me);
				if (main_localgame)
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Restart"), '0 0 0', "restart;", COMMANDBUTTON_CLOSE));
				else
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(_("Reconnect"), '0 0 0', "disconnect; reconnect;", COMMANDBUTTON_CLOSE));
	}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Return to game"), '0 0 0'));
				e.onClick = gui_dialog_close;
				e.onClickEntity = me;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton(_("Quit to desktop"), '1 0 0'));
				e.onClick = ShowQuit;
				e.onClickEntity = me;
}
/* Click. The c-word is here so you can grep for it :-) */
