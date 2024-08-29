void(void) lms_sphere_draw {
	R_AddEntity(self);
}

void(float isnew) lms_sphere_read {
	float f = net_read_byte();
	if (isnew)
		self.draw = lms_sphere_draw;

	if (f & 1) {
		self.modelindex = net_read_short();
		self.cnt = net_read_coord();
		self.radar_icon = 1337;
		self.classname = "lms_sphere";
	}
	if (f & 2)
		self.scale = net_read_coord();

	if (f & 4) {
		self.colormod_x = net_read_byte() / 255;
		self.colormod_y = net_read_byte() / 255;
		self.colormod_z = net_read_byte() / 255;
	}
	if (f & 8)
		self.alpha = net_read_byte() / 255;

	if (f & 16) {
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
		setorigin(self, self.origin);
	}
	if (f & 32) {
		self.angles_x = net_read_coord();
		self.angles_y = net_read_coord();
		self.angles_z = net_read_coord();
	}
}
