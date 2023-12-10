float(entity to, float sendflags) func_camera_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_FUNC_CAMERA);
	// we need THESE to render the warpzone (and cull properly)...
	net_write_coord(MSG_ENTITY, self.origin_x);
	net_write_coord(MSG_ENTITY, self.origin_y);
	net_write_coord(MSG_ENTITY, self.origin_z);
	net_write_short(MSG_ENTITY, self.modelindex);
	net_write_coord(MSG_ENTITY, self.mins_x);
	net_write_coord(MSG_ENTITY, self.mins_y);
	net_write_coord(MSG_ENTITY, self.mins_z);
	net_write_coord(MSG_ENTITY, self.maxs_x);
	net_write_coord(MSG_ENTITY, self.maxs_y);
	net_write_coord(MSG_ENTITY, self.maxs_z);
	net_write_byte(MSG_ENTITY, bound(1, self.scale * 16, 255));
	// we need THESE to calculate the proper transform
	net_write_coord(MSG_ENTITY, self.enemy.origin_x);
	net_write_coord(MSG_ENTITY, self.enemy.origin_y);
	net_write_coord(MSG_ENTITY, self.enemy.origin_z);
	net_write_coord(MSG_ENTITY, self.enemy.mangle_x + self.enemy.angles_x + self.mangle_x);
	net_write_coord(MSG_ENTITY, self.enemy.mangle_y + self.enemy.angles_y + self.mangle_y);
	net_write_coord(MSG_ENTITY, self.enemy.mangle_z + self.enemy.angles_z + self.mangle_z);
	net_write_byte(MSG_ENTITY, self.spawnflags & 255);
	net_write_byte(MSG_ENTITY, self.solid);
	return TRUE;
}

void() func_camera_init {
	if(self.target == "") {
		entity_abort("Camera with no target");
		return;
	}
	self.enemy = find(world, targetname, self.target);
	if(self.enemy == world) {
		entity_abort("Camera with nonexisting target");
		return;
	}
}

vector(vector org, vector ang) func_camera_transform {
	// a fixed camera view
	trace_endpos = self.enemy.origin;
	makevectors(self.enemy.angles + self.enemy.mangle);
	return trace_endpos;
}

void(void) spawnfunc_func_camera {
	if(!self.scale)
		self.scale = self.modelscale;

	if(!self.scale)
		self.scale = 1;

	if(self.model != "") {
		precache_model(self.model);
		setmodel(self, self.model); // no precision needed
	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);

	if(!self.solid)
		self.solid = SOLID_BSP;
	else if(self.solid < 0)
		self.solid = SOLID_NOT;

	self.SendEntity = func_camera_send;
	self.SendFlags = 0xFFFFFF;
	self.camera_transform = func_camera_transform;
	entity_initialize(self, func_camera_init, INITPRIO_FIRST);
	dlc_require(DLC_WARPZONE);
}
