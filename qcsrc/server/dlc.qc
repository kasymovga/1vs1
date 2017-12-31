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
		string list, s;
		list = dlc_list;
		localcmd("\n");
		while (list != "") {
			s = car(list);
			list = cdr(list);
			if (s != "") {
				dlc_exec_cfg(s);
				registercvar(dlc_init_cvar(s), "1");
			}
		}
		entity e;
		FOR_EACH_REALCLIENT(e)
			if (e.netaddress == "local") {
				localcmd("r_restart\n");
				break;
			}
		localcmd("restart\n");
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
		WriteString(MSG_ENTITY, cvar_string("sv_dlc_repository"));
	}
	if (sf & 2) {
		WriteString(MSG_ENTITY, dlc_list_send);
	}
	return TRUE;
}

void dlc_require_server_only(string dlc_name) {
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
	string s, list;
	list = cvar_string("sv_curl_serverpackages");
	float add_to_server_packages;
	add_to_server_packages = TRUE;
	while (list != "") {
		s = car(list);
		list = cdr(list);
		if (s == strcat("rexdlc_", dlc_name, ".serverpackage"))
			add_to_server_packages = FALSE;
	}

	if (add_to_server_packages)
		cvar_set("sv_curl_serverpackages", strcat(cvar_string("sv_curl_serverpackages"), " ", dlc_serverpackage_name(dlc_name)));

	list = dlc_list_send;
	while (list != "") {
		s = car(list);
		list = cdr(list);
		if (s == dlc_name)
			return;
	}
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
	dlc_set_repos(cvar_string("sv_dlc_repository"));
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

entity dlc_wait_reload;

void DLCWaitReload() {
	if (dlc_ready_all()) {
		localcmd("\n");
		string list = dlc_list;
		string s;
		while (list != "") {
			s = car(list);
			list = cdr(list);
			if (s != "")
				dlc_exec_cfg(s);
		}
		remove(self);
		dlc_wait_reload = world;
	}
	self.nextthink = time + 1;
}

void dlc_reload() {
	string list = dlc_list;
	string s;
	while (list != "") {
		s = car(list);
		list = cdr(list);
		if (s != "")
			dlc_load(s);
	}
	list = dlc_list_send;
	while (list != "") {
		s = car(list);
		list = cdr(list);
		if (s != "")
			dlc_require(s);
	}
	if not(dlc_wait_reload) {
		dlc_wait_reload = spawn();
		dlc_wait_reload.think = DLCWaitReload;
		dlc_wait_reload.nextthink = time + 1;
	}
}
