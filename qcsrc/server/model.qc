.float modelscale;
float(entity to, float sf) model_client_send;
.string lodtarget1;
.string lodtarget2;
.string lodmodel1;
.string lodmodel2;
.float loddistance1;
.float loddistance2;

float(void) model_lod_customize {
	float d;
	// TODO csqc network this so it only gets sent once
	d = vlen(entity_nearest_point_on_box(self, other.origin) - other.origin);
	if (d < self.loddistance1)
		self.modelindex = self.modelindex_lod0;
	else if (!self.modelindex_lod2 || d < self.loddistance2)
		self.modelindex = self.modelindex_lod1;
	else
		self.modelindex = self.modelindex_lod2;

	return TRUE;
}

void(void) model_lod_attach {
	entity e;
	if (!self.loddistance1)
		self.loddistance1 = 1000;

	if (!self.loddistance2)
		self.loddistance2 = 2000;

	self.modelindex_lod0 = self.modelindex;
	if (self.lodtarget1 != "") {
		e = find(world, targetname, self.lodtarget1);
		if (e) {
			self.lodmodel1 = e.model;
			remove(e);
		}
	}
	if (self.lodtarget2 != "") {
		e = find(world, targetname, self.lodtarget2);
		if (e) {
			self.lodmodel2 = e.model;
			remove(e);
		}
	}
	if (cvar("loddebug") < 0) {
		self.lodmodel1 = self.lodmodel2 = ""; // don't even initialize
	}
	if (self.lodmodel1 != "") {
		vector mi, ma;
		mi = self.mins;
		ma = self.maxs;
		precache_model(self.lodmodel1);
		setmodel(self, self.lodmodel1);
		self.modelindex_lod1 = self.modelindex;
		if (self.lodmodel2 != "") {
			precache_model(self.lodmodel2);
			setmodel(self, self.lodmodel2);
			self.modelindex_lod2 = self.modelindex;
		}
		self.modelindex = self.modelindex_lod0;
		setsize(self, mi, ma);
	}
	if (self.modelindex_lod1)
		self.customizeentityforclient = model_lod_customize;
}

void(void) model_setup {
	if (self.model != "") {
		precache_model(self.model);
		setmodel(self, self.model); // no precision needed
		entity_initialize(self, model_lod_attach, INITPRIO_FINDTARGET);
	}
	setorigin(self, self.origin);
	if (self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
}

void(void) model_setup_no_lod {
	if (self.model != "") {
		precache_model(self.model);
		setmodel(self, self.model); // no precision needed
	}
	setorigin(self, self.origin);
	if (self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
}


void(void) model_setcolormaptoactivator {
	if (team_mode) {
		if (activator.team)
			self.colormap = (activator.team - 1) * 0x11;
		else
			self.colormap = 0x00;
	} else
		self.colormap = floor(random() * 256);

	self.colormap |= 1024; // RENDER_COLORMAPPED
	if (self.SendEntity == model_client_send)
		self.SendFlags |= 1;

	BITXOR_ASSIGN(self.effects, EFFECT_TELEPORT_BIT);
}

void(void) model_dropbyspawnflags {
	if ((self.spawnflags & 3) == 1) { // ALIGN_ORIGIN
		trace_line(self.origin, self.origin - '0 0 4096', TRACE_MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos);
	} else if ((self.spawnflags & 3) == 2) { // ALIGN_BOTTOM
		trace_box(self.origin, self.mins, self.maxs, self.origin - '0 0 4096', TRACE_MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos);
	} else if ((self.spawnflags & 3) == 3) { // ALIGN_ORIGIN | ALIGN_BOTTOM
		trace_line(self.origin, self.origin - '0 0 4096', TRACE_MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos - '0 0 1' * self.mins_z);
	}
	if (self.SendEntity == model_client_send)
		self.SendFlags |= 2;
}

float(entity to, float sf) model_client_send {
	sf = sf & 0x0F;
	if (self.angles != '0 0 0')
		sf |= 0x10;
	if (self.solid && (self.mins != '0 0 0' || self.maxs != '0 0 0'))
		sf |= 0x20;
	if (self.colormap != 0)
		sf |= 0x40;
	
	net_write_byte(MSG_ENTITY, NET_CSQC_MODEL);
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		if (sf & 0x40)
			net_write_short(MSG_ENTITY, self.colormap);
	}
	if (sf & 2) {
		net_write_coord(MSG_ENTITY, self.origin_x);
		net_write_coord(MSG_ENTITY, self.origin_y);
		net_write_coord(MSG_ENTITY, self.origin_z);
	}
	if (sf & 4) {
		if (sf & 0x10) {
			net_write_angle(MSG_ENTITY, self.angles_x);
			net_write_angle(MSG_ENTITY, self.angles_y);
			net_write_angle(MSG_ENTITY, self.angles_z);
		}
	}
	if (sf & 8) {
		net_write_short(MSG_ENTITY, self.modelindex);
		net_write_byte(MSG_ENTITY, self.solid);
		net_write_coord(MSG_ENTITY, self.alpha);
		net_write_coord(MSG_ENTITY, self.scale);
		if (sf & 0x20) {
			net_write_coord(MSG_ENTITY, self.mins_x);
			net_write_coord(MSG_ENTITY, self.mins_y);
			net_write_coord(MSG_ENTITY, self.mins_z);
			net_write_coord(MSG_ENTITY, self.maxs_x);
			net_write_coord(MSG_ENTITY, self.maxs_y);
			net_write_coord(MSG_ENTITY, self.maxs_z);
		}
		net_write_string(MSG_ENTITY, self.bgmscript);
		if (self.bgmscript != "") {
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptattack * 64));
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptdecay * 64));
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptsustain * 255));
			net_write_byte(MSG_ENTITY, floor(self.bgmscriptrelease * 64));
			net_write_coord(MSG_ENTITY, self.movedir_x);
			net_write_coord(MSG_ENTITY, self.movedir_y);
			net_write_coord(MSG_ENTITY, self.movedir_z);
			net_write_byte(MSG_ENTITY, floor(self.lip * 255));
		}
	}
	return TRUE;
}

void(void) model_think {
	entity e = self.enemy;
	if (e.flags & FL_ONGROUND) {
		float z_save = e.velocity_z;
		e.velocity = e.velocity - e.velocity * frametime * e.friction;
		e.velocity_z = z_save;
	}
	if (e.SendEntity == model_client_send)
	if (e.origin != e.pos1) {
		e.pos1 = e.origin;
		e.SendFlags |= 2;
	}
	self.nextthink = time;
}

void(void) model_reset {
	setorigin(self.enemy, self.spawnorigin);
	self.enemy.velocity = '0 0 0';
}

void(void) model_movable_init {
	if (self.pushfactor > 0) {
		self.damageforcescale = self.pushfactor;
		self.takedamage = DAMAGE_AIM;
		self.touch = push_touch;
		entity e = spawn();
		e.enemy = self;
		e.think = model_think;
		e.nextthink = time;
		e.pos1 = self.origin;
		e.spawnorigin = self.origin;
		e.reset = model_reset;
	}
}

void(void) model_init_common_delayed {
	model_dropbyspawnflags();
	model_movable_init();
	if (self.movetype == MOVETYPE_NONE)
		self.culltracemode = CULLTRACEMODE_NONE;
}

void(float sol) model_init_common {
	self.use = model_setcolormaptoactivator;
	entity_initialize(self, model_init_common_delayed, INITPRIO_DROPTOFLOOR);
	if (!self.solid) self.solid = (sol); else if (self.solid < 0) self.solid = SOLID_NOT;
}

void model_init(float sol) {
	if (!self.scale) self.scale = self.modelscale;
	model_setup();
	model_init_common(sol);
}

void model_client_init(float sol) {
	if (!self.scale) self.scale = self.modelscale;
	model_setup_no_lod();
	model_init_common(sol);
	if (!self.bgmscriptsustain) self.bgmscriptsustain = 1; else if (self.bgmscriptsustain < 0) self.bgmscriptsustain = 0;
	net_link_entity(self, TRUE, 0, model_client_send);
}
