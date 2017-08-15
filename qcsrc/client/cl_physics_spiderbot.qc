entity spider;
vector spiderbot_start_angles;
vector spider_start_origin;
vector spider_start_velocity;

float physic_spiderbot_hook() {
	entity e = self;
	self = spider;
	float physic_movetype_save = physic_movetype;
	physic_movetype = MOVETYPE_WALK;
	tracebox(self.origin, self.mins, self.maxs, self.origin + normalize(self.velocity) - '0 0 0.125', MOVE_NORMAL, self);
	if (trace_startsolid || (trace_fraction <= 1 && trace_plane_normal_z > 0.7))
		self.flags = FL_ONGROUND;
	else
		self.flags = 0;

	physic_spiderbot();
	self.velocity_z = self.velocity_z - sv_gravity * frametime;
	physic_velocity = self.velocity;
	PM_ClientMovement_Move();
	self.velocity = physic_velocity;
	physic_movetype = physic_movetype_save;
	self = e;
	return 1;
}

void physic_spiderbot_pre() {
	setorigin(spider, spider_start_origin);
	spider.velocity = spider_start_velocity;
	spider.angles = spiderbot_start_angles;
}

void physic_spiderbot_post() {
	//physic_velocity = self.velocity;
	setorigin(self, spider.origin + '0 0 48');
	physic_flags = self.flags;
}

void Ent_PhysicSpiderbot_Remove() {
	spider = world;
	physic_plug_pre = physic_plug_nopostpre;
	physic_plug = physic_plug_null;
	physic_plug_post = physic_plug_nopostpre;
}

void Ent_PhysicSpiderbot(float isnew)
{
	float f = ReadShort();
	if (isnew) {
		physic_plug = physic_spiderbot_hook;
		physic_plug_pre = physic_spiderbot_pre;
		physic_plug_post = physic_spiderbot_post;
		self.entremove = Ent_PhysicSpiderbot_Remove;
		spider = self;
		spider.solid = SOLID_BBOX;
		spider.movetype = MOVETYPE_WALK;
		setsize(spider, spiderbot_MIN, spiderbot_MAX);
	}
	if (f & 1)
	{
		g_vehicle_spiderbot_jump_accel = ReadCoord();
		g_vehicle_spiderbot_jump_up = ReadCoord();
		g_vehicle_spiderbot_speed_stop = ReadCoord();
		g_vehicle_spiderbot_speed_strafe = ReadCoord();
		g_vehicle_spiderbot_speed_walk = ReadCoord();
		g_vehicle_spiderbot_turnspeed = ReadCoord();
		g_vehicle_spiderbot_movement_inertia = ReadCoord();
	}
	if (f & 2)
	{
		spiderbot_start_angles_x = ReadCoord();
		spiderbot_start_angles_y = ReadCoord();
		spiderbot_start_angles_z = ReadCoord();
		spider_start_origin_x = ReadCoord();
		spider_start_origin_y = ReadCoord();
		spider_start_origin_z = ReadCoord();
		spider_start_velocity_x = ReadCoord();
		spider_start_velocity_y = ReadCoord();
		spider_start_velocity_z = ReadCoord();
	}
}
