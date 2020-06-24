void(void) gametype_init {
	if(gametype == GAME_ONSLAUGHT)
		search_and_precache("gfx/ons-*");

	if (gametype == GAME_CTS) {
		registercvar("cl_cts_showacceleration", "1", CVAR_SAVE);
		registercvar("cl_cts_showspeed", "1", CVAR_SAVE);
		if (cvar("cl_cts_showacceleration"))
			cvar_clientsettemp("cl_showacceleration", "1");

		if (cvar("cl_cts_showspeed"))
			cvar_clientsettemp("cl_showspeed", "1");
	}
	if not(isdemo_flag) {
		localcmd("\n_cl_hook_gamestart ", gametype_name(gametype), ";");
		calledhooks |= HOOK_START;
	}
	Sbar_GameType_Init();
}
