void(vector o, vector fs, float sc, float _alpha, vector clr) rm_score_draw_numbers {
	drawfont = sbar_bigfont;
	string d = ftos(sc);
	if (sc > 0) d = strcat("+", d);
	float dw = stringwidth(d, FALSE) * fs_x;
	o_x -= fs_x * 0.5;
	drawstring(o, d, fs, clr, _alpha, DRAWFLAG_NORMAL);
	drawfont = sbar_font;
}
void(void) rm_score_draw {
	if (self.alpha <= 0 || CVAR(cl_damageindicator) <= 0) {
		remove(self);
		return;
	}
	self.alpha -= frametime / CVAR(cl_damageindicator);
	self.origin_y -= frametime * 50;
	if (self.cnt > 0)
		rm_score_draw_numbers(self.origin, '20 20 0' * max(1, self.alpha), self.cnt, self.alpha, '0 1 0');
	else
		rm_score_draw_numbers(self.origin, '20 20 0' * max(1, self.alpha), self.cnt, self.alpha, '1 0.2 0.2');
}

float rm_score_last;
void(float n) rm_score {
	if not(rm_skin_loaded) return;
	if (n == rm_score_last) return;
	entity e = spawn();
	e.alpha = 1;
	e.cnt = n - rm_score_last;
	e.draw2dflag = 1;
	e.draw2d = rm_score_draw;
	e.origin = rm_hud_scoresorigin;
	rm_score_last = n;
}
