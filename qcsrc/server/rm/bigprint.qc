void(entity e, string bigstring, string comment, float staytime) rm_bigprint {
	if (clienttype(e) != CLIENTTYPE_REAL)
		return;

	msg_entity = e;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_BIGPRINT);
	net_write_string(MSG_ONE, bigstring);
	net_write_string(MSG_ONE, comment);
	net_write_short(MSG_ONE, staytime);
}

void(entity pl, string msg, string comment, float staytime) rm_bigprint_spec {
	entity e;
	CLIENT_FOR_EACH_REAL(e)
		if (e == pl || e.enemy == pl)
			rm_bigprint(e, msg, comment, staytime);
}

void(string bigstring, string comment, float staytime) rm_bigprint_all {
	entity e;
	CLIENT_FOR_EACH_REAL(e)
		rm_bigprint(e, bigstring, comment, staytime);
}

void(string bigstring, string comment, float staytime) rm_bigprint_all_player_spec {
	entity e;
	CLIENT_FOR_EACH_REAL(e)
		if (e.classname == "player" || e.classname == "spectator")
		rm_bigprint(e, bigstring, comment, staytime);
}
