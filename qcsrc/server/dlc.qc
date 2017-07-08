entity dlc;
string dlc_list_send;
entity dlc_wait;

string dlc_init_cvar(string dlc_name) {
	return strcat("_dlc_initiated_", dlc_name);
}

void dlc_exec_cfg(string dlc_name) {
	if (fexists(strcat("rexdlc_", dlc_name, "_server.cfg")))
		localcmd(strcat("exec rexdlc_", dlc_name, "_server.cfg", "\n"));
}

void DLCWait() {
	if (dlc_ready_all()) {
		float n = tokenizebyseparator(dlc_list, " ");
		float i;
		localcmd("\n");
		for (i = 0; i < n; i++) {
			if (argv(i) != "") {
				dlc_exec_cfg(argv(i));
				registercvar(dlc_init_cvar(argv(i)), "1");
			}
		}
		localcmd("restart\n");
		localcmd("r_restart\n"); //In case if it local server
		remove(self);
		dlc_wait = world;
		return;
	}
	print("Some DLC is not ready\n");
	self.nextthink = time + 1;
}

float dlc_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_DLC_LIST);
	sf &~= 4;
	if (to.netaddress == "local") {
		sf |= 4;
	}
	WriteByte(MSG_ENTITY, sf);
	if (sf & 1) {
		WriteString(MSG_ENTITY, dlc_repo);
	}
	if (sf & 2) {
		WriteString(MSG_ENTITY, dlc_list_send);
	}
	return TRUE;
}

void dlc_require_server_only(string dlc_name) {
	float n = tokenizebyseparator(dlc_list, " ");
	float i;
	for (i = 0; i < n; i++)
		if (argv(i) == dlc_name)
			return;

	string s = strzone(strcat(dlc_list, " ", dlc_name));
	unzone_ifneeded(dlc_list);
	dlc_list = s;
	if (dlc_load(dlc_name))
		dlc_exec_cfg(dlc_name); //Just in case

	if not(cvar(dlc_init_cvar(dlc_name)))
	if not(dlc_wait) {
		dlc_wait = spawn();
		dlc_wait.think = DLCWait;
		dlc_wait.nextthink = time + 1;
	}
}

void dlc_require(string dlc_name) {
	float i, n;
	n = tokenize_console(cvar_string("sv_curl_serverpackages"));
	string s;
	float add_to_server_packages;
	add_to_server_packages = TRUE;
	for (i = 0; i < n; i++)
		if (argv(i) == strcat("rexdlc_", dlc_name, ".serverpackage"))
			add_to_server_packages = FALSE;

	if (add_to_server_packages)
		cvar_set("sv_curl_serverpackages", strcat(cvar_string("sv_curl_serverpackages"), " ", dlc_serverpackage_name(dlc_name)));

	n = tokenizebyseparator(dlc_list_send, " ");
	for (i = 0; i < n; i++)
		if (argv(i) == dlc_name)
			return;

	if not(dlc) {
		dlc = spawn();
		Net_LinkEntity(dlc, FALSE, 0, dlc_SendEntity);
	} else
		dlc.SendFlags |= 2;

	s = strzone(strcat(dlc_list_send, " ", dlc_name));
	unzone_ifneeded(dlc_list_send);
	dlc_list_send = s;
	dlc_require_server_only(dlc_name);
}

void dlc_init() {
	string s;
	dlc_repo = strzone(cvar_string("sv_dlc_repository"));
	string server_packages = cvar_string("sv_curl_serverpackages");
	string server_packages_without_dlc = "";
	while (server_packages != "") {
		s = car(server_packages);
		server_packages = cdr(server_packages);
		if (s != "")
		if (strstrofs(s, "rexdlc_", 0) != 0)
			server_packages_without_dlc = strcat(server_packages_without_dlc, " ", s);
	}
	cvar_set("sv_curl_serverpackages", server_packages_without_dlc);
	string dlc_extra = cvar_string("sv_dlc_extra");
	while (dlc_extra != "") {
		s = car(dlc_extra);
		dlc_extra = cdr(dlc_extra);
		if (s != "")
			dlc_require(s);
	}
	string dlc_server_only = strcat(cvar_string("sv_dlc_maps"), " ", cvar_string("sv_dlc_server_only"));
	while (dlc_server_only != "") {
		s = car(dlc_server_only);
		dlc_server_only = cdr(dlc_server_only);
		if (s != "")
			dlc_require_server_only(s);
	}
	s = cvar_string("_map_dlc");
	if (s != "")
		dlc_require(s);
}
