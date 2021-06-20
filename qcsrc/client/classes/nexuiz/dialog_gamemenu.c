#ifdef INTERFACE
CLASS(NexuizGameMenuDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizGameMenuDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizGameMenuDialog, configureDialog, void(entity))
	ATTRIB(NexuizGameMenuDialog, title, string, "Game Menu")
	ATTRIB(NexuizGameMenuDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizGameMenuDialog, intendedWidth, float, 0.25)
	ATTRIB(NexuizGameMenuDialog, rows, float, 12)
	ATTRIB(NexuizGameMenuDialog, columns, float, 10)
	ATTRIB(NexuizGameMenuDialog, name, string, "GameMenu")
ENDCLASS(NexuizGameMenuDialog)
#endif

#ifdef IMPLEMENTATION

void ShowGameSettings() {
	GUI_Show(GUI_GAMESETTINGS);
}

void ShowVcall() {
	GUI_Show(GUI_VCALL);
}

void ShowQuit() {
	GUI_Show(GUI_QUIT);
}

void ShowSwitchTeam() {
	GUI_Show(GUI_TEAMSELECT);
}

void ShowSaveLoad() {
	GUI_Show(GUI_SAVELOAD);
}

void configureDialogNexuizGameMenuDialog(entity me) {
	if (main_isdemo)
		me.rows = me.rows - 4;
	else {
		if (team_mode)
			me.rows = me.rows + 1;

		me.rows = me.rows + gamemenu_commands_count;
		if not(main_campaign)
			me.rows = me.rows + 2;

		if (main_localgame)
		if (main_campaign)
		if (gametype == GAMETYPE_SINGLE) {
			me.rows = me.rows + 1;
		}
	}
	configureDialogNexuizDialog(me); //Parent method
}

void showMuteListGameMenuDialog() {
	GUI_Show(GUI_MUTELIST);
}

void fillNexuizGameMenuDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Main menu", '0 0 0', "togglemenu;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Game settings", '0 0 0'));
		e.onClick = ShowGameSettings;
	if not(main_isdemo) {
		me.TR(me);
		if not(main_campaign) {
			me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Join", '0 0 0', "cmd join;", COMMANDBUTTON_CLOSE));
		}
		if (team_mode) {
			me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizButton("Switch team", '0 0 0'));
				e.onClick = ShowSwitchTeam;
		}
		float i;
		for (i = 0; i < gamemenu_commands_count; i++) {
			me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton(gamemenu_items[i], '0 0 0', gamemenu_commands[i], COMMANDBUTTON_CLOSE));
		}
		if not(main_campaign) {
			me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Spectate", '0 0 0', "cmd spectate;", COMMANDBUTTON_CLOSE));
		}
		if (main_localgame)
		if (main_campaign)
		if (gametype == GAMETYPE_SINGLE) {
			me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizButton("Save/Load", '0 0 0'));
				e.onClick = ShowSaveLoad;
		}
		if (vote_commands_count) {
			me.TR(me);
				me.TD(me, 1, me.columns, e = makeNexuizButton("Call a vote", '0 0 0'));
				e.onClick = ShowVcall;
		}
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizButton("Mute list...", '0 0 0'));
			e.onClick = showMuteListGameMenuDialog;
	}
	me.TR(me);
	if (main_isdemo) {
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Stop demo", '0 0 0', "disconnect;", COMMANDBUTTON_CLOSE));
	} else {
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Disconnect", '0 0 0', "togglemenu;disconnect;", COMMANDBUTTON_CLOSE));
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Reconnect", '0 0 0', "disconnect; reconnect;", COMMANDBUTTON_CLOSE));
	}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Return to game", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Quit to desktop", '1 0 0'));
			e.onClick = ShowQuit;
			e.onClickEntity = me;

}
#endif

/* Click. The c-word is here so you can grep for it :-) */