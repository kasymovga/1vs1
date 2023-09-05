float FL_ONGROUND_OR_SLICK = (FL_ONGROUND | FL_SLICK);
float FL_ONGROUND_OR_SLICK_OR_CLIMB = (FL_ONGROUND | FL_SLICK | FL_CLIMB);
float physics_lastflags;
float physics_groundvelocity_dotproduct;
vector physics_ground_normal;

void(void) physics_impact {
	if not(trace_ent)
		return;

	self.velocity = physics_velocity;
	if (self.touch) {
		entity oldother = other;
		other = trace_ent;
		self.touch(); //Lets hope there is not trace function in this touch function
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
		self.touch(); //Lets hope there is not trace function in this touch function
		self = oldself;
		other = oldother;
		trace_plane_normal = old_trace_plane_normal;
	}
}

float(vector v) physics_unstuck_to {
	vector o = self.origin + v;
	trace_box(o, self.mins, self.maxs, self.origin, TRACE_MOVE_NOMONSTERS, self);
	trace_box(trace_endpos, self.mins, self.maxs, trace_endpos, TRACE_MOVE_NOMONSTERS, self);
	if (trace_startsolid)
		return FALSE;

	setorigin(self, trace_endpos);
	return TRUE;
}

void(void) physics_unstuck {
	trace_box(self.origin, self.mins, self.maxs, self.origin, TRACE_MOVE_NOMONSTERS, self);
	if not(trace_startsolid)
		return;

	vector v = self.maxs - self.mins;
	if (physics_unstuck_to('0 0 1' * v_z))
		return;

	if (physics_unstuck_to('0 0 -1' * v_z))
		return;

	if (physics_unstuck_to('0 1 0' * v_y))
		return;

	if (physics_unstuck_to('0 -1 0' * v_y))
		return;

	if (physics_unstuck_to('1 0 0' * v_x))
		return;

	if (physics_unstuck_to('-1 0 0' * v_x))
		return;

	if not(sv_disable_crouch)
	if (self.crouch_mins != self.crouch_maxs) //prevent this code from objects that not support crouch (vehicles)
	if not(physics_crouch) { //Last hope
		trace_box(self.origin, self.crouch_mins, self.crouch_maxs, self.origin, TRACE_MOVE_NOMONSTERS, self);
		if not(trace_startsolid) {
			setsize(self, self.crouch_mins, self.crouch_maxs);
			physics_crouch = TRUE;
			self.view_ofs = self.crouch_view_ofs;
		}
	}
}

void(void) physics_update_status {
	physics_lastflags = physics_flags;
	// set watertype/waterlevel
	vector origin1 = self.origin;
	origin1_z += self.mins_z + 1;
	physics_waterlevel = WATER_LEVEL_NONE;
	physics_flags &= ~FL_ONGROUND_OR_SLICK_OR_CLIMB;
	float thepoint = pointcontents(origin1);
	physics_watertype = (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME);
	if (physics_watertype) {
		physics_watertype = thepoint;
		physics_waterlevel = WATER_LEVEL_WETFEET;
		origin1_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		thepoint = pointcontents(origin1);
		if (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME) {
			physics_waterlevel = WATER_LEVEL_SWIMMING;
			origin1_z = self.origin_z + self.view_ofs_z;
			thepoint = pointcontents(origin1);
			if (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME) {
				physics_waterlevel = WATER_LEVEL_SUBMERGED;
			}
		}
	}
	trace_box(self.origin, self.mins, self.maxs, self.origin - '0 0 0.125', TRACE_MOVE_NORMAL, self);
	if (trace_startsolid)
	if not(physics_flags & FL_SWIM) //NOCLIP
	if (self.solid != SOLID_NOT) {
		physics_unstuck();
		trace_box(self.origin, self.mins, self.maxs, self.origin - '0 0 0.125', TRACE_MOVE_NORMAL, self);
	}
	#ifdef SVQC
	if (trace_dpstartcontents & DPCONTENTS_NODROP)
		physics_in_nodrop();
	#endif
	if (physics_waterlevel < WATER_LEVEL_SWIMMING) {
		if (trace_fraction <= 0.01 && trace_plane_normal_z > 0.7 && ((physics_groundvelocity_dotproduct = physics_velocity * trace_plane_normal) <= 0 || (physics_have_doubjejump && (!g_doublejump_nopogostick || (physics_flags & FL_JUMPRELEASED))))) {
			physics_ground_normal = trace_plane_normal;
			physics_flags &= ~FL_DOUBLEJUMP;
			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) {
				if (g_slicksurfaces_levitation)
					physics_flags |= FL_SLICK;
				else
					physics_flags |= FL_ONGROUND_OR_SLICK;
			} else
				physics_flags |= FL_ONGROUND;

			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY) { //step on sky, usually this is map error
				#ifdef SVQC
				physics_step_on_sky();
				#endif
				physics_flags &= ~FL_ONGROUND_OR_SLICK;
			}
			self.groundentity = trace_ent;
			physics_impact();
			if (physics_groundvelocity_dotproduct < 0) {
				if (!trace_ent || trace_ent.solid != SOLID_NOT)
					physics_velocity -= physics_groundvelocity_dotproduct * trace_plane_normal;
			}
		} else if (physics_skimming > 0 && trace_fraction <= 0.01) {
			float f = vlen(physics_velocity);
			physics_velocity -= trace_plane_normal * (physics_velocity * trace_plane_normal);
			physics_velocity = f * normalize(physics_velocity);
		}
		if (g_cpmdoublejump) {
			if (physics_cpmdoublejump_time > 0)
				physics_cpmdoublejump_time -= frametime;

			if (physics_lastflags & FL_ONGROUND_OR_SLICK)
			if (physics_flags & FL_ONGROUND_OR_SLICK)
				physics_cpmdoublejump_time = 0;
		}
		if (physics_nofriction)
			physics_nofriction = max(0, physics_nofriction - frametime);
	}
}

vector(vector v1, vector v2) physics_bbox_nearest_normal {
	vector nearest = normalize(v1 + v2);
	if (nearest_z > 0.7)
		nearest = '0 0 1';
	else if (nearest_z < -0.7)
		nearest = '0 0 -1';
	else {
		nearest_z = 0;
		nearest = normalize(nearest);
	}
	if (physics_velocity * nearest <= 0)
		return nearest;
	else
		return v2;
}

void(void) physics_move {
	float bump;
	float t;
	float f;
	float blocked_prev = 0;
	float hitsomething = 0;
	vector neworigin;
	vector currentorigin2;
	vector neworigin2;
	vector prev_plane_normal = '0 0 0';
	vector trace1_endpos = '0 0 0';
	float trace1_fraction = 0;
	float trace2_fraction = 0;
	vector trace1_plane_normal = '0 0 0';
	vector trace2_plane_normal = '0 0 0';
	float halfgrav;
	halfgrav = physics_gravity_factor * sv_gravity * frametime * 0.5;
	physics_velocity_z -= halfgrav;
	vector primalvelocity = physics_velocity;
	for (bump = 0, t = frametime; bump < 8 && physics_velocity != '0 0 0'; bump++) {
		neworigin = self.origin + t * physics_velocity;
		trace_box(self.origin, self.mins, self.maxs, neworigin, TRACE_MOVE_NORMAL, self);
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
			if (trace1_plane_normal_z > 0 && trace1_plane_normal_z < 1 && (physics_flags & FL_ONGROUND) && self.mins_z + 0.03125 < self.maxs_z) { //prevent collision with wrong plane on stairs
				trace_box(self.origin, self.mins + '0 0 0.03125', self.maxs, neworigin, TRACE_MOVE_NORMAL, self);
				if (trace_plane_normal_z == 0 && vlen(trace1_endpos - trace_endpos) < 0.03125) {
					trace1_endpos = trace_endpos;
					trace1_fraction = trace_fraction;
					trace1_plane_normal = trace_plane_normal;
				}
			}
			if (trace1_plane_normal_z < 0.01 && trace1_plane_normal_z > -0.01) {
				t -= t * trace1_fraction;
				trace1_fraction = 0;
				// may be a step or wall, try stepping up
				// first move forward at a higher level
				currentorigin2 = trace1_endpos;
				currentorigin2_z += sv_stepheight;
				neworigin2 = trace1_endpos + t * physics_velocity;
				neworigin2_z = currentorigin2_z;
				trace_box(currentorigin2, self.mins, self.maxs, neworigin2, TRACE_MOVE_NORMAL, self);
				trace2_fraction = trace_fraction;
				trace2_plane_normal = trace_plane_normal;
				if not(trace_startsolid) {
					if (trace2_fraction > 0) {
						// then move down from there
						currentorigin2 = trace_endpos;
						neworigin2 = trace_endpos;
						neworigin2_z = trace1_endpos_z;
						trace_box(currentorigin2, self.mins, self.maxs, neworigin2, TRACE_MOVE_NORMAL, self);
						if (trace_plane_normal_z > 0.7 || trace_plane_normal == '0 0 0' || (physics_flags & FL_ONGROUND)) { //continue if step on ground or if already on ground, trace_plane_normal is 0-vector sometimes, engine bug?
							trace1_fraction = trace2_fraction;
							trace1_plane_normal = trace2_plane_normal;
							trace1_endpos = trace_endpos;
							if not(physics_flags & FL_ONGROUND)
								physics_velocity = physics_velocity * (1 - (trace_fraction * g_stepairslowdown));
						}
					} else if (g_climb && !(physics_flags & FL_ONGROUND) && physics_velocity_z < g_climb_speed && !physics_crouch) {
						makevectors(self.angles);
						if (trace1_plane_normal * v_forward < -0.5)
						if (trace1_plane_normal * physics_velocity < 0) {
							currentorigin2 = trace1_endpos;
							currentorigin2_z += g_climb_height;
							trace_box(trace1_endpos, self.mins, self.maxs, currentorigin2, TRACE_MOVE_NORMAL, self);
							if (trace_endpos_z - trace1_endpos_z > sv_stepheight) {
								neworigin2 = currentorigin2 - trace1_plane_normal * self.maxs_x * 0.5;
								trace_box(currentorigin2, self.crouch_mins, self.crouch_maxs, neworigin2, TRACE_MOVE_NORMAL, self);
								if (trace_fraction == 1) {
									currentorigin2 = trace_endpos;
									neworigin2_z = trace1_endpos_z;
									trace_box(currentorigin2, self.mins, self.maxs, neworigin2, TRACE_MOVE_NORMAL, self);
									if (trace_plane_normal_z > 0.7) { //continue if step on ground
										physics_velocity_z = max(physics_velocity_z, g_climb_speed);
										physics_velocity_x = physics_velocity_x * (1 - frametime * sv_friction);
										physics_velocity_y = physics_velocity_y * (1 - frametime * sv_friction);
										physics_flags |= FL_CLIMB;
									}
								}
							}
						}
					}
				}
			}
		}
		// check if it moved at all
		if (trace1_endpos == self.origin) {
			if (blocked_prev && prev_plane_normal * trace1_plane_normal < 0) {
				trace1_plane_normal = physics_bbox_nearest_normal(prev_plane_normal, trace1_plane_normal);
			} else {
				blocked_prev = 1;
			}
			prev_plane_normal = trace1_plane_normal;
		} else {
			setorigin(self, trace1_endpos);
			blocked_prev = 0;
		}
		// check if it moved all the way
		if (trace1_fraction == 1)
			break;

		t -= t * trace1_fraction;
		f = (physics_velocity * trace1_plane_normal);
		physics_velocity = physics_velocity - f * trace1_plane_normal;
	}
	if (physics_skimming > 0) {
		physics_velocity = primalvelocity;
		physics_skimming -= frametime;
		if (physics_skimming < 0)
			physics_skimming = 0;
	}
	physics_velocity_z -= halfgrav;
	if (g_velocity_rounding) {
		physics_velocity_x = floor(physics_velocity_x + 0.5);
		physics_velocity_y = floor(physics_velocity_y + 0.5);
		physics_velocity_z = floor(physics_velocity_z + 0.5);
	}
	if (g_overbounce)
	if not(physics_flags & FL_ONGROUND_OR_SLICK)
	if not(physics_button_jump) {
		if (physics_velocity_z < -sv_jumpvelocity) {
			trace_box(self.origin, self.mins, self.maxs, self.origin - '0 0 0.25', TRACE_MOVE_NORMAL, self);
			if (trace_fraction < 1 && trace_fraction > 0 && physics_velocity * trace_plane_normal < 0 && trace_plane_normal_z > 0.7) {
				f = physics_velocity * trace_plane_normal;
				vector v = physics_velocity - trace_plane_normal * f * 1.001;
				physics_velocity = vlen(physics_velocity) * normalize(v);
				#ifdef SVQC
				if (sv_overbounce_sound != "")
					player_sound(self, CHAN_PLAYER, sv_overbounce_sound, VOL_BASE, ATTN_NORM);
				#endif
			}
		}
	}
}

void(vector wishdir, float wishspeed) physics_aircontrol {
	float zspeed, xyspeed, dot, k;
	if (physics_movement_x == 0 || physics_movement_y != 0)
		return; // can't control movement if not moving forward or backward

	zspeed = physics_velocity_z;
	physics_velocity_z = 0;
	xyspeed = vlen(physics_velocity);
	physics_velocity = normalize(physics_velocity);
	dot = physics_velocity * wishdir;
	k = 32;
	k *= sv_aircontrol*dot*dot*frametime;
	if (dot > 0) // we can't change direction while slowing down
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
	if (sv_gameplayfix_q2airaccelerate)
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

	vector oldvel = physics_velocity;
	physics_velocity = vel_straight * wishdir + vel_z * '0 0 1' + vel_perpend;
}

void(vector wishdir, float wishspeed) physics_air_accelerate {
	vector curvel, wishvel, acceldir, curdir;
	float addspeed, accelspeed, curspeed, f;
	float dot;
	if (wishspeed == 0)
		return;

	curvel = physics_velocity;
	curvel_z = 0;
	curspeed = vlen(curvel);
	if (wishspeed > curspeed * 1.01) {
		wishspeed = min(wishspeed, curspeed + sv_warsowbunny_airforwardaccel * sv_maxspeed * frametime);
	} else {
		f = max(0, (sv_warsowbunny_topspeed - curspeed) / (sv_warsowbunny_topspeed - sv_maxspeed));
		wishspeed = max(curspeed, sv_maxspeed) + sv_warsowbunny_accel * f * sv_maxspeed * frametime;
	}
	wishvel = wishdir * wishspeed;
	acceldir = wishvel - curvel;
	addspeed = vlen(acceldir);
	acceldir = normalize(acceldir);
	accelspeed = min(addspeed, sv_warsowbunny_turnaccel * sv_maxspeed * frametime);
	if (sv_warsowbunny_backtosideratio < 1) {
		curdir = normalize(curvel);
		dot = acceldir * curdir;
		if (dot < 0)
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
	tap_direction_z = 0;
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
			self.lastkeys &= ~KEY_BACKWARD;
		} else
			self.lastkeys &= ~KEY_FORWARD;

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
			self.lastkeys &= ~KEY_FORWARD;
		} else
			self.lastkeys &= ~KEY_BACKWARD;

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
			self.lastkeys &= ~KEY_LEFT;
		} else
			self.lastkeys &= ~KEY_RIGHT;

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
			self.lastkeys &= ~KEY_RIGHT;
		} else
			self.lastkeys &= ~KEY_LEFT;
	}

	if (dodge_detected == 1) {
		vector dodge_velocity;
		if (physics_waterlevel >= WATER_LEVEL_SWIMMING)
			return;

		makevectors(self.angles);
		self.flags &= ~FL_ONGROUND;
		self.flags |= FL_DOUBLEJUMP; //prevent double jump after dodge
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
			player_sound(self, CHAN_PLAYER, sound_random_by_str(self.playersound_jump), VOL_BASE, ATTN_NORM);

		anim_set(self, self.anim_jump, TRUE, FALSE, TRUE);
#endif
		self.last_dodging_time = (frozen ? g_dodging_frozen_delay : g_dodging_delay);

	}
	return;
}

vector(void) physics_player_touch_wall {
	float dist, max_normal;
	vector start, end;
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
	if (physics_waterlevel >= WATER_LEVEL_SWIMMING)
		return;

	if (physics_cantjump)
		return;

	if (physics_movetype != MOVETYPE_WALK)
	if (physics_movetype != MOVETYPE_QCWALK)
		return;

	if (g_walljump)
	if not(physics_flags & FL_ONGROUND)
	if (self.lastwj <= 0) {
		makevectors(self.angles);
		vector plane_normal;
		plane_normal = physics_player_touch_wall();
		if (plane_normal != '0 0 0') {
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
			player_sound(self, CHAN_PLAYER, sound_random_by_str(self.playersound_jump), VOL_BASE, ATTN_NORM);
			#endif
		}
	}
	if (g_doublejump)
	if not(physics_flags & FL_DOUBLEJUMP)
	if (physics_flags & FL_JUMPRELEASED)
	if not(physics_flags & FL_ONGROUND)
	if (physics_velocity_z < sv_jumpvelocity * 0.5) {
		physics_flags |= FL_DOUBLEJUMP;
		physics_velocity_z = g_doublejump_speed;
		#ifdef SVQC
		self.oldvelocity_z = physics_velocity_z;
		pointparticles(particleeffectnum("smoke_ring"), self.origin, '0 0 1', 10);
		player_sound(self, CHAN_PLAYER, sound_random_by_str(self.playersound_jump), VOL_BASE, ATTN_NORM);
		#endif
	}
	if not(physics_flags & FL_ONGROUND_OR_SLICK)
		return;

	if ((physics_flags & FL_SLICK) && !g_slicksurfaces_allowjump)
		return;

	if not(sv_pogostick)
		if (!(physics_flags & FL_JUMPRELEASED))
			return;

	if (!(physics_lastflags & FL_ONGROUND) && (physics_flags & FL_ONGROUND)) {
		physics_skimming = g_skimming_time;
		physics_landing_hook();
	}
	if (g_cpmdoublejump && physics_cpmdoublejump_time > 0 && (!g_doublejump_nopogostick || (physics_flags & FL_JUMPRELEASED))) {
		if (physics_groundvelocity_dotproduct > 0)
			physics_velocity_z = max(sv_jumpvelocity * 1.3704, physics_velocity_z);
		else {
			float f = sv_jumpvelocity * 1.3704;
			physics_velocity_z = max(f, physics_velocity_z + f);
		}
	} else if (g_jumpvelocity_nodecrease) {
		float f = sv_jumpvelocity * physics_jump_velocity_mod();
		if (g_jumpvelocity_noincrease)
			physics_velocity_z = f;
		else {
			physics_velocity_z = max(f, ((physics_groundvelocity_dotproduct <= 0) ? physics_velocity_z + f : physics_velocity_z));
		}
	} else
		physics_velocity_z = physics_velocity_z + sv_jumpvelocity * physics_jump_velocity_mod();

	physics_cpmdoublejump_time = 0.4;
	physics_flags &= ~FL_ONGROUND_OR_SLICK;
	physics_flags &= ~FL_JUMPRELEASED;
	physics_on_jump_hook();
}

void(void) physics_check_water_jump {
	// check for a jump-out-of-water
	vector start, end;
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + (self.mins_z + self.maxs_z) * 0.5;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	trace_box(start, '-1 -1 -1', '1 1 1',  end, TRUE, self);
	if (trace_fraction < 1) { // solid at waist
		start_z = self.origin_z + self.maxs_z;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		trace_line (start, end, TRUE, self);
		if (trace_fraction == 1) { // open at eye level
			physics_flags |= FL_WATERJUMP;
			physics_velocity_z = sv_waterjumpvelocity;
			physics_flags &= ~FL_JUMPRELEASED;
			physics_teleport_time = 2;
			physics_check_water_jump_hook();
			return;
		}
	}
}

void(void) physics_player_frame {
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
	
	if (g_sideview) {
		if (physics_v_angle_y >= 90 && physics_v_angle_y < 270) physics_v_angle_y = 180;
		else if (physics_v_angle_y >= -270 && physics_v_angle_y < -90) physics_v_angle_y = 180;
		else physics_v_angle_y = 0;
		if (physics_movement_x) {
			if (physics_movement_x > 0) physics_movement_z = sv_maxspeed;
			else if (physics_movement_x < 0) physics_movement_z = -sv_maxspeed;
			physics_movement_x = 0;
		}
		if (physics_v_angle_y == 0) {
			if (physics_movement_y > 0) physics_movement_x = sv_maxspeed;
			else if (physics_movement_y < 0) physics_movement_x = -sv_maxspeed;
		} else {
			if (physics_movement_y > 0) physics_movement_x = -sv_maxspeed;
			else if (physics_movement_y < 0) physics_movement_x = sv_maxspeed;
		}
		physics_movement_y = 0;
	} else if (g_topview) {
		physics_v_angle_x = 0;
		makevectors(physics_v_angle - g_topview_angles_y * '0 1 0');
		vector m = -v_right * physics_movement_y + v_forward * physics_movement_x + physics_movement_z * '0 0 1';
		physics_movement = m;
	}
	physics_frame_begin_hook();
	if (physics_movetype == MOVETYPE_NONE)
		return;

	maxspd_mod = physics_max_speed_mod();
	if (physics_is_player) {
		if (physics_plug)
		if (physics_plug()) {
			physics_frame_end_hook();
			return;
		}
		physics_update_status();
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
				vector v;
				v_x = v_y = 0;
				v_z = self.stand_maxs_z - self.crouch_mins_z;
				trace_box(self.origin, self.stand_mins, self.stand_maxs - v, self.origin + v, FALSE, self);
				if (!trace_startsolid && trace_fraction == 1) {
					physics_crouch = FALSE;
					self.view_ofs = self.stand_view_ofs;
					setsize (self, self.stand_mins, self.stand_maxs);
				}
			}
		}
		// if dead, behave differently
		if (physics_deadflag != DEAD_NO)
		if (physics_deadflag != DEAD_FREEZE) {
			if (physics_flags & FL_ONGROUND)
				physics_velocity = '0 0 0';
			else if (physics_waterlevel >= WATER_LEVEL_SWIMMING)
				physics_velocity = physics_velocity * (1 - frametime * sv_friction);

			goto end;
		}
		physics_check_ground_hook();
		if (physics_button_jump)
			physics_player_jump();
		else {
			physics_flags |= FL_JUMPRELEASED;
			physics_dodging();
		}
		if (physics_waterlevel == WATER_LEVEL_SWIMMING)
		if not(physics_ladder)
		if (physics_deadflag == DEAD_NO)
			physics_check_water_jump();

		if (physics_player_plug)
		if (physics_player_plug(maxspd_mod))
			goto end;
	}
	if (physics_flags & FL_WATERJUMP) {
		physics_velocity_x = self.movedir_x;
		physics_velocity_y = self.movedir_y;
		if (physics_teleport_time < 0 || physics_waterlevel == WATER_LEVEL_NONE || physics_velocity_z < 0) {
			physics_flags &= ~FL_WATERJUMP;
			physics_teleport_time = 0;
		}
	} else if ((physics_flags & FL_ONGROUND) && physics_groundvelocity_dotproduct <= 0) {
		// walking
		makevectors(physics_v_angle_y * '0 1 0');
		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y;
		if not((physics_lastflags & FL_ONGROUND)) {
			physics_skimming = g_skimming_time;
			if (g_nofriction_cpm_hacks && physics_nofriction && physics_skimming) {
				physics_nofriction = physics_skimming;
			}
			physics_landing_hook();
		}
		v = physics_velocity;
		v_z = 0;
		f = vlen(v);
		if (f > 0) {
			float _friction;
			if ((physics_flags & FL_SLICK) || physics_nofriction > 0) {
				_friction = 0;
			} else
				_friction = sv_friction;

			if (f < sv_stopspeed) {
				f = 1 - frametime * (sv_stopspeed / f) * _friction;
			} else
				f = 1 - frametime * _friction;
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

		if (g_walk_align_to_ground && physics_ground_normal != '0 0 1') {
			f = vlen(physics_velocity);
			physics_velocity -= physics_ground_normal * (physics_velocity * physics_ground_normal);
			physics_velocity = normalize(physics_velocity) * f;
		}
	} else if (physics_flags & (FL_FLY | FL_SWIM)) { //NOCLIP or FLY
		physics_velocity = physics_velocity * (1 - frametime * sv_friction);
		if (g_sideview)
			makevectors(physics_v_angle_y * '0 1 0');
		else
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
	} else if (physics_waterlevel >= WATER_LEVEL_SWIMMING) {
		// swimming
		physics_flags &= ~FL_ONGROUND;
		if (g_sideview)
			makevectors(physics_v_angle_y * '0 1 0');
		else
			makevectors(physics_v_angle);

		physics_gravity_factor = 0;
		//wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + v_up * physics_movement_z;
		if (physics_button_jump)
			physics_movement_z = sv_maxspeed;

		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + '0 0 1' * physics_movement_z;
		if (physics_deadflag == DEAD_FREEZE) {
			if (physics_waterlevel >= WATER_LEVEL_SWIMMING)
				physics_accelerate('0 0 1', 0, sv_gravity * 0.25, sv_accelerate, 1, 0);
			else
				physics_accelerate('0 0 1', sv_gravity * 0.25, sv_gravity * 0.25, sv_accelerate, 1, 0);
		} else if (wishvel == '0 0 0') {
				wishvel_z = -sv_gravity * 0.075; // drift towards bottom
		}
		wishdir = normalize(wishvel);
		wishspeed = vlen(wishvel);
		if (wishspeed > g_maxwaterspeed * maxspd_mod)
			wishspeed = g_maxwaterspeed * maxspd_mod;

		// water friction
		physics_velocity = physics_velocity * max(0, 1 - frametime * g_waterfriction);
		// water acceleration
		physics_accelerate(wishdir, wishspeed, wishspeed, g_wateraccelerate*maxspd_mod, 1, 0);
	} else if (physics_ladder) {
		// on a spawnfunc_func_ladder or swimming in spawnfunc_func_water
		physics_flags &= ~FL_ONGROUND;
		if (g_sideview)
			makevectors(physics_v_angle_y * '0 1 0');
		else
			makevectors(physics_v_angle);

		//wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + v_up * physics_movement_z;
		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y + '0 0 1' * physics_movement_z;
		if (physics_button_jump)
			wishvel_z = wishvel_z + sv_jumpvelocity;

		physics_gravity_factor = 0;
		physics_velocity = physics_velocity * max(0, 1 - frametime * sv_friction);
		if (physics_ladder_iswater) {
			f = vlen(wishvel);
			if (f > physics_ladder_speed)
				wishvel = wishvel * (physics_ladder_speed / f);

			physics_watertype = physics_ladder_watertype;
			f = physics_ladder_top;
			if ((self.origin_z + self.view_ofs_z) < f)
				physics_waterlevel = WATER_LEVEL_SUBMERGED;
			else if ((self.origin_z + (self.mins_z + self.maxs_z) * 0.5) < f)
				physics_waterlevel = WATER_LEVEL_SWIMMING;
			else if ((self.origin_z + self.mins_z + 1) < f)
				physics_waterlevel = WATER_LEVEL_WETFEET;
			else {
				physics_waterlevel = WATER_LEVEL_NONE;
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
		float maxspd_mod2 = min(1, maxspd_mod);
		maxairspd = sv_maxairspeed*maxspd_mod2;
		airaccel = sv_airaccelerate*maxspd_mod2;
		// airborn
		makevectors(physics_v_angle_y * '0 1 0');
		wishvel = v_forward * physics_movement_x + v_right * physics_movement_y;
		// acceleration
		wishdir = normalize(wishvel);
		wishspeed = wishspeed0 = vlen(wishvel);
		if (wishspeed0 > sv_maxspeed*maxspd_mod2)
			wishspeed0 = sv_maxspeed*maxspd_mod2;

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
					airaccel = sv_airstopaccelerate*maxspd_mod2;

			if (physics_movement_x == 0 && physics_movement_y != 0) {
				if (sv_maxairstrafespeed) {
					wishspeed = min(wishspeed, sv_maxairstrafespeed*maxspd_mod2);
					if (sv_maxairstrafespeed < sv_maxairspeed)
						airaccelqw = 1;
				}
				if (sv_airstrafeaccelerate) {
					airaccel = sv_airstrafeaccelerate*maxspd_mod2;
					if (sv_airstrafeaccelerate > sv_airaccelerate)
						airaccelqw = 1;
				}
			}
			// !CPM
			if (sv_warsowbunny_turnaccel && accelerating && physics_movement_y == 0 && physics_movement_x != 0)
				physics_air_accelerate(wishdir, wishspeed);
			else
				physics_accelerate(wishdir, wishspeed, wishspeed0, airaccel, airaccelqw, sv_airaccel_sideways_friction / maxairspd);

			if (sv_aircontrol)
				physics_aircontrol(wishdir, wishspeed2);
		}
	}
:end
	if (physics_flags & (FL_SWIM | FL_FLY)) { //CHEATS
		if (physics_flags & FL_SWIM) //NOCLIP
			setorigin(self, self.origin + physics_velocity * frametime);
		else { //FLY
			float gs = sv_gravity;
			sv_gravity = 0;
			physics_move();
			sv_gravity = gs;
		}
	} else if (physics_movetype == MOVETYPE_QCWALK)
		physics_move();

	if (g_adjust_view_offset)
	if (physics_is_player) {
		if (physics_crouch)
			trace_line(self.origin, self.origin + self.crouch_view_ofs + '0 0 2', TRACE_MOVE_WORLDONLY, self);
		else
			trace_line(self.origin, self.origin + self.stand_view_ofs + '0 0 2', TRACE_MOVE_WORLDONLY, self);

		if (trace_fraction < 1)
			self.view_ofs = trace_endpos - self.origin - '0 0 2';
	}
	physics_frame_end_hook();
}

void(void) physics_player {
	if (g_physics_fixed) {
		float oldframetime = frametime;
		float f = frametime + physics_frametime_accumulator;
		frametime = 0.008;
		for ( ; f > 0.000;) {
			physics_player_frame();
			f -= 0.008;
			if (f < 0.004) {
				break;
			}
		}
		physics_frametime_accumulator = f;
		frametime = oldframetime;
	} else
		physics_player_frame();
}
