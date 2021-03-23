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

float(float bInputType, float nPrimary, float nSecondary) weaponselect_input_event;

void(vector o, vector s) weaponselect_update {
	vector v = mouse_position();
	weaponselect_selected = floor(weaponselect_numoptions * ((bound(o_y, v_y, o_y + s_y) - o_y) / s_y));
	weaponselect_selected = min(weaponselect_numoptions - 1, weaponselect_selected);
}

float(void) weaponselect_get {
	for (var n = 0, var w = 0; w <= WEP_LAST; ++w) {
		if (pow(2, w) & weaponselect_available) {
			if (n == weaponselect_selected)
				return w;
			++n;
		}
	}
	return -1;
}

void(void) weaponselect_draw {
	if (weaponselect_active) {
		weaponselect_alpha = approach(weaponselect_alpha, 1, frametime * 5);
		input_event_callback = weaponselect_input_event;
	} else
		weaponselect_alpha = approach(weaponselect_alpha, 0, frametime * 7);

	if (!weaponselect_alpha) {
		remove(self);
		return;
	}
	mouse_enable(TRUE);
	sbar_hidescores = TRUE;
	var a = weaponselect_alpha;
	drawfont = sbar_bigfont;
	drawfill('0 0', [CVAR(vid_conwidth), CVAR(vid_conheight)], '0 0 0', 0.5 * a, DRAWFLAG_NORMAL);
	vector o = [CVAR(vid_conwidth) - weaponselect_width, CVAR(vid_conheight) - weaponselect_height] * 0.5;
	vector s = [weaponselect_width, weaponselect_height];
	if (weaponselect_active)
		weaponselect_update(o, s);

	vector sz = [WEAPONSELECT_SCALE, WEAPONSELECT_SCALE];
	draw_string_center([0, o_y - sz_y * 1.25], "Weapon Selection", sz, '1 1 1', a, DRAWFLAG_NORMAL);
	o_x = (CVAR(vid_conwidth) * 0.5) - 0.5 * (weaponselect_width + WEAPONSELECT_MARGIN);
	drawfill(o, s, '0 0 0', 0.3, DRAWFLAG_NORMAL);
	draw_borderlines(2, o, s, '0 0 0', a, DRAWFLAG_NORMAL);
	string txt;
	float txtw;
	//txt = strcat("Key: ^2", strtoupper(input_command_key_first("+attack2")));
	//txtw = stringwidth(txt, TRUE, sz);
	//drawcolorcodedstring([o_x + (s_x - txtw) * 0.5, o_y + s_y + WEAPONSELECT_MARGIN * 0.5], txt, sz, a, DRAWFLAG_NORMAL);
	for (var i = 0, var w = 0; w <= WEP_LAST; ++w) {
		if (!(pow(2, w) & weaponselect_available))
			continue;

		var sidx = i;
		entity winfo = weapon_info(w + 1);
		vector p;
		float a2 = weaponselect_selalpha[sidx];
		float isSelected = i == weaponselect_selected;
		vector clr = winfo.colormod * (0.5 + 0.5 * a2);
		if (isSelected) {
			weaponselect_selalpha[sidx] = approach(weaponselect_selalpha[sidx], 1, frametime * 3);
			p = [o_x, o_y + i * sz_y + WEAPONSELECT_MARGIN * 0.5];
			drawfill(p, [s_x, sz_y], clr, 0.2 * a, DRAWFLAG_NORMAL);
		} else
			weaponselect_selalpha[sidx] = approach(weaponselect_selalpha[sidx], 0, frametime * 3);

		p = [o_x + WEAPONSELECT_MARGIN * 0.5, o_y + i * sz_y + WEAPONSELECT_MARGIN * 0.5];
		drawpic(p, strcat("gfx/hud/inv_weapon", ftos(w)), '2 1 0' * WEAPONSELECT_SCALE, '1 1 1' * (0.5 + 0.5 * a2), a, DRAWFLAG_NORMAL);
		p_x = WEAPONSELECT_MARGIN * 0.5 + o_x + sz_x * 2;
		drawstring(p, winfo.message, sz, clr, a, DRAWFLAG_NORMAL);
		if (i < 10) {
			txt = if (i == 9) "0" else ftos(i + 1);
			txtw = stringwidth(txt, FALSE) * sz_x * 0.5;
			drawstring([o_x + s_x - txtw, p_y], txt, sz * 0.5, '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);	 
		}
		if (++i == WEAPONSELECT_MAXOPTIONS)
			break;
	}
	drawfont = sbar_font;
}

void(void) weaponselect_confirm {
	var w = weapon_info(weaponselect_get() + 1);
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
			vector o = [CVAR(vid_conwidth) - weaponselect_width, CVAR(vid_conheight) - weaponselect_height] * 0.5;
			vector s = [weaponselect_width, weaponselect_height];
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
	if (weaponselect_active)
		return;

	if (main_isdemo)
		return;

	weaponselect_width = 0;
	weaponselect_numoptions = 0;
	using(drawfont = sbar_bigfont) for (var w = 0; w <= WEP_LAST; ++w) {
		if (pow(2, w) & weaponselect_available) {
			++weaponselect_numoptions;
			weaponselect_width = max(weaponselect_width, WEAPONSELECT_SCALE * 2 + stringwidth(weapon_info(w+1).message, FALSE) * WEAPONSELECT_SCALE);
		}
	}
	weaponselect_height = WEAPONSELECT_SCALE * weaponselect_numoptions + WEAPONSELECT_MARGIN;
	weaponselect_width += WEAPONSELECT_MARGIN;
	weaponselect_active = TRUE;
	entity e = spawn();
	e.draw2d = weaponselect_draw;
	e.draw2dflag = 1;
}
