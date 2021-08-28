void(void) gamestatus_draw {
	if (sbar_hidescores)
		return;

	vector pos, _size;
	drawfont = sbar_bigfont;
	pos = self.origin;
	string tail = self.message, head;
	float n;
	n = strstrofs(tail, "\n", 0);
	_size = sbar_fontsize * (2 + self.alpha) * 0.5;
	while (n >= 0) {
		head = substring(tail, 0, n);
		tail = substring(tail, n + 1, -1);
		draw_string_colorcoded_center(pos, head, _size, self.alpha, DRAWFLAG_NORMAL);
		n = strstrofs(tail, "\n", 0);
		pos_y += _size_y;
		_size *= 0.8;
	}
	draw_string_colorcoded_center(pos, tail, _size, self.alpha, DRAWFLAG_NORMAL);
}

void(void) gamestatus_remove {
	str_unzone_ifneeded(self.message);
}

void(float isnew) gamestatus_read {
	self.origin_x = 0;
	self.origin_y = CVAR(vid_conheight) / 2 - sbar_fontsize_y * 8;
	self.draw2d = gamestatus_draw;
	self.draw2dflag = 1;
	float f = net_read_byte();
	self.entremove = gamestatus_remove;
	if (f & 1)
		self.message = str_zone_ifneeded(net_read_string());

	if (f & 2)
		self.alpha = net_read_byte() / 100;
}
