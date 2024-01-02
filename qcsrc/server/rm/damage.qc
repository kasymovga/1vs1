void(entity to, vector o, float _damage, float admg) rm_damage_indicator {
	if (clienttype(to) != CLIENTTYPE_REAL) return;
	msg_entity = to;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_RM_DAMAGE_INDICATOR);
	net_write_short(MSG_ONE, o_x);
	net_write_short(MSG_ONE, o_y);
	net_write_short(MSG_ONE, o_z);
	net_write_byte(MSG_ONE, NET_BOUND_TO_BYTE(_damage + 0.4));
	net_write_byte(MSG_ONE, NET_BOUND_TO_BYTE(admg));
}
