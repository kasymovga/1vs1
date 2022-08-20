string sv_walkietalkie[10];
float sv_walkietalkie_count;
void(void) walkietalkie_menu;

string(float n) walkietalkie_sound_path {
	return strcat("walkietalkie/", sv_walkietalkie[n], ".wav");
}

var void(void(string item, string cmd) Add_Item) walkietalkie_gamemenu_send_next;
void(void(string item, string cmd) Add_Item) walkietalkie_gamemenu_send {
	if (sv_walkietalkie_count)
		Add_Item("Walkie-Talkie", "cmd walkietalkie;");

	walkietalkie_gamemenu_send_next(Add_Item);
}
var float(string cmd, float tokens) walkietalkie_cmd_client_handle_next;
float walkietalkie_cmd_client_handle(string cmd, float tokens) {
	if (cmd == "walkietalkie") {
		walkietalkie_menu();
		return TRUE;
	}
	return walkietalkie_cmd_client_handle_next(cmd, tokens);
}

void(void) walkietalkie_init {
	string s = cvar_string("sv_walkietalkie");
	if (s == "")
		return;

	sv_walkietalkie_count = min(tokenize_console(s), 10);
	float i;
	for (i = 0; i < sv_walkietalkie_count; i++) {
		sv_walkietalkie[i] = strzone(argv(i));
		precache_sound(walkietalkie_sound_path(i));
	}
	walkietalkie_gamemenu_send_next = plugin_chain_gamemenu_send;
	plugin_chain_gamemenu_send = walkietalkie_gamemenu_send;
	walkietalkie_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = walkietalkie_cmd_client_handle;
}

float walkietalkie_block[4];

void(void) walkietalkie_waypoint_remove { WaypointSprite_DetachCarrier(self); }

void(float n) walkietalkie_menu_select {
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
		if (e.cvar_cl_voice_directional >= 0)
		if (self.team == e.team || (e.classname == "spectator" && e.enemy.team == self.team)) {
			msg_entity = e;
			sound_to_at(MSG_ONE, world, '0 0 0', CHAN_VOICE, walkietalkie_sound_path(n), VOL_BASE, ATTN_NONE);
		}
	WaypointSprite_Attach("here", 0);
	defer_for(self, 2, walkietalkie_waypoint_remove);
	walkietalkie_block[_team_index] = time + 3;
}

void(void) walkietalkie_menu {
	if not(sv_walkietalkie_count)
		return;

	if (self.classname != "player")
		return;

	entity e = menu_prepare(self, "walkietalkie", "Walkie Talkie", 0, walkietalkie_menu_select);
	if not(e)
		return;

	float i;
	for (i = 0; i < sv_walkietalkie_count; i++) {
		menu_add_item(e, sv_walkietalkie[i]);
	}
}
