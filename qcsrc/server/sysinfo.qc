.string sysinfo;
string sv_sysinfo_checker;
float URI_SYSINFO_CHECKER;

var float(string cmd, float tokens) sysinfo_ClientCommandHandle_NextLink;
float(string cmd, float tokens) sysinfo_ClientCommandHandle {
	float i;
	string tmp;
    if(cmd == "sysinfo") {
		tmp = argv(1);
		for (i = 2; i < tokens; i++) {
			tmp = strcat(tmp, "-", argv(i));
		}
		tmp = strreplace(" ", "-", tmp);
		tmp = strreplace("%", "-", tmp);
		tmp = strreplace("\\", "/", tmp);
		tmp = strreplace("\"", "", tmp);
		tmp = strreplace("&", "", tmp);
		tmp = strreplace("?", "", tmp);
		if (tmp != "")
		if (self.sysinfo == "") {
			self.sysinfo = strzone(tmp);
			if (sv_sysinfo_checker != "")
				uri_get(strcat(sv_sysinfo_checker, tmp), URI_SYSINFO_CHECKER);
		}
		return TRUE;
	}
	return sysinfo_ClientCommandHandle_NextLink(cmd, tokens);
}

void(string _info, .float field, float val, string s) sysinfo_search_and_mark {
	entity e;
	for (e = find(world, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
		print(e.netname, " ", s, "\n");
		e.field = val;
	}
}

void(float id, float status, string data) sysinfo_uri_callback {
    if (status) {
        print(strcat("sysinfo checker failed, status: ", ftos(status)));
        return;
    }
	string head, tail, _info;
	tail = data;
	_info = car(tail);
	tail = cdr(tail);
	entity e;
	while (tail != "") {
		head = car(tail);
		if (head == "saboteur")
			sysinfo_search_and_mark(_info, saboteur, 1, "marked as saboteur");
		else if (head == "retard")
			sysinfo_search_and_mark(_info, retard, 1, "marked as retard");
		else if (head == "muted")
			sysinfo_search_and_mark(_info, muted, 1, "muted");
		else if (head == "drop") {
			for (e = find(world, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
				print(e.netname, " droped because of sysinfo check\n");
				dropclient(e);
			}
			break;
		}
		tail = cdr(tail);
	}
}

var void() sysinfo_RealClientDisconnect_NextLink;
void() sysinfo_RealClientDisconnect {
	unzone_ifneeded(self.sysinfo);
	sysinfo_RealClientDisconnect_NextLink();
}

void() sysinfo_init {
	CACHE_CVAR_STR(sv_sysinfo_checker);
	sysinfo_ClientCommandHandle_NextLink = GameHookChain_ClientCommandHandle;
	GameHookChain_ClientCommandHandle = sysinfo_ClientCommandHandle;
	sysinfo_RealClientDisconnect_NextLink = GameHookChain_RealClientDisconnect;
	GameHookChain_RealClientDisconnect = sysinfo_RealClientDisconnect;
	URI_SYSINFO_CHECKER = URI_RegisterHandler(sysinfo_uri_callback);
}
