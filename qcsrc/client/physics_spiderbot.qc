entity spider;
vector spiderbot_start_angles;
vector spider_start_origin;
vector spider_start_velocity;

float physics_spiderbot_hook() {
	entity e = self;
	self = spider;
	physics_spiderbot();
	self = e;
	return 1;
}

void physics_spiderbot_pre() {
	setorigin(spider, spider_start_origin);
	spider.velocity = spider_start_velocity;
	spider.angles = spiderbot_start_angles;
}

void physics_spiderbot_post() {
	physics_vehicle_common_post(spider);
}

void Ent_PhysicSpiderbot_Remove() {
	spider = world;
	physics_plug_pre = physics_plug_nopostpre;
	physics_plug = physics_plug_null;
	physics_plug_post = physics_plug_nopostpre;
	physics_plug_adjust_view = physics_plug_no_adjust_view;
	physics_player_ent = 0;
}

void Ent_PhysicSpiderbot(float isnew)
{
	float f = ReadShort();
	if (isnew) {
		physics_plug = physics_spiderbot_hook;
		physics_plug_pre = physics_spiderbot_pre;
		physics_plug_post = physics_spiderbot_post;
		vehicle_adjust_view_up = SPIDERBOT_VIEW_UP;
		vehicle_adjust_view_back = SPIDERBOT_VIEW_BACK;
		vehicle_adjust_view_start_offs = SPIDERBOT_VIEW_START_OFFSET;
		physics_plug_adjust_view = physics_vehicle_adjust_view;
		self.entremove = Ent_PhysicSpiderbot_Remove;
		spider = self;
		spider.solid = SOLID_BBOX;
		spider.movetype = MOVETYPE_QCWALK;
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
		physics_player_ent = ReadShort();
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
