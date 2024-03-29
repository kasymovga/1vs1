// a laser goes from origin in direction angles
// it has color 'colormod'
// and stops when something is in the way
.float cnt; // end effect
.float state; // on-off
.float count; // flags for the laser
.vector velocity;
.float alpha;
.float scale; // scaling factor of the thickness
.float modelscale; // scaling factor of the dlight

void(void) laser_draw {
	if (!self.state)
		return;

	interpolate_do();
	if (self.count & 0x80) {
		traceline(self.origin, self.velocity, 0, self);
	} else {
		makevectors(self.angles);
		traceline(self.origin, self.origin + v_forward * 32768, 0, self);
		if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
			trace_endpos = self.origin + v_forward * 1048576;
	}
	if (self.scale != 0) {
		if (self.alpha) {
			draw_cylindric_line(self.origin, trace_endpos, self.scale, "particles/laserbeam", 0, time * 3, self.colormod, self.alpha, DRAWFLAG_NORMAL, view_origin); // TODO make a texture to make the laser look smoother
		} else {
			draw_cylindric_line(self.origin, trace_endpos, self.scale, "particles/laserbeam", 0, time * 3, self.colormod, 0.5, DRAWFLAG_ADDITIVE, view_origin); // TODO make a texture to make the laser look smoother
		}
	}
	if not(trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOIMPACT)) {
		if (self.cnt >= 0)
			pointparticles(self.cnt, trace_endpos, trace_plane_normal, view_drawframetime * 1000);
		if (self.colormod != '0 0 0' && self.modelscale != 0)
			R_AddDynamicLight(trace_endpos + trace_plane_normal * 1, self.modelscale, self.colormod * 5);
	}
}

void(float ignore) laser_read {
	float f;
	interpolate_undo();
	// 30 bytes, or 13 bytes for just moving
	f = net_read_byte();
	self.count = (f & 0xE0);
	if (self.count & 0x80)
		self.iflags = IFLAG_VELOCITY;
	else
		self.iflags = IFLAG_ANGLES;

	if (f & 1) {
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
	}
	if (f & 8) {
		self.colormod_x = net_read_byte() / 255.0;
		self.colormod_y = net_read_byte() / 255.0;
		self.colormod_z = net_read_byte() / 255.0;
		if (f & 0x40)
			self.alpha = net_read_byte() / 255.0;
		else
			self.alpha = 0;

		self.scale = 2;
		self.modelscale = 50;
		if (f & 0x20) {
			self.scale *= net_read_byte() / 16.0; // beam radius
			self.modelscale *= net_read_byte() / 16.0; // dlight radius
		}
		self.cnt = net_read_short() - 1; // effect number
	}
	if (f & 2) {
		if (f & 0x80) {
			self.velocity_x = net_read_coord();
			self.velocity_y = net_read_coord();
			self.velocity_z = net_read_coord();
		} else {
			self.angles_x = net_read_angle();
			self.angles_y = net_read_angle();
		}
	}
	if (f & 4)
		self.state = net_read_byte();

	interpolate_note();
	self.draw = laser_draw;
}
