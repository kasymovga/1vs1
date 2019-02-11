.float modelscale;

void g_model_setcolormaptoactivator (void)
{
	if(teamplay)
	{
		if(activator.team)
			self.colormap = (activator.team - 1) * 0x11;
		else
			self.colormap = 0x00;
	}
	else
		self.colormap = floor(random() * 256);
	self.colormap |= 1024; // RENDER_COLORMAPPED
}

void g_clientmodel_setcolormaptoactivator (void)
{
	g_model_setcolormaptoactivator();
	self.SendFlags |= 1;
}

void g_model_dropbyspawnflags()
{
	if(self.spawnflags & 3 == 1) // ALIGN_ORIGIN
	{
		traceline(self.origin, self.origin - '0 0 4096', MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos);
	}
	else if(self.spawnflags & 3 == 2) // ALIGN_BOTTOM
	{
		tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 4096', MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos);
	}
	else if(self.spawnflags & 3 == 3) // ALIGN_ORIGIN | ALIGN_BOTTOM
	{
		traceline(self.origin, self.origin - '0 0 4096', MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos - '0 0 1' * self.mins_z);
	}
}

void g_clientmodel_dropbyspawnflags()
{
	vector o0;
	o0 = self.origin;
	g_model_dropbyspawnflags();
	if(self.origin != o0)
		self.SendFlags |= 2;
}

float g_clientmodel_genericsendentity (entity to, float sf)
{
	sf = sf & 0x0F;
	if(self.angles != '0 0 0')
		sf |= 0x10;
	if(self.solid && (self.mins != '0 0 0' || self.maxs != '0 0 0'))
		sf |= 0x20;
	if(self.colormap != 0)
		sf |= 0x40;
	
	WriteByte(MSG_ENTITY, ENT_CLIENT_WALL);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		if(sf & 0x40)
			WriteShort(MSG_ENTITY, self.colormap);
	}

	if(sf & 2)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}

	if(sf & 4)
	{
		if(sf & 0x10)
		{
			WriteAngle(MSG_ENTITY, self.angles_x);
			WriteAngle(MSG_ENTITY, self.angles_y);
			WriteAngle(MSG_ENTITY, self.angles_z);
		}
	}

	if(sf & 8)
	{
		WriteShort(MSG_ENTITY, self.modelindex);
		WriteByte(MSG_ENTITY, self.solid);
		WriteByte(MSG_ENTITY, floor(self.scale * 16));
		if(sf & 0x20)
		{
			WriteCoord(MSG_ENTITY, self.mins_x);
			WriteCoord(MSG_ENTITY, self.mins_y);
			WriteCoord(MSG_ENTITY, self.mins_z);
			WriteCoord(MSG_ENTITY, self.maxs_x);
			WriteCoord(MSG_ENTITY, self.maxs_y);
			WriteCoord(MSG_ENTITY, self.maxs_z);
		}
		WriteString(MSG_ENTITY, self.bgmscript);
		if(self.bgmscript != "")
		{
			WriteByte(MSG_ENTITY, floor(self.bgmscriptattack * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptdecay * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptsustain * 255));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptrelease * 64));
			WriteCoord(MSG_ENTITY, self.movedir_x);
			WriteCoord(MSG_ENTITY, self.movedir_y);
			WriteCoord(MSG_ENTITY, self.movedir_z);
			WriteByte(MSG_ENTITY, floor(self.lip * 255));
		}
	}

	return TRUE;
}

void model_think() {
	entity e = self.enemy;
	if (e.flags & FL_ONGROUND) {
		float z_save = e.velocity_z;
		e.velocity = e.velocity - e.velocity * frametime * e.friction;
		e.velocity_z = z_save;
	}
	if (e.SendEntity == g_clientmodel_genericsendentity)
	if (e.origin != e.pos1) {
		e.pos1 = e.origin;
		e.SendFlags |= 2;
	}
	self.nextthink = time;
}

void model_reset() {
	setorigin(self.enemy, self.spawnorigin);
	self.enemy.velocity = '0 0 0';
}

void model_movable_init() {
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

void model_init_common_delayed() {
	g_model_dropbyspawnflags();
	model_movable_init();
}

void model_init_common(float sol) {
	if(!self.scale) self.scale = self.modelscale;
	self.use = g_model_setcolormaptoactivator;
	InitializeEntity(self, model_init_common_delayed, INITPRIO_DROPTOFLOOR);
	if(!self.solid) self.solid = (sol); else if(self.solid < 0) self.solid = SOLID_NOT;
}

void model_init(float sol) {
	SetBrushEntityModel();
	model_init_common(sol);
}

void clientmodel_init(float sol) {
	SetBrushEntityModelNoLOD();
	model_init_common(sol);
	if(!self.bgmscriptsustain) self.bgmscriptsustain = 1; else if(self.bgmscriptsustain < 0) self.bgmscriptsustain = 0;
	Net_LinkEntity(self, TRUE, 0, g_clientmodel_genericsendentity);
}

// non-solid model entities:
void spawnfunc_misc_gamemodel()         { model_init      (SOLID_NOT);} // model entity
void spawnfunc_misc_clientmodel()       { clientmodel_init(SOLID_NOT);} // model entity
void spawnfunc_misc_models()            { model_init      (SOLID_NOT);} // DEPRECATED old compat entity with confusing name, do not use

// non-solid brush entities:
void spawnfunc_func_illusionary()       { model_init      (SOLID_NOT);} // Q1 name (WARNING: MISPREDICTED)
void spawnfunc_func_clientillusionary() { clientmodel_init(SOLID_NOT);} // brush entity
void spawnfunc_func_static()            { model_init      (SOLID_NOT);} // DEPRECATED old alias name from some other game

// solid brush entities
void spawnfunc_func_wall()              { model_init      (SOLID_BSP);} // Q1 name
void spawnfunc_func_clientwall()        { clientmodel_init(SOLID_BSP);} // brush entity (WARNING: MISPREDICTED)
