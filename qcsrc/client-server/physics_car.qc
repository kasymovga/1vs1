float(void) physics_car {
	physics_velocity = self.velocity;
	physics_movetype = MOVETYPE_QCWALK;
	physics_flags = self.flags;
	physics_update_status();
	self.velocity = physics_velocity;
	self.flags = physics_flags;
	self.angles_x = -self.angles_x;
	makevectors(self.angles);
    if(self.flags & FL_ONGROUND) {
		float _speed = vlen(self.velocity);
		if (physics_v_angle_y != self.angles_y) {
			float turn_angle_speed = g_vehicle_car_turnspeed * frametime * (_speed / g_vehicle_car_speed);
			while (self.angles_y - physics_v_angle_y > 180)
				self.angles_y -= 360;

			while (self.angles_y - physics_v_angle_y < -180)
				self.angles_y += 360;

			if (physics_v_angle_y > self.angles_y)
				self.angles_y = min(self.angles_y + turn_angle_speed, physics_v_angle_y);
			else
				self.angles_y = max(self.angles_y - turn_angle_speed, physics_v_angle_y);

			makevectors(self.angles);
		}
		float turn_inertia_factor = 1 - bound(0, (_speed / g_vehicle_car_speed_drift) - 0.5, 1);
		float forwdir;
		if (v_forward * self.velocity >= 0)
			forwdir = 1;
		else
			forwdir = -1;

		if not(physics_movement_x) {
			if (turn_inertia_factor > 0)
				movelib_move_simple(normalize(v_forward * forwdir), _speed, 20 * turn_inertia_factor * frametime); //Turning

			movelib_beak_simple(g_vehicle_car_speed_stop * frametime); //Stopping
		} else {
			if(physics_movement_x != 0) {
				if(physics_movement_x < 0)
					physics_movement_x = -1;
				else if(physics_movement_x > 0)
					physics_movement_x = 1;

				if (turn_inertia_factor > 0)
					movelib_move_simple(normalize(v_forward * forwdir), _speed, 20 * turn_inertia_factor * frametime); //Turning

				movelib_move_simple(normalize(v_forward * physics_movement_x), g_vehicle_car_speed ,g_vehicle_car_movement_inertia * frametime); //Accelerating
			}
		}
	}
	self.angles_x = -self.angles_x;
	movelib_groundalign4point(75, 75, 1);
	physics_velocity = self.velocity;
	physics_move();
	self.velocity = physics_velocity;
    return 1;
}
