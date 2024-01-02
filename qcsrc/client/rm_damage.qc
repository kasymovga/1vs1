void(void) rm_damage_indicator_draw {
	if (self.alpha <= 0 || !CVAR(cl_damageindicator)) {
		remove(self);
		return;
	}
	drawfont = sbar_bigfont;
	self.alpha -= frametime / CVAR(cl_damageindicator);
	self.origin_z += frametime * 25;
	vector o = view_project_3d_to_2d(self.origin);
	if (o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
		return;

	o_z = 0;
	vector fs = '16 16 0';
	string d = NET_UNBOUND_FROM_BYTE(self.cnt);
	float dw = stringwidth(d, FALSE) * fs_x;
	drawstring(o, NET_UNBOUND_FROM_BYTE(self.cnt), fs, '1 0.5 0', self.alpha, DRAWFLAG_NORMAL);
	if (self.float1) {
		string ad = strcat(" [", NET_UNBOUND_FROM_BYTE(self.float1), "]");
		drawstring(o + '1 0 0' * dw, ad, fs, '1 0.75 0.5', self.alpha, DRAWFLAG_NORMAL);
	}
	drawfont = sbar_font;
}

void(void) rm_damage_indicator_read {
	entity e = spawn();
	e.alpha = 1;
	e.origin_x = net_read_short();
	e.origin_y = net_read_short();
	e.origin_z = net_read_short();
	e.cnt = net_read_byte();
	e.float1 = net_read_byte();
	e.draw2d = rm_damage_indicator_draw;
	e.draw2dflag = 1;
}
