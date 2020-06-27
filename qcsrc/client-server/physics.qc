float physics_lastflags;

void(void) physics_impact {
	if not(trace_ent)
		return;

	self.velocity = physics_velocity;
	if (self.touch) {
		entity oldother = other;
		other = trace_ent;
		self.touch();
		other = oldother;
	}
	if (trace_ent.touch) {
		entity oldself = self;
		entity oldother = other;
		vector old_trace_plane_normal = trace_plane_normal;
		self.velocity = physics_velocity;
		self = trace_ent;
		trace_dpstartcontents = 0;
		trace_dphitcontents = 0;
		trace_dphitq3surfaceflags = 0;
		trace_plane_normal = -trace_plane_normal;
		other = oldself;
		self.touch();
		self = oldself;
		other = oldother;
		trace_plane_normal = old_trace_plane_normal;
	}
}

float(vector v) physics_unstuck_to {
	vector o = self.origin + v;
	trace_box(o, self.mins, self.maxs, self.origin, MOVE_NOMONSTERS, self);
	if (trace_startsolid)
		return FALSE;

	setorigin(self, trace_endpos);
	return TRUE;
}

void(void) physics_unstuck {
	trace_box(self.origin, self.mins, self.maxs, self.origin, MOVE_NOMONSTERS, self);
	if not(trace_startsolid)
		return;

	if (physics_unstuck_to('0 0 1' * self.maxs_z))
		return;

	if (physics_unstuck_to('0 0 1' * self.mins_z))
		return;

	if (physics_unstuck_to('0 1 0' * self.maxs_y))
		return;

	if (physics_unstuck_to('0 1 0' * self.mins_y))
		return;

	if (physics_unstuck_to('1 0 0' * self.maxs_x))
		return;

	if (physics_unstuck_to('1 0 0' * self.mins_x))
		return;
}

void(float ground) physics_update_status {
	if (physics_movetype == MOVETYPE_WALK || physics_movetype == MOVETYPE_QCWALK)
		physics_velocity_z -= physics_gravity_factor * sv_gravity * frametime;

	if(ground) {
		physics_flags &~= FL_ONGROUND_OR_SLICK;
		//trace_box(self.origin + '0 0 1', self.mins, self.maxs, self.origin - '0 0 1', MOVE_NORMAL, self);
		trace_box(self.origin, self.mins, self.maxs, self.origin - '0 0 0.125', MOVE_NORMAL, self);
		float f;
		if (trace_fraction <= 0.01 && trace_plane_normal_z > 0.7 && (g_q2doublejump || (f = physics_velocity * trace_plane_normal) <= 0)) {
			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK)
				physics_flags |= FL_SLICK;
			else
				physics_flags |= FL_ONGROUND;

			self.groundentity = trace_ent;
			physics_impact();
			if (!trace_ent || trace_ent.solid != SOLID_NOT)
				physics_velocity -= f * trace_plane_normal;
		}
	}
	// set watertype/waterlevel
	vector origin1 = self.origin;
	origin1_z += self.mins_z + 1;
	physics_waterlevel = WATERLEVEL_NONE;
	float thepoint = pointcontents(origin1);
	physics_watertype = (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME);
	if(physics_watertype) {
		physics_watertype = thepoint;
		physics_waterlevel = WATERLEVEL_WETFEET;
		origin1_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		thepoint = pointcontents(origin1);
		if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
		{
			physics_waterlevel = WATERLEVEL_SWIMMING;
			physics_flags &~= FL_ONGROUND_OR_SLICK;
			origin1_z = self.origin_z + self.view_ofs_z;
			thepoint = pointcontents(origin1);
			if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME) {
				physics_waterlevel = WATERLEVEL_SUBMERGED;
			}
		}
	}
}

vector(vector v1, vector v2) physics_bbox_nearest_normal {
	vector v = v1 + v2;
	vector nearest;
	float _max, check;
	_max = v * '1 0 0';
	nearest = '1 0 0';
	check = v * '-1 0 0';
	if (check > _max) {
		nearest = '-1 0 0';
		_max = check;
	}
	check = v * '0 1 0';
	if (check > _max) {
		nearest = '0 1 0';
		_max = check;
	}
	check = v * '0 -1 0';
	if (check > _max) {
		nearest = '0 -1 0';
		_max = check;
	}
	check = v * '0 0 1';
	if (check > _max) {
		nearest = '0 0 1';
		_max = check;
	}
	check = v * '0 0 -1';
	if (check > _max) {
		nearest = '0 0 -1';
		_max = check;
	}
	return nearest;
}

void(void) physics_move {
	float bump;
	float t;
	float f;
	float blocked_prev = 0;
	vector neworigin;
	vector currentorigin2;
	vector neworigin2;
	vector primalvelocity;
	vector prev_plane_normal;

	vector trace1_endpos = '0 0 0';
	vector trace2_endpos = '0 0 0';
	vector trace3_endpos = '0 0 0';
	float trace1_fraction = 0;
	float trace2_fraction = 0;
	float trace3_fraction = 0;
	vector trace1_plane_normal = '0 0 0';
	vector trace2_plane_normal = '0 0 0';
	vector trace3_plane_normal = '0 0 0';
	primalvelocity = physics_velocity;
	for (bump = 0, t = frametime; bump < 8 && physics_velocity != '0 0 0'; bump++) {
		neworigin = self.origin + t * physics_velocity;
		trace_box(self.origin, self.mins, self.maxs, neworigin, MOVE_NORMAL, self);
		trace1_endpos = trace_endpos;
		trace1_fraction = trace_fraction;
		trace1_plane_normal = trace_plane_normal;
		if (trace1_fraction < 1) {
			physics_impact();
			if (trace_ent) {
				if (trace_ent.solid == SOLID_NOT) //become non-solid after impact
					continue;

				if (trace1_plane_normal_z > 0.7) {
					self.groundentity = trace_ent;
					physics_flags |= FL_ONGROUND; //exact flags will be set on next frame. this one needed for engine
					physics_check_ground_hook();
				}
			}
			if (trace1_plane_normal_z == 0) {
				// may be a step or wall, try stepping up
				// first move forward at a higher level
				currentorigin2 = self.origin;
				currentorigin2_z += sv_stepheight;
				neworigin2 = neworigin;
				neworigin2_z = currentorigin2_z;
				//neworigin2_z += sv_stepheight;
				trace_box(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
				trace2_endpos = trace_endpos;
				trace2_fraction = trace_fraction;
				trace2_plane_normal = trace_plane_normal;
				if(!trace_startsolid)
				{
					// then move down from there
					currentorigin2 = trace2_endpos;
					neworigin2 = trace2_endpos;
					neworigin2_z = self.origin_z;
					trace_box(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
					trace3_endpos = trace_endpos;
					trace3_fraction = trace_fraction;
					trace3_plane_normal = trace_plane_normal;
					// accept the new trace if it made some progress
					if(fabs(trace3_endpos_x - trace1_endpos_x) >= 0.03125 || fabs(trace3_endpos_y - trace1_endpos_y) >= 0.03125)
					{
						trace1_endpos = trace2_endpos;
						trace1_fraction = trace2_fraction;
						trace1_plane_normal = trace2_plane_normal;
						trace1_endpos = trace3_endpos;
						if not(physics_flags & FL_ONGROUND)
							physics_velocity = physics_velocity * (1 - (trace_fraction * g_stepairslowdown));
					}
				}
			}
		}

		// check if it moved at all
		if(trace1_endpos == self.origin) {
			if (blocked_prev && prev_plane_normal * trace1_plane_normal < 0) {
				prev_plane_normal = physics_bbox_nearest_normal(prev_plane_normal, trace1_plane_normal);
				f = (physics_velocity * prev_plane_normal);
				physics_velocity = physics_velocity - f * prev_plane_normal;
			} else
				blocked_prev = 1;

			prev_plane_normal = trace1_plane_normal;
		} else {
			setorigin(self, trace1_endpos);
			blocked_prev = 0;
#ifdef SVQC
			physics_unstuck();
#endif
		}

		// check if it moved all the way
		if(trace1_fraction == 1)
			break;

		// this is only really needed for nogravityonground combined with gravityunaffectedbyticrate
		// <LordHavoc> I'm pretty sure I commented it out solely because it seemed redundant
		// this got commented out in a change that supposedly makes the code match QW better
		// so if this is broken, maybe put it in an if(cls.protocol != PROTOCOL_QUAKEWORLD) block
		//if(trace1_plane_normal_z > 0.7)
		//	physics_flags |= FL_ONGROUND;

		t -= t * trace1_fraction;

		f = (physics_velocity * trace1_plane_normal);
		physics_velocity = physics_velocity - f * trace1_plane_normal;
	}
	//physics_velocity = primalvelocity;
}

void(vector wishdir, float wishspeed) physics_aircontrol {
	float zspeed, xyspeed, dot, k;

	if(physics_movement_x == 0 || physics_movement_y != 0)
		return; // can't control movement if not moving forward or backward

	zspeed = physics_velocity_z;
	physics_velocity_z = 0;
	xyspeed = vlen(physics_velocity);
	physics_velocity = normalize(physics_velocity);

	dot = physics_velocity * wishdir;
	k = 32;
	k *= sv_aircontrol*dot*dot*frametime;

	if(dot > 0) // we can't change direction while slowing down
		physics_velocity = normalize(physics_velocity * xyspeed + wishdir * k);

	physics_velocity = physics_velocity * xyspeed;
	physics_velocity_z = zspeed;
}

void(vector wishdir, float wishspeed, float wishspeed0, float accel, float accelqw, float sidefric) physics_accelerate {
	float vel_straight;
	float vel_z;
	vector vel_perpend;
	float addspeed;
	float savespeed;
	if(sv_gameplayfix_q2airaccelerate)
		wishspeed0 = wishspeed;

	savespeed = physics_velocity * physics_velocity;
	vel_straight = physics_velocity * wishdir;
	vel_z = physics_velocity_z;
	vel_perpend = physics_velocity - vel_straight * wishdir - vel_z * '0 0 1';
	addspeed = wishspeed - vel_straight;
	if (addspeed > 0)
		vel_straight = vel_straight + min(addspeed, accel * frametime * wishspeed0) * accelqw;

	if (wishspeed > 0)
		vel_straight = vel_straight + min(wishspeed, accel * frametime * wishspeed0) * (1 - accelqw);

	if (sidefric < 0 && (vel_perpend*vel_perpend)) {
		float f, fmin;
		f = (1 + frametime * wishspeed * sidefric);
		fmin = (savespeed - vel_straight*vel_straight) / (vel_perpend*vel_perpend);
		if (fmin <= 0)
			vel_perpend = vel_perpend * f;
		else
			vel_perpend = vel_perpend * min(1, max(fmin, f));
	} else
		vel_perpend = vel_perpend * (1 - frametime * wishspeed * sidefric);

	physics_velocity = vel_straight * wishdir + vel_z * '0 0 1' + vel_perpend;
}

void(vector wishdir, float wishspeed) physics_air_accelerate {
	vector curvel, wishvel, acceldir, curdir;
	float addspeed, accelspeed, curspeed, f;
	float dot;

	if(wishspeed == 0)
		return;

	curvel = physics_velocity;
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

	physics_velocity += accelspeed * acceldir;
}

// these are used to store the last key press time for each of the keys..
.float lastkeys;
.float last_FORWARD_KEY_time;
.float last_BACKWARD_KEY_time;
.float last_LEFT_KEY_time;
.float last_RIGHT_KEY_time;

void(void) physics_dodging {
	vector tap_direction;
	float dodge_detected;
	float frozen = (physics_deadflag == DEAD_FREEZE);
	if not(frozen)
	if not(g_dodging)
		return;

	if (frozen) {
		if not(g_dodging_frozen)
			return;
	} else if (physics_deadflag)
		return;

	tap_direction_x = 0;
	tap_direction_y = 0;
	dodge_detected = 0;
    float dodging_timeout = 0.2;

	// first check if the last dodge is far enough back in time so we can dodge again
	if (self.last_dodging_time > 0)
		return;

	if not(physics_flags & FL_ONGROUND)
		return;

	if (frozen) {
		if (physics_movement_y > 0)
			tap_direction_y = 1;
		else if (physics_movement_y < 0)
			tap_direction_y = -1;

		if (physics_movement_x > 0)
			tap_direction_x = 1;
		else if (physics_movement_x < 0)
			tap_direction_x = -1;

		if (tap_direction_x || tap_direction_y)
			dodge_detected = 1;
	} else {
		if (physics_movement_x > 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_FORWARD)) {
				if (self.last_FORWARD_KEY_time > 0)	{
					tap_direction_x = 1.0;
					dodge_detected = 1;
				}
				self.last_FORWARD_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_FORWARD;
			self.lastkeys &~= KEY_BACKWARD;
		} else
			self.lastkeys &~= KEY_FORWARD;

		if (physics_movement_x < 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_BACKWARD)) {
				tap_direction_x = -1.0;
				if (self.last_BACKWARD_KEY_time > 0) {
					dodge_detected = 1;
				}
				self.last_BACKWARD_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_BACKWARD;
			self.lastkeys &~= KEY_FORWARD;
		} else
			self.lastkeys &~= KEY_BACKWARD;

		if (physics_movement_y > 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_RIGHT)) {
				tap_direction_y = 1.0;
				if (self.last_RIGHT_KEY_time > 0) {
					dodge_detected = 1;
				}
				self.last_RIGHT_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_RIGHT;
			self.lastkeys &~= KEY_LEFT;
		} else
			self.lastkeys &~= KEY_RIGHT;

		if (physics_movement_y < 0) {
			// is this a state change?
			if (!(self.lastkeys & KEY_LEFT)) {
				tap_direction_y = -1.0;
				if (self.last_LEFT_KEY_time > 0) {
					dodge_detected = 1;
				}
				self.last_LEFT_KEY_time = dodging_timeout;
			}
			self.lastkeys |= KEY_LEFT;
			self.lastkeys &~= KEY_RIGHT;
		} else
			self.lastkeys &~= KEY_LEFT;
	}

	if (dodge_detected == 1) {
		vector dodge_velocity;
		if (physics_waterlevel >= WATERLEVEL_SWIMMING)
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

		physics_velocity_x = dodge_velocity_x;
		physics_velocity_y = dodge_velocity_y;
		physics_velocity_z += dodge_velocity_z;
#ifdef SVQC
		if (g_dodging_sound)
			sound(self, CHAN_PLAYER, sound_random_by_str(self.playersound_jump), VOL_BASE, ATTN_NORM);

		anim_set(self, self.anim_jump, TRUE, FALSE, TRUE);
#endif
		self.last_dodging_time = (frozen ? g_dodging_frozen_delay : g_dodging_delay);

	}
	return;
}

vector(void) physics_player_touch_wall {
	local float dist, max_normal;
	local vector start, end;
	dist = 10;
	max_normal = 0.2;
	start = self.origin;
	end = start + v_forward * 100;
	vector _mins = self.mins;
	_mins_z = _mins_z + sv_stepheight;
	trace_box (start, _mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	end = start - v_forward * 100;
	trace_box (start, _mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	end = start + v_right * 100;
	trace_box (start, _mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	end = start - v_right * 100;
	trace_box (start, _mins, self.maxs, end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < dist && trace_plane_normal_z < max_normal)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		return trace_plane_normal;
	return '0 0 0';
}


void(void) physics_player_jump {
	if (physics_waterlevel >= WATERLEVEL_SWIMMING)
		return;

	if(physics_cantjump)
		return;

	if (physics_movetype != MOVETYPE_WALK)
	if (physics_movetype != MOVETYPE_QCWALK)
		return;

	if (g_walljump)
	//if not(self.hook.state)
	if not(physics_flags & FL_ONGROUND)
	if (self.lastwj <= 0)
	{
		makevectors(self.angles);
		local vector plane_normal;
		plane_normal = physics_player_touch_wall();
		if (plane_normal != '0 0 0')
		{
			self.lastwj = g_walljump_delay;
			float wj_force = g_walljump_force;
			float wj_xy_factor = g_walljump_velocity_xy_factor;
			float wj_z_factor = g_walljump_velocity_z_factor;
			physics_velocity_x += plane_normal_x * wj_force;
			physics_velocity_x /= wj_xy_factor;
			physics_velocity_y += plane_normal_y * wj_force;
			physics_velocity_y /= wj_xy_factor;
			physics_velocity_z = sv_jumpvelocity * wj_z_factor;
			if (physics_crouch) physics_velocity_z *= -1; // thanks Synap for the idea
			#ifdef SVQC
			pointparticles (particleeffectnum("smoke_ring"), trace_endpos, plane_normal, g_walljump_smokeparticle_num);
			sound(self, CHAN_PLAYER, sound_random_by_str(self.playersound_jump), VOL_BASE, ATTN_NORM);
			#endif
		}
	}


	if not(physics_flags & FL_ONGROUND)
	if not((physics_flags & FL_SLICK) && sv_slicksurfaces_allowjump)
		return;

	if(!sv_pogostick)
		if (!(physics_flags & FL_JUMPRELEASED))
			return;

	if(!(physics_lastflags & FL_ONGROUND) && (physics_flags & FL_ONGROUND))
		physics_landing_hook();

	physics_velocity_z = physics_velocity_z + sv_jumpvelocity * physics_jump_velocity_mod();

	physics_flags &~= FL_ONGROUND_OR_SLICK;
	physics_flags &~= FL_JUMPRELEASED;

	physics_on_jump_hook();

	// value -1 is used to not use the teleport bit (workaround for tiny hitch when re-jumping)
}

void(void) physics_check_water_jump {
	// check for a jump-out-of-water
	vector start, end;
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	trace_line (start, end, TRUE, self);
	if (trace_fraction < 1) { // solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		trace_line (start, end, TRUE, self);
		if (trace_fraction == 1) { // open at eye level
			physics_flags |= FL_WATERJUMP;
			physics_velocity_z = sv_waterjumpvelocity;
			physics_flags &~= FL_JUMPRELEASED;
			physics_teleport_time = 2;
			physics_check_water_jump_hook();
			return;
		}
	}
};

void(void) physics_player {
	vector wishvel, wishdir, v;
	float wishspeed, f, maxspd_mod, maxairspd, airaccel;
	if (self.lastwj > 0)
		self.lastwj -= frametime;

	if (g_dodging) {
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
	
	physics_frame_begin_hook();
	if (physics_plug)
	if (physics_plug())
		return;

	physics_update_status(TRUE);
	if (physics_button_crouch) {
		if not(sv_disable_crouch)
		if (!physics_crouch) {
			physics_crouch = TRUE;
			self.view_ofs = self.crouch_view_ofs;
			setsize (self, self.crouch_mins, self.crouch_maxs);
			physics_on_crouch_hook();
		}
	} else {
		if (physics_crouch) {
			trace_box(self.origin, self.stand_mins, self.stand_maxs, self.origin, FALSE, self);
			if (!trace_startsolid) {
				physics_crouch = FALSE;
				self.view_ofs = self.stand_view_ofs;
				setsize (self, self.stand_mins, self.stand_maxs);
			}
		}
	}
	if (physics_movetype == MOVETYPE_NONE)
		return;

	maxspd_mod = physics_max_speed_mod();
	// if dead, behave differently
	if (physics_deadflag != DEAD_NO)
	if (physics_deadflag != DEAD_FREEZE) {
		if (physics_flags & FL_ONGROUND)
			physics_velocity = '0 0 0';
		else if (physics_waterlevel >= WATERLEVEL_SWIMMING)
			physics_velocity = physics_velocity * (1 - frametime * sv_friction);

		goto end;
	}
	physics_check_ground_hook();
	if (physics_is_player) {
		if (physics_button_jump)
			physics_player_jump();
		else {
			physics_flags |= FL_JUMPRELEASED;
			physics_dodging();
		}
		if (physics_waterlevel == WATERLEVEL_SWIMMING)
		if not(physics_ladder)
		if (physics_deadflag == DEAD_NO)
			physics_check_water_jump();
	}
	if (physics_player_plug)
	if (physics_player_plug(maxspd_mod))
		goto end;

	if (physics_flags & FL_WATERJUMP) {
		physics_velocity_x = self.movedir_x;
		physics_velocity_y = self.movedir_y;
		if (physics_teleport_time < 0 || physics_waterlevel == WATERLEVEL_NONE || physics_velocity_z < 0) {
			physics_flags &~= FL_WATERJUMP;
			physics_teleport_time = 0;
		}
	} else if (physics_flags & FL_ONGROUND) {
		// walking
		makevectors(physics_v_angle_y * '0 1 0');
		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y;
		if not((physics_lastflags & FL_ONGROUND)) {
			physics_landing_hook();
		}
		v = physics_velocity;
		v_z = 0;
		f = vlen(v);
		if(f > 0) {
			if (f < sv_stopspeed) {
				f = 1 - frametime * (sv_stopspeed / f) * sv_friction;
			} else
				f = 1 - frametime * sv_friction;
			if (f > 0)
				physics_velocity = physics_velocity * f;
			else {
				physics_velocity_x = 0;
				physics_velocity_y = 0;
			}
		}
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > sv_maxspeed*maxspd_mod)
			wishspeed = sv_maxspeed*maxspd_mod;

		if (physics_crouch)
			wishspeed = wishspeed * 0.5;

		if (physics_teleport_time <= 0)
			physics_accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
	} else if (physics_movetype == MOVETYPE_NOCLIP || physics_movetype == MOVETYPE_FLY) {
		// noclipping or flying
		physics_flags &~= FL_ONGROUND;

		physics_velocity = physics_velocity * (1 - frametime * sv_friction);
		makevectors(physics_v_angle);
		//wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + v_up * physics_movement_z;
		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + '0 0 1' * physics_movement_z;
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > sv_maxspeed*maxspd_mod)
			wishspeed = sv_maxspeed*maxspd_mod;
		if (physics_teleport_time <= 0)
			physics_accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
	} else if (physics_waterlevel >= WATERLEVEL_SWIMMING) {
		// swimming
		physics_flags &~= FL_ONGROUND;
		makevectors(physics_v_angle);
		//wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + v_up * physics_movement_z;
		if (physics_button_jump)
			physics_movement_z = sv_maxspeed;

		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + '0 0 1' * physics_movement_z;
		if (physics_deadflag == DEAD_FREEZE) {
			if (physics_watertype == WATERLEVEL_SWIMMING)
				physics_accelerate('0 0 1', 0, sv_gravity * 0.25, sv_accelerate, 1, 0);
			else
				physics_accelerate('0 0 1', sv_gravity * 0.25, sv_gravity * 0.25, sv_accelerate, 1, 0);
		} else if (wishvel == '0 0 0') {
				wishvel_z = -sv_gravity * 0.075; // drift towards bottom
		}
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > sv_maxspeed * maxspd_mod)
			wishspeed = sv_maxspeed * maxspd_mod;

		wishspeed = wishspeed * 0.7;
		// water friction
		physics_velocity = physics_velocity * max(0, 1 - frametime * sv_friction);
		// water acceleration
		physics_accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
	} else if (physics_ladder) {
		// on a spawnfunc_func_ladder or swimming in spawnfunc_func_water
		physics_flags &~= FL_ONGROUND;
		makevectors(physics_v_angle);
		//wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + v_up * physics_movement_z;
		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + '0 0 1' * physics_movement_z;
		if (physics_gravity_factor)
			physics_velocity_z = physics_velocity_z + physics_gravity_factor * sv_gravity * frametime;
		else
			physics_velocity_z = physics_velocity_z + sv_gravity * frametime;

		physics_velocity = physics_velocity * max(0, 1 - frametime * sv_friction);
		if (physics_ladder_iswater) {
			f = vlen(wishvel);
			if (f > physics_ladder_speed)
				wishvel = wishvel * (physics_ladder_speed / f);

			physics_watertype = physics_ladder_watertype;
			f = physics_ladder_top;
			if ((self.origin_z + self.view_ofs_z) < f)
				physics_waterlevel = WATERLEVEL_SUBMERGED;
			else if ((self.origin_z + (self.mins_z + self.maxs_z) * 0.5) < f)
				physics_waterlevel = WATERLEVEL_SWIMMING;
			else if ((self.origin_z + self.mins_z + 1) < f)
				physics_waterlevel = WATERLEVEL_WETFEET;
			else {
				physics_waterlevel = WATERLEVEL_NONE;
				physics_watertype = CONTENT_EMPTY;
			}
		}
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > sv_maxspeed*maxspd_mod)
			wishspeed = sv_maxspeed*maxspd_mod;

		if (physics_teleport_time <= 0) {
			// water acceleration
			physics_accelerate(wishdir, wishspeed, wishspeed, sv_accelerate*maxspd_mod, 1, 0);
		}
	} else {
		float wishspeed0;
		if (maxspd_mod < 1) {
			maxairspd = sv_maxairspeed*maxspd_mod;
			airaccel = sv_airaccelerate*maxspd_mod;
		} else {
			maxairspd = sv_maxairspeed;
			airaccel = sv_airaccelerate;
		}
		// airborn
		makevectors(physics_v_angle_y * '0 1 0');
		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y;
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = wishspeed0 = vlen(wishvel);
		if (wishspeed0 > sv_maxspeed*maxspd_mod)
			wishspeed0 = sv_maxspeed*maxspd_mod;

		if (wishspeed > maxairspd)
			wishspeed = maxairspd;

		if (physics_crouch)
			wishspeed = wishspeed * 0.5;

		if (physics_teleport_time <= 0) {
			float accelerating;
			float wishspeed2;
			float airaccelqw;
			airaccelqw = sv_airaccel_qw;
			accelerating = (physics_velocity * wishdir > 0);
			wishspeed2 = wishspeed;
			// CPM
			if (sv_airstopaccelerate)
				if (physics_velocity * wishdir < 0)
					airaccel = sv_airstopaccelerate*maxspd_mod;

			if (physics_movement_x == 0 && physics_movement_y != 0) {
				if (sv_maxairstrafespeed) {
					wishspeed = min(wishspeed, sv_maxairstrafespeed*maxspd_mod);
					if(sv_maxairstrafespeed < sv_maxairspeed)
						airaccelqw = 1;
				}
				if (sv_airstrafeaccelerate) {
					airaccel = sv_airstrafeaccelerate*maxspd_mod;
					if(sv_airstrafeaccelerate > sv_airaccelerate)
						airaccelqw = 1;
				}
			}
			// !CPM
			if (sv_warsowbunny_turnaccel && accelerating && physics_movement_y == 0 && physics_movement_x != 0)
				physics_air_accelerate(wishdir, wishspeed);
			else
				physics_accelerate(wishdir, wishspeed, wishspeed0, airaccel, airaccelqw, sv_airaccel_sideways_friction / maxairspd);

			if(sv_aircontrol)
				physics_aircontrol(wishdir, wishspeed2);
		}
	}
:end
	physics_lastflags = physics_flags;
	physics_frame_end_hook();
	if (physics_movetype == MOVETYPE_QCWALK)
		physics_move();
}
