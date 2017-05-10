float sv_gamemenu;
void GameMenu_Select(float select) {
	Menu_Remove_For(self, "gamemenu");
}

void GameMenu_Show() {
	if (cvar("sv_gamemenu_broken"))
		return;

	if not(sv_gamemenu) {
		stuffcmd(self,"togglemenu\n");
		return;
	}

	entity e = Menu_Prepare(self, "gamemenu", "Game Menu", 0, GameMenu_Select);
	if not(e)
		return;

	Menu_Set_Flags(e, MENU_ESCAPE_ENABLE);
	Menu_Add_Item(e, "Main Menu|togglemenu");
	Menu_Add_Item(e, "Disconnect|disconnect");
	Menu_Add_Item(e, "Return to Game");
	if (teams_matter) {
		CheckAllowedTeams(self);
		if (self.team <= 0) {
			Menu_Add_Item(e, "Join Match|cmd join");
		} else {
			Menu_Add_Item(e, "Switch Team/Spectate|menu_showteamselect");
		}
	} else { 
		if (self.classname == "spectator" || self.classname == "observer")
			Menu_Add_Item(e, "Join Match|cmd join");
		else
			Menu_Add_Item(e, "Spectate|cmd spectate");
	}
	if (GameHookChain_GameMenuAddItems)
		GameHookChain_GameMenuAddItems(e);
}

void GameMenu_Init() {
	CACHE_CVAR(sv_gamemenu);
}
