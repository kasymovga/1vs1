entity dlc_wait;
float localConnection;
string dlc_sounds;
float dlc_sounds_ready;
string dlc_extra_pk3_list;
entity dlc_extra_pk3_list_wait;

void(void) dlc_precache_sounds {
	string s, l;
	l = dlc_sounds;
	while (l != "") {
		s = str_car(l);
		l = str_cdr(l);
		if (s != "") {
			precache_sound(s);
		}
	}
	dlc_sounds_ready = TRUE;
}

void(void) dlc_extra_pk3_list_wait_think {
	string tail, head = "", pk3, pk3_file;
	float colon;
	for (tail = dlc_extra_pk3_list; tail != ""; head = str_car(tail), tail = str_cdr(tail)) {
		if (head == "") continue;
		colon = strstrofs(head, ":", 0);
		if (colon < 0) continue;
		pk3 = substring(head, 0, colon);
		pk3_file = substring(head, colon + 1, -1);
		if not(file_exists(pk3_file)) {
			if (self.cnt <= 0)
				break;

			self.cnt = self.cnt - 1;
			self.nextthink = time + 10;
			return;
		}
	}
	remove(self);
	dlc_extra_pk3_list_wait = world;
	localcmd("\nr_restart;cl_cmd r_restart\n");
}

void(entity e, float c, string s, float v, float a) dlc_sound {
	if not(dlc_sounds_ready) {
		print("dlc_sound: not ready\n");
		return;
	}
	sound(e, c, s, v, a);
}

void(void) dlc_wait_think {
	if not(dlc_ready_all()) {
		self.nextthink = time + 1;
		return;
	}
	string l, s;
	localcmd("\n");
	l = dlc_list;
	while (l != "") {
		s = str_car(l);
		l = str_cdr(l);
		if (s != "")
		if (file_exists(strcat("rexdlc_", s, "_client.cfg")))
			localcmd(strcat("exec rexdlc_", s, "_client.cfg", "\n"));
	}
	dlc_precache_sounds();
	if (!localConnection || main_isdemo) {
		localcmd("r_restart;cl_cmd r_restart\n");
	}
	l = dlc_list;
	while (l != "") {
		s = str_car(l);
		l = str_cdr(l);
		if (s != "")
		if (file_exists(strcat("rexdlc_", s, "_client_post.cfg")))
			localcmd(strcat("exec rexdlc_", s, "_client_post.cfg\n"));
	}
	remove(self);
	dlc_wait = world;
}

void(void) dlc_draw2d {
	vector pos;
	pos_y = 100;
	string s = "Some content still downloading";
	pos_x = (CVAR(vid_conwidth) / 2) - stringwidth(s, FALSE) * 6;
	pos_z = 0;
	drawstring(pos, s, '12 12 0', '0 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void(float new) dlc_read {
	float f = ReadByte();
	if (f & 1) {
		dlc_set_repos(ReadString());
	}

	float not_all_loaded = FALSE;
	if (f & 2) {
		string list = ReadString();
		string s;
		not_all_loaded = FALSE;
		string l = list;
		while (l != "") {
			s = str_car(l);
			l = str_cdr(l);
			if (s != "")
			if not(dlc_load(s, FALSE)) {
				not_all_loaded = TRUE;
			}
		}
		if (not_all_loaded) {
			if not(dlc_wait) {
				dlc_wait = spawn();
				dlc_wait.think = dlc_wait_think;
				dlc_wait.nextthink = time + 0.2;
				dlc_wait.draw2d = dlc_draw2d;
				dlc_wait.draw2dflag = 1;
			}
		} else {
			localcmd("\n");
			l = list;
			while (l != "") {
				s = str_car(l);
				l = str_cdr(l);
				if (s != "") {
					if (file_exists(strcat("rexdlc_", s, "_client.cfg")))
						localcmd(strcat("exec rexdlc_", s, "_client.cfg\n"));

					if (file_exists(strcat("rexdlc_", s, "_client_post.cfg")))
						localcmd(strcat("exec rexdlc_", s, "_client_post.cfg\n"));
				}
			}
		}
		dlc_extra_pk3_list = strzone(ReadString());
	}
	if (f & 4)
		localConnection = TRUE;
	else
		localConnection = FALSE;

	if (f & 8) {
		str_unzone_ifneeded(dlc_sounds);
		dlc_sounds = str_zone_ifneeded(ReadString());
		if (not_all_loaded)
			dlc_sounds_ready = FALSE;
		else
			dlc_precache_sounds();
	}
	string tail, head, pk3, pk3_file;
	registercvar("cl_curl_fallback", "http://rexuiz.com/maps/");
	string cl_curl_fallback = cvar_string("cl_curl_fallback");
	float colon;
	for (tail = dlc_extra_pk3_list; tail != "";) {
		head = str_car(tail);
		tail = str_cdr(tail);
		if (head == "") continue;
		colon = strstrofs(head, ":", 0);
		if (colon < 0) continue;
		pk3 = substring(head, 0, colon);
		pk3_file = substring(head, colon + 1, -1);
		if (pk3 == "" || pk3_file == "") continue;
		if (file_exists(pk3_file)) continue;
		print(pk3, " is missing, trying to fix\n");
		localcmd(strcat("curl --pak ", cl_curl_fallback, pk3, "\n"));
		if not(dlc_extra_pk3_list_wait) {
			dlc_extra_pk3_list_wait = spawn();
			dlc_extra_pk3_list_wait.cnt = 10;
			dlc_extra_pk3_list_wait.think = dlc_extra_pk3_list_wait_think;
			dlc_extra_pk3_list_wait.nextthink = time + 10;
		}
	}
}

void(float new) dlc_sound_read {
	float sf = ReadByte();
	if (sf & 1) {
		vector v;
		v_x = ReadCoord();
		v_y = ReadCoord();
		v_z = ReadCoord();
		setorigin(self, v);
	}
	if (sf & 2) {
		string s = ReadString();
		self.cnt = ReadByte();
		float vol = ReadCoord();
		float attn = ReadCoord();
		dlc_sound(self, self.cnt, s, vol, attn);
	}
}
