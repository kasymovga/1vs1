entity rm_damage_received_indicator_last;

string(float f) rm_damage_indicator_ftos {
	float tens = f % 10;
	if (tens) {
		return strcat(ftos((f - tens) / 10), ".", ftos(tens));
	}
	return ftos(f / 10);
}

void(vector o, vector fs, float h, float a, float _alpha, vector clr) rm_damage_indicator_draw_numbers {
	drawfont = sbar_bigfont;
	string d = rm_damage_indicator_ftos(h);
	float dw = stringwidth(d, FALSE) * fs_x;
	o_x -= fs_x * 0.5;
	drawstring(o, d, fs, clr, _alpha, DRAWFLAG_NORMAL);
	if (a) {
		string ad = strcat(" [", rm_damage_indicator_ftos(a), "]");
		drawstring(o + '1 0 0' * dw, ad, fs, '.5 .5 .5' + clr * 0.2, _alpha, DRAWFLAG_NORMAL);
	}
	drawfont = sbar_font;
}

void(void) rm_damage_received_indicator_draw {
	if (self.alpha <= 0 || CVAR(cl_damageindicator) <= 0) {
		if (self == rm_damage_received_indicator_last) rm_damage_received_indicator_last = NULL;
		remove(self);
		return;
	}
	self.alpha -= frametime / CVAR(cl_damageindicator);
	self.origin_y -= frametime * 50;
	rm_damage_indicator_draw_numbers(self.origin, '20 20 0', self.cnt, self.float1, self.alpha, '1 0.2 0.2');
}

void(void) rm_damage_indicator_draw {
	if (self.alpha <= 0 || CVAR(cl_damageindicator) <= 0) {
		remove(self);
		return;
	}
	self.alpha -= frametime / CVAR(cl_damageindicator);
	float f = (2 - self.alpha);
	self.origin_z += frametime * 25 * f;
	self.origin_x += sin(time * 2) * frametime * 25 * f;
	self.origin_y += sin(time * 2 + 1.57) * frametime * 25 * f;
	vector o = view_project_3d_to_2d(self.origin);
	if (o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
		return;

	o_z = 0;
	rm_damage_indicator_draw_numbers(o, self.iorigin1, self.cnt, self.float1, self.alpha, self.iorigin2);
}

void(void) rm_damage_indicator_read {
	entity e = spawn();
	float t;
	e.alpha = 1;
	t = net_read_byte();
	e.origin_x = net_read_short();
	e.origin_y = net_read_short();
	e.origin_z = net_read_short();
	e.cnt = net_read_short();
	e.float1 = net_read_short();
	e.draw2d = rm_damage_indicator_draw;
	e.draw2dflag = 1;
	if (t == RM_DAMAGE_DEFAULT) {
		e.iorigin1 = '16 16 0';
		e.iorigin2 = '1 0.7 0';
	} else if (t == RM_DAMAGE_NOTPLAYER) {
		e.iorigin1 = '13 13 0';
		e.iorigin2 = '1 1 1';
	} else if (t == RM_DAMAGE_HEAL) {
		e.iorigin1 = '16 16 0';
		e.iorigin2 = '0 1 0';
	} else if (t == RM_DAMAGE_CRITICAL) {
		e.iorigin1 = '32 32 0';
		e.iorigin2 = '1 0.7 0';
	} else if (t == RM_DAMAGE_FRIENDLY_FIRE) {
		e.iorigin1 = '16 16 0';
		e.iorigin2 = '1 0.2 0.2';
	}
}

float rm_damage_received_indicator_last_time;
void(void) rm_damage_received_indicator_read {
	entity e;
	if (rm_damage_received_indicator_last_time + 0.1 >= time && rm_damage_received_indicator_last) {
		e = rm_damage_received_indicator_last;
		e.cnt += net_read_short();
		e.float1 += net_read_short();
	} else {
		e = spawn();
		rm_damage_received_indicator_last = e;
		rm_damage_received_indicator_last_time = time;
		e.alpha = 1;
		e.cnt = net_read_short();
		e.float1 = net_read_short();
		e.origin = rm_hud_dmgtakenorigin;
		e.draw2d = rm_damage_received_indicator_draw;
		e.draw2dflag = 1;
	}
	if not(rm_skin_loaded) {
		if (e == rm_damage_received_indicator_last) rm_damage_received_indicator_last = NULL;
		remove(e);
		return;
	}
}
