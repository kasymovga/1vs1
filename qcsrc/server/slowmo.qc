void(void) slowmo_update {
	slowmo = gamehook_chain_slowmo_update_mod(1);
	cvar_set("slowmo", ftos(slowmo));
}
