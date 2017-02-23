float physic_aircraft()
{
	self.angles_x = -self.angles_x;
	if(physic_button_jump) {
		self.velocity_z = self.velocity_z + g_vehicle_aircraft_accel_up * frametime;
	}

	if (self.flags & FL_ONGROUND) {
		movelib_beak_simple(g_vehicle_aircraft_speed_stop * frametime);
	}

	float turn_angle_speed;
	if (self.angles_y != physic_v_angle_y) {
		turn_angle_speed = g_vehicle_aircraft_turnspeed * frametime;
		while (self.angles_y - physic_v_angle_y > 180)
			self.angles_y -= 360;

		while (self.angles_y - physic_v_angle_y < -180)
			self.angles_y += 360;

		if (physic_v_angle_y > self.angles_y)
			self.angles_y = min(self.angles_y + turn_angle_speed, physic_v_angle_y);
		else
			self.angles_y = max(self.angles_y - turn_angle_speed, physic_v_angle_y);
	}

	if (self.angles_x != physic_v_angle_x) {
		turn_angle_speed = g_vehicle_aircraft_turnspeed * frametime;
		while (self.angles_x - physic_v_angle_x > 180)
			self.angles_x -= 360;

		while (self.angles_x - physic_v_angle_x < -180)
			self.angles_x += 360;

		if (physic_v_angle_x > self.angles_x)
			self.angles_x = min(self.angles_x + turn_angle_speed, physic_v_angle_x);
		else
			self.angles_x = max(self.angles_x - turn_angle_speed, physic_v_angle_x);

		if (self.angles_x > 60)
			self.angles_x = 60;
		else if (self.angles_x < -60)
			self.angles_x = -60;
	}

	makevectors(self.angles);
	if(physic_movement_x != 0)
	{
		if(physic_movement_x > 0)
			physic_movement_x = 1;
		else if(physic_movement_x < 0)
			physic_movement_x = -1;

		movelib_move_simple(normalize(v_forward * physic_movement_x),g_vehicle_aircraft_speed,g_vehicle_aircraft_movement_inertia * frametime);
	}
	if(physic_movement_y != 0) {
		if(physic_movement_y < 0)
			physic_movement_y = -1;
		else if(physic_movement_y > 0)
			physic_movement_y = 1;

		movelib_move_simple(normalize(v_right * physic_movement_y),g_vehicle_aircraft_speed,g_vehicle_aircraft_movement_inertia * frametime);
	}
	self.angles_x = -self.angles_x;
    return 1;
}
