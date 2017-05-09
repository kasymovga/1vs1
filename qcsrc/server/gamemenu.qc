float sv_gamemenu;
.entity gamemenu;
void GameMenu_Select(float select) {
	if not(self.gamemenu)
		return;

	remove(self.gamemenu);
	self.gamemenu = world;
}

void GameMenu_Show() {
	if not(sv_gamemenu) {
		stuffcmd(self,"togglemenu\n");
		return;
	}
	if (self.gamemenu) {
		remove(self.gamemenu);
		self.gamemenu = world;
		return;
	}

	entity e = self.gamemenu = Menu_Prepare(self, "gamemenu", "Game Menu", 0, GameMenu_Select);
	Menu_Set_Flags(e, MENU_ESCAPE_ENABLE);
	if (teams_matter) {
		CheckAllowedTeams(self);
		if (self.team <= 0) {
			Menu_Add_Item(e, "Join Game|cmd join");
		} else {
			Menu_Add_Item(e, "Switch Team/Spectate|menu_showteamselect");
		}
	} else { 
		if (self.classname == "spectator" || self.classname == "observer")
			Menu_Add_Item(e, "Join Game|cmd join");
		else
			Menu_Add_Item(e, "Spectate|cmd spectate");
	}

	if (g_nadgets)
	if (self.team > 0 || self.classname == "player")
		Menu_Add_Item(e, "Switch Nadget|cmd picknade");

	Menu_Add_Item(e, "Main Menu|togglemenu");
	Menu_Add_Item(e, "Disconnect|disconnect");
	Menu_Add_Item(e, "Return to Game");
}

void GameMenu_Init() {
	CACHE_CVAR(sv_gamemenu);
}
