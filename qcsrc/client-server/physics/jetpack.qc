var float(float maxspd_mod) physics_jetpack_next;
float(float maxspd_mod) physics_jetpack {
	float maxairspd, f;
	vector wishvel;
	float r = (physics_jetpack_next ? physics_jetpack_next(maxspd_mod) : 0);
	if (g_jetpack_hook_button) {
		#ifdef SVQC
		if not(self.BUTTON_HOOK)
		#else
		if not(input_buttons & 32)
		#endif
			return r;
	} else {
		if not(physics_button_jump)
			return r;

		if not(physics_flags & FL_JUMPRELEASED)
			return r;

		if (physics_flags & FL_ONGROUND)
			return r;

	}
	if (physics_waterlevel)
		return r;

	if not(jetpack_using())
		return r;

	if (g_sideview)
		makevectors(physics_v_angle_y * '0 1 0');
	else
		makevectors(physics_v_angle);

	wishvel = v_forward * physics_movement_x + v_right * physics_movement_y;
	// add remaining speed as Z component
	maxairspd = sv_maxairspeed*max(1, maxspd_mod);
	// fix speedhacks :P
	wishvel = normalize(wishvel) * min(vlen(wishvel) / maxairspd, 1);
	// add the unused velocity as up component
	wishvel_z = 0;
	wishvel_z = sqrt(max(0, 1 - wishvel * wishvel));
	// it is now normalized, so...
	float a_side, a_up, a_add, a_diff;
	a_side = g_jetpack_acceleration_side;
	a_up = g_jetpack_acceleration_up;
	a_add = g_jetpack_antigravity * sv_gravity;
	wishvel_x *= a_side;
	wishvel_y *= a_side;
	wishvel_z *= a_up;
	wishvel_z += a_add;
	float best;
	best = 0;
	//////////////////////////////////////////////////////////////////////////////////////
	// finding the maximum over all vectors of above form
	// with wishvel having an absolute value of 1
	//////////////////////////////////////////////////////////////////////////////////////
	// we're finding the maximum over
	//   f(a_side, a_up, a_add, z) := a_side * (1 - z^2) + (a_add + a_up * z)^2;
	// for z in the range from -1 to 1
	//////////////////////////////////////////////////////////////////////////////////////
	// maximum is EITHER attained at the single extreme point:
	a_diff = a_side * a_side - a_up * a_up;
	if(a_diff != 0) {
		f = a_add * a_up / a_diff; // this is the zero of diff(f(a_side, a_up, a_add, z), z)
		if(f > -1 && f < 1) { // can it be attained?
			best = (a_diff + a_add * a_add) * (a_diff + a_up * a_up) / a_diff;
			//print("middle\n");
		}
	}
	// OR attained at z = 1:
	f = (a_up + a_add) * (a_up + a_add);
	if(f > best) {
		best = f;
		//print("top\n");
	}
	// OR attained at z = -1:
	f = (a_up - a_add) * (a_up - a_add);
	if(f > best) {
		best = f;
		//print("bottom\n");
	}
	best = sqrt(best);
	float fxy, fz;
	float speed_factor = (physics_crouch ? 0.25 : 1);
	fxy = bound(0, 1 - (physics_velocity * normalize(wishvel_x * '1 0 0' + wishvel_y * '0 1 0')) / (g_jetpack_maxspeed_side * speed_factor), 1);
	if(wishvel_z - sv_gravity > 0)
		fz = bound(0, 1 - physics_velocity_z / (g_jetpack_maxspeed_up * speed_factor), 1);
	else
		fz = bound(0, 1 + physics_velocity_z / (g_jetpack_maxspeed_up * speed_factor), 1);

	float fvel;
	fvel = vlen(wishvel);
	wishvel_x *= fxy;
	wishvel_y *= fxy;
	wishvel_z = (wishvel_z - sv_gravity) * fz + sv_gravity;
	fvel = min(1, vlen(wishvel) / best);
	f = jetpack_velocity_mod(fvel);
	if (f > 0 && wishvel != '0 0 0') {
		physics_velocity = physics_velocity + wishvel * f * frametime;
		physics_flags &= ~FL_ONGROUND;
		jetpack_finished(fvel * f);
	}
	return 1;
}

float physics_jetpack_enabled;
void(void) physics_jetpack_enable {
	if (physics_jetpack_enabled)
		return;

	physics_jetpack_enabled = 1;
	physics_jetpack_next = physics_player_plug;
	physics_player_plug = physics_jetpack;
}
