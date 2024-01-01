void(entity e, vector flashcolor, float staytime, float intensivity, float alph) rm_hud_flash {
	if (clienttype(e) != CLIENTTYPE_REAL)
		return;

	if (e.classname == "")
		return;

	msg_entity = e;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_HUDFLASH);
	net_write_coord(MSG_ONE, flashcolor_x);
	net_write_coord(MSG_ONE, flashcolor_y);
	net_write_coord(MSG_ONE, flashcolor_z);
	net_write_coord(MSG_ONE, staytime);
	net_write_coord(MSG_ONE, intensivity);
	net_write_coord(MSG_ONE, alph);
}

void(entity e, float staytime, float intensivity, float alph) rm_hud_flash_teamcolor {
	if (clienttype(e) != CLIENTTYPE_REAL)
		return;

	if (e.classname == "")
		return;

	msg_entity = e;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_HUDFLASH_TEAMCOLOR);
	net_write_coord(MSG_ONE, staytime);
	net_write_coord(MSG_ONE, intensivity);
	net_write_coord(MSG_ONE, alph);
}
