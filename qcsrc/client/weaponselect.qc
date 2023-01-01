#define WEAPONSELECT_MAXOPTIONS 8
#define WEAPONSELECT_SCALE NADGETSELECT_SCALE
#define WEAPONSELECT_MARGIN NADGETSELECT_MARGIN

float weaponselect_selalpha[WEAPONSELECT_MAXOPTIONS];
float weaponselect_numoptions;
float weaponselect_active;
float weaponselect_alpha;
float weaponselect_width;
float weaponselect_height;
float weaponselect_selected;
float weaponselect_available;
float weaponselect_available_extra;

float(float bInputType, float nPrimary, float nSecondary) weaponselect_input_event;

entity weaponselect;

void(vector o, vector s) weaponselect_update {
	vector v = mouse_position();
	weaponselect_selected = floor(weaponselect_numoptions * ((bound(o_y, v_y, o_y + s_y) - o_y) / s_y));
	weaponselect_selected = min(weaponselect_numoptions - 1, weaponselect_selected);
}

float(void) weaponselect_get {
	entity e;
	float n = 0;
	WEAPON_INFO_FOR_EACH(e) {
		if ((e.weapons & weaponselect_available) || (e.weapons_extra & weaponselect_available_extra)) {
			if (n == weaponselect_selected)
				return e.weapon;
			++n;
		}
	}
	return -1;
}

void(void) weaponselect_draw {
	if (weaponselect_active) {
		weaponselect_alpha = approach(weaponselect_alpha, 1, frametime * 5);
		input_event_callback = weaponselect_input_event;
		mouse_enable("");
	} else
		weaponselect_alpha = approach(weaponselect_alpha, 0, frametime * 7);

	if (!weaponselect_alpha) {
		remove(self);
		weaponselect = NULL;
		return;
	}
	sbar_hidescores = TRUE;
	float a = weaponselect_alpha;
	drawfont = sbar_bigfont;
	drawfill('0 0 0', '1 0 0' * CVAR(vid_conwidth) + CVAR(vid_conheight) * '0 1 0', '0 0 0', 0.5 * a, DRAWFLAG_NORMAL);
	vector o = ('1 0 0' * (CVAR(vid_conwidth) - weaponselect_width) + (CVAR(vid_conheight) - weaponselect_height) * '0 1 0') * 0.5;
	vector s;
	s_x = weaponselect_width;
	s_y = weaponselect_height;
	s_z = 0;
	if (weaponselect_active)
		weaponselect_update(o, s);

	vector sz;
	sz_x = WEAPONSELECT_SCALE;
	sz_y = WEAPONSELECT_SCALE;
	sz_z = 0;
	draw_string_center('0 1 0' * (o_y - sz_y * 1.25), "Weapon Selection", sz, '1 1 1', a, DRAWFLAG_NORMAL);
	o_x = (CVAR(vid_conwidth) * 0.5) - 0.5 * (weaponselect_width + WEAPONSELECT_MARGIN);
	drawfill(o, s, '0 0 0', 0.3, DRAWFLAG_NORMAL);
	draw_borderlines(2, o, s, '0 0 0', a, DRAWFLAG_NORMAL);
	string txt;
	float txtw;
	//txt = strcat("Key: ^2", strtoupper(input_command_key_first("+attack2")));
	//txtw = stringwidth(txt, TRUE, sz);
	//drawcolorcodedstring([o_x + (s_x - txtw) * 0.5, o_y + s_y + WEAPONSELECT_MARGIN * 0.5], txt, sz, a, DRAWFLAG_NORMAL);
	entity e;
	float i = 0;
	WEAPON_INFO_FOR_EACH(e) {
		if (!(e.weapons & weaponselect_available) && !(e.weapons_extra & weaponselect_available_extra))
			continue;

		float sidx = i;
		vector p;
		p_z = 0;
		float a2 = weaponselect_selalpha[sidx];
		float isSelected = i == weaponselect_selected;
		vector clr = '0.75 0.75 0.75';
		if (isSelected) {
			weaponselect_selalpha[sidx] = approach(weaponselect_selalpha[sidx], 1, frametime * 3);
			p_x = o_x;
			p_y = o_y + i * sz_y + WEAPONSELECT_MARGIN * 0.5;
			drawfill(p, s_x * '1 0 0' + sz_y * '0 1 0', clr, 0.2 * a, DRAWFLAG_NORMAL);
		} else
			weaponselect_selalpha[sidx] = approach(weaponselect_selalpha[sidx], 0, frametime * 3);

		p_x = o_x + WEAPONSELECT_MARGIN * 0.5;
		p_y = o_y + i * sz_y + WEAPONSELECT_MARGIN * 0.5;
		drawpic(p, strcat("gfx/hud/inv_weapon", ftos(e.weapon - 1)), '2 1 0' * WEAPONSELECT_SCALE, '1 1 1' * (0.5 + 0.5 * a2), a, DRAWFLAG_NORMAL);
		p_x = WEAPONSELECT_MARGIN * 0.5 + o_x + sz_x * 2;
		drawstring(p, e.message, sz, clr, a, DRAWFLAG_NORMAL);
		if (i < 10) {
			txt = ((i == 9) ? "0" : ftos(i + 1));
			txtw = stringwidth(txt, FALSE) * sz_x * 0.5;
			drawstring('1 0 0' * (o_x + s_x - txtw) + p_y * '0 1 0', txt, sz * 0.5, '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);
		}
		if (++i == WEAPONSELECT_MAXOPTIONS)
			break;
	}
	drawfont = sbar_font;
}

void(void) weaponselect_confirm {
	entity w = weapon_info(weaponselect_get());
	localcmd("cmd pickweapon ", w.netname, "; cmd join\n");
	weaponselect_active = FALSE;
}

float weaponselect_input_event(float bInputType, float nPrimary, float nSecondary) {
	if (!weaponselect_active)
		return FALSE;

	if (bInputType == 2)
		return TRUE;

	if (bInputType == 0) {
		if (nPrimary == K_ESCAPE) {
			weaponselect_active = FALSE;
			return TRUE;
		}
		if (nPrimary == K_MOUSE1) {
			vector o = ('1 0 0' * (CVAR(vid_conwidth) - weaponselect_width) + (CVAR(vid_conheight) - weaponselect_height) * '0 1 0') * 0.5;
			vector s;
			s_x = weaponselect_width;
			s_y = weaponselect_height;
			s_z = 0;
			weaponselect_update(o, s);
			weaponselect_confirm();
			return TRUE;
		}
		if (nPrimary >= '0' && nPrimary <= '9') {
			weaponselect_selected = nPrimary - '0';
			if (!weaponselect_selected)
				weaponselect_selected = 10;
			else
				--weaponselect_selected;

			weaponselect_selected = bound(0, weaponselect_selected, weaponselect_numoptions - 1);
			weaponselect_confirm();
		}
	}
	return FALSE;
}

void(void) weaponselect_read {
	weaponselect_available = net_read_int24();
	weaponselect_available_extra = net_read_int24();
	if (weaponselect_active)
		return;

	if (main_isdemo)
		return;

	weaponselect_width = 0;
	weaponselect_numoptions = 0;
	float olddrawfont = drawfont;
	drawfont = sbar_bigfont;
	for (float w = 0; w <= WEAPON_LAST; ++w) {
		if (pow(2, w) & weaponselect_available) {
			++weaponselect_numoptions;
			weaponselect_width = max(weaponselect_width, WEAPONSELECT_SCALE * 2 + stringwidth(weapon_info(w).message, FALSE) * WEAPONSELECT_SCALE);
		}
	}
	drawfont = olddrawfont;
	weaponselect_height = WEAPONSELECT_SCALE * weaponselect_numoptions + WEAPONSELECT_MARGIN;
	weaponselect_width += WEAPONSELECT_MARGIN;
	weaponselect_active = TRUE;
	if not(weaponselect) {
		weaponselect = spawn();
		weaponselect.draw2d = weaponselect_draw;
		weaponselect.draw2dflag = 1;
	}
}
