float physic_car()
{
	self.angles_x = -self.angles_x;
	makevectors(self.angles);
    if(self.flags & FL_ONGROUND) {
		if (physic_v_angle_y != self.angles_y) {
			float turn_angle_speed = g_vehicle_car_turnspeed * frametime;
			while (self.angles_y - physic_v_angle_y > 180)
				self.angles_y -= 360;

			while (self.angles_y - physic_v_angle_y < -180)
				self.angles_y += 360;

			if (physic_v_angle_y > self.angles_y)
				self.angles_y = min(self.angles_y + turn_angle_speed, physic_v_angle_y);
			else
				self.angles_y = max(self.angles_y - turn_angle_speed, physic_v_angle_y);

			makevectors(self.angles);
		}
		if not(physic_movement_x) {
			movelib_beak_simple(g_vehicle_car_speed_stop * frametime);
		} else {
			if(physic_movement_x != 0) {
				if(physic_movement_x < 0)
					physic_movement_x = -1;
				else if(physic_movement_x > 0)
					physic_movement_x = 1;

				movelib_move_simple(normalize(v_forward * physic_movement_x),g_vehicle_car_speed,g_vehicle_car_movement_inertia * frametime);
			}
		}
	}
	self.angles_x = -self.angles_x;
	movelib_groundalign4point(75, 75, 1);
    return 1;
}
