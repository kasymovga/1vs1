void(void) sphere_draw {
	R_AddEntity(self);
}

void(float isnew) sphere_read {
	float f = ReadByte();
	if (isnew)
		self.draw = sphere_draw;

	if (f & 1) {
		self.modelindex = ReadShort();
	}
	if (f & 2)
		self.scale = ReadCoord();

	if (f & 4) {
		self.colormod_x = ReadByte() / 255;
		self.colormod_y = ReadByte() / 255;
		self.colormod_z = ReadByte() / 255;
	}
	if (f & 8)
		self.alpha = ReadByte() / 255;

	if (f & 16) {
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
	}
	if (f & 32) {
		self.angles_x = ReadCoord();
		self.angles_y = ReadCoord();
		self.angles_z = ReadCoord();
	}
}
