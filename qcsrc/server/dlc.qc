entity dlc;
string dlc_list_send;
entity dlc_wait;
string dlc_sounds;
string dlc_extra_pk3_list;

string(string s) dlc_trimspaces {
	string c;
	for (;;) {
		c = substring(s, 0, 1);
		if (c == " " || c == "\t") {
			s = substring (s, 1, -1);
			continue;
		}
		break;
	}
	float n;
	for (;;) {
		n = strlen(s) - 1;
		if (n < 0) break;
		c = substring(s, n, 1);
		if (c == " " || c == "\t") {
			s = substring (s, 0, n);
			continue;
		}
		break;
	}
	return s;
}

float(string s) dlc_findspace {
	float space = strstrofs(s, " ", 0);
	float tab = strstrofs(s, "\t", 0);
	float separator = -1;
	if (space > 0 && tab > 0)
		separator = min(space, tab);
	else if (space > 0)
		separator = space;
	else if (tab > 0)
		separator = tab;

	return separator;
}

void dlc_settemp(string name, string value) {
	float n = cvar("_dlc_settemps_count");
	print("DLC set temp: ", name, " = ", value, "\n");
	string s1 = strcat("_dlc_settemp_name", ftos(n));
	string s2 = strcat("_dlc_settemp_savevalue", ftos(n));
	registercvar(s1, "");
	registercvar(s2, "");
	cvar_set(s1, name);
	cvar_set(s2, cvar_string(name));
	cvar_set(name, value);
	cvar_set("_dlc_settemps_count", ftos(n + 1));
}

float(string s) dlc_load_settemps_from {
	float f;
	string line, c;
	string cvar_name, cvar_value;
	float separator;
	f = fopen(s, FILE_READ);
	if (f < 0) return FALSE;
	float r = 1;
	while ((line = dlc_trimspaces(fgets(f)))) {
		c = substring(line, 0, 1);
		if (c == "#" || c == "/") continue;
		separator = dlc_findspace(line);
		if (separator < 0)
			continue;

		cvar_name = substring(line, 0, separator);
		if (cvar_name == "require") {
			line = dlc_trimspaces(substring(line, separator + 1, -1));
			separator = dlc_findspace(line);
			if (separator < 0)
				continue;

			cvar_name = substring(line, 0, separator);
			cvar_value = dlc_trimspaces(substring(line, separator + 1, -1));
			if (cvar_name == "g_profile") {
				if not(cvar_profile_presents(cvar_value)) {
					r = 0;
					break;
				}
			} else if (cvar_string(cvar_name) != cvar_value) {
				r = 0;
				break;
			}
			continue;
		}
		cvar_value = dlc_trimspaces(substring(line, separator + 1, -1));
		dlc_settemp(cvar_name, cvar_value);
	}
	fclose(f);
	return r;
}

void(string dlc_name) dlc_exec_cfg {
	dlc_load_settemps_from(strcat("rexdlc_", dlc_name, "_settemps.cfg"));
	if (file_exists(strcat("rexdlc_", dlc_name, "_server.cfg")))
		localcmd(strcat("exec rexdlc_", dlc_name, "_server.cfg", "\n"));
}

void(void) dlc_unload_settemps {
	float n = cvar("_dlc_settemps_count");
	float i;
	for (i = 0; i < n; i++) {
		cvar_set(cvar_string(strcat("_dlc_settemp_name", ftos(i))), cvar_string(strcat("_dlc_settemp_savevalue", ftos(i))));
	}
	cvar_set("_dlc_settemps_count", "0");
}

void(void) dlc_load_exts {
	dlc_unload_settemps();
	float search = search_begin("rexext_*.cfg", TRUE, TRUE);
	if (search < 0)
		return;

	float n = search_getsize(search);
	float i;
	string s, head, tail;
	float add_to_server_packages;
	for (i = 0; i < n; i++) {
		add_to_server_packages = TRUE;
		s = search_getfilename(search, i);
		if not(dlc_load_settemps_from(s))
			continue;

		tail = cvar_string("sv_curl_serverpackages");
		while (tail != "") {
			head = str_car(tail);
			tail = str_cdr(tail);
			if (head == s) {
				add_to_server_packages = FALSE;
				break;
			}
		}
		if (add_to_server_packages)
			cvar_set("sv_curl_serverpackages", strcat(cvar_string("sv_curl_serverpackages"), " ", s));
	}
	search_end(search);
}

void(void) dlc_reset_all {
	entity e = self;
	for (self = nextent(world); self; self = nextent(self)) {
		if (self.dlc_reset) {
			print("DLC reset for ", self.classname, "\n");
			self.dlc_reset();
		}
	}
	self = e;
	weapon_register_weapons();
	float i, wbit;
	for (i = WEP_FIRST; i <= WEP_LAST; i++) {
		wbit = weapon_bit(i);
		if ((weapon_spawned_list & wbit) || (player_start_weapons & wbit))
			weapon_info(i).weapon_func(WR_PRECACHE);
	}
}

#define dlc_wait_think DLCWait //compatibility with old save files
void(void) dlc_wait_think {
	if (dlc_ready_all()) {
		string list, s;
		list = dlc_list;
		localcmd("\n");
		dlc_load_exts();
		while (list != "") {
			s = str_car(list);
			list = str_cdr(list);
			if (s != "") {
				dlc_exec_cfg(s);
			}
		}
		entity e;
		FOR_EACH_REALCLIENT(e)
			if (e.netaddress == "local") {
				localcmd("sv_cmd dlc_pause; r_restart; cl_cmd r_restart; sv_cmd dlc_unpause\n");
				break;
			}
		remove(self);
		dlc_wait = world;
		localcmd("sv_cmd dlc_reset\n");
		return;
	}
	print("Some DLC is not ready\n");
	self.nextthink = time + 1;
}

#define dlc_send dlc_SendEntity //compatibility with old save files
float(entity to, float sf) dlc_send {
	WriteByte(MSG_ENTITY, NET_CSQC_DLC_LIST);
	sf &= ~12;
	if (to.netaddress == "local") {
		sf |= 4;
	}
	if (dlc_sounds != "")
		sf |= 8;

	WriteByte(MSG_ENTITY, sf);
	if (sf & 1) {
		WriteString(MSG_ENTITY, cvar_string("sv_dlc_repository"));
	}
	if (sf & 2) {
		WriteString(MSG_ENTITY, dlc_list_send);
		WriteString(MSG_ENTITY, dlc_extra_pk3_list);
	}
	if (sf & 8) {
		WriteString(MSG_ENTITY, dlc_sounds);
	}
	return TRUE;
}

void(string dlc_name) dlc_require_server_only {
	if (dlc_load(dlc_name, FALSE))
		dlc_exec_cfg(dlc_name); //Just in case
	else if not(dlc_wait) {
		dlc_wait = spawn();
		dlc_wait.think = dlc_wait_think;
		dlc_wait.nextthink = time + 0.2;
	}
}

void(string dlc_name) dlc_require {
	string s, list;
	list = cvar_string("sv_curl_serverpackages");
	float add_to_server_packages;
	add_to_server_packages = TRUE;
	while (list != "") {
		s = str_car(list);
		list = str_cdr(list);
		if (s == strcat("rexdlc_", dlc_name, ".serverpackage")) {
			add_to_server_packages = FALSE;
			break;
		}
	}
	if (add_to_server_packages)
		cvar_set("sv_curl_serverpackages", strcat(cvar_string("sv_curl_serverpackages"), " ", dlc_serverpackage_name(dlc_name)));

	list = dlc_list_send;
	while (list != "") {
		s = str_car(list);
		list = str_cdr(list);
		if (s == dlc_name)
			return;
	}
	if not(dlc) {
		dlc = spawn();
		net_link_entity(dlc, FALSE, 0, dlc_send);
	} else
		dlc.SendFlags |= 2;

	s = strzone(strcat(dlc_list_send, " ", dlc_name));
	str_unzone_ifneeded(dlc_list_send);
	dlc_list_send = s;
	dlc_require_server_only(dlc_name);
}

float dlc_pause;

var float(string cmd, float argc) dlc_cmd_game_handle_NextLink;
float(string cmd, float argc) dlc_cmd_game_handle {
	if (cmd == "dlc_require" || cmd == "require_dlc") //this command is deprecated, only present for prevent warnings
	if (argv(1) != "") {
		//dlc_require(argv(1));
		return TRUE;
	}
	if (cmd == "dlc_reload") {
		dlc_reload();
		return TRUE;
	}
	if (cmd == "dlc_reset") {
		dlc_reset_all();
		return TRUE;
	}
	if (cmd == "dlc_pause") {
		dlc_pause = TRUE;
		return TRUE;
	}
	if (cmd == "dlc_unpause") {
		dlc_pause = FALSE;
		slowmo_update();
		return TRUE;
	}
	return dlc_cmd_game_handle_NextLink(cmd, argc);
}

var float(float tempo) dlc_slowmo_update_mod_NextLink;
float(float tempo) dlc_slowmo_update_mod {
	if (dlc_pause)
		return 0;

	return dlc_slowmo_update_mod_NextLink(tempo);
}

void(void) dlc_extra_pk3_list_build {
	string map_file = strcat("maps/", mapname, ".bsp");
	str_unzone_ifneeded(dlc_extra_pk3_list);
	dlc_extra_pk3_list = strcat(whichpack(strcat("maps/", mapname, ".bsp")), ":", map_file);
	string head, tail, pk3;
	for (tail = cvar_string("sv_curl_serverpackages"); tail != "";) {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head == "")
			continue;

		pk3 = whichpack(head);
		if (substring(pk3, 0, 8) == "dlcache/")
			pk3 = substring(pk3, 8, -1);

		if (pk3 != "")
		if (substring(pk3, 0, 11) != "zzz-rexdlc_") {
			dlc_extra_pk3_list = strcat(dlc_extra_pk3_list, " ", pk3, ":", head);
		}
	}
	dlc_extra_pk3_list = strzone(dlc_extra_pk3_list);
	if (strstrofs(dlc_extra_pk3_list, ";", 0) >= 0 ||
			strstrofs(dlc_extra_pk3_list, "\"", 0) >= 0 ||
			strstrofs(dlc_extra_pk3_list, "\\", 0) >= 0)
		dlc_extra_pk3_list = ""; //prevent dangerous symbols in localcm
}

void(void) dlc_init {
	string s;
	registercvar("_dlc_settemps_count", "0");
	dlc_set_repos(cvar_string("sv_dlc_repository"));
	string server_packages = cvar_string("sv_curl_serverpackages");
	string server_packages_without_dlc = "";
	while (server_packages != "") {
		s = str_car(server_packages);
		server_packages = str_cdr(server_packages);
		if (s != "")
		if (strstrofs(s, "rexdlc_", 0) != 0 && strstrofs(s, "rexext_", 0) != 0)
			server_packages_without_dlc = strcat(server_packages_without_dlc, " ", s);
	}
	cvar_set("sv_curl_serverpackages", server_packages_without_dlc);
	dlc_load_exts();
	string dlc_extra = cvar_string("sv_dlc_extra");
	while (dlc_extra != "") {
		s = str_car(dlc_extra);
		dlc_extra = str_cdr(dlc_extra);
		if (s != "")
			dlc_require(s);
	}
	string dlc_server_only = strcat(cvar_string("sv_dlc_server_only"), " " DLC_BASE_LIST);
	while (dlc_server_only != "") {
		s = str_car(dlc_server_only);
		dlc_server_only = str_cdr(dlc_server_only);
		if (s != "")
			dlc_require_server_only(s);
	}
	s = cvar_string("_map_dlc");
	if (s != "")
		dlc_require(s);

	string map_pk3 = whichpack(strcat("maps/", mapname, ".bsp"));
	if (substring(map_pk3, 0, 8) == "dlcache/")
		map_pk3 = substring(map_pk3, 8, -1);

	if (map_pk3 != "")
	if (substring(map_pk3, 0, 11) == "zzz-rexdlc_") {
		s = substring(map_pk3, 11, strlen(map_pk3) - 15);
		if (s != "") {
			if (file_exists(dlc_serverpackage_name(s))) {
				print("Map from DLC: ", s, "\n");
				dlc_require(s);
			}
		}
	}
	dlc_extra_pk3_list_build();
	dlc_cmd_game_handle_NextLink = gamehook_chain_cmd_game_handle;
	gamehook_chain_cmd_game_handle = dlc_cmd_game_handle;
	dlc_slowmo_update_mod_NextLink = gamehook_chain_slowmo_update_mod;
	gamehook_chain_slowmo_update_mod = dlc_slowmo_update_mod;
}

void(void) dlc_finish {
	dlc_unload_settemps();
}

entity dlc_wait_reload;

void(void) dlc_wait_reload_think {
	if (dlc_ready_all()) {
		localcmd("\n");
		string list = dlc_list;
		string s;
		dlc_load_exts();
		while (list != "") {
			s = str_car(list);
			list = str_cdr(list);
			if (s != "")
				dlc_exec_cfg(s);
		}
		localcmd("sv_cmd dlc_reset\n");
		entity e;
		FOR_EACH_REALCLIENT(e)
			if (e.netaddress == "local") {
				localcmd("sv_cmd dlc_pause; r_restart; cl_cmd r_restart; sv_cmd dlc_unpause\n");
				break;
			}
		remove(self);
		dlc_wait_reload = world;
		dlc_extra_pk3_list_build();
	} else
		self.nextthink = time + 1;
}

void(void) dlc_reload {
	string list = dlc_list;
	string s;
	while (list != "") {
		s = str_car(list);
		list = str_cdr(list);
		if (s != "")
			dlc_load(s, FALSE);
	}
	list = dlc_list_send;
	while (list != "") {
		s = str_car(list);
		list = str_cdr(list);
		if (s != "")
			dlc_require(s);
	}
	if not(dlc_wait_reload) {
		dlc_wait_reload = spawn();
		dlc_wait_reload.think = dlc_wait_reload_think;
		dlc_wait_reload.nextthink = time + 0.2;
	}
}

void(string s) dlc_precache_sound {
	string l, head;
	l = dlc_sounds;
	while (l != "") {
		head = str_car(l);
		l = str_cdr(l);
		if (head == s)
			return;
	}
	string dlc_sounds_new = strcat(dlc_sounds, " ", s);
	str_unzone_ifneeded(dlc_sounds);
	dlc_sounds = strzone(dlc_sounds_new);
	dlc.SendFlags |= 8;
}

void(void) dlc_sound_think {
	if (time > self.pushltime) {
		remove(self);
		return;
	}
	if (self.origin != self.owner.origin) {
		setorigin(self, self.owner.origin);
		self.SendFlags |= 1;
	}
	self.nextthink = time;
}

#define dlc_sound_send dlc_sound_SendEntity //compatibility with old save files
float(entity to, float sf) dlc_sound_send {
	WriteByte(MSG_ENTITY, NET_CSQC_DLC_SOUND);
	WriteByte(MSG_ENTITY, sf);
	if (sf & 1) {
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}
	if (sf & 2) {
		WriteString(MSG_ENTITY, self.message);
		WriteByte(MSG_ENTITY, self.cnt);
		WriteCoord(MSG_ENTITY, self.scale);
		WriteCoord(MSG_ENTITY, self.health);
	}
	return TRUE;
}

entity dlc_sound(entity e, float chan, string s, float vol, float attn) {
	entity snd = spawn();
	snd.cnt = chan;
	snd.message = s;
	snd.scale = vol;
	snd.health = attn;
	snd.think = stdproc_remove;
	snd.nextthink = time + 0.5;
	snd.origin = e.origin;
	snd.owner = e;
	net_link_entity(snd, FALSE, 0, dlc_sound_send);
	return snd;
}

void dlc_sound_follow(entity e, float chan, string s, float vol, float attn) {
	entity snd = dlc_sound(e, chan, s, vol, attn);
	snd.think = dlc_sound_think;
	snd.nextthink = time;
	snd.pushltime = time + 2;
}

float(entity e, float chan, string samp, float vol, float attn) dlc_sound_spam {
	if (time > e.announcetime) {
		e.announcetime = time;
		dlc_sound(e, chan, samp, vol, attn);
		return TRUE;
	}
	return FALSE;
}
