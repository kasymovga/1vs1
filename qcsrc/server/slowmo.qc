void(void) slowmo_update {
	slowmo = slowmo_factor * gamehook_chain_slowmo_update_mod(1);
	cvar_set("slowmo", ftos(slowmo));
}
