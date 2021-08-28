#define NADGETSELECT_MAX_OPTIONS 16
#define NADGETSELECT_SCALE 24
#define NADGETSELECT_MARGIN 10

float nadgetselect_options[NADGETSELECT_MAX_OPTIONS*2];
float nadgetselect_selalpha[NADGETSELECT_MAX_OPTIONS*2];
float nadgetselect_numoptions;
float nadgetselect_active;
float nadgetselect_alpha;
float nadgetselect_width;
float nadgetselect_height;
float nadgetselect_selected;
float nadgetselect_selected_in;
float nadgetselect_confirmed1;
float nadgetselect_confirmed2;
float g_nadgets_double;

float(float bInputType, float nPrimary, float nSecondary) nadgetselect_input_event;

void(vector o, vector s) nadgetselect_update {
	vector v = mouse_position();
	if (g_nadgets_double)
		nadgetselect_selected_in = (v_x > CVAR(vid_conwidth) * 0.5);
	else
		nadgetselect_selected_in = 0;

	nadgetselect_selected = floor(nadgetselect_numoptions * ((bound(o_y, v_y, o_y + s_y) - o_y) / s_y));
	nadgetselect_selected = min(nadgetselect_numoptions - 1, nadgetselect_selected);
}

void(void) nadgetselect_draw {
	if (nadgetselect_active) {
		nadgetselect_alpha = approach(nadgetselect_alpha, 1, frametime * 5);
		input_event_callback = nadgetselect_input_event;
	} else
		nadgetselect_alpha = approach(nadgetselect_alpha, 0, frametime * 7);

	if (!nadgetselect_alpha) {
		remove(self);
		return;
	}
	mouse_enable("");
	sbar_hidescores = TRUE;
	float a = nadgetselect_alpha;
	drawfont = sbar_bigfont;
	//drawfill('0 0', '1 0' * CVAR(vid_conwidth) + '0 1' * CVAR(vid_conheight), '0 0 0', 0.5 * a, DRAWFLAG_NORMAL);
	vector o;
	o_x = (CVAR(vid_conwidth) - nadgetselect_width) * 0.5;
	o_y = (CVAR(vid_conheight) - nadgetselect_height) * 0.5;
	o_z = 0;
	vector s;
	s_x = nadgetselect_width;
	s_y = nadgetselect_height;
	s_z = 0;
	if (nadgetselect_active)
		nadgetselect_update(o, s);

	vector sz;
	sz_x = NADGETSELECT_SCALE;
	sz_y = NADGETSELECT_SCALE;
	sz_z = 0;
	draw_string_center((o_y - sz_y * (1.25 + 2 * g_nadgets_double)) * '0 1 0', "Nadget Selection", sz, '1 1 1', a, DRAWFLAG_NORMAL);
	float table, tables;
	for (table = 0; table < (tables = g_nadgets_double + 1); ++table) {
		o_x = (CVAR(vid_conwidth) * 0.5) - (1 * tables * 0.5 - 1 * table) * (nadgetselect_width + NADGETSELECT_MARGIN);
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
		drawcolorcodedstring((o_x + (s_x - txtw) * 0.5) * '1 0 0' + (o_y + s_y + NADGETSELECT_MARGIN * 0.5) * '0 1 0', txt, sz, a, DRAWFLAG_NORMAL);
		float confirmed = (table ? nadgetselect_confirmed2 : nadgetselect_confirmed1);
		float confirmedOther = (table ? nadgetselect_confirmed1 : nadgetselect_confirmed2);
		float i;
		for (i = 0; i < nadgetselect_numoptions; ++i) {
			float sidx = i + NADGETSELECT_MAX_OPTIONS * table;
			float t = nadgetselect_options[sidx];
			if (t < 0)
				break;

			vector p = '0 0 0';
			float a2 = nadgetselect_selalpha[sidx];
			float isConfirmed = t == confirmed;
			float isSelected = i == nadgetselect_selected && nadgetselect_selected_in == table;
			vector clr = (((confirmed < 0 || isConfirmed || isSelected) && (t != confirmedOther || t == NADGET_RANDOM)) ?
					nadget_TypeToColor(t) * (0.5 + 0.5 * a2) :
					'0.1 0.1 0.1');

			if (isConfirmed || isSelected) {
				nadgetselect_selalpha[sidx] = approach(nadgetselect_selalpha[sidx], 1, frametime * 3);
				p_x = o_x;
				p_y = o_y + i * sz_y + NADGETSELECT_MARGIN * 0.5;
				drawfill(p, (s_x * '1 0 0' + sz_y * '0 1 0'), clr, 0.2 * a, DRAWFLAG_NORMAL);
			} else
				nadgetselect_selalpha[sidx] = approach(nadgetselect_selalpha[sidx], 0, frametime * 3);

			p_x = o_x + NADGETSELECT_MARGIN * 0.5;
			p_y = o_y + i * sz_y + NADGETSELECT_MARGIN * 0.5;
			if (t == NADGET_RANDOM) {
				p_x = p_x + (sz_x - stringwidth("?", FALSE) * sz_x) * 0.5;
				drawstring(p, "?", sz, clr, a, DRAWFLAG_NORMAL);
			} else {
				drawpic(p, nadget_TypeToIcon(t, TRUE, FALSE), sz, '1 1 1' * (0.5 + 0.5 * a2), a, DRAWFLAG_NORMAL);
			}
			p_x = NADGETSELECT_MARGIN * 0.5 + o_x + sz_x;
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

void(void) nadgetselect_confirm {
	if (nadgetselect_selected_in) {
		nadgetselect_confirmed2 = nadgetselect_options[NADGETSELECT_MAX_OPTIONS + nadgetselect_selected];
		if (nadgetselect_confirmed2 == nadgetselect_confirmed1 && nadgetselect_confirmed2 != NADGET_RANDOM)
			nadgetselect_confirmed1 = -1;
	} else {
		nadgetselect_confirmed1 = nadgetselect_options[nadgetselect_selected];
		if (nadgetselect_confirmed1 == nadgetselect_confirmed2 && nadgetselect_confirmed1 != NADGET_RANDOM)
			nadgetselect_confirmed2 = -1;
	}

	if (!g_nadgets_double || (nadgetselect_confirmed1 >= 0 && nadgetselect_confirmed2 >= 0)) {
		string cmd = strcat("cmd picknade ", nadget_TypeToName(nadgetselect_confirmed1));
		if (nadgetselect_confirmed2 >= 0)
			cmd = strcat(cmd, " ", nadget_TypeToName(nadgetselect_confirmed2));

		cmd = strcat(cmd, "; cmd join\n");
		localcmd(cmd);
		nadgetselect_active = FALSE;
	}
}

float(float bInputType, float nPrimary, float nSecondary) nadgetselect_input_event {
	if (!nadgetselect_active)
		return FALSE;

	if (bInputType == 2)
		return TRUE;

	if (bInputType == 0) {
		if (nPrimary == K_ESCAPE) {
			if (nadgetselect_confirmed2 >= 0)
				nadgetselect_confirmed2 = -1;
			else if (nadgetselect_confirmed1 >= 0)
				nadgetselect_confirmed1 = -1;
			else {
				nadgetselect_active = FALSE;
			}
			return TRUE;
		}
		if (nPrimary == K_MOUSE1) {
			vector o;
			o_x = (CVAR(vid_conwidth) - nadgetselect_width) * 0.5;
			o_y = (CVAR(vid_conheight) - nadgetselect_height) * 0.5;
			o_z = 0;
			vector s;
			s_x = nadgetselect_width;
			s_y = nadgetselect_height;
			s_z = 0;
			nadgetselect_update(o, s);
			nadgetselect_confirm();
			return TRUE;
		}
		if (nPrimary >= '0' && nPrimary <= '9') {
			nadgetselect_selected = nPrimary - '0';
			if (!nadgetselect_selected)
				nadgetselect_selected = 10;
			else
				--nadgetselect_selected;

			nadgetselect_selected = bound(0, nadgetselect_selected, nadgetselect_numoptions - 1);
			nadgetselect_selected_in = 0;
			if (nadgetselect_confirmed1 >= 0)
				++nadgetselect_selected_in;

			nadgetselect_confirm();
		}
	}
	return FALSE;
}

void(void) nadgetselect_read {
	string opts_pri, opts_sec = "";
	if (net_read_byte())
		g_nadgets_double = 1;

	opts_pri = net_read_string();
	if (g_nadgets_double)
		opts_sec = net_read_string();

	if (main_isdemo)
		return;

	if (!nadgetselect_active) {
		nadgetselect_confirmed1 = nadgetselect_confirmed2 = -1;
	}
	nadgetselect_width = 0;
	nadgetselect_numoptions = 0;
	float oldfont = drawfont;
	drawfont = sbar_bigfont;
	float table;
	for (table = 0; table < 2; ++table) {
		nadgetselect_numoptions = max(nadgetselect_numoptions, tokenizebyseparator((table ? opts_sec : opts_pri), " "));
		float i;
		for (i = 0; i < NADGETSELECT_MAX_OPTIONS; ++i) {
			string typename = argv(i);
			float idx = i + table * NADGETSELECT_MAX_OPTIONS;
			float valid = (typename != "");
			if (valid)
				nadgetselect_options[idx] = nadget_NameToType(typename);
			else
				nadgetselect_options[idx] = -1;

			if (!nadgetselect_active)
				nadgetselect_selalpha[idx] = 0;

			if (!valid)
				continue;

			nadgetselect_width = max(nadgetselect_width, NADGETSELECT_SCALE + stringwidth(nadget_TypeToExpandedName(nadgetselect_options[idx]), FALSE) * NADGETSELECT_SCALE);
		}
	}
	drawfont = oldfont;
	nadgetselect_height = NADGETSELECT_SCALE * nadgetselect_numoptions + NADGETSELECT_MARGIN;
	nadgetselect_width += NADGETSELECT_MARGIN;
	nadgetselect_active = TRUE;
	entity e = spawn();
	e.draw2d = nadgetselect_draw;
	e.draw2dflag = 1;
}
