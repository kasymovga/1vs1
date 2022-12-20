float perf_high_load_mode;
void(float load, float lost, float offset_avg, float offset_max, float offset_sadv) perf_event { //called by engine
	if (!perf_high_load_mode && load > 0.8) {
		perf_high_load_mode = TRUE;
		entity e;
		if not(cvar("_sv_init"))
		if not(cvar("sv_threaded"))
			return; //don't really have sense if server running in render thread

		chat_print("* Server load high, adjusting settings...\n");
		cvar_settemp("mod_q3bsp_tracelineofsight_brushes", "0");
		debris_disable();
	}
}
