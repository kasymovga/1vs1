float pin_selected;
string pin_code;

float pin_input_event(float bInputType, float nPrimary, float nSecondary) {
	if (bInputType == 2)
		return TRUE;

	float pin_try = FALSE;
	if (nPrimary == K_MOUSE1 && bInputType == 0) {
		if (pin_selected == -2) {
			str_unzone_ifneeded(pin_code);
			pin_code = "";
		} else if (pin_selected == -1) {
			string pin_code_new = substring(pin_code, 0, strlen(pin_code) - 1);
			str_unzone_ifneeded(pin_code);
			pin_code = str_zone_ifneeded(pin_code_new);
		} else {
			pin_try = TRUE;
			string pin_code_new = strcat(pin_code, ftos(pin_selected));
			str_unzone_ifneeded(pin_code);
			pin_code = str_zone_ifneeded(pin_code_new);
		}
	} else if (nPrimary >= '0' && nPrimary <= '9') {
		pin_try = TRUE;
		string pin_code_new = strcat(pin_code, ftos(nPrimary - '0'));
		str_unzone_ifneeded(pin_code);
		pin_code = str_zone_ifneeded(pin_code_new);
	}
	if (pin_try) {
		localcmd(strcat("cmd pin_code ", pin_code, "\n"));
		return TRUE;
	}
	return FALSE;
}

void(float i, vector numpad_center, vector mv, float a) pin_numpad_digit_draw {
	float x, y;
	string letter = "";
	if (i == -2)
		x = 2;
	else if (i == -1)
		x = 0;
	else if (i == 0)
		x = 1;
	else
		x = math_mod(i - 1, 3);

	if (i >= 0) letter = ftos(i);
	else if (i == -1) letter = "<";
	else if (i == -2) letter = "_";
	y = 3 - floor((i + 2) / 3);
	vector v, v2;
	v_x = numpad_center_x * 0.2;
	v_y = numpad_center_y * 0.2;
	v_z = 0;
	v2_z = 0;
	v2_x = numpad_center_x + v_x * (-1.5 + x);
	v2_y = numpad_center_y + v_y * (-2 + y);
	float selected = FALSE;
	if (a >= 1)
	if (pin_selected == -3)
	if (mv_x >= v2_x && mv_x <= v2_x + v_x)
	if (mv_y >= v2_y && mv_y <= v2_y + v_y) {
		selected = TRUE;
		pin_selected = i;
	}
	draw_borderlines(2, v2 + v * 0.05, v * 0.9, (selected ? '0.5 0.5 0.5' : '0 0 0'), 1, DRAWFLAG_NORMAL);
	draw_string_center('1 0 0' * (x - 1) * v_x + '0 1 0' * (v2_y + v_y * 0.2), letter, v * 0.5, (selected ? '1 1 0' : '1 1 1'), a, DRAWFLAG_NORMAL);
}

void(void) pin_draw {
	if (self.classname == "pin_remove") {
		self.alpha -= view_drawframetime;
		if (self.alpha <= 0) {
			remove(self);
			return;
		}
	} else
		input_event_callback = pin_input_event;

	pin_selected = -3;
	drawfill('0 0 0', '1 0 0' * CVAR(vid_conwidth) + CVAR(vid_conheight) * '0 1 0', '0 0 0', 0.5 * self.alpha, DRAWFLAG_NORMAL);
	vector numpad_center;
	numpad_center_x = CVAR(vid_conwidth) / 2;
	numpad_center_y = CVAR(vid_conheight) / 2;
	numpad_center_z = 0;
	mouse_enable("");
	drawfont = sbar_bigfont;
	draw_string_center('0 1 0' * numpad_center_y * 0.15, _("Enter PIN-code:"), numpad_center * 0.05, '1 1 1', self.alpha, DRAWFLAG_NORMAL);
	self.cnt -= frametime;
	if (self.alpha >= 1)
		draw_string_center('0 1 0' * numpad_center_y * 0.2, strcat(ftos(max(1, ceil(self.cnt))), " seconds left"), numpad_center * 0.025, '1 1 1', self.alpha, DRAWFLAG_NORMAL);

	draw_string_center('0 1 0' * numpad_center_y * 0.3, pin_code, numpad_center * 0.2, '1 1 1', self.alpha, DRAWFLAG_NORMAL);
	if (self.alpha < 0.9)
		draw_string_center('0 1 0' * numpad_center_y * 0.5, _("Success!"), numpad_center * 0.05, '0.5 1 0.5', self.alpha, DRAWFLAG_NORMAL);

	float i;
	vector mv = mouse_position();
	for (i = -2; i < 10; i++)
		pin_numpad_digit_draw(i, numpad_center, mv, self.alpha);

	drawfont = sbar_font;
}

void(void) pin_remove {
	entity e = spawn();
	e.draw2dflag = 3;
	e.draw2d = pin_draw;
	e.classname = "pin_remove";
	e.alpha = 1;
}

void(float isnew) pin_read {
	self.draw2dflag = 3;
	self.draw2d = pin_draw;
	self.entremove = pin_remove;
	self.cnt = net_read_coord();
	self.alpha = 1;
	string s = cvar_string("_cl_pin_code");
	if (s != "" && isnew)
		localcmd(strcat("cmd pin_code ", s, "\n"));
}
