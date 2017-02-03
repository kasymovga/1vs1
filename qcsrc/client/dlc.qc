entity dlc_wait;

void DLCWait() {
	if (dlc_ready_all()) {
		localcmd("\nr_restart\n");
		remove(self);
		dlc_wait = world;
		return;
	}
	self.nextthink = time + 1;
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
		unzone_ifneeded(dlc_list);
		dlc_list = zone_ifneeded(ReadString());

		float n = tokenizebyseparator(dlc_list, " ");
		float i;
		float not_all_loaded;
		not_all_loaded = FALSE;
		for (i = 0; i < n; i++)
			if (argv(i) != "")
				if not(dlc_load(argv(i)))
					not_all_loaded = TRUE;
					
		if (not_all_loaded)
		if not(dlc_wait) {
			dlc_wait = spawn();
			dlc_wait.think = DLCWait;
			dlc_wait.nextthink = time + 1;
			dlc_wait.draw2d = DLCDraw2d;
		}
	}
}
