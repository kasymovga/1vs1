float physic_lastflags;

void CPM_PM_Aircontrol(vector wishdir, float wishspeed)
{
	float zspeed, xyspeed, dot, k;

	if(physic_movement_x == 0 || physic_movement_y != 0)
		return; // can't control movement if not moving forward or backward

	zspeed = physic_velocity_z;
	physic_velocity_z = 0;
	xyspeed = vlen(physic_velocity);
	physic_velocity = normalize(physic_velocity);

	dot = physic_velocity * wishdir;
	k = 32;
	k *= sv_aircontrol*dot*dot*frametime;

	if(dot > 0) // we can't change direction while slowing down
		physic_velocity = normalize(physic_velocity * xyspeed + wishdir * k);

	physic_velocity = physic_velocity * xyspeed;
	physic_velocity_z = zspeed;
}

void PM_Accelerate(vector wishdir, float wishspeed, float wishspeed0, float accel, float accelqw, float sidefric)
{
	float vel_straight;
	float vel_z;
	vector vel_perpend;
	float addspeed;
	float savespeed;

	if(sv_gameplayfix_q2airaccelerate)
		wishspeed0 = wishspeed;

	savespeed = physic_velocity * physic_velocity;

	vel_straight = physic_velocity * wishdir;
	vel_z = physic_velocity_z;
	vel_perpend = physic_velocity - vel_straight * wishdir - vel_z * '0 0 1';

	addspeed = wishspeed - vel_straight;
	if(addspeed > 0)
		vel_straight = vel_straight + min(addspeed, accel * frametime * wishspeed0) * accelqw;
	if(wishspeed > 0)
		vel_straight = vel_straight + min(wishspeed, accel * frametime * wishspeed0) * (1 - accelqw);

	if(sidefric < 0 && (vel_perpend*vel_perpend))
	{
		float f, fmin;
		f = (1 + frametime * wishspeed * sidefric);
		fmin = (savespeed - vel_straight*vel_straight) / (vel_perpend*vel_perpend);
		if(fmin <= 0)
			vel_perpend = vel_perpend * f;
		else
			vel_perpend = vel_perpend * min(1, max(fmin, f));
	}
	else
		vel_perpend = vel_perpend * (1 - frametime * wishspeed * sidefric);

	physic_velocity = vel_straight * wishdir + vel_z * '0 0 1' + vel_perpend;
}

void PM_AirAccelerate(vector wishdir, float wishspeed)
{
	vector curvel, wishvel, acceldir, curdir;
	float addspeed, accelspeed, curspeed, f;
	float dot;

	if(wishspeed == 0)
		return;

	curvel = physic_velocity;
	curvel_z = 0;
	curspeed = vlen(curvel);

	if(wishspeed > curspeed * 1.01)
	{
		wishspeed = min(wishspeed, curspeed + sv_warsowbunny_airforwardaccel * sv_maxspeed * frametime);
	}
	else
	{
		f = max(0, (sv_warsowbunny_topspeed - curspeed) / (sv_warsowbunny_topspeed - sv_maxspeed));
		wishspeed = max(curspeed, sv_maxspeed) + sv_warsowbunny_accel * f * sv_maxspeed * frametime;
	}
	wishvel = wishdir * wishspeed;
	acceldir = wishvel - curvel;
	addspeed = vlen(acceldir);
	acceldir = normalize(acceldir);

	accelspeed = min(addspeed, sv_warsowbunny_turnaccel * sv_maxspeed * frametime);

	if(sv_warsowbunny_backtosideratio < 1)
	{
		curdir = normalize(curvel);
		dot = acceldir * curdir;
		if(dot < 0)
			acceldir = acceldir - (1 - sv_warsowbunny_backtosideratio) * dot * curdir;
	}

	physic_velocity += accelspeed * acceldir;
}

// these are used to store the last key press time for each of the keys..
.float lastkeys;
.float last_FORWARD_KEY_time;
.float last_BACKWARD_KEY_time;
.float last_LEFT_KEY_time;
.float last_RIGHT_KEY_time;

void dodging() {
	vector tap_direction;
	float dodge_detected;
	float frozen = (physic_deadflag == DEAD_FREEZE);
	if not(frozen)
	if not(g_dodging)
		return;

	if (frozen) {
		if not(g_dodging_frozen)
			return;
	} else if (physic_deadflag)
		return;

	tap_direction_x = 0;
	tap_direction_y = 0;
	dodge_detected = 0;
    float dodging_timeout = 0.2;

	// first check if the last dodge is far enough back in time so we can dodge again
	if (self.last_dodging_time > 0)
		return;

	if not(physic_flags & FL_ONGROUND)
		return;

	if (frozen) {
		if (physic_movement_y > 0)
			tap_direction_y = 1;
		else if (physic_movement_y < 0)
			tap_direction_y = -1;

		if (physic_movement_x > 0)
			tap_direction_x = 1;
		else if (physic_movement_x < 0)
			tap_direction_x = -1;

		if (tap_direction_x || tap_direction_y)
			dodge_detected = 1;
	} else {
		if (physic_movement_x > 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_FORWARD)) {
				if (self.last_FORWARD_KEY_time > 0)	{
					tap_direction_x = 1.0;
					dodge_detected = 1;
				}
				self.last_FORWARD_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_FORWARD;
		} else
			self.lastkeys &~= KEY_FORWARD;

		if (physic_movement_x < 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_BACKWARD)) {
				tap_direction_x = -1.0;
				if (self.last_BACKWARD_KEY_time > 0) {
					dodge_detected = 1;
				}
				self.last_BACKWARD_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_BACKWARD;
		} else
			self.lastkeys &~= KEY_BACKWARD;

		if (physic_movement_y > 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_RIGHT)) {
				tap_direction_y = 1.0;
				if (self.last_RIGHT_KEY_time > 0) {
					dodge_detected = 1;
				}
				self.last_RIGHT_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_RIGHT;
		} else
			self.lastkeys &~= KEY_RIGHT;

		if (physic_movement_y < 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_LEFT)) {
				tap_direction_y = -1.0;
				if (self.last_LEFT_KEY_time > 0) {
					dodge_detected = 1;
				}
				self.last_LEFT_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_LEFT;
		} else
			self.lastkeys &~= KEY_LEFT;
	}

	if (dodge_detected == 1) {
		vector dodge_velocity;
		if (physic_waterlevel >= WATERLEVEL_SWIMMING)
			return;

		makevectors(self.angles);

		self.flags &~= FL_ONGROUND;

		if (tap_direction_x)
		if (tap_direction_y)
			tap_direction *= sqrt(0.5);

		dodge_velocity = v_forward * g_dodging_horiz_speed * tap_direction_x
				+ v_right * g_dodging_horiz_speed * tap_direction_y
				+ g_dodging_up_speed * v_up;

		if (frozen)
			dodge_velocity *= g_dodging_frozen_factor;

		physic_velocity_x = dodge_velocity_x;
		physic_velocity_y = dodge_velocity_y;
		physic_velocity_z += dodge_velocity_z;
#ifdef SVQC
		if (g_dodging_sound)
			sound(self, CHAN_PLAYER, randomsound_bystr(self.playersound_jump), VOL_BASE, ATTN_NORM);

		setanim(self, self.anim_jump, TRUE, FALSE, TRUE);
#endif
		self.last_dodging_time = (frozen ? g_dodging_frozen_delay : g_dodging_delay);

	}
	return;
}

/*
=============
PlayerJump

When you press the jump key
=============
*/
vector PlayerTouchWall ()
{
	local float dist, max_normal;
	local vector start, end;
	dist = 10;
	max_normal = 0.2;
	start = self.origin;
	end = start + v_forward * 100;
	tracebox (start, self.mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	end = start - v_forward * 100;
	tracebox (start, self.mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	end = start + v_right * 100;
	tracebox (start, self.mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	end = start - v_right * 100;
	tracebox (start, self.mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	return '0 0 0';
}


void PlayerJump (void)
{
	if (physic_waterlevel >= WATERLEVEL_SWIMMING)
	{
		if (physic_watertype == CONTENT_WATER)
			physic_velocity_z = 200;
		else if (physic_watertype == CONTENT_SLIME)
			physic_velocity_z = 80;
		else
			physic_velocity_z = 50;

		return;
	}
	if(physic_cantjump)
		return;

	if (physic_movetype != MOVETYPE_WALK)
		return;

	if (g_walljump)
	//if not(self.hook.state)
	if not(physic_flags & FL_ONGROUND)
	if (self.lastwj <= 0)
	{
		makevectors(self.angles);
		local vector plane_normal;
		plane_normal = PlayerTouchWall ();
		if (plane_normal != '0 0 0')
		{
			self.lastwj = g_walljump_delay;
			float wj_force = g_walljump_force;
			float wj_xy_factor = g_walljump_velocity_xy_factor;
			float wj_z_factor = g_walljump_velocity_z_factor;
			physic_velocity_x += plane_normal_x * wj_force;
			physic_velocity_x /= wj_xy_factor;
			physic_velocity_y += plane_normal_y * wj_force;
			physic_velocity_y /= wj_xy_factor;
			physic_velocity_z = sv_jumpvelocity * wj_z_factor;
			if (physic_crouch) physic_velocity_z *= -1; // thanks Synap for the idea
			#ifdef SVQC
			pointparticles (particleeffectnum("smoke_ring"), trace_endpos, plane_normal, g_walljump_smokeparticle_num);
			sound(self, CHAN_PLAYER, randomsound_bystr(self.playersound_jump), VOL_BASE, ATTN_NORM);
			#endif
		}
	}


	if not(physic_flags & FL_ONGROUND)
	if not((physic_flags & FL_SLICK) && sv_slicksurfaces_allowjump)
		return;

	if(!sv_pogostick)
		if (!(physic_flags & FL_JUMPRELEASED))
			return;

	if(!(physic_lastflags & FL_ONGROUND) && (physic_flags & FL_ONGROUND))
		Physic_LandingHook();

	physic_velocity_z = physic_velocity_z + sv_jumpvelocity * Physic_JumpVelocityFactor();

	physic_flags &~= FL_ONGROUND_OR_SLICK;
	physic_flags &~= FL_JUMPRELEASED;

	Physic_OnJumpHook();

	// value -1 is used to not use the teleport bit (workaround for tiny hitch when re-jumping)
}

void CheckWaterJump()
{
	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			physic_flags |= FL_WATERJUMP;
			physic_velocity_z = 225;
			physic_flags &~= FL_JUMPRELEASED;
			physic_teleport_time = 2;
			Physic_CheckWaterJumpHook();
			return;
		}
	}
};

void PlayerPhysics()
{
	local vector wishvel, wishdir, v;
	local float wishspeed, f, maxspd_mod, maxairspd, airaccel;
	if (g_dodging) {
		if (self.lastwj > 0)
			self.lastwj -= frametime;

		if (self.last_FORWARD_KEY_time > 0)
			self.last_FORWARD_KEY_time -= frametime;
		if (self.last_BACKWARD_KEY_time > 0)
			self.last_BACKWARD_KEY_time -= frametime;
		if (self.last_LEFT_KEY_time > 0)
			self.last_LEFT_KEY_time -= frametime;
		if (self.last_RIGHT_KEY_time > 0)
			self.last_RIGHT_KEY_time -= frametime;
	}
	
	if (self.last_dodging_time > 0)
		self.last_dodging_time -= frametime;
	
	Physic_FrameBeginHook();
    if(physic_plug)
        if(physic_plug())
            return;

	if (physic_button_crouch)
	{
		if not(sv_disable_crouch)
		if (!physic_crouch)
		{
			physic_crouch = TRUE;
			self.view_ofs = self.crouch_view_ofs;
			setsize (self, self.crouch_mins, self.crouch_maxs);
			Physic_OnCrouchHook();
		}
	}
	else
	{
		if (physic_crouch)
		{
			tracebox(self.origin, self.stand_mins, self.stand_maxs, self.origin, FALSE, self);
			if (!trace_startsolid)
			{
				physic_crouch = FALSE;
				self.view_ofs = self.stand_view_ofs;
				setsize (self, self.stand_mins, self.stand_maxs);
			}
		}
	}

	if (physic_movetype == MOVETYPE_NONE)
		return;

	maxspd_mod = Physic_MaxSpeedMod();

	// if dead, behave differently
	if (physic_deadflag != DEAD_NO)
	if (physic_deadflag != DEAD_FREEZE)
		goto end;

	if(sv_slicksurfaces)
	if(physic_flags & FL_ONGROUND)
	{
		tracebox(self.origin + '0 0 1', self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
		if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK)
		{
			physic_flags &~= FL_ONGROUND;
			physic_flags |= FL_SLICK;
		}
		else
			physic_flags &~= FL_SLICK;
	}

	Physic_CheckGroundHook();

	if(physic_is_player)
	{
		if (physic_button_jump)
			PlayerJump ();
		else {
			physic_flags |= FL_JUMPRELEASED;
			dodging();
		}
		if (physic_waterlevel == WATERLEVEL_SWIMMING)
			CheckWaterJump ();
	}

	if (physic_flags & FL_WATERJUMP )
	{
		physic_velocity_x = self.movedir_x;
		physic_velocity_y = self.movedir_y;
		if (physic_teleport_time < 0 || physic_waterlevel == WATERLEVEL_NONE)
		{
			physic_flags &~= FL_WATERJUMP;
			self.teleport_time = 0;
		}
	}
	else if (physic_movetype == MOVETYPE_NOCLIP || physic_movetype == MOVETYPE_FLY)
	{
		// noclipping or flying
		physic_flags &~= FL_ONGROUND;

		physic_velocity = physic_velocity * (1 - frametime * sv_friction);
		makevectors(physic_v_angle);
		//wishvel = v_forward * physic_movement_x + v_right * physic_movement_y + v_up * physic_movement_z;
		wishvel = v_forward * physic_movement_x + v_right * physic_movement_y + '0 0 1' * physic_movement_z;
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > sv_maxspeed*maxspd_mod)
			wishspeed = sv_maxspeed*maxspd_mod;
		if (physic_teleport_time <= 0)
			PM_Accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
	}
	else if (physic_waterlevel >= WATERLEVEL_SWIMMING)
	{
		// swimming
		physic_flags &~= FL_ONGROUND;

		makevectors(physic_v_angle);
		//wishvel = v_forward * physic_movement_x + v_right * physic_movement_y + v_up * physic_movement_z;
		wishvel = v_forward * physic_movement_x + v_right * physic_movement_y + '0 0 1' * physic_movement_z;
		if (wishvel == '0 0 0')
			wishvel = '0 0 -60'; // drift towards bottom

		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > sv_maxspeed*maxspd_mod)
			wishspeed = sv_maxspeed*maxspd_mod;
		wishspeed = wishspeed * 0.7;

		// water friction
		physic_velocity = physic_velocity * (1 - frametime * sv_friction);

		// water acceleration
		PM_Accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
	}
	else if (physic_ladder)
	{
		// on a spawnfunc_func_ladder or swimming in spawnfunc_func_water
		physic_flags &~= FL_ONGROUND;

		physic_velocity = physic_velocity * (1 - frametime * sv_friction);
		makevectors(physic_v_angle);
		//wishvel = v_forward * physic_movement_x + v_right * physic_movement_y + v_up * physic_movement_z;
		wishvel = v_forward * physic_movement_x + v_right * physic_movement_y + '0 0 1' * physic_movement_z;
		if (physic_gravity_factor)
			physic_velocity_z = physic_velocity_z + physic_gravity_factor * sv_gravity * frametime;
		else
			physic_velocity_z = physic_velocity_z + sv_gravity * frametime;
		if (physic_ladder_iswater)
		{
			f = vlen(wishvel);
			if (f > physic_ladder_speed)
				wishvel = wishvel * (physic_ladder_speed / f);

			physic_watertype = physic_ladder_watertype;
			f = physic_ladder_top;
			if ((self.origin_z + self.view_ofs_z) < f)
				physic_waterlevel = WATERLEVEL_SUBMERGED;
			else if ((self.origin_z + (self.mins_z + self.maxs_z) * 0.5) < f)
				physic_waterlevel = WATERLEVEL_SWIMMING;
			else if ((self.origin_z + self.mins_z + 1) < f)
				physic_waterlevel = WATERLEVEL_WETFEET;
			else
			{
				physic_waterlevel = WATERLEVEL_NONE;
				physic_watertype = CONTENT_EMPTY;
			}
		}
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > sv_maxspeed*maxspd_mod)
			wishspeed = sv_maxspeed*maxspd_mod;
		if (physic_teleport_time <= 0)
		{
			// water acceleration
			PM_Accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
		}
	}
	else if (Physic_CanUseJetPack())
	{
		//makevectors(self.v_angle_y * '0 1 0');
		makevectors(physic_v_angle);
		wishvel = v_forward * physic_movement_x + v_right * physic_movement_y;
		// add remaining speed as Z component
		maxairspd = sv_maxairspeed*max(1, maxspd_mod);
		// fix speedhacks :P
		wishvel = normalize(wishvel) * min(vlen(wishvel) / maxairspd, 1);
		// add the unused velocity as up component
		wishvel_z = 0;

		// if(self.BUTTON_JUMP)
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
		if(a_diff != 0)
		{
			f = a_add * a_up / a_diff; // this is the zero of diff(f(a_side, a_up, a_add, z), z)
			if(f > -1 && f < 1) // can it be attained?
			{
				best = (a_diff + a_add * a_add) * (a_diff + a_up * a_up) / a_diff;
				//print("middle\n");
			}
		}
		// OR attained at z = 1:
		f = (a_up + a_add) * (a_up + a_add);
		if(f > best)
		{
			best = f;
			//print("top\n");
		}
		// OR attained at z = -1:
		f = (a_up - a_add) * (a_up - a_add);
		if(f > best)
		{
			best = f;
			//print("bottom\n");
		}
		best = sqrt(best);
		//////////////////////////////////////////////////////////////////////////////////////

		//print("best possible acceleration: ", ftos(best), "\n");

		float fxy, fz;
		fxy = bound(0, 1 - (physic_velocity * normalize(wishvel_x * '1 0 0' + wishvel_y * '0 1 0')) / g_jetpack_maxspeed_side, 1);
		if(wishvel_z - sv_gravity > 0)
			fz = bound(0, 1 - physic_velocity_z / g_jetpack_maxspeed_up, 1);
		else
			fz = bound(0, 1 + physic_velocity_z / g_jetpack_maxspeed_up, 1);

		float fvel;
		fvel = vlen(wishvel);
		wishvel_x *= fxy;
		wishvel_y *= fxy;
		wishvel_z = (wishvel_z - sv_gravity) * fz + sv_gravity;

		fvel = min(1, vlen(wishvel) / best);
		f = Physic_JetPackVelocityFactor(fvel);

		//print("this acceleration: ", ftos(vlen(wishvel) * f), "\n");

		if (f > 0 && wishvel != '0 0 0')
		{
			physic_velocity = physic_velocity + wishvel * f * frametime;
			physic_flags &~= FL_ONGROUND;
			Physic_JetPackHook(fvel * f);
		}
	}
	else if (physic_flags & FL_ONGROUND)
	{
		// walking
		makevectors(physic_v_angle_y * '0 1 0');
		wishvel = v_forward * physic_movement_x + v_right * physic_movement_y;

		if(!(physic_lastflags & FL_ONGROUND))
		{
			Physic_LandingHook();
		}

#ifdef LETS_TEST_FTEQCC
		if(physic_velocity_x || physic_velocity_y)
		{
			// good
		}
		else
		{
			if(physic_velocity_x)
				checkclient();
			if(physic_velocity_y)
				checkclient();
		}
#endif

		v = physic_velocity;
		v_z = 0;
		f = vlen(v);
		if(f > 0)
		{
			if (f < sv_stopspeed)
			{
				f = 1 - frametime * (sv_stopspeed / f) * sv_friction;
			}
			else
				f = 1 - frametime * sv_friction;
			if (f > 0)
				physic_velocity = physic_velocity * f;
			else
				physic_velocity = '0 0 0';
		}

		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);

		if (wishspeed > sv_maxspeed*maxspd_mod)
			wishspeed = sv_maxspeed*maxspd_mod;
		if (physic_crouch)
			wishspeed = wishspeed * 0.5;
		if (physic_teleport_time <= 0)
			PM_Accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
	}
	else
	{
		float wishspeed0;

		if(maxspd_mod < 1)
		{
			maxairspd = sv_maxairspeed*maxspd_mod;
			airaccel = sv_airaccelerate*maxspd_mod;
		}
		else
		{
			maxairspd = sv_maxairspeed;
			airaccel = sv_airaccelerate;
		}
		// airborn
		makevectors(physic_v_angle_y * '0 1 0');
		wishvel = v_forward * physic_movement_x + v_right * physic_movement_y;
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = wishspeed0 = vlen(wishvel);
		if (wishspeed0 > sv_maxspeed*maxspd_mod)
			wishspeed0 = sv_maxspeed*maxspd_mod;
		if (wishspeed > maxairspd)
			wishspeed = maxairspd;
		if (physic_crouch)
			wishspeed = wishspeed * 0.5;
		if (physic_teleport_time <= 0)
		{
			float accelerating;
			float wishspeed2;
			float airaccelqw;

			airaccelqw = sv_airaccel_qw;
			accelerating = (physic_velocity * wishdir > 0);
			wishspeed2 = wishspeed;

			// CPM
			if(sv_airstopaccelerate)
				if(physic_velocity * wishdir < 0)
					airaccel = sv_airstopaccelerate*maxspd_mod;
			if(physic_movement_x == 0 && physic_movement_y != 0)
			{
				if(sv_maxairstrafespeed)
				{
					wishspeed = min(wishspeed, sv_maxairstrafespeed*maxspd_mod);
					if(sv_maxairstrafespeed < sv_maxairspeed)
						airaccelqw = 1;
				}
				if(sv_airstrafeaccelerate)
				{
					airaccel = sv_airstrafeaccelerate*maxspd_mod;
					if(sv_airstrafeaccelerate > sv_airaccelerate)
						airaccelqw = 1;
				}
			}
			// !CPM

			if(sv_warsowbunny_turnaccel && accelerating && physic_movement_y == 0 && physic_movement_x != 0)
				PM_AirAccelerate(wishdir, wishspeed);
			else
				PM_Accelerate(wishdir, wishspeed, wishspeed0, airaccel, airaccelqw, sv_airaccel_sideways_friction / maxairspd);

			if(sv_aircontrol)
				CPM_PM_Aircontrol(wishdir, wishspeed2);
		}
	}

:end

	physic_lastflags = physic_flags;
	Physic_FrameEndHook();
};

