string sv_walkietalkie[10];
float sv_walkietalkie_count;

string WalkieTalkie_SoundPath(float n) {
	return strcat("walkietalkie/", sv_walkietalkie[n], ".wav");
}

var void(void(string item, string cmd) Add_Item) WalkieTalkie_gamemenu_send_NextLink;
void WalkieTalkie_gamemenu_send(void(string item, string cmd) Add_Item) {
	if (sv_walkietalkie_count)
		Add_Item("Walkie-Talkie", "cmd walkietalkie;");

	WalkieTalkie_gamemenu_send_NextLink(Add_Item);
}
var float(string cmd, float tokens) WalkieTalkie_ClientCommandHandle_NextLink;
float WalkieTalkie_ClientCommandHandle(string cmd, float tokens) {
	if (cmd == "walkietalkie") {
		WalkieTalkie_Menu();
		return TRUE;
	}
	return WalkieTalkie_ClientCommandHandle_NextLink(cmd, tokens);
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
	WalkieTalkie_gamemenu_send_NextLink = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = WalkieTalkie_gamemenu_send;
	WalkieTalkie_ClientCommandHandle_NextLink = gamehook_chain_cmd_client_handle;
	gamehook_chain_cmd_client_handle = WalkieTalkie_ClientCommandHandle;
}

float walkietalkie_block[4];

void WalkeTalkie_WaypointRemove() { WaypointSprite_DetachCarrier(self); }

void WalkieTalkie_Menu_Select(float n) {
	menu_remove_for(self, "walkietalkie");
	if (n < 0)
		return;

	if (n >= sv_walkietalkie_count)
		return;

	if (self.classname != "player")
		return;

	float _team_index = (team_mode ? team_index(self.team) : 0);
	if (_team_index)
		_team_index--;

	if (walkietalkie_block[_team_index] > time)
		return;

	entity e;
	FOR_EACH_REALCLIENT(e)
		if (self.team == e.team)
			announce_force(e, WalkieTalkie_SoundPath(n), "");

	WaypointSprite_Attach("here", 0);
	defer_for(self, 2, WalkeTalkie_WaypointRemove);
	walkietalkie_block[_team_index] = time + 3;
}

void WalkieTalkie_Menu() {
	if not(sv_walkietalkie_count)
		return;

	if (self.classname != "player")
		return;

	entity e = menu_prepare(self, "walkietalkie", "Walkie Talkie", 0, WalkieTalkie_Menu_Select);
	if not(e)
		return;

	float i;
	for (i = 0; i < sv_walkietalkie_count; i++) {
		menu_add_item(e, sv_walkietalkie[i]);
	}
}
