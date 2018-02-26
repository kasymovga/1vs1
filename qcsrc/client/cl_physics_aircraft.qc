entity aircraft;
vector aircraft_start_angles;
vector aircraft_start_origin;
vector aircraft_start_velocity;

float physic_aircraft_hook() {
	entity e = self;
	self = aircraft;
	float physic_movetype_save = physic_movetype;
	physic_movetype = MOVETYPE_WALK;
	tracebox(self.origin, self.mins, self.maxs, self.origin + normalize(self.velocity) - '0 0 0.125', MOVE_NORMAL, self);
	if (trace_startsolid || (trace_fraction <= 1 && trace_plane_normal_z > 0.7))
		self.flags = FL_ONGROUND;
	else
		self.flags = 0;

	physic_aircraft();
	self.velocity_z = self.velocity_z - sv_gravity * frametime;
	physic_velocity = self.velocity;
	PM_ClientMovement_Move();
	self.velocity = physic_velocity;
	physic_movetype = physic_movetype_save;
	self = e;
	return 1;
}

void physic_aircraft_pre() {
	setorigin(aircraft, aircraft_start_origin);
	aircraft.velocity = aircraft_start_velocity;
	aircraft.angles = aircraft_start_angles;
}

void physic_aircraft_post() {
	//physic_velocity = self.velocity;
	vector v = aircraft.origin + '0 0 48';
	makevectors(input_angles);
	tracebox(v, '-1 -1 -1', '1 1 1', v - v_forward * 200, MOVE_WORLDONLY, world);
	v = trace_endpos;
	tracebox(v, '-1 -1 -1', '1 1 1', v + v_up * 100, MOVE_WORLDONLY, world);
	v = trace_endpos;
	setorigin(self, v);
	physic_flags = self.flags;
}

void Ent_PhysicAircraft_Remove() {
	aircraft = world;
	physic_plug_pre = physic_plug_nopostpre;
	physic_plug = physic_plug_null;
	physic_plug_post = physic_plug_nopostpre;
}

void Ent_PhysicAircraft(float isnew)
{
	float f = ReadShort();
	if (isnew) {
		physic_plug = physic_aircraft_hook;
		physic_plug_pre = physic_aircraft_pre;
		physic_plug_post = physic_aircraft_post;
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
