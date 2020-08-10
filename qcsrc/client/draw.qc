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
