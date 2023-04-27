vector(vector org, vector ang) portal_transform {
	trace_endpos = self.oldorigin;
	makevectors(self.angles);
	vector v = self.origin + v_forward * 4 - org;
	vector v2 = self.oldorigin - anglestransform_apply(self.view_ofs, v);
	makevectors(anglestransform_multiply(self.view_ofs, ang));
	return v2;
}

void(float isnew) portal_read {
	if (!cvar("r_water"))
		cvar_clientsettemp("r_water", "1");

	self.classname = "portal";
	self.modelindex = net_read_short();
	self.skin = net_read_short();
	self.effects = net_read_coord();
	self.origin_x = net_read_coord();
	self.origin_y = net_read_coord();
	self.origin_z = net_read_coord();
	self.angles_x = net_read_coord();
	self.angles_y = net_read_coord();
	self.angles_z = net_read_coord();
	if (net_read_byte()) {
		self.oldorigin_x = net_read_coord();
		self.oldorigin_y = net_read_coord();
		self.oldorigin_z = net_read_coord();
		self.view_ofs_x = net_read_coord();
		self.view_ofs_y = net_read_coord();
		self.view_ofs_z = net_read_coord();
		self.camera_transform = portal_transform;
	} else {
		self.camera_transform = NULL;
	}
	// engine currently wants this
	self.drawmask = MASK_NORMAL;
	setorigin(self, self.origin);
	setsize(self, '0 0 0', '0 0 0');
}
