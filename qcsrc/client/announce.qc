entity announce;
void(void) announce_draw {
	if (self.alpha <= 0) {
		str_unzone_ifneeded(self.message);
		announce  = world;
		remove(self);
		return;
	}
	drawfont = sbar_bigfont;
	draw_string_colorcoded_center(self.origin, self.message, sbar_fontsize * 2, self.alpha, DRAWFLAG_NORMAL);
	self.alpha -= frametime;
}

void(void) announce_print {
	if not(announce) {
		announce = spawn();
		announce.draw2d = announce_draw;
		announce.draw2dflag = 1;
	}
	announce.message = str_zone_ifneeded(ReadString());
	if (announce.message == " ")
		announce.alpha = -1;
	else
		announce.alpha = CVAR(cl_announcer_print);

	announce.origin_x = CVAR(vid_conwidth) / 2;
	announce.origin_y = CVAR(vid_conheight) / 2 - sbar_fontsize_y * 12;
}
