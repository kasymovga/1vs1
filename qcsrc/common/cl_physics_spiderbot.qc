float physic_spiderbot()
{
	self.angles_x = -self.angles_x;
	makevectors(self.angles);
    if(self.flags & FL_ONGROUND) {
        if(physic_button_jump) {
            physic_button_jump = 0;
			self.velocity = self.velocity * g_vehicle_spiderbot_jump_accel + v_up * g_vehicle_spiderbot_jump_up;
        } else {
            if(vlen(physic_movement) == 0) {
                movelib_beak_simple(g_vehicle_spiderbot_speed_stop);
			} else {
				if (physic_v_angle_y != physic_spiderbot_angle) {
					float turn_angle_speed = g_vehicle_spiderbot_turnspeed * frametime;
					while (physic_spiderbot_angle - physic_v_angle_y > 180)
						physic_spiderbot_angle -= 360;

					while (physic_spiderbot_angle - physic_v_angle_y < -180)
						physic_spiderbot_angle += 360;

					if (physic_v_angle_y > physic_spiderbot_angle)
						physic_spiderbot_angle = min(physic_spiderbot_angle + turn_angle_speed, physic_v_angle_y);
					else
						physic_spiderbot_angle = max(physic_spiderbot_angle - turn_angle_speed, physic_v_angle_y);

					self.angles_y = physic_spiderbot_angle;
					makevectors(self.angles);
				}
                if(physic_movement_x != 0)
                {
                    if(physic_movement_x > 0)
                        physic_movement_x = 1;
                    else if(physic_movement_x < 0)
                        physic_movement_x = -1;

                    physic_movement_y = 0;
                    movelib_move_simple(normalize(v_forward * physic_movement_x),g_vehicle_spiderbot_speed_walk,g_vehicle_spiderbot_movement_inertia);
                } else if(physic_movement_y != 0) {
                    if(physic_movement_y < 0)
                        physic_movement_y = -1;
                    else if(physic_movement_y > 0)
                        physic_movement_y = 1;

                    movelib_move_simple(normalize(v_right * physic_movement_y),g_vehicle_spiderbot_speed_strafe,g_vehicle_spiderbot_movement_inertia);
                }
            }
        }
	}
	self.angles_x = -self.angles_x;
    return 1;
}
