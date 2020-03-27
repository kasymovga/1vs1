void(void) ice_draw {
	if not(CVAR(chase_active)) {
		setorigin(self, self.iorigin1 + physics_end_origin);
		R_AddEntity(self);
	}
}

void(float isnew) ice_read {
	float f = ReadByte();
	if (isnew) {
		self.draw = ice_draw;
		self.effects = 32768 | EF_FULLBRIGHT; //EF_DOUBLESIDED;
	}
	if (f & 1) {
		self.modelindex = ReadShort();
		self.colormod_x = ReadByte() / 255;
		self.colormod_y = ReadByte() / 255;
		self.colormod_z = ReadByte() / 255;
		self.scale = ReadCoord();
		self.iorigin1_x = ReadCoord();
		self.iorigin1_y = ReadCoord();
		self.iorigin1_z = ReadCoord();
		self.skin = ReadByte();
	}
	if (f & 2)
		self.alpha = ReadByte() / 255;
}

