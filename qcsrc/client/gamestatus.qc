void GameStatus_Draw() {
	vector pos, size;
	pos = self.origin;
	string tail = self.message, head;
	float n;
	n = strstrofs(tail, "\n", 0);
	size = sbar_fontsize * (1 + self.alpha) * 0.5;
	while (n >= 0) {
		head = substring(tail, 0, n);
		tail = substring(tail, n + 1, -1);
		drawcolorcodedstringcenter(pos, head, size, self.alpha, DRAWFLAG_NORMAL);
		n = strstrofs(tail, "\n", 0);
		pos_y += size_y;
	}
	drawcolorcodedstringcenter(pos, tail, size, self.alpha, DRAWFLAG_NORMAL);
}

void GameStatus_Remove() {
	unzone_ifneeded(self.message);
}

void Ent_GameStatus(float isnew) {
	self.origin_x = CVAR(vid_conwidth) / 2;
	self.origin_y = CVAR(vid_conheight) / 2 - sbar_fontsize_y * 6;
	self.draw2d = GameStatus_Draw;
	float f = ReadByte();
	self.entremove = GameStatus_Remove;
	if (f & 1)
		self.message = zone_ifneeded(ReadString());

	if (f & 2)
		self.alpha = ReadByte() / 100;
}
