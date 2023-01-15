entity progressbar;

void(void) progressbar_draw {
	entity e;
	float center = CVAR(vid_conwidth) / 2;
	float left = center - 100;
	vector pos, fillrect;
	fillrect = '200 10 0';
	pos_y = CVAR(vid_conheight) - 100;
	pos_z = 0;
	float f;
	drawfont = sbar_font;
	for (e = progressbar; e; e = e.sort_next) {
		pos_y -= self.origin_z;
		if (time != e.iorigin1_x) {
			f = (e.iorigin1_x - e.iorigin2_x);
			f = e.iorigin1_x + bound(0, (f / (e.iorigin1_y - e.iorigin2_y)) * (time - e.iorigin1_y), f);
		} else
			f = e.iorigin1_x;

		f = bound(0, f, 100);
		if (e.iorigin1_x > e.iorigin2_x)
			e.iorigin1_z = max(f, e.iorigin1_z);
		else
			e.iorigin1_z = min(f, e.iorigin1_z);

		//float ft = bound(0.001, frametime * 200, 0.999);
		//e.iorigin1_z = e.iorigin1_z * (1 - ft) + f * ft;
		f = e.iorigin1_z;
		pos_x = left;
		draw_borderlines(1, pos, '200 10 0', '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);
		fillrect_x = 200 * (f / 100);
		drawfill(pos, fillrect, '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);
		pos_y -= 20;
		pos_x = center - stringwidth(e.netname, FALSE) * 6;
		drawstring(pos, e.netname, '12 12 0', '0 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
		pos_y -= 50;
		if (e.origin_z > 0)
			e.origin_z = max(0, self.origin_z - 100 * frametime);
	}
}

void(void) progressbar_fade_draw {
	self.alpha -= frametime * 5;
	if (self.alpha < 0) {
		str_unzone_ifneeded(self.netname);
		self.netname = NULL;
		self.draw2d = NULL;
		self.draw2dflag = 0;
		remove(self);
		return;
	}
	drawfont = sbar_font;
	float center = CVAR(vid_conwidth) / 2;
	float left = center - 100;
	vector pos, fillrect;
	pos_x = left;
	fillrect = '200 10 0';
	pos_y = CVAR(vid_conheight) - 100 - self.origin_z;
	pos_z = 0;
	draw_borderlines(1, pos, '200 10 0', '1 1 0', sbar_alpha_fg * self.alpha, DRAWFLAG_NORMAL);
	fillrect_x = 200 * (self.origin_x / 100);
	drawfill(pos, fillrect, '1 1 0', sbar_alpha_fg * self.alpha, DRAWFLAG_NORMAL);
	pos_y -= 20;
	pos_x = center - stringwidth(self.netname, FALSE) * 6;
	drawstring(pos, self.netname, '12 12 0', '0 1 1', sbar_alpha_fg * self.alpha, DRAWFLAG_NORMAL);
}

void(void) progressbar_remove {
	entity e;
	entity fade = spawn();
	fade.alpha = 1;
	fade.draw2dflag = 1;
	fade.draw2d = progressbar_fade_draw;
	fade.netname = self.netname;
	fade.origin_z = self.origin_z;
	fade.origin_x = self.iorigin1_x;
	self.iorigin1 = '0 0 0';
	self.iorigin2 = '0 0 0';
	if (progressbar == self) {
		progressbar = progressbar.sort_next;
		if (progressbar) {
			progressbar.draw2dflag = 1;
			progressbar.draw2d = progressbar_draw;
			progressbar.origin_z += 70 + self.origin_z;
		}
	} else
		for (e = progressbar; e.sort_next; e = e.sort_next) {
			fade.origin_z += 70 + e.origin_z;
			if (e.sort_next == self) {
				e.sort_next = self.sort_next;
				if (self.sort_next)
					e.sort_next.origin_z += 70;

				return;
			}
		}
}

void(float bIsNewEntity) progressbar_read {
	float f = net_read_byte();
	if (bIsNewEntity) {
		self.iorigin2_x = 0;
		self.iorigin2_y = time;
		self.iorigin1_z = 0;
		self.origin = '0 0 0';
	} else {
		self.iorigin2_x = self.iorigin1_x;
		self.iorigin2_y = self.iorigin1_y;
	}
	self.iorigin1_x = net_read_byte();
	self.iorigin1_y = time;
	if (f & 2) {
		str_unzone_ifneeded(self.netname);
		self.netname = str_zone_ifneeded(net_read_string());
	}
	if (bIsNewEntity) {
		entity e;
		for (e = progressbar; e; e = e.sort_next)
			if (e == self) //Already added in chain
				return;

		self.entremove = progressbar_remove;
		self.sort_next = NULL;
		if (progressbar) {
			for (e = progressbar; e.sort_next; e = e.sort_next) { }
			e.sort_next = self;
		} else {
			progressbar = self;
			progressbar.draw2dflag = 1;
			progressbar.draw2d = progressbar_draw;
		}
	}
}
