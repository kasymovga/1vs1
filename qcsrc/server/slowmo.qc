float slowmo_last;
void(void) slowmo_update {
	slowmo = slowmo_factor * gamehook_chain_slowmo_update_mod(1);
	if (slowmo_last != slowmo) {
		slowmo_last = slowmo;
		cvar_set("slowmo", ftos(slowmo));
	}
}
