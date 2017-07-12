string dlc_pk3_name(string dlc_name) {
	return strcat("zzz-rexdlc_", dlc_name, ".pk3");
}

string dlc_serverpackage_name(string dlc_name) {
	return strcat("rexdlc_", dlc_name, ".serverpackage");
}
string dlc_url(string dlc_name) {
	return strcat(dlc_repo, dlc_pk3_name(dlc_name));
}

float dlc_ready(string dlc_name) {
	return fexists(dlc_serverpackage_name(dlc_name));
}

float dlc_load(string dlc_name) {
	float n = tokenizebyseparator(dlc_list, " ");
	float i;
	string list = dlc_list;
	string s;
	while (list != "") {
		s = car(list);
		list = cdr(list);
		if (s == dlc_name)
			return TRUE;
	}
	s = strzone(strcat(dlc_list, " ", dlc_name));
	unzone_ifneeded(dlc_list);
	dlc_list = s;
	if (dlc_ready(dlc_name))
		return TRUE;

	localcmd("\ncurl --pak ", dlc_url(dlc_name), "\n");
	return FALSE;
}

float dlc_ready_all() {
	string list = dlc_list;
	string s;
	while (list != "") {
		s = car(list);
		list = cdr(list);
		if (s != "")
		if not(dlc_ready(s))
			return FALSE;
	}
	return TRUE;
}
