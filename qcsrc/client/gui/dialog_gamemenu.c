#ifdef INTERFACE
CLASS(NexuizGameMenuDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizGameMenuDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizGameMenuDialog, configureDialog, void(entity))
	ATTRIB(NexuizGameMenuDialog, title, string, "Game Menu")
	ATTRIB(NexuizGameMenuDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizGameMenuDialog, intendedWidth, float, 0.25)
	ATTRIB(NexuizGameMenuDialog, rows, float, 10)
	ATTRIB(NexuizGameMenuDialog, columns, float, 10)
	ATTRIB(NexuizGameMenuDialog, name, string, "GameMenu")
ENDCLASS(NexuizGameMenuDialog)
#endif

#ifdef IMPLEMENTATION

void configureDialogNexuizGameMenuDialog(entity me) {
	if (teamplay)
		me.rows = me.rows + 1;

	me.rows = me.rows + gamemenu_commands_count;
	configureDialogNexuizDialog(me); //Parent method
}

void fillNexuizGameMenuDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Main menu", '0 0 0', "togglemenu;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Game settings", '0 0 0', "showgamesettings;", COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Join", '0 0 0', "cmd join;", COMMANDBUTTON_CLOSE));
	if (teamplay) {
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Switch team", '0 0 0', "menu_cmd directmenu TeamSelect;", COMMANDBUTTON_CLOSE));
			//setDependent(e, "_teams_available", 1, 1337);
	}
	float i, separator;
	for (i = 0; i < gamemenu_commands_count; i++) {
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizCommandButton(gamemenu_items[i], '0 0 0', gamemenu_commands[i], COMMANDBUTTON_CLOSE));
			//setDependent(e, "_nadgets_select_available", 1, 1337);
		
	}
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Spectate", '0 0 0', "cmd spectate;", COMMANDBUTTON_CLOSE));
#if 0
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Call a vote", '0 0 0', "menu_cmd directmenu VcallMenu;", COMMANDBUTTON_CLOSE));
#endif
		//setDependent(e, "_voting_allowed", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Disconnect", '0 0 0', "disconnect;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Reconnect", '0 0 0', "disconnect; reconnect;", COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Return to game", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;

}
#endif

/* Click. The c-word is here so you can grep for it :-) */
