void(void) gametype_init {
	if (gametype == GAMETYPE_CTS) {
		registercvar("cl_cts_showacceleration", "1", CVAR_SAVE);
		registercvar("cl_cts_showspeed", "1", CVAR_SAVE);
		if (cvar("cl_cts_showacceleration"))
			cvar_clientsettemp("cl_showacceleration", "1");

		if (cvar("cl_cts_showspeed"))
			cvar_clientsettemp("cl_showspeed", "1");

		race_init();
	}
	if (gametype == GAMETYPE_SINGLE || gametype == GAMETYPE_COOP || gametype == GAMETYPE_SURVIVE) {
		view_kickangles = TRUE;
	} else
		view_kickangles = FALSE;

	if not(main_isdemo) {
		localcmd("\n_cl_hook_gamestart ", gametype_name(gametype), ";");
		main_calledhooks |= MAIN_HOOK_START;
	}
	sbar_gametype_init();
}
