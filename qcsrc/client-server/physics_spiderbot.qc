float(void) physics_spiderbot {
	physics_velocity = self.velocity;
	physics_movetype = MOVETYPE_QCWALK;
	physics_flags = self.flags;
	physics_update_status();
	self.velocity = physics_velocity;
	self.flags = physics_flags;
	self.angles_x = -self.angles_x;
	makevectors(self.angles);
	if (self.flags & FL_ONGROUND) {
		#ifdef SVQC
		if (self.wasFlying && self.nextstep < time) {
			sound(self, CHAN_PLAYER, sound_random("misc/metalhitground", 4), VOL_BASE, ATTN_NORM);
			self.nextstep = time + 0.2;
			self.wasFlying = 0;
		}
		#endif
		if (physics_button_jump) {
			self.velocity = self.velocity * g_vehicle_spiderbot_jump_accel + v_up * g_vehicle_spiderbot_jump_up;
			self.flags &= ~FL_ONGROUND;
		} else {
			if (vlen(physics_movement) == 0) {
				movelib_beak_simple(g_vehicle_spiderbot_speed_stop * frametime);
			} else {
				if (physics_v_angle_y != self.angles_y) {
					float turn_angle_speed = g_vehicle_spiderbot_turnspeed * frametime;
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
				if(physics_movement_x != 0) {
					if(physics_movement_x > 0)
						physics_movement_x = 1;
					else if(physics_movement_x < 0)
						physics_movement_x = -1;

					physics_movement_y = 0;
					movelib_move_simple(normalize(v_forward * physics_movement_x),g_vehicle_spiderbot_speed_walk,g_vehicle_spiderbot_movement_inertia * frametime);
				} else if(physics_movement_y != 0) {
					if(physics_movement_y < 0)
						physics_movement_y = -1;
					else if(physics_movement_y > 0)
						physics_movement_y = 1;

					movelib_move_simple(normalize(v_right * physics_movement_y),g_vehicle_spiderbot_speed_strafe,g_vehicle_spiderbot_movement_inertia * frametime);
				}
			}
		}
	}
	#ifdef SVQC
	else
		self.wasFlying = 1;
	#endif

	self.angles_x = -self.angles_x;
	movelib_groundalign4point(75, 75, 1);
	physics_spiderbot_jump_decr = 0;
	physics_velocity = self.velocity;
	physics_move();
	self.velocity = physics_velocity;
    return 1;
}
