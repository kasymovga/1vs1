#define PMF_JUMP_HELD 1
#define PMF_DUCKED 4
#define PMF_ONGROUND 8

.float pmove_flags;
float physics_button_crouch;
float physics_maxspeedmod;
float physics_jump_velocity_factor;
float physics_start_teleport_time;
float physics_start_crouch;
float physics_start_flags_jumpreleased;
float physics_start_flags_doublejump;
float physics_start_frametime_accumulator;
float physics_ground_time;
float physics_ground_curtime;
float physics_ground_oldtime;
vector physics_ground_origin;
vector physics_ground_oldorigin;
float physics_ground_lastent;
entity physics;
float physics_skimming_start;
float physics_cpmdoublejump_time_start;

vector(void) physics_side_adjust_view {
	makevectors('0 90 0');
	vector o = view_origin - v_forward * 500 + '0 0 1' * g_sideview_up;
	if not(main_isdemo) {
		mouse_enable("gfx/crosshairuzi");
		vector v = mouse_position();
		vector v2;
		float f = CVAR(vid_conwidth) * 0.5;
		v2_x = tan(view_fovx * 0.5 * MATH_DEG2RAD) * (v_x - f) / f;
		f = CVAR(vid_conheight) * 0.5;
		v2_y = tan(view_fovy * 0.5 * MATH_DEG2RAD) * (v_y - f) / f;
		v2_z = 0;
		vector v3 = o + v_forward * 200 - v_up * v2_y * 200 + v_right * v2_x * 200;
		//pointparticles(particleeffectnum("laser_impact"), v3, '0 0 0', 0.01);
		view_angles = vectoangles(WarpZone_PlaneAndLineCross(view_origin, v_forward, o, normalize(v3 - o)) - view_origin);
		view_angles_z = 0;
		view_angles_x = -view_angles_x;
		R_SetView(VF_CL_VIEWANGLES, view_angles);
	}
	view_fixangle = TRUE;
	view_fixed_angles = '0 90 0';
	view_crosshair = FALSE;
	if (view_width / view_height > 1.35)
		view_fov = 105;
	else
		view_fov = 115;

	return o;
}

vector(void) physics_top_adjust_view {
	makevectors(g_topview_angles);
	vector o = view_origin - v_forward * 500;
	if not(main_isdemo) {
		mouse_enable("gfx/crosshairuzi");
		vector v = mouse_position();
		vector v2;
		float f = CVAR(vid_conwidth) * 0.5;
		v2_x = tan(view_fovx * 0.5 * MATH_DEG2RAD) * (v_x - f) / f;
		f = CVAR(vid_conheight) * 0.5;
		v2_y = tan(view_fovy * 0.5 * MATH_DEG2RAD) * (v_y - f) / f;
		v2_z = 0;
		vector v3 = o + v_forward * 200 - v_up * v2_y * 200 + v_right * v2_x * 200;
		view_angles = vectoangles(WarpZone_PlaneAndLineCross(view_origin, '0 0 1', v3, v_forward) - view_origin);
		view_angles_x = 0;
		R_SetView(VF_CL_VIEWANGLES, view_angles);
	}
	view_fixangle = TRUE;
	view_fixed_angles = g_topview_angles;
	view_crosshair = FALSE;
	if (view_width / view_height > 1.35)
		view_fov = 105;
	else
		view_fov = 115;

	return o;
}

vector(void) physics_vehicle_adjust_view {
	view_vehicle = TRUE;
	makevectors(view_angles);
	vector v = view_origin;
	tracebox(v, '-8 -8 -8', '8 8 8', v - v_forward * vehicle_adjust_view_back, TRACE_MOVE_WORLDONLY, world);
	v = trace_endpos;
	tracebox(v, '-8 -8 -8', '8 8 8', v  + v_up * vehicle_adjust_view_up, TRACE_MOVE_WORLDONLY, world);
	v = trace_endpos;
	return v;
}

void(entity e) physics_vehicle_common_post {
	if (main_ext_DP_RM_SETRENDERENTITY)
		setentityvec(physics_player_ent, E_ORIGIN, e.origin);

	physics_flags = self.flags;
	setorigin(physics, e.origin + '0 0 1' * vehicle_adjust_view_start_offs - physics.view_ofs);
}

float(void) physics_max_speed_mod {
	return physics_maxspeedmod;
}

float(void) physics_jump_velocity_mod {
	return physics_jump_velocity_factor;
}

void(void) physics_check_ground_hook {
}

void(void) physics_check_water_jump_hook {
}

void(void) physics_on_jump_hook {
}

void(void) physics_on_crouch_hook {
}

void(void) physics_landing_hook {
}

void(void) physics_frame_begin_hook {
	physics_velocity_frame_begin = physics_velocity;
}

void(void) physics_frame_end_hook {
	physics_teleport_time -= frametime;
	if (physics_movetype == MOVETYPE_NOCLIP) {
		setorigin(self, self.origin + (physics_velocity * frametime));
	}
	physics_velocity_frame_end = physics_velocity;
	physics_frametime = frametime;
}

float stairsmoothz;
.vector pmove_velocity;
float was_teleported;
float physics_lastwj;
float physics_last_dodging;
float physics_last_FORWARD_KEY_time;
float physics_last_BACKWARD_KEY_time;
float physics_last_RIGHT_KEY_time;
float physics_last_LEFT_KEY_time;
vector(void) physics_view_origin {
	vector v;
	if (physics && servercommandframe && clientcommandframe && (!view_spectatee_status || view_observer_status)) {
		float frametime_save = frametime;
		float i;
		float n = clientcommandframe + 1;
		physics_skimming = physics_skimming_start;
		physics_cpmdoublejump_time = physics_cpmdoublejump_time_start;
		entity oldself = self;
		self = physics;
		self.velocity = physics_velocity = self.pmove_velocity;
		physics_teleport_time = physics_start_teleport_time;
		physics_deadflag = player_deadflag;
		physics_cantjump = (physics_deadflag != DEAD_NO);
		if (physics_start_flags_jumpreleased)
			physics_flags = FL_JUMPRELEASED;
		else
			physics_flags = 0;

		if (physics_start_flags_doublejump)
			physics_flags |= FL_DOUBLEJUMP;

		if (physics_plug_pre)
			physics_plug_pre();

		physics_crouch = physics_start_crouch;
		if (physics_start_crouch) {
			setsize(self, self.crouch_mins, self.crouch_maxs);
			self.view_ofs = self.crouch_view_ofs;
		} else {
			setsize(self, self.stand_mins, self.stand_maxs);
			self.view_ofs = self.stand_view_ofs;
		}
		self.origin = physics_start_origin;
		if (physics_ground_lastent)
		if (physics_ground_origin != physics_ground_oldorigin) {
			float f;
			f = max(0, (physics_ground_curtime - physics_ground_oldtime) / (physics_ground_time - physics_ground_oldtime));
			physics_ground_curtime += frametime;
			vector ground_curorigin = (1 - f) * physics_ground_oldorigin + f * physics_ground_origin;
			self.origin = physics_start_origin - (physics_ground_origin - ground_curorigin);
			tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 8', TRACE_MOVE_NOMONSTERS, self);
			if not(trace_startsolid)
				self.origin = trace_endpos;
		}
		pmove_org = self.origin;
		self.lastwj = physics_lastwj;
		if (g_dodging || g_dodging_frozen) {
			self.last_dodging_time = physics_last_dodging;
			self.last_FORWARD_KEY_time = physics_last_FORWARD_KEY_time;
			self.last_BACKWARD_KEY_time = physics_last_BACKWARD_KEY_time;
			self.last_RIGHT_KEY_time = physics_last_RIGHT_KEY_time;
			self.last_LEFT_KEY_time = physics_last_LEFT_KEY_time;
			self.lastkeys = getstatf(STAT_PRESSED_KEYS);
		}
		physics_frametime_accumulator = physics_start_frametime_accumulator;
		for (i = servercommandframe + 1; i <= n; i++) {
			if not(RetrieveMovementFrame(i))
				break;

			if (warpzone_view)
			if (i >= warpzone_view_commandframe) {
				//print("warp input angles correction ", ftos(i), " ", vtos(input_angles));
				input_angles = WarpZone_UnTransformAngles(warpzone_view, input_angles);
				//print(" ", vtos(input_angles), "\n");
			}
			frametime = input_timelength;
			physics_button_crouch = input_buttons & 16;
			physics_movement = input_movevalues;
			physics_v_angle = input_angles;
			physics_button_jump = input_buttons & 2;
			self.angles_y = input_angles_y;
			physics_player();
		}
		physics_lastcommandframe = i;
		if (physics_plug_post)
			physics_plug_post();

		self = oldself;
		frametime = frametime_save;
		v = physics.origin + physics.view_ofs;
		if (CVAR(cl_stairsmoothspeed)) {
			if (!(physics_flags & FL_ONGROUND) || physics_start_teleport_time > 0 || was_teleported || physics_ground_lastent) {
				stairsmoothz = v_z;
				was_teleported = FALSE;
			} else {
				if (v_z > stairsmoothz) {
					v_z = bound(v_z - sv_stepheight, stairsmoothz + frametime * autocvar_cl_stairsmoothspeed, v_z);
				} else {
					v_z = bound(v_z, stairsmoothz - frametime * autocvar_cl_stairsmoothspeed, v_z + sv_stepheight);
				}
				stairsmoothz = v_z;
			}
		}
		if not(view_camera_active)
			R_SetView(VF_ORIGIN, v);

		physics_end_origin = physics.origin;
	} else {
		physics_end_origin = pmove_org;
		v = physics_end_origin + '0 0 1' * getstati(STAT_VIEWHEIGHT);
		if (view_camera_correction_needed) {
			if not(CVAR(chase_active))
			if not(view_camera_active)
				R_SetView(VF_ORIGIN, v);

			view_camera_correction_needed = FALSE;
		}
	}
	return v;
}

void(void) physics_camera_setup {
	if (physics) {
		if (physics_plug_adjust_view) {
			view_camera_origin = physics_plug_adjust_view();
		} else
			view_camera_origin = view_origin;

		if not(view_camera_active) {
			if not(view_spectatee_status)
			if not(physics_player_ent) {
				if (main_ext_DP_RM_SETRENDERENTITY) {
					if not(main_isdemo)
						setentityvec(player_localentnum, E_ORIGIN, physics.origin);
				} else {
					if (CVAR(chase_active))
						physics_end_origin = physics_start_origin;
				}
			}
			if (CVAR(chase_active) && !physics_plug_adjust_view) {
				makevectors(view_angles);
				tracebox(view_camera_origin, '-4 -4 -4', '4 4 4', view_camera_origin - v_forward * CVAR(chase_back), TRACE_MOVE_NORMAL, world);
				view_camera_origin = trace_endpos;
				tracebox(view_camera_origin, '-4 -4 -4', '4 4 4', view_camera_origin + v_up * CVAR(chase_up), TRACE_MOVE_NORMAL, world);
				view_camera_origin = trace_endpos;
			}
			R_SetView(VF_ORIGIN, view_camera_origin);
		}
	} else {
		view_camera_origin = view_origin;
	}
}

float physics_player_content;
void(float isnew) physics_read {
	float f = ReadShort();
	float f2;
	if (f & 16384)
		f2 = ReadByte();
	else
		f2 = 0;

	physics = self;
	if (f & 1) {
		if (cvar("cl_movement_replay"))
			cvar_clientsettemp("cl_movement_replay", "0");

		sv_stepheight = ReadCoord();
		g_stepairslowdown = ReadCoord();
		sv_gravity = ReadCoord();
		sv_maxairspeed = ReadCoord();
		sv_maxspeed = ReadCoord();
		sv_friction = ReadCoord();
		sv_accelerate = ReadCoord();
		sv_airaccelerate = ReadCoord();
		sv_airaccel_sideways_friction = ReadCoord();
		sv_airaccel_qw = ReadCoord();
		sv_stopspeed = ReadCoord();
		sv_airstopaccelerate = ReadCoord();
		sv_airstrafeaccelerate = ReadCoord();
		sv_maxairstrafespeed = ReadCoord();
		sv_aircontrol = ReadCoord();
		sv_warsowbunny_turnaccel = ReadCoord();
		sv_warsowbunny_airforwardaccel = ReadCoord();
		sv_warsowbunny_accel = ReadCoord();
		sv_warsowbunny_topspeed = ReadCoord();
		sv_warsowbunny_backtosideratio = ReadCoord();
		sv_jumpvelocity = ReadCoord();
		sv_waterjumpvelocity = ReadCoord();
		g_skimming_time = ReadCoord();
		g_waterfriction = ReadCoord();
		g_wateraccelerate = ReadCoord();
		g_maxwaterspeed = ReadCoord();
		g_climb_height = ReadCoord();
		if (g_climb_height)
			g_climb_speed = ReadCoord();

		float switches = ReadCoord();
		g_slicksurfaces_allowjump = switches & 2;
		sv_pogostick = switches & 4;
		sv_disable_crouch = switches & 8;
		sv_gameplayfix_q2airaccelerate = switches & 16;
		g_walljump = switches & 32;
		g_dodging = switches & 64;
		g_dodging_frozen = switches & 128;
		if (switches & 256) //g_playerclip_collisions
			physics_player_content = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
		else
			physics_player_content = DPCONTENTS_SOLID;

		if not(switches & 512) //mod_q3bsp_curves_collisions
			cvar_clientsettemp("mod_q3bsp_curves_collisions" , "0");

		if (switches & 8192) //mod_collision_bih
			cvar_clientsettemp("mod_collision_bih" , "1");
		else
			cvar_clientsettemp("mod_collision_bih" , "0");

		g_q2doublejump = switches & 1024;
		g_doublejump_nopogostick = switches & 2048;
		g_slicksurfaces_levitation = switches & 4096;
		g_jumpvelocity_nodecrease = switches & 16384;
		g_cpmdoublejump = switches & 32768;
		g_jumpvelocity_noincrease = switches & 65536;
		g_physics_fixed = switches & 131072;
		g_adjust_view_offset = switches & 262144;
		if (switches & 524288) //collision_triangle_directional
			cvar_clientsettemp("collision_triangle_directional" , "-1");
		else if (switches & 1048576)
			cvar_clientsettemp("collision_triangle_directional" , "1");
		else
			cvar_clientsettemp("collision_triangle_directional" , "0");

		g_sideview = switches & 2097152;
		g_topview = switches & 4194304;
		g_doublejump = switches & 8388608;
		if (g_sideview)
			physics_plug_adjust_view = physics_side_adjust_view;
		else if (g_topview)
			physics_plug_adjust_view = physics_top_adjust_view;

		physics_have_doubjejump = (g_q2doublejump || g_cpmdoublejump);
		if (g_walljump) {
			g_walljump_delay = ReadCoord();
			g_walljump_force = ReadCoord();
			g_walljump_velocity_xy_factor = ReadCoord();
			g_walljump_velocity_z_factor = ReadCoord();
		}
		if (g_dodging || g_dodging_frozen) {
			g_dodging_horiz_speed = ReadCoord();
			g_dodging_up_speed = ReadCoord();
			g_dodging_delay = ReadCoord();
			g_dodging_frozen_delay = ReadCoord();
			g_dodging_frozen_factor = ReadCoord();
		}
		if (g_sideview) {
			g_sideview_up = ReadShort();
		}
		if (g_topview) {
			g_topview_angles_x = ReadShort();
			g_topview_angles_y = ReadShort();
		}
	}
	if (f & 2) {
		self.crouch_mins_x = ReadCoord();
		self.crouch_mins_y = ReadCoord();
		self.crouch_mins_z = ReadCoord();
		self.crouch_maxs_x = ReadCoord();
		self.crouch_maxs_y = ReadCoord();
		self.crouch_maxs_z = ReadCoord();
		self.stand_mins_x = ReadCoord();
		self.stand_mins_y = ReadCoord();
		self.stand_mins_z = ReadCoord();
		self.stand_maxs_x = ReadCoord();
		self.stand_maxs_y = ReadCoord();
		self.stand_maxs_z = ReadCoord();
		self.crouch_view_ofs_x = ReadCoord();
		self.crouch_view_ofs_y = ReadCoord();
		self.crouch_view_ofs_z = ReadCoord();
		self.stand_view_ofs_x = ReadCoord();
		self.stand_view_ofs_y = ReadCoord();
		self.stand_view_ofs_z = ReadCoord();
	}
	if (f & 4) {
		physics_start_origin_x = ReadCoord();
		physics_start_origin_y = ReadCoord();
		physics_start_origin_z = ReadCoord();
		physics_velocity_frame_begin = self.pmove_velocity;
		self.pmove_velocity_x = ReadCoord();
		self.pmove_velocity_y = ReadCoord();
		self.pmove_velocity_z = ReadCoord();
		physics_velocity_frame_end = self.pmove_velocity;
		physics_frametime = server_ticrate;
		physics_is_player = f & 8;
		self.solid = (physics_is_player ? SOLID_SLIDEBOX : SOLID_NOT);
		physics_ladder = f & 32;
		physics_ladder_iswater = f & 64;
		physics_start_flags_jumpreleased = f & 128;
		physics_start_crouch = f & 256;
		if (physics_ladder && physics_ladder_iswater) {
			physics_ladder_speed = ReadCoord();
			physics_ladder_watertype = ReadCoord();
			physics_ladder_top = ReadCoord();
		}
		if (f & 512) {
			physics_maxspeedmod = ReadCoord();
			physics_jump_velocity_factor = ReadCoord();
		} else {
			physics_maxspeedmod = 1;
			physics_jump_velocity_factor = 1;
		}
		if (f & 1024)
			physics_movetype = ReadByte();
		else
			physics_movetype = MOVETYPE_QCWALK;

		if (physics_movetype == MOVETYPE_NOCLIP)
			self.dphitcontentsmask = 0;
		else
			self.dphitcontentsmask = physics_player_content;

		if (f & 2048)
			physics_gravity_factor = ReadCoord();
		else
			physics_gravity_factor = 1;

		if (f & 4096) {
			physics_start_teleport_time = ReadCoord();
			was_teleported = TRUE;
		} else
			physics_start_teleport_time = -1;

		if (f & 8192) {
			physics_lastwj = ReadCoord();
		} else
			physics_lastwj = 0;

		if (g_dodging) {
			physics_last_dodging = 0;
			physics_last_FORWARD_KEY_time = 0;
			physics_last_BACKWARD_KEY_time = 0;
			physics_last_LEFT_KEY_time = 0;
			physics_last_RIGHT_KEY_time = 0;
		}
		if (f2 & 4) {
			float dodging_flags = ReadByte();
			if (dodging_flags & 1) physics_last_dodging = ReadCoord();
			if (dodging_flags & 2) physics_last_FORWARD_KEY_time = ReadCoord();
			if (dodging_flags & 4) physics_last_BACKWARD_KEY_time = ReadCoord();
			if (dodging_flags & 8) physics_last_LEFT_KEY_time = ReadCoord();
			if (dodging_flags & 16) physics_last_RIGHT_KEY_time = ReadCoord();
		}
		if (f2 & 8) {
			physics_start_frametime_accumulator = ReadCoord();
		}
		if (f & 32768) {
			physics_ground_oldorigin = physics_ground_origin;
			physics_ground_curtime = physics_ground_oldtime = physics_ground_time;
			float ground_ent = ReadCoord();
			physics_ground_origin_x = ReadCoord();
			physics_ground_origin_y = ReadCoord();
			physics_ground_origin_z = ReadCoord();
			physics_ground_time = time;
			if (physics_ground_lastent != ground_ent) {
				physics_ground_oldorigin = physics_ground_origin;
				physics_ground_oldtime = physics_ground_time;
				physics_ground_lastent = ground_ent;
			}
		} else {
			physics_ground_lastent = 0;
		}
		if (f2 & 1) {
			physics_skimming_start = ReadCoord();
		} else {
			physics_skimming_start = 0;
		}
		if (f2 & 2) {
			physics_cpmdoublejump_time_start = ReadCoord();
		} else {
			physics_cpmdoublejump_time_start = 0;
		}
		physics_start_flags_doublejump = f2 & 16;
	}
}
