float g_twoweapons;
var .float twoweapons_buttonatck1 = BUTTON_ATCK;
var .float twoweapons_buttonatck2 = BUTTON_ATCK2;

var void() weapon_two_weapons_player_think_next;
void() weapon_two_weapons_player_think {
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
	weapon_two_weapons_player_think_next();
}

void() weapon_two_weapons_init {
	string s = cvar_string("g_twoweapons");
	entity e;
	WEAPON_INFO_FOR_EACH(e) {
		if (s == e.netname) {
			g_twoweapons = e.weapon;
		}
	}
	if not(g_twoweapons)
		return;

	if (cvar("g_twoweapons_invert_buttons")) {
		twoweapons_buttonatck1 = BUTTON_ATCK2;
		twoweapons_buttonatck2 = BUTTON_ATCK;
	}
	weapon_two_weapons_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = weapon_two_weapons_player_think;
}
