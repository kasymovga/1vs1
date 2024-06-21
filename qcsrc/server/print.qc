string(string text, string arg1, string arg2, string arg3) print_text_prepare {
	if (arg1 != "") text = strreplace("{1}", arg1, text);
	if (arg2 != "") text = strreplace("{2}", arg2, text);
	if (arg3 != "") text = strreplace("{3}", arg3, text);
	return text;
}

void(entity cl, float type, string s, string arg1, string arg2, string arg3) print_to {
	msg_entity = cl;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_PRINT);
	type &= 15;
	float c;
	if (arg3 == "") {
		if (arg2 == "") {
			if (arg1 == "") {
				c = 0;
			} else
				c = 1;
		} else
			c = 2;
	} else {
		c = 3;
	}
	net_write_byte(MSG_ONE, (type | (c << 4)));
	net_write_string(MSG_ONE, s);
	if (c > 0) {
		net_write_string(MSG_ONE, arg1);
		if (c > 1) {
			net_write_string(MSG_ONE, arg2);
			if (c > 2)
				net_write_string(MSG_ONE, arg3);
		}
	}
}

void(entity cl, float type, string s, string arg1, string arg2, string arg3, string arg4, string arg5, string arg6) print_to_long {
	msg_entity = cl;
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_PRINT);
	type &= 15;
	float c;
	if (arg6 == "") {
		if (arg5 == "")
			c = 4;
		else
			c = 5;
	} else
		c = 6;

	net_write_byte(MSG_ONE, (type | (c << 4)));
	net_write_string(MSG_ONE, s);
	net_write_string(MSG_ONE, arg1);
	net_write_string(MSG_ONE, arg2);
	net_write_string(MSG_ONE, arg3);
	net_write_string(MSG_ONE, arg4);
	if (c > 4) {
		net_write_string(MSG_ONE, arg5);
		if (c > 5) {
			net_write_string(MSG_ONE, arg6);
		}
	}
}

void(entity cl, float type, string s, string arg1, string arg2, string arg3) print_to_spec {
	entity spec;
	if (cl.classname == "player")
		CLIENT_FOR_EACH_REAL(spec)
			if (spec.enemy == cl)
			if (spec.classname == "spectator")
				print_to(spec, type, s, arg1, arg2, arg3);

	if (clienttype(cl) == CLIENTTYPE_REAL)
		print_to(cl, type, s, arg1, arg2, arg3);
}

void(float type, string s, string arg1, string arg2, string arg3, string arg4, string arg5, string arg6) print_all_long {
	entity e;
	CLIENT_FOR_EACH_REAL(e) {
		print_to_long(e, type, s, arg1, arg2, arg3, arg4, arg5, arg6);
	}
}

void(float type, string s, string arg1, string arg2, string arg3) print_all {
	entity e;
	CLIENT_FOR_EACH_REAL(e) {
		print_to(e, type, s, arg1, arg2, arg3);
	}
	if (world_dedicated) {
		s = strcat(print_text_prepare(s, arg1, arg2, arg3), "\n");
		print(s);
		if (type == PRINT_CHAT)
			plugin_chain_PublicPlayerChat(NULL, s);
	}
}
