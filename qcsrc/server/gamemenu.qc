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
			Menu_Add_Item(e, "Auto team select|cmd selectteam auto;cmd join");
			if (c1 >= 0) {
				Menu_Add_Item(e, "Join ^1Red|cmd selectteam red;cmd join");
			}
			if (c2 >= 0) {
				Menu_Add_Item(e, "Join ^4Blue|cmd selectteam blue;cmd join");
			}
			if (c3 >= 0) {
				Menu_Add_Item(e, "Join ^3Yellow|cmd selectteam yellow;cmd join");
			}
			if (c4 >= 0) {
				Menu_Add_Item(e, "Join ^6Pink|cmd selectteam pink;cmd join");
			}
		} else {
			if (c1 >= 0)
			if (self.team != COLOR_TEAM1) {
				Menu_Add_Item(e, "Switch to ^1Red|cmd selectteam red");
			}
			if (c2 >= 0)
			if (self.team != COLOR_TEAM2) {
				Menu_Add_Item(e, "Switch to ^4Blue|cmd selectteam blue");
			}
			if (c3 >= 0)
			if (self.team != COLOR_TEAM3) {
				Menu_Add_Item(e, "Switch to ^3Yellow|cmd selectteam yellow");
			}
			if (c4 >= 0)
			if (self.team != COLOR_TEAM4) {
				Menu_Add_Item(e, "Switch to ^6Pink|cmd selectteam pink");
			}
		}
	} else if (self.classname == "spectator" || self.classname == "observer") {
		Menu_Add_Item(e, "Join game|cmd join");
	}
	if (self.classname != "spectator" || self.team > 0)
		Menu_Add_Item(e, "Spectate|cmd spectate");

	if (g_nadgets)
	if (self.team > 0 || self.classname == "player")
		Menu_Add_Item(e, "Select nadget|cmd picknade");

	Menu_Add_Item(e, "Main menu|togglemenu");
	Menu_Add_Item(e, "Leave Match|disconnect");
	Menu_Add_Item(e, "Return to game");
}

void GameMenu_Init() {
	CACHE_CVAR(sv_gamemenu);
}
