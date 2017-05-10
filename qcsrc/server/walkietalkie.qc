string sv_walkietalkie[10];
float sv_walkietalkie_count;

string WalkieTalkie_SoundPath(float n) {
	return strcat("walkietalkie/", sv_walkietalkie[n], ".wav");
}

var void(entity menu) WalkieTalkie_GameMenuAddItems_NextLink;
void WalkieTalkie_GameMenuAddItems(entity menu) {
	if (sv_walkietalkie_count)
		Menu_Add_Item(menu, "Walkie-Talkie|cmd walkietalkie");

	if (WalkieTalkie_GameMenuAddItems_NextLink)
		WalkieTalkie_GameMenuAddItems_NextLink(menu);
}
var float(string cmd, float tokens) WalkieTalkie_ClientCommandHandle_NextLink;
float WalkieTalkie_ClientCommandHandle(string cmd, float tokens) {
	if (cmd == "walkietalkie") {
		WalkieTalkie_Menu();
		return TRUE;
	}
	if (WalkieTalkie_ClientCommandHandle_NextLink)
		return WalkieTalkie_ClientCommandHandle_NextLink(cmd, tokens);

	return FALSE;
}

void WalkieTalkie_Init() {
	string s = cvar_string("sv_walkietalkie");
	if (s == "")
		return;

	sv_walkietalkie_count = min(tokenize_console(s), 10);
	float i;
	for (i = 0; i < sv_walkietalkie_count; i++) {
		sv_walkietalkie[i] = strzone(argv(i));
		precache_sound(WalkieTalkie_SoundPath(i));
	}
	WalkieTalkie_GameMenuAddItems_NextLink = GameHookChain_GameMenuAddItems;
	GameHookChain_GameMenuAddItems = WalkieTalkie_GameMenuAddItems;
	WalkieTalkie_ClientCommandHandle_NextLink = GameHookChain_ClientCommandHandle;
	GameHookChain_ClientCommandHandle = WalkieTalkie_ClientCommandHandle;
}

float walkietalkie_block[4];

void WalkeTalkie_WaypointRemove() { WaypointSprite_DetachCarrier(self); }

void WalkieTalkie_Menu_Select(float n) {
	Menu_Remove_For(self, "walkietalkie");
	if (n < 0)
		return;

	if (n >= sv_walkietalkie_count)
		return;

	if (self.classname != "player")
		return;

	float team_index = (teams_matter ? TeamColorSkin(self.team) : 0);
	if (team_index)
		team_index--;

	if (walkietalkie_block[team_index] > time)
		return;

	entity e;
	FOR_EACH_REALCLIENT(e)
		if (self.team == e.team)
			announce_force(e, WalkieTalkie_SoundPath(n));

	WaypointSprite_Attach("here", 0);
	defer_for(self, 2, WalkeTalkie_WaypointRemove);
	walkietalkie_block[team_index] = time + 3;
}

void WalkieTalkie_Menu() {
	if not(sv_walkietalkie_count)
		return;

	if (self.classname != "player")
		return;

	entity e = Menu_Prepare(self, "walkietalkie", "Walkie Talkie", 0, WalkieTalkie_Menu_Select);
	if not(e)
		return;

	float i;
	for (i = 0; i < sv_walkietalkie_count; i++) {
		Menu_Add_Item(e, sv_walkietalkie[i]);
	}
}
