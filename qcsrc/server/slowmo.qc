void(void) slowmo_update {
	slowmo = gamehook_chain_TempoMod(1);
	cvar_set("slowmo", ftos(slowmo));
}
