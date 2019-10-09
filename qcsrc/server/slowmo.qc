void(void) slowmo_update {
	slowmo = GameHookChain_TempoMod(1);
	cvar_set("slowmo", ftos(slowmo));
}
