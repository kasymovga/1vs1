void(void) gametype_init {
	if(gametype == GAME_ONSLAUGHT)
		search_and_precache("gfx/ons-*");

	if not(isdemo_flag) {
		localcmd("\n_cl_hook_gamestart ", gametype_name(gametype), ";");
		calledhooks |= HOOK_START;
	}
	Sbar_GameType_Init();
}
