float g_start_weapon_selectable;
float weapon_selectable_for_bots;

.float w_secondary_picked;
void(void) weapon_selectable_send {
	msg_entity = self;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_WEAPONSELECT);
	net_write_int24(MSG_ONE, g_start_weapon_selectable);
}

var void(void(string item, string cmd) Add_Item) weapon_selectable_gamemenu_send_next;
void(void(string item, string cmd) Add_Item) weapon_selectable_gamemenu_send {
	Add_Item("Switch Weapon", "cmd pickweapon;");
	weapon_selectable_gamemenu_send_next(Add_Item);
}

var float(string cmd, float tokens) weapon_selectable_cmd_client_handle_next;
float(string cmd, float tokens) weapon_selectable_cmd_client_handle {
	if (cmd == "pickweapon") {
		if (tokens == 2) {
			entity e;
			string s = argv(1);
			float i;
			for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
				e = weapon_info(i);
				if (e.netname == s) {
					if not(g_start_weapon_selectable & weapon_bit(e.weapon))
						return TRUE;

					self.w_secondary_picked = e.weapon;
					break;
				}
			}
		} else {
			weapon_selectable_send();
		}
		return TRUE;
	}
	return weapon_selectable_cmd_client_handle_next(cmd, tokens);
}

var float(void) weapon_selectable_spectator_to_player_handle_next;
float(void) weapon_selectable_spectator_to_player_handle {
	if (clienttype(self) != CLIENTTYPE_REAL)
		return FALSE;

	if (!self.w_secondary_picked) {
		weapon_selectable_send();
		return TRUE;
	}
	return weapon_selectable_spectator_to_player_handle_next();
}

var void(entity spot) weapon_selectable_spawn_next;
void(entity spot) weapon_selectable_spawn {
	if (self.w_secondary_picked)
		self.weapons |= weapon_bit(self.w_secondary_picked);
	else if (clienttype(self) == CLIENTTYPE_BOT)
		self.weapons |= weapon_bit(weapon_selectable_for_bots);

	weapon_selectable_spawn_next(spot);
}

void(void) weapon_selectable_init {
	string s = cvar_string("g_start_weapon_selectable");
	string head, tail;
	float i;
	entity e;
	for (head = str_car(s), tail = str_cdr(s); head != ""; head = str_car(tail), tail = str_cdr(tail)) {
		for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
			e = weapon_info(i);
			if (head == e.netname) {
				g_start_weapon_selectable |= weapon_bit(i);
				weapon_selectable_for_bots = i;
				weapon_precache(e.weapon);
			}
		}
	}
	if not(g_start_weapon_selectable)
		return;

	weapon_selectable_spectator_to_player_handle_next = gamehook_chain_spectator_to_player_handle;
	gamehook_chain_spectator_to_player_handle = weapon_selectable_spectator_to_player_handle;
	weapon_selectable_cmd_client_handle_next = gamehook_chain_cmd_client_handle;
	gamehook_chain_cmd_client_handle = weapon_selectable_cmd_client_handle;
	weapon_selectable_spawn_next = gamehook_chain_spawn;
	gamehook_chain_spawn = weapon_selectable_spawn;
	weapon_selectable_gamemenu_send_next = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = weapon_selectable_gamemenu_send;
}
