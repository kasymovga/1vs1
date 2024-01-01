void(void) rm_init {
	rm_active = cvar("g_rm");
	rm_flak = cvar("g_rm_flak");
	rm_pryaxe = cvar("g_rm_pryaxe");
	if (rm_active) {
		print("RM mode active\n");
	}
}
