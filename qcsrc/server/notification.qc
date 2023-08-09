void(entity e1, float icontype, float iconmessage, entity e2) notification {
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_NOTIFICATION);
	net_write_byte(MSG_BROADCAST, icontype);
	net_write_short(MSG_BROADCAST, num_for_edict(e1));
	net_write_short(MSG_BROADCAST, num_for_edict(e2));
	net_write_coord(MSG_BROADCAST, iconmessage);
}
