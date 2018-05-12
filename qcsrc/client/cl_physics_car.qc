entity mycar;
vector car_start_angles;
vector car_start_origin;
vector car_start_velocity;

float physic_car_hook() {
	entity e = self;
	self = mycar;
	float physic_movetype_save = physic_movetype;
	physic_movetype = MOVETYPE_WALK;
	tracebox(self.origin, self.mins, self.maxs, self.origin + normalize(self.velocity) - '0 0 0.125', MOVE_NORMAL, self);
	if (trace_startsolid || (trace_fraction <= 1 && trace_plane_normal_z > 0.7))
		self.flags = FL_ONGROUND;
	else
		self.flags = 0;

	physic_car();
	self.velocity_z = self.velocity_z - sv_gravity * frametime;
	physic_velocity = self.velocity;
	PM_ClientMovement_Move();
	self.velocity = physic_velocity;
	physic_movetype = physic_movetype_save;
	self = e;
	return 1;
}

void physic_car_pre() {
	setorigin(mycar, car_start_origin);
	mycar.velocity = car_start_velocity;
	mycar.angles = car_start_angles;
}

void physic_car_post() {
	self.origin = mycar.origin + '0 0 40';
	physic_flags = self.flags;
}

void Ent_PhysicCar_Remove() {
	mycar = world;
	physic_plug_pre = physic_plug_nopostpre;
	physic_plug = physic_plug_null;
	physic_plug_post = physic_plug_nopostpre;
	physic_plug_adjust_view = physic_plug_no_adjust_view;
}

void Ent_PhysicCar(float isnew)
{
	float f = ReadShort();
	if (isnew) {
		physic_plug = physic_car_hook;
		physic_plug_pre = physic_car_pre;
		physic_plug_post = physic_car_post;
		vehicle_adjust_view_up = 100;
		vehicle_adjust_view_back = 220;
		physic_plug_adjust_view = vehicle_adjust_view;
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

