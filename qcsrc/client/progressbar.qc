entity progressbar;

void ProgressBar_Draw() {
	entity e;
	float center = CVAR(vid_conwidth) / 2;
	float left = center - 100;
	vector pos, posleft, fillrect;
	fillrect = '200 10 0';
	posleft = pos + '-100 0 0';
	pos_y = CVAR(vid_conheight) - 100;
	for (e = progressbar; e; e = e.entchain) {
		pos_x = left;
		drawborderlines(1, pos, '200 10 0', '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);
		fillrect_x = 200 * (e.cnt / 100);
		drawfill(pos, fillrect, '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);
		pos_y -= 20;
		pos_x = center - stringwidth(e.netname, false) * 6;
		drawstring(pos, e.netname, '12 12 0', '0 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
		pos_y -= 50;
	}
}

void Ent_ProgressBar_Remove() {
	entity e;
	strunzone(self.netname);
	if (progressbar == self) {
		progressbar = progressbar.entchain;
		if (progressbar)
			progressbar.draw2dflag = 1;
	} else
		for (e = progressbar; e.entchain; e = e.entchain) {
			if (e.entchain == self) {
				e.entchain = self.entchain;
				return;
			}
		}
}

void Ent_ProgressBar(float bIsNewEntity) {
	float f = ReadByte();
	self.cnt = ReadByte();
	if (f & 2) {
		self.netname = strzone(ReadString());
	}
	if (bIsNewEntity) {
		entity e;
		if (progressbar)
			progressbar.draw2dflag = 0;

		for (e = progressbar; e; e = e.entchain)
			if (e == self) //Already added in chain
				return;

		self.entremove = Ent_ProgressBar_Remove;
		self.entchain = progressbar;
		progressbar = self;
		progressbar.draw2d = ProgressBar_Draw;
		progressbar.draw2dflag = 1;
	}
}
