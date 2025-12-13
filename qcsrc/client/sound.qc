void(float flags, float isnew) sound_loop_read {
	float f = net_read_byte();
	if (f & 1) {
		self.cnt = net_read_short(); //owner
		self.message = str_zone_ifneeded(net_read_string()); //sound name
		self.armor = net_read_byte(); //channel
		self.atten = net_read_short() / 64;
		self.volume = net_read_short() / 64;
		if (self.message != "")
			sound(self, self.message, self.armor, self.message, self.atten, self.volume);
		else
			sound(self, "null", self.armor, self.message, self.atten, self.volume);
	}
	if (f & 4) {
		self.origin_x = net_read_int24();
		self.origin_y = net_read_int24();
		self.origin_z = net_read_int24();
		setorigin(self, self.origin);
	}
	self.think = sound_loop_think;
}
