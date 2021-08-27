float g_announcer_print;

void(entity player, string msg, string txt) announce_force {
	entity e;
	if (player.classname == "player")
		FOR_EACH_CLIENT(e) {
			if (e.enemy == player)
			if (e.classname == "spectator") {
				announce_force(e, msg, txt);
			}
		}
	if (clienttype(player) != CLIENTTYPE_REAL)
		return;

	player.announcetime = time + 0.8;
	if (msg != "")
		sound_play2(player, msg);

	if (txt != "")
	if (g_announcer_print) {
		msg_entity = player;
		net_write_byte(MSG_ONE, SVC_TEMPENTITY);
		net_write_byte(MSG_ONE, NET_TE_CSQC_ANNOUNCE_PRINT);
		net_write_string(MSG_ONE, txt);
	}
}

void(entity player, string msg, string txt) announce {
	if (time > player.announcetime)
		announce_force(player, msg, txt);
}

void(void) announce_init {
	CVAR_CACHE(g_announcer_print);
}
