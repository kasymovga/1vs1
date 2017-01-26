float physic_spiderbot()
{
	self.angles_x = -self.angles_x;
	makevectors(self.angles);
    if(self.flags & FL_ONGROUND) {
        if(physic_button_jump) {
			self.velocity = self.velocity * g_vehicle_spiderbot_jump_accel + v_up * g_vehicle_spiderbot_jump_up;
			self.flags &~= FL_ONGROUND;
        } else {
            if(vlen(physic_movement) == 0) {
                movelib_beak_simple(g_vehicle_spiderbot_speed_stop);
			} else {
				if (physic_v_angle_y != self.angles_y) {
					float turn_angle_speed = g_vehicle_spiderbot_turnspeed * frametime;
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
	movelib_groundalign4point(75, 75, 1);
	physic_spiderbot_jump_decr = 0;
    return 1;
}
