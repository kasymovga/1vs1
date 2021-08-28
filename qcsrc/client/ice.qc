void(void) ice_draw {
	if not(CVAR(chase_active)) {
		setorigin(self, self.iorigin1 + physics_end_origin);
		R_AddEntity(self);
	}
}

void(float isnew) ice_read {
	float f = net_read_byte();
	if (isnew) {
		self.draw = ice_draw;
		self.effects = 32768 | EFFECT_FULLBRIGHT; //EFFECT_DOUBLESIDED;
	}
	if (f & 1) {
		self.modelindex = net_read_short();
		self.colormod_x = net_read_byte() / 255;
		self.colormod_y = net_read_byte() / 255;
		self.colormod_z = net_read_byte() / 255;
		self.scale = net_read_coord();
		self.iorigin1_x = net_read_coord();
		self.iorigin1_y = net_read_coord();
		self.iorigin1_z = net_read_coord();
		self.skin = net_read_byte();
	}
	if (f & 2)
		self.alpha = net_read_byte() / 255;
}

