void(void) weapon_info_send {
	entity e;
	for (float i = WEP_FIRST; i < WEP_LAST_EXTRA; i++) {
		e = weapon_info(i);
		if not(e.weapon) continue;
		net_write_byte(MSG_ENTITY, e.weapon);
		net_write_byte(MSG_ENTITY, e.impulse);
		net_write_coord(MSG_ENTITY, e.items);
		net_write_string(MSG_ENTITY, e.netname);
	}
	net_write_byte(MSG_ENTITY, 0);
}
