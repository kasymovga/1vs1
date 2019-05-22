float g_twoweapons;
var .float twoweapons_buttonatck1 = BUTTON_ATCK;
var .float twoweapons_buttonatck2 = BUTTON_ATCK2;

var void() TwoWeapons_PlayerPreThink_NextLink;
void TwoWeapons_PlayerPreThink() {
	if (self.twoweapons_buttonatck1)
		weapon_switch(g_twoweapons);
	else if (self.twoweapons_buttonatck2) {
		if (!self.switchweapon || self.switchweapon == g_twoweapons) {
			float lastwep = self.cnt;
			if (lastwep && lastwep != g_twoweapons) {
				weapon_switch(lastwep);
				if (self.switchweapon != lastwep)
					weapon_next(0);
			} else
				weapon_next(0);
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

	if (cvar("g_twoweapons_invert_buttons")) {
		twoweapons_buttonatck1 = BUTTON_ATCK2;
		twoweapons_buttonatck2 = BUTTON_ATCK;
	}
	TwoWeapons_PlayerPreThink_NextLink = GameHookChain_PlayerPreThink;
	GameHookChain_PlayerPreThink = TwoWeapons_PlayerPreThink;
}
