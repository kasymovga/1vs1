void(void) game_type_init {
	if (game_type == GAME_TYPE_CTS) {
		registercvar("cl_cts_showacceleration", "1", CVAR_SAVE);
		registercvar("cl_cts_showspeed", "1", CVAR_SAVE);
		if (cvar("cl_cts_showacceleration"))
			cvar_clientsettemp("cl_showacceleration", "1");

		if (cvar("cl_cts_showspeed"))
			cvar_clientsettemp("cl_showspeed", "1");

		race_init();
	}
	if (game_type == GAME_TYPE_SINGLE || game_type == GAME_TYPE_COOP || game_type == GAME_TYPE_SURVIVE) {
		if (game_type == GAME_TYPE_SINGLE) {
			weapon_wheel_enable();
		}
		view_kickangles = TRUE;
	} else
		view_kickangles = FALSE;

	if not(main_isdemo) {
		localcmd("\n_cl_hook_gamestart ", game_type_name(game_type), ";");
		main_calledhooks |= MAIN_HOOK_START;
	}
	sbar_game_init();
}
