.string sysinfo;
string sv_sysinfo_checker;
float URI_SYSINFO_CHECKER;

var float(string cmd, float tokens) sysinfo_ClientCommandHandle_NextLink;
float(string cmd, float tokens) sysinfo_ClientCommandHandle {
	float i;
	string tmp;
	if(cmd == "sysinfo") {
		if (g_campaign)
			return TRUE;

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
			tmp = strcat(tmp, "&ip=", self.netaddress);
			tmp = strcat(tmp, "&name=", uri_escape(self.netname));
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
		voip_setup(e);
	}
}

void(void) sysinfo_flag_think {
	self.cnt--;
	entity e;
	FOR_EACH_REALCLIENT(e) {
		if (e.sysinfo == self.netname) {
			ip2c_set(e, self.message);
			self.cnt = -1;
		}
	}
	if (self.cnt < 0) {
		str_unzone_ifneeded(self.netname);
		str_unzone_ifneeded(self.message);
		remove(self);
		return;
	}
	self.nextthink = time + 1;
}

void(float id, float status, string data) sysinfo_uri_callback {
	if (status) {
		print("sysinfo checker failed, status: ", ftos(status), "\n");
		return;
	}
	string head, tail, _info;
	tail = data;
	_info = str_car(tail);
	tail = str_cdr(tail);
	entity e;
	while (tail != "") {
		head = str_car(tail);
		if (head == "saboteur")
			sysinfo_search_and_mark(_info, saboteur, 1, "marked as saboteur");
		else if (head == "noteam" && team_mode) {
			sysinfo_search_and_mark(_info, saboteur, 2, "marked as no team");
			FOR_EACH_REALPLAYER(e) {
				if (e.sysinfo == _info)
					player_to_spec(e);
			}
		} else if (head == "nodup") {
			string addr = "";
			FOR_EACH_REALCLIENT(e) {
				if (e.sysinfo == _info) {
					addr = e.netaddress;
					break;
				}
			}
			if (addr != "") {
				float keepone = FALSE;
				FOR_EACH_REALCLIENT(e) {
					if (e.netaddress == addr) {
						if (keepone)
							dropclient(e);
						else
							keepone = TRUE;
					}
				}
			}
		} else if (head == "retard") {
			sysinfo_search_and_mark(_info, retard, 1, "marked as retard");
			FOR_EACH_REALCLIENT(e) {
				if (e.retard > 0)
					e.netname = client_retardplayername;
			}
		} else if (head == "muted")
			sysinfo_search_and_mark(_info, muted, 1, "muted");
		else if (head == "stacker")
			sysinfo_search_and_mark(_info, stacker, 1, "marked as stacker");
		else if (head == "drop") {
			for (e = find(world, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
				print(e.netname, " droped because of sysinfo check\n");
				dropclient(e);
			}
			break;
		} else if (substring(head, 0, 5)  == "flag=") {
			print("flag received\n");
			e = spawn();
			e.nextthink = time + 1;
			e.message = str_zone_ifneeded(substring(head, 5, 2));
			e.netname = str_zone_ifneeded(_info);
			e.think = sysinfo_flag_think;
			e.cnt = 5;
		} else if (substring(head, 0, 5) == "clid=") {
			for (e = find(world, sysinfo, _info); e; e = find(e, sysinfo, _info)) {
				str_unzone_ifneeded(e.clid);
				e.clid = str_zone_ifneeded(substring(head, 5, 16));
				stuffcmd(e, strcat("seta _cl_id ", e.clid, "\n"));
				entity oldself = self;
				self = e;
				rank_load();
				self = oldself;
				print(e.netname, " have clid forced by sysinfo: ", e.clid, "\n");
			}
		}
		tail = str_cdr(tail);
	}
}

var void() sysinfo_client_disconnect_real_NextLink;
void() sysinfo_client_disconnect_real {
	str_unzone_ifneeded(self.sysinfo);
	sysinfo_client_disconnect_real_NextLink();
}

void() sysinfo_init {
	CVAR_CACHE_STR(sv_sysinfo_checker);
	sysinfo_ClientCommandHandle_NextLink = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = sysinfo_ClientCommandHandle;
	sysinfo_client_disconnect_real_NextLink = plugin_chain_client_disconnect_real;
	plugin_chain_client_disconnect_real = sysinfo_client_disconnect_real;
	URI_SYSINFO_CHECKER = uri_register_handler(sysinfo_uri_callback);
}
