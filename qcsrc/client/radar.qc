vector radar_picmin; // adjusted mins that map to the picture (square)
vector radar_picmax; // adjusted maxs that map to the picture (square)
vector radar_pictexcoord0; // texcoords of the image corners (after transforming, these are 2D coords too)
vector radar_pictexcoord1; // texcoords of the image corners (after transforming, these are 2D coords too)
vector radar_pictexcoord2; // texcoords of the image corners (after transforming, these are 2D coords too)
vector radar_pictexcoord3; // texcoords of the image corners (after transforming, these are 2D coords too)
float radar_angle; // player yaw angle
vector radar_origin3d_in_texcoord; // player origin
vector radar_origin2d; // 2D origin
vector radar_size2d; // 2D size
vector radar_extraclip_mins, radar_extraclip_maxs; // don't even ask
float radar_size_scale; // 2D scale factor
float radar_scale; // window size = ...qu
float radar_nohudhack;
entity radar_chain;

void(void) radar_init {
	vector extend;
	radar_picmin = world_min;
	radar_picmax = world_max;
	// extend radar_picmax to get a square aspect ratio
	// center the map in that area
	extend = radar_picmax - radar_picmin;
	if (extend_y > extend_x) {
		radar_picmin_x -= (extend_y - extend_x) * 0.5;
		radar_picmax_x += (extend_y - extend_x) * 0.5;
	} else {
		radar_picmin_y -= (extend_x - extend_y) * 0.5;
		radar_picmax_y += (extend_x - extend_y) * 0.5;
	}
	// add another some percent
	extend = (radar_picmax - radar_picmin) * (1 / 64.0);
	radar_picmin -= extend;
	radar_picmax += extend;
	// calculate the texcoords
	radar_pictexcoord0 = radar_pictexcoord1 = radar_pictexcoord2 = radar_pictexcoord3 = '0 0 0';
	// first the two corners of the origin
	radar_pictexcoord0_x = (world_min_x - radar_picmin_x) / (radar_picmax_x - radar_picmin_x);
	radar_pictexcoord0_y = (world_min_y - radar_picmin_y) / (radar_picmax_y - radar_picmin_y);
	radar_pictexcoord2_x = (world_max_x - radar_picmin_x) / (radar_picmax_x - radar_picmin_x);
	radar_pictexcoord2_y = (world_max_y - radar_picmin_y) / (radar_picmax_y - radar_picmin_y);
	// then the other corners
	radar_pictexcoord1_x = radar_pictexcoord0_x;
	radar_pictexcoord1_y = radar_pictexcoord2_y;
	radar_pictexcoord3_x = radar_pictexcoord2_x;
	radar_pictexcoord3_y = radar_pictexcoord0_y;
}

float(vector v) radar_vlen2d {
	return sqrt(v_x * v_x + v_y * v_y);
}

float(vector v) radar_vlen_maxnorm2d {
	return max4(v_x, v_y, -v_x, -v_y);
}

float(vector v) radar_vlen_minnorm2d {
	return min(max(v_x, -v_x), max(v_y, -v_y));
}

vector(vector in) radar_3dcoord_to_texcoord {
	vector out;
	out_x = (in_x - radar_picmin_x) / (radar_picmax_x - radar_picmin_x);
	out_y = (in_y - radar_picmin_y) / (radar_picmax_y - radar_picmin_y);
	out_z = 0;
	return out;
}

vector(vector in) radar_texcoord_to_3dcoord {
	vector out;
	out_x = in_x * (radar_picmax_x - radar_picmin_x) + radar_picmin_x;
	out_y = in_y * (radar_picmax_y - radar_picmin_y) + radar_picmin_y;
	out_z = 0;
	return out;
}

vector(vector in) radar_texcoord_to_2dcoord {
	vector out;
	in -= radar_origin3d_in_texcoord;
	out = math_rotate(in, radar_angle * MATH_DEG2RAD);
	out_y = - out_y; // screen space is reversed
	out = out * radar_size_scale;
	if (CVAR(v_flipped))
		out_x = -out_x;

	out += radar_origin2d;
	return out;
}

vector radar_2dcoord_to_texcoord(vector in) {
	vector out;
	out = in - radar_origin2d;
	if (CVAR(v_flipped))
		out_x = -out_x;

	out = out * (1 / radar_size_scale);
	out_y = -out_y;
	out = math_rotate(out, -radar_angle * MATH_DEG2RAD);
	out += radar_origin3d_in_texcoord;
	return out;
}

vector(vector v) radar_yinvert {
	v_y = 1 - v_y;
	return v;
}

void(float bg, float fg) radar_background_draw {
	float fga;
	vector fgc;
	if (bg > 0) {
		R_BeginPolygon("", 0);
		R_PolygonVertex('1 0 0' * (radar_origin2d_x - radar_size2d_x * 0.5 + radar_extraclip_mins_x) + '0 1 0' * (radar_origin2d_y - radar_size2d_y * 0.5 + radar_extraclip_mins_y), '0 0 0', '0 0 0', bg);
		R_PolygonVertex('1 0 0' * (radar_origin2d_x + radar_size2d_x * 0.5 + radar_extraclip_maxs_x) + '0 1 0' * (radar_origin2d_y - radar_size2d_y * 0.5 + radar_extraclip_mins_y), '0 0 0', '0 0 0', bg);
		R_PolygonVertex('1 0 0' * (radar_origin2d_x + radar_size2d_x * 0.5 + radar_extraclip_maxs_x) + '0 1 0' * (radar_origin2d_y + radar_size2d_y * 0.5 + radar_extraclip_maxs_y), '0 0 0', '0 0 0', bg);
		R_PolygonVertex('1 0 0' * (radar_origin2d_x - radar_size2d_x * 0.5 + radar_extraclip_mins_x) + '0 1 0' * (radar_origin2d_y + radar_size2d_y * 0.5 + radar_extraclip_maxs_y), '0 0 0', '0 0 0', bg);
		R_EndPolygon();
	}
	if (fg > 0 && radar_minimapname != "") {
		fga = 1;
		fgc = '1 1 1' * fg;
		R_BeginPolygon(radar_minimapname, DRAWFLAG_SCREEN | DRAWFLAG_MIPMAP);
		if (CVAR(v_flipped)) {
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord3), radar_yinvert(radar_pictexcoord3), fgc, fga);
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord2), radar_yinvert(radar_pictexcoord2), fgc, fga);
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord1), radar_yinvert(radar_pictexcoord1), fgc, fga);
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord0), radar_yinvert(radar_pictexcoord0), fgc, fga);
		} else {
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord0), radar_yinvert(radar_pictexcoord0), fgc, fga);
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord1), radar_yinvert(radar_pictexcoord1), fgc, fga);
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord2), radar_yinvert(radar_pictexcoord2), fgc, fga);
			R_PolygonVertex(radar_texcoord_to_2dcoord(radar_pictexcoord3), radar_yinvert(radar_pictexcoord3), fgc, fga);
		}
		R_EndPolygon();
	}
}

void(vector coord3d, vector pangles, vector rgb) radar_player_draw {
	vector coord, rgb2;
	coord = radar_texcoord_to_2dcoord(radar_3dcoord_to_texcoord(coord3d));
	makevectors(pangles - '0 1 0' * radar_angle);
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

void(vector coord, float icon, vector rgb, float a) radar_icon_draw {
	float dt;
	vector v;
	float i;
	coord = radar_texcoord_to_2dcoord(radar_3dcoord_to_texcoord(coord));
	drawpic(coord - '4 4 0', strcat("gfx/teamradar_icon_", ftos(icon)), '8 8 0', rgb, a, 0);
}

void(entity pingdata, float a) radar_ping_draw {
	float dt = time - pingdata.state;
	if (dt > 1) {
		remove(pingdata);
		return;
	}
	vector coord = radar_texcoord_to_2dcoord(radar_3dcoord_to_texcoord(pingdata.origin));
	vector v = '2 2 0' * radar_size_scale * dt;
	drawpic(coord - 0.5 * v, "gfx/teamradar_ping", v, '1 1 1', (1 - dt) * a, DRAWFLAG_ADDITIVE);
}

void(vector start, vector end, float colors) radar_link_draw {
	vector c0, c1, norm;
	start = radar_texcoord_to_2dcoord(radar_3dcoord_to_texcoord(start));
	end = radar_texcoord_to_2dcoord(radar_3dcoord_to_texcoord(end));
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

float radar_scale;
float radar_background_alpha;
float radar_foreground_alpha;
float radar_rotation;
vector radar_size;
vector radar_position;
float radar_zoommode;

void(float big) radar_loadcvars {
	if (big) {
		radar_scale = 42; // dummy, not used (see zoommode)
		radar_background_alpha = 1 * (1 - CVAR(_menu_alpha));
		radar_foreground_alpha = 1 * (1 - CVAR(_menu_alpha));
		radar_rotation = CVAR(cl_teamradar_rotation);
		if (!radar_rotation)
			radar_rotation = 4;

		radar_size = '256 256 0' * big; // TODO make somewhat variable?
		radar_position = '0.5 0.5 0';
		radar_zoommode = 3;
		radar_nohudhack = 0;
	} else {
		radar_scale = CVAR(cl_teamradar_scale);
		radar_background_alpha = CVAR(cl_teamradar_background_alpha) * sbar_alpha_fg;
		radar_foreground_alpha = CVAR(cl_teamradar_foreground_alpha) * sbar_alpha_fg;
		radar_rotation = CVAR(cl_teamradar_rotation);
		radar_size = CVAR(cl_teamradar_size);
		radar_position = CVAR(cl_teamradar_position);
		radar_zoommode = CVAR(cl_teamradar_zoommode);
		// others default to 0
		if (!radar_scale) radar_scale = 4096;
		if (!radar_background_alpha) radar_background_alpha = 0.4 * sbar_alpha_fg;
		if (!radar_foreground_alpha) radar_foreground_alpha = 0.8 * sbar_alpha_fg;
		if (!radar_size_x) radar_size_x = 128;
		if (!radar_size_y) radar_size_y = radar_size_x;
		radar_size_z = 0;
		radar_nohudhack = radar_position_z;
		radar_position_z = 0;
	}
}

void(float big, string title) radar_view {
	float color1, color2; // color already declared as a global in sbar.qc
	vector rgb;
	entity tm;
	float scale2d, normalsize, bigsize;
	float f;
	if (big)
		view_crosshair = 0;
	else if (radar_minimapname == "")
		return;

	radar_loadcvars(big);
	switch (radar_zoommode) {
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
	switch (radar_rotation) {
	case 0:
		radar_angle = view_angles_y - 90;
		break;
	default:
		radar_angle = 90 * radar_rotation;
		break;
	}
	scale2d = radar_vlen_maxnorm2d(radar_picmax - radar_picmin);
	radar_size2d = radar_size;
	radar_origin2d =
			'1 0 0' * (0.5 * radar_size2d_x + radar_position_x * (CVAR(vid_conwidth) - radar_size2d_x))
			+ '0 1 0' * (0.5 * radar_size2d_y + radar_position_y * (CVAR(vid_conheight) - radar_size2d_y));
	radar_extraclip_mins = radar_extraclip_maxs = '0 0 0';
	if (radar_position == '1 0 0') {
		if (radar_nohudhack < 2)
			radar_origin2d_y += 25;
		if (radar_nohudhack < 1)
			radar_extraclip_mins_y -= 25;
	} else if (radar_position == '0 1 0' || radar_position == '1 1 0') {
		if (radar_nohudhack < 2)
			radar_origin2d_y -= 50;
	}
	// pixels per world qu to match the radar_size2d_x range in the longest dimension
	if (radar_rotation == 0) {
		// max-min distance must fit the radar in any rotation
		bigsize = radar_vlen_minnorm2d(radar_size2d) * scale2d / (1.05 * radar_vlen2d(world_max - world_min));
	} else {
		vector c0, c1, c2, c3, span;
		c0 = math_rotate(world_min, radar_angle * MATH_DEG2RAD);
		c1 = math_rotate(world_max, radar_angle * MATH_DEG2RAD);
		c2 = math_rotate('1 0 0' * world_min_x + '0 1 0' * world_max_y, radar_angle * MATH_DEG2RAD);
		c3 = math_rotate('1 0 0' * world_max_x + '0 1 0' * world_min_y, radar_angle * MATH_DEG2RAD);
		span = '0 0 0';
		span_x = max4(c0_x, c1_x, c2_x, c3_x) - min4(c0_x, c1_x, c2_x, c3_x);
		span_y = max4(c0_y, c1_y, c2_y, c3_y) - min4(c0_y, c1_y, c2_y, c3_y);
		// max-min distance must fit the radar in x=x, y=y
		bigsize = min(
				radar_size2d_x * scale2d / (1.05 * span_x),
				radar_size2d_y * scale2d / (1.05 * span_y)
		);
	}
	normalsize = radar_vlen_maxnorm2d(radar_size2d) * scale2d / radar_scale;
	if (bigsize > normalsize)
		normalsize = bigsize;

	radar_size_scale =
			f * bigsize
			+ (1 - f) * normalsize;
	radar_origin3d_in_texcoord = radar_3dcoord_to_texcoord(
			f * (world_min + world_max) * 0.5
			+ (1 - f) * view_origin);
	color1 = player_color(player_localentnum-1);
	rgb = team_rgb(color1);
	drawsetcliparea(
			radar_origin2d_x - radar_size2d_x * 0.5 + radar_extraclip_mins_x,
			radar_origin2d_y - radar_size2d_y * 0.5 + radar_extraclip_mins_y,
			radar_size2d_x + radar_extraclip_maxs_x - radar_extraclip_mins_x,
			radar_size2d_y + radar_extraclip_maxs_y - radar_extraclip_mins_y
			);
	radar_background_draw(radar_background_alpha, radar_foreground_alpha);
	if (big) {
		drawresetcliparea();
		vector frame_origin, frame_size;
		frame_origin = frame_size = '0 0 0';
		frame_origin_x = radar_origin2d_x - radar_size2d_x * 0.55859375;
		frame_origin_y = radar_origin2d_y - radar_size2d_y * 0.55859375;
		frame_size_x = radar_size2d_x * 1.1171875;
		frame_size_y = radar_size2d_y * 1.1171875;
		drawpic(frame_origin, "gfx/ons-frame", frame_size, '1 1 1', sbar_alpha_fg, 0);
		drawpic(frame_origin, "gfx/ons-frame-team", frame_size, rgb, sbar_alpha_fg, 0);
		if (title)
			drawstring(frame_origin - '0 24 0', title, '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);

		drawsetcliparea(
				radar_origin2d_x - radar_size2d_x * 0.5,
				radar_origin2d_y - radar_size2d_y * 0.5,
				radar_size2d_x,
				radar_size2d_y
		);
	}
	for (tm = NULL; (tm = findflags(tm, radar_icon, 0xFFFF)); ) {
		if (tm.classname == "entcs_receiver") {
			if (tm.cnt)
				continue;

			color2 = player_color(tm.sv_entnum);
			//if (color == COLOR_SPECTATOR || color == color2)
			radar_player_draw(tm.origin, tm.angles, team_rgb(color2));
		} else if (tm.radar_icon < 1337)
			radar_icon_draw(tm.origin, tm.radar_icon, tm.radar_color, tm.alpha * sbar_alpha_fg);
		else if (tm.classname == "radarping")
			radar_ping_draw(tm, sbar_alpha_fg);
		else if (tm.classname == "radarlink")
			radar_link_draw(tm.origin, tm.velocity, tm.team);
	}
	radar_player_draw(view_origin, view_angles, '1 1 1');
	drawresetcliparea();
}

void(vector org) radar_ping {
	entity e = spawn();
	e.classname = "radarping";
	e.origin = org;
	e.radar_icon = 1337;
	e.state = time;
}

void(float ignore) radar_link_read {
	float sendflags;
	sendflags = net_read_byte();
	self.classname = "radarlink";
	self.radar_icon = 1337;
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
}
