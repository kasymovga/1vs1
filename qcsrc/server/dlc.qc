entity dlc;
string sv_dlc_extra;
entity dlc_wait;

void DLCWait() {
	if (dlc_ready_all()) {
		float n = tokenizebyseparator(dlc_list, " ");
		float i;
		localcmd("\n");
		for (i = 0; i < n; i++) {
			if (argv(i) != "")
			if (fexists(strcat("rexdlc_", argv(i), "_server.cfg")))
				localcmd(strcat("exec rexdlc_", argv(i), "_server.cfg", "\n"));
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
	WriteByte(MSG_ENTITY, sf);
	if (sf & 1) {
		WriteString(MSG_ENTITY, dlc_repo);
	}
	if (sf & 2) {
		WriteString(MSG_ENTITY, dlc_list);
	}
	return TRUE;
}

void dlc_require(string dlc_name) {
	float i, n;
	n = tokenize_console(cvar_string("sv_curl_serverpackages"));
	string s;
	for (i = 0; i < n; i++)
		if (argv(i) == strcat("rexdlc_", dlc_name, ".serverpackage"))
			return;

	cvar_set("sv_curl_serverpackages", strcat(cvar_string("sv_curl_serverpackages"), " ", dlc_serverpackage_name(dlc_name)));
	n = tokenizebyseparator(dlc_list, " ");
	for (i = 0; i < n; i++)
		if (argv(i) == dlc_name)
			return;

	if not(dlc) {
		dlc = spawn();
		Net_LinkEntity(dlc, FALSE, 0, dlc_SendEntity);
	} else
		dlc.SendFlags |= 2;

	s = zone_ifneeded(strcat(dlc_list, " ", dlc_name));
	unzone_ifneeded(dlc_list);
	dlc_list = s;
	if not(dlc_load(dlc_name))
	if not(dlc_wait) {
		dlc_wait = spawn();
		dlc_wait.think = DLCWait;
		dlc_wait.nextthink = time + 1;
	}
}

void dlc_init() {
	string s;
	dlc_repo = strzone(cvar_string("sv_dlc_repository"));
	string dlc_extra = cvar_string("sv_dlc_extra");
	while (dlc_extra != "") {
		s = car(dlc_extra);
		dlc_extra = cdr(dlc_extra);
		if (s != "")
			dlc_require(s);
	}
}
