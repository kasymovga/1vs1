vector porto_polyline[16];

void(void) porto_draw {
	vector p, dir, ang, q, nextdir;
	float idx, portal_number, portal1_idx = 0;
	dir = view_forward;
	/*
	if (angles_held_status) {
		makevectors(angles_held);
		dir = v_forward;
	}
	*/
	p = view_origin;
	porto_polyline[0] = p;
	idx = 1;
	portal_number = 0;
	nextdir = dir;
	for (;;) {
		dir = nextdir;
		trace_box(p, self.mins, self.maxs, p + 65536 * dir, TRUE, self);
		if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			return;

		nextdir = dir - 2 * (dir * trace_plane_normal) * trace_plane_normal; // mirror dir at trace_plane_normal
		p = trace_endpos;
		porto_polyline[idx] = p;
		++idx;
		if (idx >= 16)
			return;

		if ((trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK))
			continue;

		++portal_number;
		ang = vectoangles2(trace_plane_normal, dir);
		ang_x = -ang_x;
		makevectors(ang);
		if not(portal_check_wire_frame_box(self, p - 48 * v_right - 48 * v_up + 16 * v_forward, 96 * v_right, 96 * v_up, 96 * v_forward))
			return;

		if (portal_number == 1)
			portal1_idx = idx;

		if (portal_number >= 2)
			break;
	}
	while (idx >= 2) {
		p = porto_polyline[idx-2];
		q = porto_polyline[idx-1];
		if (idx == 2)
			p = p - view_up * 16;
		if (idx-1 >= portal1_idx) {
			draw_cylindric_line(p, q, 4, "", 1, 0, '0 0 1', 0.5, DRAWFLAG_NORMAL, view_camera_origin);
		} else {
			draw_cylindric_line(p, q, 4, "", 1, 0, '1 0 0', 0.5, DRAWFLAG_NORMAL, view_camera_origin);
		}
		--idx;
	}
}

void(float isnew) porto_read {
	self.draw = porto_draw;
}
