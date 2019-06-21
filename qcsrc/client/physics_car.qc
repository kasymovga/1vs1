entity mycar;
vector car_start_angles;
vector car_start_origin;
vector car_start_velocity;

float physics_car_hook() {
	entity e = self;
	self = mycar;
	float physics_movetype_save = physics_movetype;
	physics_movetype = MOVETYPE_WALK;
	tracebox(self.origin, self.mins, self.maxs, self.origin + normalize(self.velocity) - '0 0 0.125', MOVE_NORMAL, self);
	if (trace_startsolid || (trace_fraction <= 1 && trace_plane_normal_z > 0.7))
		self.flags = FL_ONGROUND;
	else
		self.flags = 0;

	physics_car();
	self.velocity_z = self.velocity_z - sv_gravity * frametime;
	physics_velocity = self.velocity;
	physics_move();
	self.velocity = physics_velocity;
	physics_movetype = physics_movetype_save;
	self = e;
	return 1;
}

void physics_car_pre() {
	setorigin(mycar, car_start_origin);
	mycar.velocity = car_start_velocity;
	mycar.angles = car_start_angles;
}

void physics_car_post() {
	self.origin = mycar.origin + '0 0 40';
	physics_flags = self.flags;
}

void Ent_PhysicCar_Remove() {
	mycar = world;
	physics_plug_pre = physics_plug_nopostpre;
	physics_plug = physics_plug_null;
	physics_plug_post = physics_plug_nopostpre;
	physics_plug_adjust_view = physics_plug_no_adjust_view;
}

void Ent_PhysicCar(float isnew)
{
	float f = ReadShort();
	if (isnew) {
		physics_plug = physics_car_hook;
		physics_plug_pre = physics_car_pre;
		physics_plug_post = physics_car_post;
		vehicle_adjust_view_up = CAR_VIEW_UP;
		vehicle_adjust_view_back = CAR_VIEW_BACK;
		vehicle_adjust_view_start_offs = CAR_VIEW_START_OFFSET;
		physics_plug_adjust_view = vehicle_adjust_view;
		self.entremove = Ent_PhysicCar_Remove;
		mycar = self;
		mycar.solid = SOLID_BBOX;
		mycar.movetype = MOVETYPE_WALK;
		setsize(mycar, car_MIN, car_MAX);
	}
	if (f & 1)
	{
		g_vehicle_car_speed_stop = ReadCoord();
		g_vehicle_car_speed = ReadCoord();
		g_vehicle_car_turnspeed = ReadCoord();
		g_vehicle_car_movement_inertia = ReadCoord();
		g_vehicle_car_speed_drift = ReadCoord();
	}
	if (f & 2)
	{
		car_start_angles_x = ReadCoord();
		car_start_angles_y = ReadCoord();
		car_start_angles_z = ReadCoord();
		car_start_origin_x = ReadCoord();
		car_start_origin_y = ReadCoord();
		car_start_origin_z = ReadCoord();
		car_start_velocity_x = ReadCoord();
		car_start_velocity_y = ReadCoord();
		car_start_velocity_z = ReadCoord();
	}
}

