void GameStatus_Draw() {
	if (sb_hidescores)
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

void GameStatus_Remove() {
	str_unzone_ifneeded(self.message);
}

void Ent_GameStatus(float isnew) {
	self.origin_x = CVAR(vid_conwidth) / 2;
	self.origin_y = CVAR(vid_conheight) / 2 - sbar_fontsize_y * 8;
	self.draw2d = GameStatus_Draw;
	self.draw2dflag = 1;
	float f = ReadByte();
	self.entremove = GameStatus_Remove;
	if (f & 1)
		self.message = str_zone_ifneeded(ReadString());

	if (f & 2)
		self.alpha = ReadByte() / 100;
}
