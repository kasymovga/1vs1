entity dlc_wait;
float localConnection;

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
	if not(localConnection) {
		localcmd("r_restart;");
		if not(isdemo())
			localcmd("disconnect;reconnect\n");
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
		unzone_ifneeded(dlc_repo);
		dlc_repo = zone_ifneeded(ReadString());
	}

	if (f & 2) {
		string list = ReadString();
		string s;
		float not_all_loaded;
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
				dlc_wait.nextthink = time + 1;
				dlc_wait.draw2d = DLCDraw2d;
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
}
