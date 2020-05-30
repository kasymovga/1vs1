void(float bIsNewEntity) entcs_read {
	float f = ReadByte();
	if (f & 1) {
		self.sv_entnum = ReadByte() - 1;
		self.shownames_entnum = ReadShort() - 1;
	}
	if (f & 64) {
		if (f & 2) {
			self.origin_x = ReadShort();
			self.origin_y = ReadShort();
		}
		if (f & 4) {
			self.origin_z = ReadShort();
			self.angles_y = ReadShort();
		}
		if (self.cnt)
			self.cnt = FALSE;
	} else {
		if not(self.cnt)
			self.cnt = TRUE;
	}
	if (f & 8) {
		self.maxs_x = self.maxs_y = 0;
		self.maxs_z = ReadShort();
	}
	if (team_mode)
		Shownames_UpdateTeamBubble(self, f & 32);

	if (f & 128) {
		if (f & 16) {
			self.health = ReadByte();
			self.armorvalue = ReadByte();
		}
	} else
		self.health = 0;

	self.classname = "entcs_receiver";
	if (bIsNewEntity)
		Shownames_Init(self);
}


