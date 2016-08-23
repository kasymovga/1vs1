
// these are used to store the last key press time for each of the keys..
.float last_FORWARD_KEY_time;
.float last_BACKWARD_KEY_time;
.float last_LEFT_KEY_time;
.float last_RIGHT_KEY_time;

float g_dodging_delay;
float g_dodging_frozen_factor;
float g_dodging_height_threshold;
float g_dodging_wall_distance_threshold;
float g_dodging_wall_dodging;

void dodging_Initialize() {
	// print("dodging_Initialize\n");

	self.last_FORWARD_KEY_time = 0;
	self.last_BACKWARD_KEY_time = 0;
	self.last_RIGHT_KEY_time = 0;
	self.last_LEFT_KEY_time = 0;
	self.last_dodging_time = 0;
	self.dodging_action = 0;
	self.dodging_velocity_gain = 0;
	self.dodging_single_action = 0;
	self.dodging_direction_x = 0;
	self.dodging_direction_y = 0;
}

void dodging_ReadCvars() {
	// print("dodging_Initialize\n");

	CACHE_CVAR(g_dodging);
	CACHE_CVAR(g_dodging_delay);
	CACHE_CVAR(g_dodging_frozen_factor);
	CACHE_CVAR(g_dodging_height_threshold);
	CACHE_CVAR(g_dodging_horiz_speed);
	CACHE_CVAR(g_dodging_ramp_time);
	CACHE_CVAR(g_dodging_sound);
	CACHE_CVAR(g_dodging_up_speed);
	CACHE_CVAR(g_dodging_wall_distance_threshold);
	CACHE_CVAR(g_dodging_wall_dodging);

}

// returns 1 if the player is close to a wall
float check_close_to_wall(float threshold) {
	if (g_dodging_wall_dodging == 0)
		return 0;

	vector trace_start;
	vector trace_end;

	trace_start = self.origin;

	trace_end = self.origin + (1000*v_right);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	trace_end = self.origin - (1000*v_right);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	trace_end = self.origin + (1000*v_forward);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	trace_end = self.origin - (1000*v_forward);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	return 0;
}

float check_close_to_ground(float threshold) {
	if (self.flags & FL_ONGROUND)
		return 1;

	return 0;
}

.float cvar_cl_dodging_timeout;
float dodging_GetPressedKeys()
{
	float length;
	float tap_direction_x;
	float tap_direction_y;

	tap_direction_x = 0;
	tap_direction_y = 0;

	float dodge_detected;
	if(!g_dodging)
		return 0;

	if (self.deadflag == DEAD_FREEZE) {
		if not(g_dodging_frozen_factor)
			return 0;
	} else if (self.deadflag)
		return 0;

	dodge_detected = 0;
    self.cvar_cl_dodging_timeout = 0.2;

	// first check if the last dodge is far enough back in time so we can dodge again
	if ((time - self.last_dodging_time) < g_dodging_delay)
		return 0;

	if (check_close_to_ground(g_dodging_height_threshold) != 1
		&& check_close_to_wall(g_dodging_wall_distance_threshold) != 1)
		return 0;

	if (self.movement_x > 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_FORWARD)) {
			if ((time - self.last_FORWARD_KEY_time) < self.cvar_cl_dodging_timeout)	{
				tap_direction_x = 1.0;
				dodge_detected = 1;
			}
 			self.last_FORWARD_KEY_time = time;
 		}
	}

	if (self.movement_x < 0) {
		// is this a state change?
 		if (!(self.pressedkeys & KEY_BACKWARD)) {
			tap_direction_x = -1.0;
			if ((time - self.last_BACKWARD_KEY_time) < self.cvar_cl_dodging_timeout)	{
				dodge_detected = 1;
			}
 			self.last_BACKWARD_KEY_time = time;
 		}
	}

	if (self.movement_y > 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_RIGHT)) {
			tap_direction_y = 1.0;
			if ((time - self.last_RIGHT_KEY_time) < self.cvar_cl_dodging_timeout)	{
				dodge_detected = 1;
			}
 			self.last_RIGHT_KEY_time = time;
 		}
	}

	if (self.movement_y < 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_LEFT)) {
			tap_direction_y = -1.0;
			if ((time - self.last_LEFT_KEY_time) < self.cvar_cl_dodging_timeout)	{
				dodge_detected = 1;
			}
 			self.last_LEFT_KEY_time = time;
 		}
	}



	if (dodge_detected == 1) {
		self.last_dodging_time = time;

		self.dodging_action = 1;
		self.dodging_single_action = 1;

		self.dodging_velocity_gain = g_dodging_horiz_speed;
		if (self.deadflag == DEAD_FREEZE)
			self.dodging_velocity_gain *= g_dodging_frozen_factor;

		self.dodging_direction_x = tap_direction_x;
		self.dodging_direction_y = tap_direction_y;

		// normalize the dodging_direction vector.. (unlike UT99) XD
		length = length + self.dodging_direction_x * self.dodging_direction_x;
		length = length + self.dodging_direction_y * self.dodging_direction_y;
		length = sqrt(length);

		self.dodging_direction_x = self.dodging_direction_x * 1.0/length;
		self.dodging_direction_y = self.dodging_direction_y * 1.0/length;
	}

	return 0;
}


