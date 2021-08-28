void(float bIsNewEntity) entcs_read {
	float f = net_read_byte();
	if (f & 1) {
		self.sv_entnum = net_read_byte() - 1;
		self.shownames_entnum = net_read_short() - 1;
	}
	if (f & 64) {
		if (f & 2) {
			self.origin_x = net_read_short();
			self.origin_y = net_read_short();
		}
		if (f & 4) {
			self.origin_z = net_read_short();
			self.angles_y = net_read_short();
		}
		if (self.cnt)
			self.cnt = FALSE;
	} else {
		if not(self.cnt)
			self.cnt = TRUE;
	}
	if (f & 8) {
		self.maxs_x = self.maxs_y = 0;
		self.maxs_z = net_read_short();
	}
	if (team_mode)
		Shownames_UpdateTeamBubble(self, f & 32);

	if (f & 128) {
		if (f & 16) {
			self.health = net_read_byte();
			self.armorvalue = net_read_byte();
		}
	} else
		self.health = 0;

	self.classname = "entcs_receiver";
	if (bIsNewEntity)
		Shownames_Init(self);
}


