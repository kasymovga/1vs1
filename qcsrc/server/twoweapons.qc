float g_twoweapons;

var void() TwoWeapons_PlayerPreThink_NextLink;
void TwoWeapons_PlayerPreThink() {
	if (self.BUTTON_ATCK)
		W_SwitchWeapon(g_twoweapons);
	else if (self.BUTTON_ATCK2) {
		if (self.switchweapon == g_twoweapons) {
			W_NextWeapon(0);
		}
	}
}

void TwoWeapons_Init() {
	string s = cvar_string("g_twoweapons");
	float i;
	entity e;
	for (i = WEP_FIRST; i <= WEP_LAST; i++) {
		e = get_weaponinfo(i);
		if (s == e.netname) {
			g_twoweapons = i;
		}
	}
	if not(g_twoweapons)
		return;

	TwoWeapons_PlayerPreThink_NextLink = GameHookChain_PlayerPreThink;
	GameHookChain_PlayerPreThink = TwoWeapons_PlayerPreThink;
}
