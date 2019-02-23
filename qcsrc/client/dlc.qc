entity dlc_wait;
float localConnection;
string dlc_sounds;
float dlc_sounds_ready;

void dlc_precache_sounds() {
	print("dlc_precache_sounds\n");
	string s, l;
	l = dlc_sounds;
	while (l != "") {
		s = car(l);
		l = cdr(l);
		if (s != "") {
			precache_sound(s);
		}
	}
	dlc_sounds_ready = TRUE;
}

void dlc_sound(entity e, float c, string s, float v, float a) {
	if not(dlc_sounds_ready) {
		print("dlc_sound: not ready\n");
		return;
	}
	sound(e, c, s, v, a);
}

void DLCWait() {
	if not(dlc_ready_all()) {
		self.nextthink = time + 1;
		return;
	}
	string l, s;
	localcmd("\n");
	l = dlc_list;
	while (l != "") {
		s = car(l);
		l = cdr(l);
		if (s != "")
		if (fexists(strcat("rexdlc_", s, "_client.cfg")))
			localcmd(strcat("exec rexdlc_", s, "_client.cfg", "\n"));
	}
	dlc_precache_sounds();
	if (!localConnection || isdemo_flag) {
		localcmd("r_restart\n");
	} else {
		l = dlc_list;
		while (l != "") {
			s = car(l);
			l = cdr(l);
			if (s != "")
				localcmd(strcat("exec rexdlc_", s, "_client_post.cfg\n"));
		}
	}
	remove(self);
	dlc_wait = world;
}

void DLCDraw2d() {
	vector pos;
	pos_y = 100;
	string s = "Some content still downloading";
	pos_x = (CVAR(vid_conwidth) / 2) - stringwidth(s, false) * 6;
	drawstring(pos, s, '12 12 0', '0 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void Ent_DLCList(float new) {
	float f = ReadByte();
	if (f & 1) {
		dlc_set_repos(ReadString());
	}

	float not_all_loaded;
	if (f & 2) {
		string list = ReadString();
		string s;
		not_all_loaded = FALSE;
		string l = list;
		while (l != "") {
			s = car(l);
			l = cdr(l);
			if (s != "")
			if not(dlc_load(s)) {
				not_all_loaded = TRUE;
			}
		}
		if (not_all_loaded) {
			if not(dlc_wait) {
				dlc_wait = spawn();
				dlc_wait.think = DLCWait;
				dlc_wait.nextthink = time + 0.2;
				dlc_wait.draw2d = DLCDraw2d;
				dlc_wait.draw2dflag = 1;
			}
		} else {
			localcmd("\n");
			l = list;
			while (l != "") {
				s = car(l);
				l = cdr(l);
				if (s != "") {
					if (fexists(strcat("rexdlc_", s, "_client.cfg")))
						localcmd(strcat("exec rexdlc_", s, "_client.cfg\n"));

					if (fexists(strcat("rexdlc_", s, "_client_post.cfg")))
						localcmd(strcat("exec rexdlc_", s, "_client_post.cfg\n"));
				}
			}
		}
	}
	if (f & 4)
		localConnection = TRUE;
	else
		localConnection = FALSE;

	if (f & 8) {
		unzone_ifneeded(dlc_sounds);
		dlc_sounds = strzone(ReadString());
		if (not_all_loaded)
			dlc_sounds_ready = FALSE;
		else
			dlc_precache_sounds();
	}
}

void Ent_DLCSound(float new) {
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
