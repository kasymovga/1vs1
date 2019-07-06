float sv_announcer_print;

float(entity player, string msg, string txt) announce_force {
	if not(clienttype(player) == CLIENTTYPE_REAL)
		return FALSE;

	player.announcetime = time + 0.8;
	if (msg != "")
		sound_play2(player, msg);

	if (txt != "")
	if (sv_announcer_print) {
		msg_entity = player;
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_ANNOUNCE_PRINT);
		WriteString(MSG_ONE, txt);
	}
	return TRUE;
}

float(entity player, string msg, string txt) announce {
    if (time > player.announcetime)
		return announce_force(player, msg, txt);

    return FALSE;
}

void(void) announce_init {
	CACHE_CVAR(sv_announcer_print);
}
