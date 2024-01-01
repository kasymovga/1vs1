void(void) rm_init {
	rm_active = cvar("g_rm");
	if (rm_active) {
		print("RM mode active\n");
	}
}
