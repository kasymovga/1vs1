float g_start_weapon_selectable;

.float w_secondary_picked;
void W_WriteSecondarySelect(void) {
    msg_entity = self;
    WriteByte(MSG_ONE, SVC_TEMPENTITY);
    WriteByte(MSG_ONE, TE_CSQC_WEAPONSELECT);
    WriteInt24_t(MSG_ONE, g_start_weapon_selectable);
}

var float(string cmd, float tokens) SelectableWeapon_ClientCommandHandle_NextLink;
float SelectableWeapon_ClientCommandHandle(string cmd, float tokens) {
	if (cmd == "pickweapon") {
		if (tokens == 2) {
			entity e;
			string s = argv(1);
			float i;
			for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
				e = get_weaponinfo(i);
				if (e.netname == s) {
					if not(g_start_weapon_selectable & W_WeaponBit(e.weapon))
						return TRUE;

					self.w_secondary_picked = e.weapon;
					break;
				}
			}
		} else {
			W_WriteSecondarySelect();
		}
		return TRUE;
	}
	return SelectableWeapon_ClientCommandHandle_NextLink(cmd, tokens);
}

var float() SelectableWeapon_JoinHandle_NextLink;
float SelectableWeapon_JoinHandle() {
    if(clienttype(self) != CLIENTTYPE_REAL)
        return FALSE;

    if(!self.w_secondary_picked) {
        W_WriteSecondarySelect();
        return TRUE;
    }
	return SelectableWeapon_JoinHandle_NextLink();
}

var void(entity spot) SelectableWeapon_Spawn_NextLink;
void SelectableWeapon_Spawn(entity spot) {
	if (self.w_secondary_picked)
		self.weapons |= W_WeaponBit(self.w_secondary_picked);

	SelectableWeapon_Spawn_NextLink(spot);
}

void SelectableWeapon_Init() {
	string s = cvar_string("g_start_weapon_selectable");
	string head, tail;
	float i;
	entity e;
	for (head = car(s), tail = cdr(s); head != ""; head = car(tail), tail = cdr(tail)) {
		for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
			e = get_weaponinfo(i);
			if (head == e.netname) {
				g_start_weapon_selectable |= W_WeaponBit(i);
				weapon_precache(e.weapon);
			}
		}
	}
	if not(g_start_weapon_selectable)
		return;

	SelectableWeapon_JoinHandle_NextLink = GameHookChain_JoinHandle;
	GameHookChain_JoinHandle = SelectableWeapon_JoinHandle;
	SelectableWeapon_ClientCommandHandle_NextLink = GameHookChain_ClientCommandHandle;
	GameHookChain_ClientCommandHandle = SelectableWeapon_ClientCommandHandle;
	SelectableWeapon_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = SelectableWeapon_Spawn;
}
