#define NADGET_SELECT_MAX_OPTIONS 16
#define NADGET_SELECT_SCALE 24
#define NADGET_SELECT_MARGIN 10

float nadget_select_options[NADGET_SELECT_MAX_OPTIONS*2];
float nadget_select_selalpha[NADGET_SELECT_MAX_OPTIONS*2];
float nadget_select_numoptions;
float nadget_select_active;
float nadget_select_alpha;
float nadget_select_width;
float nadget_select_height;
float nadget_select_selected;
float nadget_select_selected_in;
float nadget_select_confirmed1;
float nadget_select_confirmed2;
float g_nadgets_double;
entity nadget_select;

float(float bInputType, float nPrimary, float nSecondary) nadget_select_input_event;

void(vector o, vector s) nadget_select_update {
	vector v = mouse_position();
	if (g_nadgets_double)
		nadget_select_selected_in = (v_x > CVAR(vid_conwidth) * 0.5);
	else
		nadget_select_selected_in = 0;

	nadget_select_selected = floor(nadget_select_numoptions * ((bound(o_y, v_y, o_y + s_y) - o_y) / s_y));
	nadget_select_selected = min(nadget_select_numoptions - 1, nadget_select_selected);
}

void(void) nadget_select_draw {
	if (nadget_select_active) {
		nadget_select_alpha = approach(nadget_select_alpha, 1, frametime * 5);
		input_event_callback = nadget_select_input_event;
		mouse_enable("");
	} else
		nadget_select_alpha = approach(nadget_select_alpha, 0, frametime * 7);

	if (!nadget_select_alpha) {
		nadget_select = NULL;
		remove(self);
		return;
	}
	float a = nadget_select_alpha;
	drawfont = sbar_bigfont;
	//drawfill('0 0', '1 0' * CVAR(vid_conwidth) + '0 1' * CVAR(vid_conheight), '0 0 0', 0.5 * a, DRAWFLAG_NORMAL);
	vector o;
	o_x = (CVAR(vid_conwidth) - nadget_select_width) * 0.5;
	o_y = (CVAR(vid_conheight) - nadget_select_height) * 0.5;
	o_z = 0;
	vector s;
	s_x = nadget_select_width;
	s_y = nadget_select_height;
	s_z = 0;
	if (nadget_select_active)
		nadget_select_update(o, s);

	vector sz;
	sz_x = NADGET_SELECT_SCALE;
	sz_y = NADGET_SELECT_SCALE;
	sz_z = 0;
	draw_string_center((o_y - sz_y * (1.25 + 2 * g_nadgets_double)) * '0 1 0', "Nadget Selection", sz, '1 1 1', a, DRAWFLAG_NORMAL);
	float table, tables;
	for (table = 0; table < (tables = g_nadgets_double + 1); ++table) {
		o_x = (CVAR(vid_conwidth) * 0.5) - (1 * tables * 0.5 - 1 * table) * (nadget_select_width + NADGET_SELECT_MARGIN);
		drawfill(o, s, '0 0 0', 0.3, DRAWFLAG_NORMAL);
		draw_borderlines(2, o, s, '0 0 0', a, DRAWFLAG_NORMAL);
		string txt;
		float txtw;
		if (g_nadgets_double) {
			txt = (table ? "Secondary" : "Primary");
			txtw = stringwidth(txt, FALSE) * sz_x;
			drawstring((o_x + (s_x - txtw) * 0.5) * '1 0 0' + (o_y - sz_y * 1.25) * '0 1 0', txt, sz, '1 1 1', a, DRAWFLAG_NORMAL);
		}
		txt = (table ? "'+nadget2' '+button9'" : (input_hook_use_swapped ? "+hook" : "+use"));
		txt = strcat("Key: ^2", strtoupper(input_command_key_first(txt)));
		txtw = stringwidth(txt, TRUE) * sz_x;
		drawcolorcodedstring((o_x + (s_x - txtw) * 0.5) * '1 0 0' + (o_y + s_y + NADGET_SELECT_MARGIN * 0.5) * '0 1 0', txt, sz, a, DRAWFLAG_NORMAL);
		float confirmed = (table ? nadget_select_confirmed2 : nadget_select_confirmed1);
		float confirmedOther = (table ? nadget_select_confirmed1 : nadget_select_confirmed2);
		float i;
		for (i = 0; i < nadget_select_numoptions; ++i) {
			float sidx = i + NADGET_SELECT_MAX_OPTIONS * table;
			float t = nadget_select_options[sidx];
			if (t < 0)
				break;

			vector p = '0 0 0';
			float a2 = nadget_select_selalpha[sidx];
			float isConfirmed = t == confirmed;
			float isSelected = i == nadget_select_selected && nadget_select_selected_in == table;
			vector clr = (((confirmed < 0 || isConfirmed || isSelected) && (t != confirmedOther || t == NADGET_RANDOM)) ?
					nadget_TypeToColor(t) * (0.5 + 0.5 * a2) :
					'0.1 0.1 0.1');

			if (isConfirmed || isSelected) {
				nadget_select_selalpha[sidx] = approach(nadget_select_selalpha[sidx], 1, frametime * 3);
				p_x = o_x;
				p_y = o_y + i * sz_y + NADGET_SELECT_MARGIN * 0.5;
				drawfill(p, (s_x * '1 0 0' + sz_y * '0 1 0'), clr, 0.2 * a, DRAWFLAG_NORMAL);
			} else
				nadget_select_selalpha[sidx] = approach(nadget_select_selalpha[sidx], 0, frametime * 3);

			p_x = o_x + NADGET_SELECT_MARGIN * 0.5;
			p_y = o_y + i * sz_y + NADGET_SELECT_MARGIN * 0.5;
			if (t == NADGET_RANDOM) {
				p_x = p_x + (sz_x - stringwidth("?", FALSE) * sz_x) * 0.5;
				drawstring(p, "?", sz, clr, a, DRAWFLAG_NORMAL);
			} else {
				drawpic(p, nadget_TypeToIcon(t, TRUE, FALSE), sz, '1 1 1' * (0.5 + 0.5 * a2), a, DRAWFLAG_NORMAL);
			}
			p_x = NADGET_SELECT_MARGIN * 0.5 + o_x + sz_x;
			drawstring(p, nadget_TypeToExpandedName(t), sz, clr, a, DRAWFLAG_NORMAL);
			if (i < 10) {
				txt = ((i == 9) ? "0" : ftos(i + 1));
				txtw = stringwidth(txt, FALSE) * sz_x * 0.5;
				drawstring((o_x + s_x - txtw) * '1 0 0' + p_y * '0 1 0', txt, sz * 0.5, '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);	 
			}
		}
	}
	drawfont = sbar_font;
}

void(void) nadget_select_confirm {
	if (nadget_select_selected_in) {
		nadget_select_confirmed2 = nadget_select_options[NADGET_SELECT_MAX_OPTIONS + nadget_select_selected];
		if (nadget_select_confirmed2 == nadget_select_confirmed1 && nadget_select_confirmed2 != NADGET_RANDOM)
			nadget_select_confirmed1 = -1;
	} else {
		nadget_select_confirmed1 = nadget_select_options[nadget_select_selected];
		if (nadget_select_confirmed1 == nadget_select_confirmed2 && nadget_select_confirmed1 != NADGET_RANDOM)
			nadget_select_confirmed2 = -1;
	}

	if (!g_nadgets_double || (nadget_select_confirmed1 >= 0 && nadget_select_confirmed2 >= 0)) {
		string cmd = strcat("cmd picknade ", nadget_TypeToName(nadget_select_confirmed1));
		if (nadget_select_confirmed2 >= 0)
			cmd = strcat(cmd, " ", nadget_TypeToName(nadget_select_confirmed2));

		cmd = strcat(cmd, "; cmd join\n");
		localcmd(cmd);
		nadget_select_active = FALSE;
	}
}

float(float bInputType, float nPrimary, float nSecondary) nadget_select_input_event {
	if (!nadget_select_active)
		return FALSE;

	if (bInputType == 2)
		return TRUE;

	if (bInputType == 0) {
		if (nPrimary == K_ESCAPE) {
			if (nadget_select_confirmed2 >= 0)
				nadget_select_confirmed2 = -1;
			else if (nadget_select_confirmed1 >= 0)
				nadget_select_confirmed1 = -1;
			else {
				nadget_select_active = FALSE;
			}
			return TRUE;
		}
		if (nPrimary == K_MOUSE1) {
			vector o;
			o_x = (CVAR(vid_conwidth) - nadget_select_width) * 0.5;
			o_y = (CVAR(vid_conheight) - nadget_select_height) * 0.5;
			o_z = 0;
			vector s;
			s_x = nadget_select_width;
			s_y = nadget_select_height;
			s_z = 0;
			nadget_select_update(o, s);
			nadget_select_confirm();
			return TRUE;
		}
		if (nPrimary >= '0' && nPrimary <= '9') {
			nadget_select_selected = nPrimary - '0';
			if (!nadget_select_selected)
				nadget_select_selected = 10;
			else
				--nadget_select_selected;

			nadget_select_selected = bound(0, nadget_select_selected, nadget_select_numoptions - 1);
			nadget_select_selected_in = 0;
			if (nadget_select_confirmed1 >= 0)
				++nadget_select_selected_in;

			nadget_select_confirm();
		}
	}
	return FALSE;
}

void(void) nadget_select_read {
	string opts_pri, opts_sec = "";
	if (net_read_byte())
		g_nadgets_double = 1;

	opts_pri = net_read_string();
	if (g_nadgets_double)
		opts_sec = net_read_string();

	if (main_isdemo)
		return;

	if (!nadget_select_active) {
		nadget_select_confirmed1 = nadget_select_confirmed2 = -1;
	}
	nadget_select_width = 0;
	nadget_select_numoptions = 0;
	float oldfont = drawfont;
	drawfont = sbar_bigfont;
	float table;
	for (table = 0; table < 2; ++table) {
		nadget_select_numoptions = max(nadget_select_numoptions, tokenizebyseparator((table ? opts_sec : opts_pri), " "));
		float i;
		for (i = 0; i < NADGET_SELECT_MAX_OPTIONS; ++i) {
			string typename = argv(i);
			float idx = i + table * NADGET_SELECT_MAX_OPTIONS;
			float valid = (typename != "");
			if (valid)
				nadget_select_options[idx] = nadget_NameToType(typename);
			else
				nadget_select_options[idx] = -1;

			if (!nadget_select_active)
				nadget_select_selalpha[idx] = 0;

			if (!valid)
				continue;

			nadget_select_width = max(nadget_select_width, NADGET_SELECT_SCALE + stringwidth(nadget_TypeToExpandedName(nadget_select_options[idx]), FALSE) * NADGET_SELECT_SCALE);
		}
	}
	drawfont = oldfont;
	nadget_select_height = NADGET_SELECT_SCALE * nadget_select_numoptions + NADGET_SELECT_MARGIN;
	nadget_select_width += NADGET_SELECT_MARGIN;
	nadget_select_active = TRUE;
	if not(nadget_select) {
		nadget_select = spawn();
		nadget_select.draw2d = nadget_select_draw;
		nadget_select.draw2dflag = 3;
	}
}
