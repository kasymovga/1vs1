string(float f) rm_damage_indicator_ftos {
	float tens = f % 10;
	if (tens) {
		return strcat(ftos((f - tens) / 10), ".", ftos(tens));
	}
	return ftos(f / 10);
}

void(void) rm_damage_indicator_draw {
	if (self.alpha <= 0 || !CVAR(cl_damageindicator)) {
		remove(self);
		return;
	}
	drawfont = sbar_bigfont;
	self.alpha -= frametime / CVAR(cl_damageindicator);
	float f = (2 - self.alpha);
	self.origin_z += frametime * 25 * f;
	self.origin_x += sin(time * 2) * frametime * 25 * f;
	self.origin_y += sin(time * 2 + 1.57) * frametime * 25 * f;
	vector o = view_project_3d_to_2d(self.origin);
	if (o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
		return;

	o_z = 0;
	vector fs = '16 16 0';
	string d = rm_damage_indicator_ftos(self.cnt);
	float dw = stringwidth(d, FALSE) * fs_x;
	drawstring(o, d, fs, '1 0.5 0', self.alpha, DRAWFLAG_NORMAL);
	if (self.float1) {
		string ad = strcat(" [", rm_damage_indicator_ftos(self.float1), "]");
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
	e.cnt = net_read_short();
	e.float1 = net_read_short();
	e.draw2d = rm_damage_indicator_draw;
	e.draw2dflag = 1;
}
