float g_start_weapon_selectable;

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
	if not(self.w_secondary_picked)
	if (clienttype(self) == CLIENTTYPE_REAL) {
		weapon_selectable_send();
		return TRUE;
	}
	return weapon_selectable_spectator_to_player_handle_next();
}

var void(entity spot) weapon_selectable_player_spawn_next;
void(entity spot) weapon_selectable_player_spawn {
	if not(self.w_secondary_picked) {
		random_selection_init();
		for (float i = WEP_FIRST, j = 1; i <= WEP_LAST; i++, j *= 2) {
			if ((j & g_start_weapon_selectable)) {
				random_selection_add(NULL, i, "", 1, 1);
			}
		}
		self.w_secondary_picked = random_selection_chosen_float;
	}
	if (self.w_secondary_picked) {
		self.weapons |= weapon_bit(self.w_secondary_picked);
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
			entity e = weapon_info(self.w_secondary_picked);
			float a = e.items & IT_AMMO;
			if (a) {
				var .float ammofield = item_counter_field(e.items & IT_AMMO);
				if (self.ammofield <= 0)
					self.ammofield = cvar(strcat("g_start_weapon_selectable_", item_counter_field_name(a)));

				if (self.ammofield <= 0)
					self.ammofield = cvar(strcat("g_pickup_", item_counter_field_name(a)));
			}
		}
		if (!self.switchweapon)
			self.switchweapon = self.w_secondary_picked;
	}
	weapon_selectable_player_spawn_next(spot);
}

void(void) weapon_selectable_init {
	string s = cvar_string("g_start_weapon_selectable");
	string head, tail;
	entity e;
	for (head = str_car(s), tail = str_cdr(s); head != "" || tail != ""; head = str_car(tail), tail = str_cdr(tail)) {
		if (head != "") {
			e = weapon_info_by_name(head);
			if (e) {
				g_start_weapon_selectable |= weapon_bit(e.weapon);
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
	weapon_selectable_player_spawn_next = gamehook_chain_player_spawn;
	gamehook_chain_player_spawn = weapon_selectable_player_spawn;
	weapon_selectable_gamemenu_send_next = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = weapon_selectable_gamemenu_send;
}
