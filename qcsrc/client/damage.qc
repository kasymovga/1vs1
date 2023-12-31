void(void) damage_indicator_draw {
	if (self.alpha <= 0)
		return;

	drawfont = sbar_bigfont;
	self.alpha -= frametime / CVAR(cl_damageindicator);
	self.origin_z += frametime * 25;
	vector o = view_project_3d_to_2d(self.origin);
	if (o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
		return;

	o_z = 0;
	drawstring(o, NET_UNBOUND_FROM_BYTE(self.cnt), '12 12 0', '1 0.5 0', self.alpha, DRAWFLAG_NORMAL);
	drawfont = sbar_font;
}

void(void) damage_indicator_remove {
	entity e = spawn();
	e.origin = self.origin;
	e.cnt = self.cnt;
	e.alpha = self.alpha;
	e.draw2d = damage_indicator_draw;
	e.draw2dflag = 1;
	e.think = stdproc_remove;
	e.nextthink = time + self.alpha * CVAR(cl_damageindicator);
}

void(float bisnew) damage_indicator_read {
	self.cnt = net_read_byte();
	self.origin_x = net_read_short();
	self.origin_y = net_read_short();
	self.origin_z = net_read_short();
	if (CVAR(cl_damageindicator) > 0) {
		self.alpha = 1;
		self.draw2d = damage_indicator_draw;
		self.draw2dflag = 1;
		self.entremove = damage_indicator_remove;
	}
}
