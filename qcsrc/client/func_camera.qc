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
	self.origin_x = net_read_coord();
	self.origin_y = net_read_coord();
	self.origin_z = net_read_coord();
	self.modelindex = net_read_short();
	self.mins_x = net_read_coord();
	self.mins_y = net_read_coord();
	self.mins_z = net_read_coord();
	self.maxs_x = net_read_coord();
	self.maxs_y = net_read_coord();
	self.maxs_z = net_read_coord();
	self.scale = net_read_byte() / 16;
	self.oldorigin_x = net_read_coord();
	self.oldorigin_y = net_read_coord();
	self.oldorigin_z = net_read_coord();
	self.avelocity_x = net_read_coord();
	self.avelocity_y = net_read_coord();
	self.avelocity_z = net_read_coord();
	self.cnt = net_read_byte();
	self.solid = net_read_byte();
	// engine currently wants this
	self.drawmask = MASK_NORMAL;
	self.camera_transform = func_camera_transform;
	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
}
