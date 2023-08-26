void(void) slowmo_update {
	slowmo = slowmo_factor * plugin_chain_slowmo_update_mod(1);
	builtin_cvar_set("slowmo", ftos(slowmo));
}
