entity aircraft;
vector aircraft_start_angles;
vector aircraft_start_origin;
vector aircraft_start_velocity;

float physics_aircraft_hook() {
	entity e = self;
	self = aircraft;
	float physics_movetype_save = physics_movetype;
	physics_movetype = MOVETYPE_WALK;
	tracebox(self.origin, self.mins, self.maxs, self.origin + normalize(self.velocity) - '0 0 0.125', MOVE_NORMAL, self);
	if (trace_startsolid || (trace_fraction <= 1 && trace_plane_normal_z > 0.7))
		self.flags = FL_ONGROUND;
	else
		self.flags = 0;

	physics_aircraft();
	self.velocity_z = self.velocity_z - sv_gravity * frametime;
	physics_velocity = self.velocity;
	physics_move();
	self.velocity = physics_velocity;
	physics_movetype = physics_movetype_save;
	self = e;
	return 1;
}

void physics_aircraft_pre() {
	setorigin(aircraft, aircraft_start_origin);
	aircraft.velocity = aircraft_start_velocity;
	aircraft.angles = aircraft_start_angles;
}

void physics_aircraft_post() {
	setorigin(self, aircraft.origin + '0 0 48');
	physics_flags = self.flags;
}

void Ent_PhysicAircraft_Remove() {
	aircraft = world;
	physics_plug_pre = physics_plug_nopostpre;
	physics_plug = physics_plug_null;
	physics_plug_post = physics_plug_nopostpre;
	physics_plug_adjust_view = physics_plug_no_adjust_view;
}

void Ent_PhysicAircraft(float isnew)
{
	float f = ReadShort();
	if (isnew) {
		physics_plug = physics_aircraft_hook;
		physics_plug_pre = physics_aircraft_pre;
		physics_plug_post = physics_aircraft_post;
		vehicle_adjust_view_up = AIRCRAFT_VIEW_UP;
		vehicle_adjust_view_back = AIRCRAFT_VIEW_BACK;
		vehicle_adjust_view_start_offs = AIRCRAFT_VIEW_START_OFFSET;
		physics_plug_adjust_view = vehicle_adjust_view;
		self.entremove = Ent_PhysicAircraft_Remove;
		aircraft = self;
		aircraft.solid = SOLID_BBOX;
		aircraft.movetype = MOVETYPE_WALK;
		setsize(aircraft, aircraft_MIN, aircraft_MAX);
	}
	if (f & 1)
	{
		g_vehicle_aircraft_accel_up = ReadCoord();
		g_vehicle_aircraft_speed = ReadCoord();
		g_vehicle_aircraft_speed_stop = ReadCoord();
		g_vehicle_aircraft_turnspeed = ReadCoord();
		g_vehicle_aircraft_movement_inertia = ReadCoord();
	}
	if (f & 2)
	{
		aircraft_start_angles_x = ReadCoord();
		aircraft_start_angles_y = ReadCoord();
		aircraft_start_angles_z = ReadCoord();
		aircraft_start_origin_x = ReadCoord();
		aircraft_start_origin_y = ReadCoord();
		aircraft_start_origin_z = ReadCoord();
		aircraft_start_velocity_x = ReadCoord();
		aircraft_start_velocity_y = ReadCoord();
		aircraft_start_velocity_z = ReadCoord();
	}
}
