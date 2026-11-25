void(entity me) gui_rexuiz_dialog_gamemenu_configure;
void(entity me) gui_rexuiz_dialog_gamemenu_fill;

entity (void) gui_rexuiz_dialog_gamemenu_spawn {
	entity me = gui_rexuiz_rootdialog_spawn();
	me.fill = gui_rexuiz_dialog_gamemenu_fill;
	me.configureDialog = gui_rexuiz_dialog_gamemenu_configure;
	me.title = _("Game Menu");
	me.color = SKINCOLOR_DIALOG_TEAMSELECT;
	me.intendedWidth = 0.25;
	me.rows = 12;
	me.columns = 10;
	me.name = "GameMenu";
	me.classname = "NexuizGameMenuDialog";
	return me;
}

void(entity ignore, entity ignore2) gui_rexuiz_dialog_gamemenu_gamesettings {
	GUI_Show(GUI_GAMESETTINGS);
}

void(entity ignore, entity ignore2) gui_rexuiz_dialog_gamemenu_vcall {
	GUI_Show(GUI_VCALL);
}

void(entity ignore, entity ignore2) gui_rexuiz_dialog_gamemenu_quit {
	GUI_Show(GUI_QUIT);
}

void(entity ignore, entity ignore2) gui_rexuiz_dialog_gamemenu_switchteam {
	GUI_Show(GUI_TEAMSELECT);
}

void(entity ignore, entity ignore2) gui_rexuiz_dialog_gamemenu_saveload {
	GUI_Show(GUI_SAVELOAD);
}

void(entity me) gui_rexuiz_dialog_gamemenu_configure {
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
	gui_rexuiz_dialog_configure(me); //Parent method
}

void(entity ignore, entity ignore2) gui_rexuiz_dialog_gamemenu_mutelist {
	GUI_Show(GUI_MUTELIST);
}

void(entity me) gui_rexuiz_dialog_gamemenu_fill {
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Main menu"), '0 0 0', "togglemenu;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Game settings"), '0 0 0'));
		e.onClick = gui_rexuiz_dialog_gamemenu_gamesettings;
	if not(main_isdemo) {
		me.TR(me);
			if not(main_campaign) {
				me.TR(me);
					me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Join"), '0 0 0', "cmd join;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
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
					me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Switch team"), '0 0 0'));
						e.onClick = gui_rexuiz_dialog_gamemenu_switchteam;
						if (tc <= 1) {
							e.disabled = TRUE;
						}
			}
			float i;
			for (i = 0; i < game_menu_commands_count; i++) {
				me.TR(me);
					me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(game_menu_items[i], '0 0 0', game_menu_commands[i], GUI_REXUIZ_COMMANDBUTTON_CLOSE));
			}
			if not(main_campaign) {
				me.TR(me);
					me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Spectate"), '0 0 0', "cmd spectate;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
			}
			if (main_localgame)
			if (main_campaign)
			if (game_type == GAME_TYPE_SINGLE) {
				me.TR(me);
					me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Save/Load"), '0 0 0'));
						e.onClick = gui_rexuiz_dialog_gamemenu_saveload;
			}
			if (!main_campaign) {
				me.TR(me);
					if (vote_commands_count) {
						me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Call a vote"), '0 0 0'));
							e.onClick = gui_rexuiz_dialog_gamemenu_vcall;
					}
				if (game_type != GAME_TYPE_SINGLE) {
					me.TR(me);
						me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Mute list..."), '0 0 0'));
							e.onClick = gui_rexuiz_dialog_gamemenu_mutelist;
				}
			}
	}
	me.TR(me);
	if (main_isdemo) {
		me.TR(me);
			me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Stop demo"), '0 0 0', "togglemenu;disconnect;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
	} else {
		me.TR(me);
			if (main_localgame)
				me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Stop game"), '0 0 0', "togglemenu;disconnect;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
			else
				me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Disconnect"), '0 0 0', "togglemenu;disconnect;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
		me.TR(me);
			if (main_localgame)
				me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Restart"), '0 0 0', "restart;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
			else
				me.TD(me, 1, me.columns, e = gui_rexuiz_commandbutton_make(_("Reconnect"), '0 0 0', "disconnect; reconnect;", GUI_REXUIZ_COMMANDBUTTON_CLOSE));
	}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Return to game"), '0 0 0'));
			e.onClick = gui_dialog_button_close;
			e.onClickEntity = me;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = gui_rexuiz_button_make(_("Quit to desktop"), '1 0 0'));
			e.onClick = gui_rexuiz_dialog_gamemenu_quit;
			e.onClickEntity = me;
}
