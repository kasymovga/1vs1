float g_pinata;
float g_pinata_drop_all;

var float() pinata_player_death_weapon_throw_handle_NextLink;
float() pinata_player_death_weapon_throw_handle {
	if not(g_pinata)
		return pinata_player_death_weapon_throw_handle_NextLink();

	entity wi;
	WEAPON_INFO_FOR_EACH(wi) {
		if ((self.weapons & wi.weapons) || (self.weapons_extra & wi.weapons_extra))
			if (weapon_throwable(wi.weapon) || g_pinata_drop_all)
				weapon_throw_new(self, wi.weapon, FALSE, self.origin, randomvec() * 175 + '0 0 325');
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
	pinata_player_death_weapon_throw_handle_NextLink = plugin_chain_player_death_weapon_throw_handle;
	plugin_chain_player_death_weapon_throw_handle = pinata_player_death_weapon_throw_handle;
}
