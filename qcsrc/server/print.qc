void(entity cl, float type, string s, string arg1, string arg2, string arg3) print_to {
	msg_entity = cl;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_PRINT);
	net_write_byte(MSG_ONE, type);
	net_write_string(MSG_ONE, s);
	net_write_string(MSG_ONE, arg1);
	net_write_string(MSG_ONE, arg2);
	net_write_string(MSG_ONE, arg3);
}

void(float type, string s, string arg1, string arg2, string arg3) print_all {
	entity e;
	FOR_EACH_REALCLIENT(e) {
		print_to(e, type, s, arg1, arg2, arg3);
	}
}
