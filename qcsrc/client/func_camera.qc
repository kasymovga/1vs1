vector(vector org, vector ang) func_camera_transform {
	// a fixed camera view
	trace_endpos = self.oldorigin;
	if (self.cnt & 1) { //portal
		makevectors(self.avelocity);
		vector v = self.origin + (self.mins + self.maxs) * 0.5 - org;
		vector v2 = self.oldorigin - v_forward * v_x + v_right * v_y - v_up * v_z;
		makevectors(self.avelocity + ang);
		return v2;
	}
	makevectors(self.avelocity);
	return self.oldorigin;
}

void(float isnew) func_camera_read {
	self.classname = "func_camera";
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	self.modelindex = ReadShort();
	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	self.scale = ReadByte() / 16;
	self.oldorigin_x = ReadCoord();
	self.oldorigin_y = ReadCoord();
	self.oldorigin_z = ReadCoord();
	self.avelocity_x = ReadCoord();
	self.avelocity_y = ReadCoord();
	self.avelocity_z = ReadCoord();
	self.cnt = ReadByte();
	self.solid = ReadByte();
	// engine currently wants this
	self.drawmask = MASK_NORMAL;
	self.camera_transform = func_camera_transform;
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
}
