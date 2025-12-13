#define WEAPON_SELECT_MAXOPTIONS 8
#define WEAPON_SELECT_SCALE NADGET_SELECT_SCALE
#define WEAPON_SELECT_MARGIN NADGET_SELECT_MARGIN

float weapon_select_selalpha[WEAPON_SELECT_MAXOPTIONS];
float weapon_select_numoptions;
float weapon_select_active;
float weapon_select_alpha;
float weapon_select_width;
float weapon_select_height;
float weapon_select_selected;
float weapon_select_available;
float weapon_select_available_extra;

float(float bInputType, float nPrimary, float nSecondary) weapon_select_input_event;

entity weapon_select;

void(vector o, vector s) weapon_select_update {
	vector v = mouse_position();
	weapon_select_selected = floor(weapon_select_numoptions * ((bound(o_y, v_y, o_y + s_y) - o_y) / s_y));
	weapon_select_selected = min(weapon_select_numoptions - 1, weapon_select_selected);
}

float(void) weapon_select_get {
	entity e;
	float n = 0;
	WEAPON_INFO_FOR_EACH(e) {
		if ((e.weapons & weapon_select_available) || (e.weapons_extra & weapon_select_available_extra)) {
			if (n == weapon_select_selected)
				return e.weapon;
			++n;
		}
	}
	return -1;
}

void(void) weapon_select_draw {
	if (weapon_select_active) {
		weapon_select_alpha = approach(weapon_select_alpha, 1, frametime * 5);
		input_event_callback = weapon_select_input_event;
		mouse_enable("");
	} else
		weapon_select_alpha = approach(weapon_select_alpha, 0, frametime * 7);

	if (!weapon_select_alpha) {
		remove(self);
		weapon_select = NULL;
		return;
	}
	float a = weapon_select_alpha;
	drawfont = sbar_bigfont;
	drawfill('0 0 0', '1 0 0' * CVAR(vid_conwidth) + CVAR(vid_conheight) * '0 1 0', '0 0 0', 0.5 * a, DRAWFLAG_NORMAL);
	vector o = ('1 0 0' * (CVAR(vid_conwidth) - weapon_select_width) + (CVAR(vid_conheight) - weapon_select_height) * '0 1 0') * 0.5;
	vector s;
	s_x = weapon_select_width;
	s_y = weapon_select_height;
	s_z = 0;
	if (weapon_select_active)
		weapon_select_update(o, s);

	vector sz;
	sz_x = WEAPON_SELECT_SCALE;
	sz_y = WEAPON_SELECT_SCALE;
	sz_z = 0;
	draw_string_center('0 1 0' * (o_y - sz_y * 1.25), "Weapon Selection", sz, '1 1 1', a, DRAWFLAG_NORMAL);
	o_x = (CVAR(vid_conwidth) * 0.5) - 0.5 * (weapon_select_width + WEAPON_SELECT_MARGIN);
	drawfill(o, s, '0 0 0', 0.3, DRAWFLAG_NORMAL);
	draw_borderlines(2, o, s, '0 0 0', a, DRAWFLAG_NORMAL);
	string txt;
	float txtw;
	//txt = strcat("Key: ^2", strtoupper(input_command_key_first("+attack2")));
	//txtw = stringwidth(txt, TRUE, sz);
	//drawcolorcodedstring([o_x + (s_x - txtw) * 0.5, o_y + s_y + WEAPON_SELECT_MARGIN * 0.5], txt, sz, a, DRAWFLAG_NORMAL);
	entity e;
	float i = 0;
	WEAPON_INFO_FOR_EACH(e) {
		if (!(e.weapons & weapon_select_available) && !(e.weapons_extra & weapon_select_available_extra))
			continue;

		float sidx = i;
		vector p;
		p_z = 0;
		float a2 = weapon_select_selalpha[sidx];
		float isSelected = i == weapon_select_selected;
		vector clr = '0.75 0.75 0.75';
		if (isSelected) {
			weapon_select_selalpha[sidx] = approach(weapon_select_selalpha[sidx], 1, frametime * 3);
			p_x = o_x;
			p_y = o_y + i * sz_y + WEAPON_SELECT_MARGIN * 0.5;
			drawfill(p, s_x * '1 0 0' + sz_y * '0 1 0', clr, 0.2 * a, DRAWFLAG_NORMAL);
		} else
			weapon_select_selalpha[sidx] = approach(weapon_select_selalpha[sidx], 0, frametime * 3);

		p_x = o_x + WEAPON_SELECT_MARGIN * 0.5;
		p_y = o_y + i * sz_y + WEAPON_SELECT_MARGIN * 0.5;
		drawpic(p, e.icon, '2 1 0' * WEAPON_SELECT_SCALE, '1 1 1' * (0.5 + 0.5 * a2), a, DRAWFLAG_NORMAL);
		p_x = WEAPON_SELECT_MARGIN * 0.5 + o_x + sz_x * 2;
		drawstring(p, e.message, sz, clr, a, DRAWFLAG_NORMAL);
		if (i < 10) {
			txt = ((i == 9) ? "0" : ftos(i + 1));
			txtw = stringwidth(txt, FALSE) * sz_x * 0.5;
			drawstring('1 0 0' * (o_x + s_x - txtw) + p_y * '0 1 0', txt, sz * 0.5, '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);
		}
		if (++i == WEAPON_SELECT_MAXOPTIONS)
			break;
	}
	drawfont = sbar_font;
}

void(void) weapon_select_confirm {
	entity w = weapon_info(weapon_select_get());
	localcmd("cmd pickweapon ", w.netname, "; cmd join\n");
	weapon_select_active = FALSE;
}

float weapon_select_input_event(float bInputType, float nPrimary, float nSecondary) {
	if (!weapon_select_active)
		return FALSE;

	if (bInputType == 2)
		return TRUE;

	if (bInputType == 0) {
		if (nPrimary == K_ESCAPE) {
			weapon_select_active = FALSE;
			return TRUE;
		}
		if (nPrimary == K_MOUSE1) {
			vector o = ('1 0 0' * (CVAR(vid_conwidth) - weapon_select_width) + (CVAR(vid_conheight) - weapon_select_height) * '0 1 0') * 0.5;
			vector s;
			s_x = weapon_select_width;
			s_y = weapon_select_height;
			s_z = 0;
			weapon_select_update(o, s);
			weapon_select_confirm();
			return TRUE;
		}
		if (nPrimary >= '0' && nPrimary <= '9') {
			weapon_select_selected = nPrimary - '0';
			if (!weapon_select_selected)
				weapon_select_selected = 10;
			else
				--weapon_select_selected;

			weapon_select_selected = bound(0, weapon_select_selected, weapon_select_numoptions - 1);
			weapon_select_confirm();
		}
	}
	return FALSE;
}

void(void) weapon_select_read {
	weapon_select_available = net_read_int24();
	weapon_select_available_extra = net_read_int24();
	if (weapon_select_active)
		return;

	if (main_isdemo)
		return;

	weapon_select_width = 0;
	weapon_select_numoptions = 0;
	float olddrawfont = drawfont;
	drawfont = sbar_bigfont;
	for (float w = 0; w <= WEAPON_LAST; ++w) {
		if (pow(2, w) & weapon_select_available) {
			++weapon_select_numoptions;
			weapon_select_width = max(weapon_select_width, WEAPON_SELECT_SCALE * 2 + stringwidth(weapon_info(w).message, FALSE) * WEAPON_SELECT_SCALE);
		}
	}
	drawfont = olddrawfont;
	weapon_select_height = WEAPON_SELECT_SCALE * weapon_select_numoptions + WEAPON_SELECT_MARGIN;
	weapon_select_width += WEAPON_SELECT_MARGIN;
	weapon_select_active = TRUE;
	if not(weapon_select) {
		weapon_select = spawn();
		weapon_select.draw2d = weapon_select_draw;
		weapon_select.draw2dflag = 3;
	}
}
