vector teamradar_picmin; // adjusted mins that map to the picture (square)
vector teamradar_picmax; // adjusted maxs that map to the picture (square)
vector teamradar_pictexcoord0; // texcoords of the image corners (after transforming, these are 2D coords too)
vector teamradar_pictexcoord1; // texcoords of the image corners (after transforming, these are 2D coords too)
vector teamradar_pictexcoord2; // texcoords of the image corners (after transforming, these are 2D coords too)
vector teamradar_pictexcoord3; // texcoords of the image corners (after transforming, these are 2D coords too)
float teamradar_angle; // player yaw angle
vector teamradar_origin3d_in_texcoord; // player origin
vector teamradar_origin2d; // 2D origin
vector teamradar_size2d; // 2D size
vector teamradar_extraclip_mins, teamradar_extraclip_maxs; // don't even ask
float teamradar_size_scale; // 2D scale factor
float teamradar_scale; // window size = ...qu
float teamradar_nohudhack;

void(void) teamradar_init {
	vector extend;
	teamradar_picmin = world_min;
	teamradar_picmax = world_max;
	// extend teamradar_picmax to get a square aspect ratio
	// center the map in that area
	extend = teamradar_picmax - teamradar_picmin;
	if (extend_y > extend_x) {
		teamradar_picmin_x -= (extend_y - extend_x) * 0.5;
		teamradar_picmax_x += (extend_y - extend_x) * 0.5;
	} else {
		teamradar_picmin_y -= (extend_x - extend_y) * 0.5;
		teamradar_picmax_y += (extend_x - extend_y) * 0.5;
	}
	// add another some percent
	extend = (teamradar_picmax - teamradar_picmin) * (1 / 64.0);
	teamradar_picmin -= extend;
	teamradar_picmax += extend;
	// calculate the texcoords
	teamradar_pictexcoord0 = teamradar_pictexcoord1 = teamradar_pictexcoord2 = teamradar_pictexcoord3 = '0 0 0';
	// first the two corners of the origin
	teamradar_pictexcoord0_x = (world_min_x - teamradar_picmin_x) / (teamradar_picmax_x - teamradar_picmin_x);
	teamradar_pictexcoord0_y = (world_min_y - teamradar_picmin_y) / (teamradar_picmax_y - teamradar_picmin_y);
	teamradar_pictexcoord2_x = (world_max_x - teamradar_picmin_x) / (teamradar_picmax_x - teamradar_picmin_x);
	teamradar_pictexcoord2_y = (world_max_y - teamradar_picmin_y) / (teamradar_picmax_y - teamradar_picmin_y);
	// then the other corners
	teamradar_pictexcoord1_x = teamradar_pictexcoord0_x;
	teamradar_pictexcoord1_y = teamradar_pictexcoord2_y;
	teamradar_pictexcoord3_x = teamradar_pictexcoord2_x;
	teamradar_pictexcoord3_y = teamradar_pictexcoord0_y;
}

float(vector v) teamradar_vlen2d {
	return sqrt(v_x * v_x + v_y * v_y);
}

float(vector v) teamradar_vlen_maxnorm2d {
	return max4(v_x, v_y, -v_x, -v_y);
}

float(vector v) teamradar_vlen_minnorm2d {
	return min(max(v_x, -v_x), max(v_y, -v_y));
}

vector(vector in) teamradar_3dcoord_to_texcoord {
	vector out;
	out_x = (in_x - teamradar_picmin_x) / (teamradar_picmax_x - teamradar_picmin_x);
	out_y = (in_y - teamradar_picmin_y) / (teamradar_picmax_y - teamradar_picmin_y);
	out_z = 0;
	return out;
}

vector(vector in) teamradar_texcoord_to_3dcoord {
	vector out;
	out_x = in_x * (teamradar_picmax_x - teamradar_picmin_x) + teamradar_picmin_x;
	out_y = in_y * (teamradar_picmax_y - teamradar_picmin_y) + teamradar_picmin_y;
	out_z = 0;
	return out;
}

vector(vector in) teamradar_texcoord_to_2dcoord {
	vector out;
	in -= teamradar_origin3d_in_texcoord;
	out = math_rotate(in, teamradar_angle * MATH_DEG2RAD);
	out_y = - out_y; // screen space is reversed
	out = out * teamradar_size_scale;
	if (CVAR(v_flipped))
		out_x = -out_x;

	out += teamradar_origin2d;
	return out;
}

vector teamradar_2dcoord_to_texcoord(vector in) {
	vector out;
	out = in - teamradar_origin2d;
	if (CVAR(v_flipped))
		out_x = -out_x;

	out = out * (1 / teamradar_size_scale);
	out_y = -out_y;
	out = math_rotate(out, -teamradar_angle * MATH_DEG2RAD);
	out += teamradar_origin3d_in_texcoord;
	return out;
}

vector(vector v) teamradar_yinvert {
	v_y = 1 - v_y;
	return v;
}

void(float bg, float fg) teamradar_background_draw {
	float fga;
	vector fgc;
	if (bg > 0) {
		R_BeginPolygon("", 0);
		R_PolygonVertex('1 0 0' * (teamradar_origin2d_x - teamradar_size2d_x * 0.5 + teamradar_extraclip_mins_x) + '0 1 0' * (teamradar_origin2d_y - teamradar_size2d_y * 0.5 + teamradar_extraclip_mins_y), '0 0 0', '0 0 0', bg);
		R_PolygonVertex('1 0 0' * (teamradar_origin2d_x + teamradar_size2d_x * 0.5 + teamradar_extraclip_maxs_x) + '0 1 0' * (teamradar_origin2d_y - teamradar_size2d_y * 0.5 + teamradar_extraclip_mins_y), '0 0 0', '0 0 0', bg);
		R_PolygonVertex('1 0 0' * (teamradar_origin2d_x + teamradar_size2d_x * 0.5 + teamradar_extraclip_maxs_x) + '0 1 0' * (teamradar_origin2d_y + teamradar_size2d_y * 0.5 + teamradar_extraclip_maxs_y), '0 0 0', '0 0 0', bg);
		R_PolygonVertex('1 0 0' * (teamradar_origin2d_x - teamradar_size2d_x * 0.5 + teamradar_extraclip_mins_x) + '0 1 0' * (teamradar_origin2d_y + teamradar_size2d_y * 0.5 + teamradar_extraclip_maxs_y), '0 0 0', '0 0 0', bg);
		R_EndPolygon();
	}
	if (fg > 0 && teamradar_minimapname != "") {
		fga = 1;
		fgc = '1 1 1' * fg;
		R_BeginPolygon(teamradar_minimapname, DRAWFLAG_SCREEN | DRAWFLAG_MIPMAP);
		if (CVAR(v_flipped)) {
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord3), teamradar_yinvert(teamradar_pictexcoord3), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord2), teamradar_yinvert(teamradar_pictexcoord2), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord1), teamradar_yinvert(teamradar_pictexcoord1), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord0), teamradar_yinvert(teamradar_pictexcoord0), fgc, fga);
		} else {
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord0), teamradar_yinvert(teamradar_pictexcoord0), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord1), teamradar_yinvert(teamradar_pictexcoord1), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord2), teamradar_yinvert(teamradar_pictexcoord2), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(teamradar_pictexcoord3), teamradar_yinvert(teamradar_pictexcoord3), fgc, fga);
		}
		R_EndPolygon();
	}
}

void(vector coord3d, vector pangles, vector rgb) teamradar_player_draw {
	vector coord, rgb2;
	coord = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(coord3d));
	makevectors(pangles - '0 1 0' * teamradar_angle);
	if (CVAR(v_flipped)) {
		v_forward_x = -v_forward_x;
		v_right_x = -v_right_x;
		v_up_x = -v_up_x;
	}
	v_forward_z = 0;
	v_forward = normalize(v_forward);
	v_forward_y *= -1.0;
	v_right_x = -v_forward_y;
	v_right_y = v_forward_x;
	if (rgb == '1 1 1')
		rgb2 = '0 0 0';
	else
		rgb2 = '1 1 1';

	R_BeginPolygon("", 0);
	R_PolygonVertex(coord+v_forward*3, '0 0 0', rgb2, sbar_alpha_fg);
	R_PolygonVertex(coord+v_right*4-v_forward*2.5, '0 1 0', rgb2, sbar_alpha_fg);
	R_PolygonVertex(coord-v_forward*2, '1 0 0', rgb2, sbar_alpha_fg);
	R_PolygonVertex(coord-v_right*4-v_forward*2.5, '1 1 0', rgb2, sbar_alpha_fg);
	R_EndPolygon();
	R_BeginPolygon("", 0);
	R_PolygonVertex(coord+v_forward*2, '0 0 0', rgb, sbar_alpha_fg);
	R_PolygonVertex(coord+v_right*3-v_forward*2, '0 1 0', rgb, sbar_alpha_fg);
	R_PolygonVertex(coord-v_forward, '1 0 0', rgb, sbar_alpha_fg);
	R_PolygonVertex(coord-v_right*3-v_forward*2, '1 1 0', rgb, sbar_alpha_fg);
	R_EndPolygon();
}

void(vector coord, float icon, entity pingdata, vector rgb, float a) teamradar_icon_draw {
	float dt;
	vector v;
	float i;
	coord = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(coord));
	drawpic(coord - '4 4 0', strcat("gfx/teamradar_icon_", ftos(icon)), '8 8 0', rgb, a, 0);
	if (pingdata) {
		for (i = 0; i < MAX_TEAMRADAR_TIMES; ++i) {
			dt = pingdata.(teamradar_times[i]);
			if (dt == 0)
				continue;

			dt = time - dt;
			if (dt >= 1 || dt <= 0)
				continue;

			v = '2 2 0' * teamradar_size_scale * dt;
			drawpic(coord - 0.5 * v, "gfx/teamradar_ping", v, '1 1 1', (1 - dt) * a, DRAWFLAG_ADDITIVE);
		}
	}
}

void(vector start, vector end, float colors) teamradar_link_draw {
	vector c0, c1, norm;
	start = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(start));
	end = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(end));
	norm = normalize(start - end);
	norm_z = norm_x;
	norm_x = -norm_y;
	norm_y = norm_z;
	norm_z = 0;
	c0 = colormap_palette_color(colors & 0x0F, FALSE);
	c1 = colormap_palette_color((colors & 0xF0) / 0x10, FALSE);
	R_BeginPolygon("", 0);
	R_PolygonVertex(start - norm, '0 0 0', c0, sbar_alpha_fg);
	R_PolygonVertex(start + norm, '0 1 0', c0, sbar_alpha_fg);
	R_PolygonVertex(end + norm, '1 1 0', c1, sbar_alpha_fg);
	R_PolygonVertex(end - norm, '1 0 0', c1, sbar_alpha_fg);
	R_EndPolygon();
}

float teamradar_scale;
float teamradar_background_alpha;
float teamradar_foreground_alpha;
float teamradar_rotation;
vector teamradar_size;
vector teamradar_position;
float teamradar_zoommode;

void(float big) teamradar_loadcvars {
	if (big) {
		teamradar_scale = 42; // dummy, not used (see zoommode)
		teamradar_background_alpha = 1 * (1 - CVAR(_menu_alpha));
		teamradar_foreground_alpha = 1 * (1 - CVAR(_menu_alpha));
		teamradar_rotation = CVAR(cl_teamradar_rotation);
		if (!teamradar_rotation)
			teamradar_rotation = 4;

		teamradar_size = '256 256 0' * big; // TODO make somewhat variable?
		teamradar_position = '0.5 0.5 0';
		teamradar_zoommode = 3;
		teamradar_nohudhack = 0;
	} else {
		teamradar_scale = CVAR(cl_teamradar_scale);
		teamradar_background_alpha = CVAR(cl_teamradar_background_alpha) * sbar_alpha_fg;
		teamradar_foreground_alpha = CVAR(cl_teamradar_foreground_alpha) * sbar_alpha_fg;
		teamradar_rotation = CVAR(cl_teamradar_rotation);
		teamradar_size = CVAR(cl_teamradar_size);
		teamradar_position = CVAR(cl_teamradar_position);
		teamradar_zoommode = CVAR(cl_teamradar_zoommode);
		// others default to 0
		// match this to defaultNexuiz.cfg!
		if (!teamradar_scale) teamradar_scale = 4096;
		if (!teamradar_background_alpha) teamradar_background_alpha = 0.4 * sbar_alpha_fg;
		if (!teamradar_foreground_alpha) teamradar_foreground_alpha = 0.8 * sbar_alpha_fg;
		if (!teamradar_size_x) teamradar_size_x = 128;
		if (!teamradar_size_y) teamradar_size_y = teamradar_size_x;
		teamradar_size_z = 0;
		teamradar_nohudhack = teamradar_position_z;
		teamradar_position_z = 0;
	}
}

void(float big, string title) teamradar_view {
	float color1, color2; // color already declared as a global in sbar.qc
	vector rgb;
	entity tm;
	float scale2d, normalsize, bigsize;
	float f;
	if (big)
		view_crosshair = 0;
	else if (teamradar_minimapname == "")
		return;

	teamradar_loadcvars(big);
	switch (teamradar_zoommode) {
	default:
	case 0:
		f = view_zoom_fraction_current;
		break;
	case 1:
		f = 1 - view_zoom_fraction_current;
		break;
	case 2:
		f = 0;
		break;
	case 3:
		f = 1;
		break;
	}
	switch (teamradar_rotation) {
	case 0:
		teamradar_angle = view_angles_y - 90;
		break;
	default:
		teamradar_angle = 90 * teamradar_rotation;
		break;
	}
	scale2d = teamradar_vlen_maxnorm2d(teamradar_picmax - teamradar_picmin);
	teamradar_size2d = teamradar_size;
	teamradar_origin2d =
			'1 0 0' * (0.5 * teamradar_size2d_x + teamradar_position_x * (CVAR(vid_conwidth) - teamradar_size2d_x))
			+ '0 1 0' * (0.5 * teamradar_size2d_y + teamradar_position_y * (CVAR(vid_conheight) - teamradar_size2d_y));
	teamradar_extraclip_mins = teamradar_extraclip_maxs = '0 0 0';
	if (teamradar_position == '1 0 0') {
		if (teamradar_nohudhack < 2)
			teamradar_origin2d_y += 25;
		if (teamradar_nohudhack < 1)
			teamradar_extraclip_mins_y -= 25;
	} else if (teamradar_position == '0 1 0' || teamradar_position == '1 1 0') {
		if (teamradar_nohudhack < 2)
			teamradar_origin2d_y -= 50;
		//if (teamradar_nohudhack < 1)
			//teamradar_extraclip_size_y += 50; // don't, the HUD looks nice
	}
	// pixels per world qu to match the teamradar_size2d_x range in the longest dimension
	if (teamradar_rotation == 0) {
		// max-min distance must fit the radar in any rotation
		bigsize = teamradar_vlen_minnorm2d(teamradar_size2d) * scale2d / (1.05 * teamradar_vlen2d(world_max - world_min));
	} else {
		vector c0, c1, c2, c3, span;
		c0 = math_rotate(world_min, teamradar_angle * MATH_DEG2RAD);
		c1 = math_rotate(world_max, teamradar_angle * MATH_DEG2RAD);
		c2 = math_rotate('1 0 0' * world_min_x + '0 1 0' * world_max_y, teamradar_angle * MATH_DEG2RAD);
		c3 = math_rotate('1 0 0' * world_max_x + '0 1 0' * world_min_y, teamradar_angle * MATH_DEG2RAD);
		span = '0 0 0';
		span_x = max4(c0_x, c1_x, c2_x, c3_x) - min4(c0_x, c1_x, c2_x, c3_x);
		span_y = max4(c0_y, c1_y, c2_y, c3_y) - min4(c0_y, c1_y, c2_y, c3_y);
		// max-min distance must fit the radar in x=x, y=y
		bigsize = min(
			teamradar_size2d_x * scale2d / (1.05 * span_x),
			teamradar_size2d_y * scale2d / (1.05 * span_y)
		);
	}
	normalsize = teamradar_vlen_maxnorm2d(teamradar_size2d) * scale2d / teamradar_scale;
	if (bigsize > normalsize)
		normalsize = bigsize;

	teamradar_size_scale =
			f * bigsize
			+ (1 - f) * normalsize;
	teamradar_origin3d_in_texcoord = teamradar_3dcoord_to_texcoord(
			f * (world_min + world_max) * 0.5
			+ (1 - f) * view_origin);
	color1 = player_color(player_localentnum-1);
	rgb = team_rgb(color1);
	drawsetcliparea(
			teamradar_origin2d_x - teamradar_size2d_x * 0.5 + teamradar_extraclip_mins_x,
			teamradar_origin2d_y - teamradar_size2d_y * 0.5 + teamradar_extraclip_mins_y,
			teamradar_size2d_x + teamradar_extraclip_maxs_x - teamradar_extraclip_mins_x,
			teamradar_size2d_y + teamradar_extraclip_maxs_y - teamradar_extraclip_mins_y
			);
	teamradar_background_draw(teamradar_background_alpha, teamradar_foreground_alpha);
	if (big) {
		drawresetcliparea();
		vector frame_origin, frame_size;
		frame_origin = frame_size = '0 0 0';
		frame_origin_x = teamradar_origin2d_x - teamradar_size2d_x * 0.55859375;
		frame_origin_y = teamradar_origin2d_y - teamradar_size2d_y * 0.55859375;
		frame_size_x = teamradar_size2d_x * 1.1171875;
		frame_size_y = teamradar_size2d_y * 1.1171875;
		drawpic(frame_origin, "gfx/ons-frame", frame_size, '1 1 1', sbar_alpha_fg, 0);
		drawpic(frame_origin, "gfx/ons-frame-team", frame_size, rgb, sbar_alpha_fg, 0);
		if (title)
			drawstring(frame_origin - '0 24 0', title, '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);

		drawsetcliparea(
			teamradar_origin2d_x - teamradar_size2d_x * 0.5,
			teamradar_origin2d_y - teamradar_size2d_y * 0.5,
			teamradar_size2d_x,
			teamradar_size2d_y
		);
	}
	for (tm = world; (tm = find(tm, classname, "radarlink")); )
		teamradar_link_draw(tm.origin, tm.velocity, tm.team);

	for (tm = world; (tm = findflags(tm, teamradar_icon, 0xFFFFFF)); )
		teamradar_icon_draw(tm.origin, tm.teamradar_icon, tm, tm.teamradar_color, tm.alpha * sbar_alpha_fg);

	for (tm = world; (tm = find(tm, classname, "entcs_receiver")); ) {
		if (tm.cnt)
			continue;

		color2 = player_color(tm.sv_entnum);
		//if (color == COLOR_SPECTATOR || color == color2)
		teamradar_player_draw(tm.origin, tm.angles, team_rgb(color2));
	}
	teamradar_player_draw(view_origin, view_angles, '1 1 1');
	drawresetcliparea();
}

void(float ignore) teamradar_link_read {
	float sendflags;
	sendflags = net_read_byte();
	interpolate_undo();
	self.iflags = IFLAG_VELOCITY;
	self.classname = "radarlink";
	if (sendflags & 1) {
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
	}
	if (sendflags & 2) {
		self.velocity_x = net_read_coord();
		self.velocity_y = net_read_coord();
		self.velocity_z = net_read_coord();
	}
	if (sendflags & 4) {
		self.team = net_read_byte();
	}
	interpolate_note();
}
