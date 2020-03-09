entity aircraft;
vector aircraft_start_angles;
vector aircraft_start_origin;
vector aircraft_start_velocity;

float physics_aircraft_hook() {
	entity e = self;
	self = aircraft;
	physics_aircraft();
	self = e;
	return 1;
}

void physics_aircraft_pre() {
	setorigin(aircraft, aircraft_start_origin);
	aircraft.velocity = aircraft_start_velocity;
	aircraft.angles = aircraft_start_angles;
}

void physics_aircraft_post() {
	physics_vehicle_common_post(aircraft);
}

void Ent_PhysicAircraft_Remove() {
	aircraft = world;
	physics_plug_pre = physics_plug_nopostpre;
	physics_plug = physics_plug_null;
	physics_plug_post = physics_plug_nopostpre;
	physics_plug_adjust_view = physics_plug_no_adjust_view;
	physics_player_ent = 0;
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
		physics_plug_adjust_view = physics_vehicle_adjust_view;
		self.entremove = Ent_PhysicAircraft_Remove;
		aircraft = self;
		aircraft.solid = SOLID_BBOX;
		aircraft.movetype = MOVETYPE_QCWALK;
		setsize(aircraft, aircraft_MIN, aircraft_MAX);
	}
	if (f & 1)
	{
		g_vehicle_aircraft_accel_up = ReadCoord();
		g_vehicle_aircraft_speed = ReadCoord();
		g_vehicle_aircraft_speed_stop = ReadCoord();
		g_vehicle_aircraft_turnspeed = ReadCoord();
		g_vehicle_aircraft_movement_inertia = ReadCoord();
		physics_player_ent = ReadShort();
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
