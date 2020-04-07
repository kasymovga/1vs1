float g_start_weapon_selectable;
float selectable_weapon_for_bots;

.float w_secondary_picked;
void(void) weapon_selectable_send {
    msg_entity = self;
    WriteByte(MSG_ONE, SVC_TEMPENTITY);
    WriteByte(MSG_ONE, TE_CSQC_WEAPONSELECT);
    net_write_int24(MSG_ONE, g_start_weapon_selectable);
}

var void(void(string item, string cmd) Add_Item) weapon_selectable_GameMenuAddItems_NextLink;
void(void(string item, string cmd) Add_Item) weapon_selectable_GameMenuAddItems {
	Add_Item("Switch Weapon", "cmd pickweapon;");
	weapon_selectable_GameMenuAddItems_NextLink(Add_Item);
}

var float(string cmd, float tokens) weapon_selectable_ClientCommandHandle_NextLink;
float(string cmd, float tokens) weapon_selectable_ClientCommandHandle {
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
	return weapon_selectable_ClientCommandHandle_NextLink(cmd, tokens);
}

var float(void) weapon_selectable_JoinHandle_NextLink;
float(void) weapon_selectable_JoinHandle {
    if(clienttype(self) != CLIENTTYPE_REAL)
        return FALSE;

    if(!self.w_secondary_picked) {
        weapon_selectable_send();
        return TRUE;
    }
	return weapon_selectable_JoinHandle_NextLink();
}

var void(entity spot) weapon_selectable_Spawn_NextLink;
void(entity spot) weapon_selectable_Spawn {
	if (self.w_secondary_picked)
		self.weapons |= weapon_bit(self.w_secondary_picked);
	else if (clienttype(self) == CLIENTTYPE_BOT)
		self.weapons |= weapon_bit(selectable_weapon_for_bots);

	weapon_selectable_Spawn_NextLink(spot);
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
				selectable_weapon_for_bots = i;
				weapon_precache(e.weapon);
			}
		}
	}
	if not(g_start_weapon_selectable)
		return;

	weapon_selectable_JoinHandle_NextLink = GameHookChain_JoinHandle;
	GameHookChain_JoinHandle = weapon_selectable_JoinHandle;
	weapon_selectable_ClientCommandHandle_NextLink = GameHookChain_ClientCommandHandle;
	GameHookChain_ClientCommandHandle = weapon_selectable_ClientCommandHandle;
	weapon_selectable_Spawn_NextLink = gamehook_chain_spawn;
	gamehook_chain_spawn = weapon_selectable_Spawn;
	weapon_selectable_GameMenuAddItems_NextLink = GameHookChain_GameMenuAddItems;
	GameHookChain_GameMenuAddItems = weapon_selectable_GameMenuAddItems;
}
