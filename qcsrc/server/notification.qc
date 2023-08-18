void(entity e1, float icontype, float iconmessage, entity e2) notification {
	net_write_byte(MSG_BROADCAST, SVC_TEMPENTITY);
	net_write_byte(MSG_BROADCAST, NET_TE_CSQC_NOTIFICATION);
	if (clienttype(e1) == CLIENTTYPE_NOTACLIENT)
		icontype |= 64;
	else
		icontype &= ~64;

	net_write_byte(MSG_BROADCAST, icontype);
	if (icontype & 64)
		net_write_string(MSG_BROADCAST, e1.netname);
	else
		net_write_short(MSG_BROADCAST, num_for_edict(e1));

	net_write_short(MSG_BROADCAST, num_for_edict(e2));
	net_write_coord(MSG_BROADCAST, iconmessage);
}
