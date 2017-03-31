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
	if (dlc_ready(dlc_name))
		return TRUE;

	localcmd("\ncurl --pak ", dlc_url(dlc_name), "\n");
	return FALSE;
}

float dlc_ready_all() {
	float n = tokenize_console(dlc_list);
	float i;
	for (i = 0; i < n; i++)
		if (argv(i) != "")
		if not(dlc_ready(argv(i)))
			return FALSE;

	return TRUE;
}
