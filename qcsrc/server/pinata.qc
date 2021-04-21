float g_pinata;
float g_pinata_drop_all;

var float() pinata_player_death_weapon_throw_handle_NextLink;
float() pinata_player_death_weapon_throw_handle {
	if not(g_pinata)
		return pinata_player_death_weapon_throw_handle_NextLink();

	float j;
	for(j = WEP_FIRST; j <= WEP_LAST; ++j) {
		if(self.weapons & weapon_bit(j))
			if (weapon_throwable(j) || g_pinata_drop_all)
				weapon_throw_new(self, j, FALSE, self.origin, randomvec() * 175 + '0 0 325');
	}
	return TRUE;
}

float pinata_init_done;
void() pinata_init {
	CVAR_CACHE(g_pinata);
	CVAR_CACHE(g_pinata_drop_all);
	if (pinata_init_done)
		return;

	pinata_init_done = TRUE;
	pinata_player_death_weapon_throw_handle_NextLink = gamehook_chain_player_death_weapon_throw_handle;
	gamehook_chain_player_death_weapon_throw_handle = pinata_player_death_weapon_throw_handle;
}
