string(string s, string arg1, string arg2, string arg3, string arg4, string arg5, string arg6) print_text_prepare_long {
	s = translate(s);
	float cmdkey, cmdkey_end;
	for (cmdkey = 0; (cmdkey = strstrofs(s, "{", cmdkey)) >= 0;) {
		cmdkey_end = strstrofs(s, "}", cmdkey);
		if (cmdkey_end < 0)
			break;

		string s1, s2, s3;
		s1 = substring(s, 0, cmdkey);
		if (cmdkey + 1 == cmdkey_end) {
			s2 = "{";
		} else {
			s2 = substring(s, cmdkey + 1, cmdkey_end - cmdkey - 1);
			if (cmdkey + 2 == cmdkey_end) {
				if (s2 == "1")
					s2 = arg1;
				else if (s2 == "2")
					s2 = arg2;
				else if (s2 == "3")
					s2 = arg3;
				else if (s2 == "4")
					s2 = arg4;
				else if (s2 == "5")
					s2 = arg5;
				else if (s2 == "6")
					s2 = arg6;
			} else if (cmdkey + 3 == cmdkey_end && substring(s2, 0, 1) == "$") {
				if (s2 == "$1")
					s2 = arg1;
				else if (s2 == "$2")
					s2 = arg2;
				else if (s2 == "$3")
					s2 = arg3;
				else if (s2 == "$4")
					s2 = arg4;
				else if (s2 == "$5")
					s2 = arg5;
				else if (s2 == "$6")
					s2 = arg6;

				s2 = translate(s2);
			} else
				s2 = input_command_key(s2, s2);
		}
		s3 = substring(s, cmdkey_end + 1, -1);
		cmdkey = strlen(s1) + strlen(s2);
		s = strcat(s1, s2, s3);
	}
	return s;
}

string(string s, string arg1, string arg2, string arg3) print_text_prepare {
	s = translate(s);
	float cmdkey, cmdkey_end;
	for (cmdkey = 0; (cmdkey = strstrofs(s, "{", cmdkey)) >= 0;) {
		cmdkey_end = strstrofs(s, "}", cmdkey);
		if (cmdkey_end < 0)
			break;

		string s1, s2, s3;
		s1 = substring(s, 0, cmdkey);
		if (cmdkey + 1 == cmdkey_end) {
			s2 = "{";
		} else {
			s2 = substring(s, cmdkey + 1, cmdkey_end - cmdkey - 1);
			if (cmdkey + 2 == cmdkey_end) {
				if (s2 == "1")
					s2 = arg1;
				else if (s2 == "2")
					s2 = arg2;
				else if (s2 == "3")
					s2 = arg3;
			} else if (cmdkey + 3 == cmdkey_end && substring(s2, 0, 1) == "$") {
				if (s2 == "$1")
					s2 = arg1;
				else if (s2 == "$2")
					s2 = arg2;
				else if (s2 == "$3")
					s2 = arg3;

				s2 = translate(s2);
			} else
				s2 = input_command_key(s2, s2);
		}
		s3 = substring(s, cmdkey_end + 1, -1);
		cmdkey = strlen(s1) + strlen(s2);
		s = strcat(s1, s2, s3);
	}
	return s;
}

void(void) print_read {
	float type = net_read_byte();
	float c = (type >> 4);
	type &= 15;
	string s = net_read_string();
	if (c > 0) {
		if (c > 1) {
			if (c > 2) {
				if (c > 3) {
					if (c > 4) {
						if (c > 5)
							s = print_text_prepare_long(s, net_read_string(), net_read_string(), net_read_string(), net_read_string(), net_read_string(), net_read_string());
						else
							s = print_text_prepare_long(s, net_read_string(), net_read_string(), net_read_string(), net_read_string(), net_read_string(), "");
					} else {
						s = print_text_prepare_long(s, net_read_string(), net_read_string(), net_read_string(), net_read_string(), "", "");
					}
				} else
					s = print_text_prepare(s, net_read_string(), net_read_string(), net_read_string());
			} else
				s = print_text_prepare(s, net_read_string(), net_read_string(), "");
		} else {
			s = print_text_prepare(s, net_read_string(), "", "");
		}
	} else {
		s = print_text_prepare(s, "", "", "");
	}
	if (type == PRINT_CENTER) {
		print_center(s);
	} else if (type == PRINT_INFO) {
		print(s, "\n");
	} else if (type == PRINT_CHAT) {
		print("\{1}", s, "\n");
	} else if (type == PRINT_CHAT_SILENT) {
		print("\{3}", s, "\n");
	}
}
