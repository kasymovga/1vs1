float(entity to, float sendflags) func_camera_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_FUNC_CAMERA);
	// we need THESE to render the warpzone (and cull properly)...
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteCoord(MSG_ENTITY, self.mins_x);
	WriteCoord(MSG_ENTITY, self.mins_y);
	WriteCoord(MSG_ENTITY, self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x);
	WriteCoord(MSG_ENTITY, self.maxs_y);
	WriteCoord(MSG_ENTITY, self.maxs_z);
	WriteByte(MSG_ENTITY, bound(1, self.scale * 16, 255));
	// we need THESE to calculate the proper transform
	WriteCoord(MSG_ENTITY, self.enemy.origin_x);
	WriteCoord(MSG_ENTITY, self.enemy.origin_y);
	WriteCoord(MSG_ENTITY, self.enemy.origin_z);
	WriteCoord(MSG_ENTITY, self.enemy.mangle_x + self.enemy.angles_x + self.mangle_x);
	WriteCoord(MSG_ENTITY, self.enemy.mangle_y + self.enemy.angles_y + self.mangle_y);
	WriteCoord(MSG_ENTITY, self.enemy.mangle_z + self.enemy.angles_z + self.mangle_z);
	WriteByte(MSG_ENTITY, self.spawnflags & 255);
	WriteByte(MSG_ENTITY, self.solid);
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
}
