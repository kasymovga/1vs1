entity progressbar;

void(void) progressbar_draw {
	entity e;
	float center = CVAR(vid_conwidth) / 2;
	float left = center - 100;
	vector pos, posleft, fillrect;
	fillrect = '200 10 0';
	posleft = pos + '-100 0 0';
	pos_y = CVAR(vid_conheight) - 100;
	for (e = progressbar; e; e = e.sort_next) {
		pos_x = left;
		draw_borderlines(1, pos, '200 10 0', '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);
		fillrect_x = 200 * (e.cnt / 100);
		drawfill(pos, fillrect, '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);
		pos_y -= 20;
		pos_x = center - stringwidth(e.netname, FALSE) * 6;
		drawstring(pos, e.netname, '12 12 0', '0 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
		pos_y -= 50;
	}
}

void(void) progressbar_remove {
	entity e;
	strunzone(self.netname);
	if (progressbar == self) {
		progressbar = progressbar.sort_next;
		if (progressbar)
			progressbar.draw2dflag = 1;
	} else
		for (e = progressbar; e.sort_next; e = e.sort_next) {
			if (e.sort_next == self) {
				e.sort_next = self.sort_next;
				return;
			}
		}
}

void(float bIsNewEntity) progressbar_read {
	float f = ReadByte();
	self.cnt = ReadByte();
	if (f & 2) {
		self.netname = strzone(ReadString());
	}
	if (bIsNewEntity) {
		entity e;
		if (progressbar)
			progressbar.draw2dflag = 0;

		for (e = progressbar; e; e = e.sort_next)
			if (e == self) //Already added in chain
				return;

		self.entremove = progressbar_remove;
		self.sort_next = progressbar;
		progressbar = self;
		progressbar.draw2d = progressbar_draw;
		progressbar.draw2dflag = 1;
	}
}
