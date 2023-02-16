string mute_list;

void(void) mute_init {
	registercvar("_mute_list", "");
	mute_list = str_zone_ifneeded(cvar_string("_mute_list"));
}

void(void) mute_shutdown {
	cvar_set("_mute_list", mute_list);
}

float(float n) mute_listed {
	return (strstrofs(mute_list, strcat(" ", ftos(n), " "), 0) >= 0);
}

void(float n) mute_add {
	if (mute_listed(n))
		return;

	if (n <= 0 && n >= 255)
		return;

	string s;
	if (mute_list == "")
		s = strcat(" ", ftos(n), " ");
	else
		s = strcat(mute_list, ftos(n), " ");

	str_unzone_ifneeded(mute_list);
	mute_list = strzone(s);
}

void(float n) mute_remove {
	string s;
	string s1 = strcat(" ", ftos(n), " ");
	n = strstrofs(mute_list, s1, 0);
	if (n < 0)
		return;

	s = strcat(substring(mute_list, 0, n), " ", substring(mute_list, n + strlen(s1), -1));
	str_unzone_ifneeded(mute_list);
	mute_list = strzone(s);
}

float(string strMessage) mute_check {
	float n;
	string s1, s2;
	string prefix;
	string base_name;
	string check_name;
	string colorstr;
	entity pl;
	for (s2 = mute_list; s2 != ""; s2 = str_cdr(s2)) {
		s1 = str_car(s2);
		n = stof(s1);
		pl = player_slots[n - 1];
		if (team_mode) {
			colorstr = team_color_code(pl.team);
			if (colorstr == "^7")
				colorstr = "^0";
		} else
			colorstr = "^0";

		base_name = player_name(n - 1);
		check_name = strcat(base_name, "^0#", s1);
		prefix = strcat("\{1}", check_name, "^7: ");
		if (prefix == substring(strMessage, 0, strlen(prefix))) {
			print("message from #", s1, " was skipped\n");
			return TRUE;
		}
		prefix = strcat("\{1}", colorstr, "(^3", check_name, colorstr, ") ^7");
		if (prefix == substring(strMessage, 0, strlen(prefix))) {
			print("group message from #", s1, " was skipped\n");
			return TRUE;
		}
		prefix = strcat("\{1}* ^3", check_name, "^3 tells you: ^7");
		if (prefix == substring(strMessage, 0, strlen(prefix))) {
			print("private message from #", s1, " was skipped\n");
			return TRUE;
		}
		if (team_mode) {
			check_name = strcat(colorstr, strdecolorize(base_name), "^0#", ftos(n));
			prefix = strcat("\{1}", check_name, "^7: ");
			if (prefix == substring(strMessage, 0, strlen(prefix))) {
				print("message from #", s1, " was skipped\n");
				return TRUE;
			}
			prefix = strcat("\{1}", colorstr, "(^3", check_name, colorstr, ") ^7");
			if (prefix == substring(strMessage, 0, strlen(prefix))) {
				print("group message from #", s1, " was skipped\n");
				return TRUE;
			}
			prefix = strcat("\{1}* ^3", check_name, "^3 tells you: ^7");
			if (prefix == substring(strMessage, 0, strlen(prefix))) {
				print("private message from #", s1, " was skipped\n");
				return TRUE;
			}
		}
	}
	return FALSE;
}
