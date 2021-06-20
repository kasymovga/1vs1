float(float fadelerp) draw_expandingbox_sizefactor_from_fadelerp {
	return 1.2 / (1.2 - fadelerp);
}

vector(float sz, vector boxsize, float boxxsizefactor) draw_expandingbox_resize_centered_box_offset {
	boxsize_x *= boxxsizefactor; // easier interface for text
	return boxsize * (0.5 * (1 - sz));
}

void(float thickness, vector pos, vector dim, vector color, float alpha, float drawflag) draw_borderlines {
	vector line_dim;
	// left and right lines
	pos_x -= thickness;
	line_dim_x = thickness;
	line_dim_y = dim_y;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_x + thickness) * '1 0 0', line_dim, color, alpha, drawflag);
	// upper and lower lines
	pos_y -= thickness;
	line_dim_x = dim_x + thickness * 2; // make upper and lower lines longer
	line_dim_y = thickness;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_y + thickness) * '0 1 0', line_dim, color, alpha, drawflag);
}

void(vector pos, string pic, vector sz, vector area, vector color, float alpha, float drawflag) draw_pic_tiled {
	vector current_pos, end_pos, new_size, ratio;
	end_pos = pos + area;
	current_pos_y = pos_y;
	if (sz_x == 0 || sz_y == 0) {
		backtrace("draw_pic_tiled: empty image\n");
		return;
	}
	while (current_pos_y < end_pos_y) {
		current_pos_x = pos_x;
		while (current_pos_x < end_pos_x) {
			new_size_x = min(sz_x, end_pos_x - current_pos_x);
			new_size_y = min(sz_y, end_pos_y - current_pos_y);
			ratio_x = new_size_x / sz_x;
			ratio_y = new_size_y / sz_y;
			drawsubpic(current_pos, new_size, pic, '0 0 0', ratio, color, alpha, drawflag);
			current_pos_x += sz_x;
		}
		current_pos_y += sz_y;
	}
}

void(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp) draw_pic_expanding {
	float sz;
	sz = draw_expandingbox_sizefactor_from_fadelerp(fadelerp);
	drawpic(position + draw_expandingbox_resize_centered_box_offset(sz, scale, 1), pic, scale * sz, rgb, alpha * (1 - fadelerp), flag);
}

void(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp) draw_pic_expanding_two {
	draw_pic_expanding(position, pic, scale, rgb, alpha, flag, fadelerp);
	drawpic(position, pic, scale, rgb, alpha * fadelerp, flag);
}

void(vector position, string text, vector scale, vector rgb, float alpha, float flag, float fadelerp) draw_string_expanding {
	float sz;
	sz = draw_expandingbox_sizefactor_from_fadelerp(fadelerp);
	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
	drawstring(position + draw_expandingbox_resize_centered_box_offset(sz, scale, stringwidth(text, FALSE)), text, scale * sz, rgb, alpha * (1 - fadelerp), flag);
}

void(vector from, vector to, float thickness, string texture, float aspect, float shift, vector rgb, float alpha, float drawflag, vector view_org) draw_cylindric_line {
	// I want to draw a quad...
	// from and to are MIDPOINTS.
	vector axis, thickdir, A, B, C, D;
	float length_tex;
	axis = normalize(to - from);
	length_tex = aspect * vlen(to - from) / thickness;
	// direction is perpendicular to the view normal, and perpendicular to the axis
	thickdir = normalize(math_cross(axis, view_org - from));
	A = from - thickdir * (thickness / 2);
	B = from + thickdir * (thickness / 2);
	C = to + thickdir * (thickness / 2);
	D = to - thickdir * (thickness / 2);
	R_BeginPolygon(texture, drawflag);
	R_PolygonVertex(A, '0 0 0' + shift * '1 0 0', rgb, alpha);
	R_PolygonVertex(B, '0 1 0' + shift * '1 0 0', rgb, alpha);
	R_PolygonVertex(C, '0 1 0' + (shift + length_tex) * '1 0 0', rgb, alpha);
	R_PolygonVertex(D, '0 0 0' + (shift + length_tex) * '1 0 0', rgb, alpha);
	R_EndPolygon();
}

void(vector position, string text, vector scale, vector rgb, float alpha, float flag) draw_string_right {
	position_x -= stringwidth(text, FALSE) * scale_x;
	drawstring(position, text, scale, rgb, alpha, flag);
}

void(vector position, string text, vector scale, vector rgb, float alpha, float flag) draw_string_center {
	position_x =  position_x + 0.5 * (CVAR(vid_conwidth) - stringwidth(text, FALSE) * scale_x);
	drawstring(position, text, scale, rgb, alpha, flag);
}

void(vector position, string text, vector scale, float alpha, float flag) draw_string_colorcoded_center {
	position_x = position_x + 0.5 * (CVAR(vid_conwidth) - stringwidth(text, TRUE) * scale_x);
	drawcolorcodedstring(position, text, scale, alpha, flag);
}

void(vector cpos, vector l_size, float progress, float alpha, vector l_color, float fragments) draw_progress_fragmented {
	vector pos;
	pos_x = cpos_x - l_size_x / 2;
	pos_y = cpos_y - l_size_y / 2;
	vector fill = l_size;
	fill_x *= progress;
	drawfill(pos, fill, l_color, alpha * 0.7, DRAWFLAG_NORMAL);
	if (fragments < 2) {
		draw_borderlines(1, pos, l_size, l_color, alpha, DRAWFLAG_NORMAL);
	} else {
		vector fragsize;
		fragsize_x = l_size_x / fragments;
		fragsize_y = l_size_y;
		fragsize_z = 0;
		float frag;
		for (frag = 0; frag < fragments; ++frag) {
			draw_borderlines(1, pos + fragsize_x * frag * '1 0 0', fragsize, l_color, alpha, DRAWFLAG_NORMAL);
		}
	}
}

void draw_quad(vector o, vector ri, vector up, string pic, vector rgb, float a, float f) {
	R_BeginPolygon(pic, f);
	R_PolygonVertex(o, '0 0 0', rgb, a);
	R_PolygonVertex(o + ri, '1 0 0', rgb, a);
	R_PolygonVertex(o + up + ri, '1 1 0', rgb, a);
	R_PolygonVertex(o + up, '0 1 0', rgb, a);
	R_EndPolygon();
}

void (vector org, float rot, string pic, vector sz, vector hotspot, vector rgb, float a, float f) draw_picture_rotate {
	vector v1, v2, v3, v4;
	hotspot = -1 * hotspot;
	// hotspot-relative coordinates of the corners
	v1 = hotspot;
	v2 = hotspot + '1 0 0' * sz_x;
	v3 = hotspot + '1 0 0' * sz_x + '0 1 0' * sz_y;
	v4 = hotspot                  + '0 1 0' * sz_y;
	// rotate them, and make them absolute
	rot = -rot; // rotate by the opposite angle, as our coordinate system is reversed
	v1 = math_rotate(v1, rot) + org;
	v2 = math_rotate(v2, rot) + org;
	v3 = math_rotate(v3, rot) + org;
	v4 = math_rotate(v4, rot) + org;
	// draw them
	R_BeginPolygon(pic, f);
	R_PolygonVertex(v1, '0 0 0', rgb, a);
	R_PolygonVertex(v2, '1 0 0', rgb, a);
	R_PolygonVertex(v3, '1 1 0', rgb, a);
	R_PolygonVertex(v4, '0 1 0', rgb, a);
	R_EndPolygon();
}

void(string s, float type) draw_search_and_precache {
	float i;
	string pic;
	float glob = search_begin(s, TRUE, TRUE);
	if (glob < 0)
		return;

	for(i = 0; i < search_getsize(glob); ++i) {
		pic = search_getfilename(glob, i);
		pic = substring(pic, 0, strstrofs(pic, ".tga", 0));
		pic = substring(pic, 0, strstrofs(pic, ".jpg", 0));
		pic = substring(pic, 0, strstrofs(pic, ".png", 0));
		//print("Precaching ", pic, "\n");
		if (type == 1) //just image
			precache_pic(pic);
		else if (type == 2) //3d texture
			draw_cylindric_line('1 1 1', '2 2 2', 1, pic, 1, 1, '1 1 1', 1, DRAWFLAG_ADDITIVE, view_camera_origin);
		else if (type == 3) //sprite
			draw_picture_rotate('1 1 0', 1, pic, '1 1 0', '0.5 0.5 0', '1 1 1', 1, DRAWFLAG_MIPMAP);
	}
	search_end(glob);
}

void(void) draw_init_draw {
	draw_search_and_precache("gfx/num_*", 1);
	draw_search_and_precache("gfx/inv_*", 1);
	draw_search_and_precache("gfx/crosshair*", 1);
	draw_search_and_precache("gfx/sb_*", 1);
	draw_search_and_precache("gfx/hud/*.tga", 1);
	draw_search_and_precache("gfx/hud/keys/*.tga", 1);
	draw_search_and_precache("gfx/teamradar_*.tga", 1);
	draw_search_and_precache("particles/*.tga", 2);
	draw_search_and_precache("models/sprites/*_frame*", 3);
	float dummy = particleeffectnum("nex_muzzleflash");
	remove(self);
}

void(void) draw_init {
	entity e = spawn();
	e.draw2dflag = 1;
	e.draw2d = draw_init_draw;
}
