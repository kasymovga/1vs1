string(string s, string arg1, string arg2, string arg3) print_text_prepare {
	s = translate(s);
	float cmdkey, cmdkey_end;
	if (main_isdemo) {
		cmdkey = strstrofs(s, "\n", 0);
		if (cmdkey >= 0)
			s = substring(s, 0, cmdkey);
	}
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
	string s = net_read_string();
	string arg1 = net_read_string();
	string arg2 = net_read_string();
	string arg3 = net_read_string();
	s = print_text_prepare(s, arg1, arg2, arg3);
	if (type == PRINT_CENTER) {
		centerprint(s);
	} else if (type == PRINT_INFO) {
		print(s, "\n");
	} else if (type == PRINT_CHAT) {
		print("\{1}", s, "\n");
	}
}
