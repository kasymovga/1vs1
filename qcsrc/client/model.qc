.float lip;
.float bgmscriptangular;

void(void) model_draw {
	float f;
	vector save;
	var .vector fld;
	interpolate_do();
	if (self.bgmscriptangular)
		fld = angles;
	else
		fld = origin;
	
	save = self.fld;
	f = BGMScript(self);
	if (f >= 0) {
		if (self.lip < 0) // < 0: alpha goes from 1 to 1-|lip| when toggled (toggling subtracts lip)
			self.alpha = 1 + self.lip * f;
		else // > 0: alpha goes from 1-|lip| to 1 when toggled (toggling adds lip)
			self.alpha = 1 - self.lip * (1 - f);

		self.fld = self.fld + self.movedir * f;
	} else
		self.alpha = 1;

	if (self.alpha >= EFFECT_ALPHA_MIN_VISIBLE)
		R_AddEntity(self);

	self.fld = save;
}

void(void) model_remove {
	if (self.bgmscript)
		strunzone(self.bgmscript);

	self.bgmscript = NULL;
}

void(float ignore) model_read {
	float f;
	interpolate_undo();
	self.iflags = IFLAG_ANGLES;
	f = net_read_byte();
	if (f & 1) {
		if (f & 0x40)
			self.colormap = net_read_short();
		else
			self.colormap = 0;
	}
	if (f & 2) {
		self.origin_x = net_read_coord();
		self.origin_y = net_read_coord();
		self.origin_z = net_read_coord();
	}
	if (f & 4) {
		if (f & 0x10) {
			self.angles_x = net_read_angle();
			self.angles_y = net_read_angle();
			self.angles_z = net_read_angle();
		} else
			self.angles = '0 0 0';
	}
	if (f & 8) {
		self.modelindex = net_read_short();
		self.solid = net_read_byte();
		self.scale = net_read_byte() / 16.0;
		if (f & 0x20) {
			self.mins_x = net_read_coord();
			self.mins_y = net_read_coord();
			self.mins_z = net_read_coord();
			self.maxs_x = net_read_coord();
			self.maxs_y = net_read_coord();
			self.maxs_z = net_read_coord();
		} else
			self.mins = self.maxs = '0 0 0';

		if (self.bgmscript)
			strunzone(self.bgmscript);

		self.bgmscript = net_read_string();
		if (substring(self.bgmscript, 0, 1) == "<") {
			self.bgmscript = strzone(substring(self.bgmscript, 1, -1));
			self.bgmscriptangular = 1;
		} else {
			self.bgmscript = strzone(self.bgmscript);
			self.bgmscriptangular = 0;
		}
		if (self.bgmscript != "") {
			self.bgmscriptattack = net_read_byte() / 64.0;
			self.bgmscriptdecay = net_read_byte() / 64.0;
			self.bgmscriptsustain = net_read_byte() / 255.0;
			self.bgmscriptrelease = net_read_byte() / 64.0;
			self.movedir_x = net_read_coord();
			self.movedir_y = net_read_coord();
			self.movedir_z = net_read_coord();
			self.lip = net_read_byte() / 255.0;
		}
		BGMScript_InitEntity(self);
	}
	interpolate_note();
	setorigin(self, self.origin);
	self.entremove = model_remove;
	self.draw = model_draw;
}
