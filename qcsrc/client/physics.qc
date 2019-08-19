#define PMF_JUMP_HELD 1
#define PMF_DUCKED 4
#define PMF_ONGROUND 8

.float pmove_flags;
float physics_button_crouch;
float pmove_onground;
float physics_maxspeedmod;
float physics_jump_velocity_factor;
float physics_start_teleport_time;
float physics_start_crouch;
float physics_start_flags_jumpreleased;

vector vehicle_adjust_view() {
	makevectors(view_angles);
	vector v = view_origin;
	v_z += vehicle_adjust_view_start_offs;
	tracebox(v, '-8 -8 -8', '8 8 8', v - v_forward * vehicle_adjust_view_back, MOVE_WORLDONLY, world);
	v = trace_endpos;
	tracebox(v, '-8 -8 -8', '8 8 8', v  + v_up * vehicle_adjust_view_up, MOVE_WORLDONLY, world);
	v = trace_endpos;
	return v;
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
}

void(void) physics_frame_end_hook {
	physics_teleport_time -= frametime;
	if (physics_movetype == MOVETYPE_NOCLIP) {
		setorigin(self, self.origin + (physics_velocity * frametime));
	}
}

entity physics;

float stairsmoothz;
.vector pmove_origin;
.vector pmove_velocity;
float was_teleported;
float physics_lastwj;
float physics_last_dodging;
float physics_last_FORWARD_KEY_time;
float physics_last_BACKWARD_KEY_time;
float physics_last_RIGHT_KEY_time;
float physics_last_LEFT_KEY_time;
vector CSQCPhysic_SetViewOrg()
{
	vector v;
	if(physics && servercommandframe && clientcommandframe && (!spectatee_status || observer_status))
	{
		float frametime_save = frametime;
		float i;
		float n = clientcommandframe + 1;
		entity oldself = self;
		self = physics;
		self.origin = self.pmove_origin;
		pmove_org = self.origin;
		self.velocity = physics_velocity = self.pmove_velocity;
		physics_teleport_time = physics_start_teleport_time;
		physics_deadflag = player_deadflag;
		physics_cantjump = (physics_deadflag != DEAD_NO);
		if (physics_start_flags_jumpreleased)
			physics_flags = FL_JUMPRELEASED;
		else
			physics_flags = 0;

		if (physics_plug_pre)
			physics_plug_pre();

		physics_crouch = physics_start_crouch;
		if (physics_start_crouch)
		{
			setsize(self, self.crouch_mins, self.crouch_maxs);
			self.view_ofs = self.crouch_view_ofs;
		}
		else
		{
			setsize(self, self.stand_mins, self.stand_maxs);
			self.view_ofs = self.stand_view_ofs;
		}
		
		self.lastwj = physics_lastwj;
		if (g_dodging || g_dodging_frozen) {
			self.last_dodging_time = physics_last_dodging;
			self.last_FORWARD_KEY_time = physics_last_FORWARD_KEY_time;
			self.last_BACKWARD_KEY_time = physics_last_BACKWARD_KEY_time;
			self.last_RIGHT_KEY_time = physics_last_RIGHT_KEY_time;
			self.last_LEFT_KEY_time = physics_last_LEFT_KEY_time;
			self.lastkeys = getstatf(STAT_PRESSED_KEYS);
		}
		for (i = servercommandframe + 1; i <= n; i++)
		{
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
			if (!(physics_flags & FL_ONGROUND) || physics_start_teleport_time > 0 || was_teleported) {
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
		R_SetView(VF_ORIGIN, v);
	}
	else {
		v = pmove_org + '0 0 1' * getstati(STAT_VIEWHEIGHT);
		if (camera_correction_needed) {
			if not(CVAR(chase_active))
				R_SetView(VF_ORIGIN, v);

			camera_correction_needed = FALSE;
		}
	}

	return v;
}

void CSQCPhysic_SetCamera() {
	if (physics)
	if (servercommandframe)
	if (clientcommandframe) {
		vector v;
		if (physics_plug_adjust_view)
			v = physics_plug_adjust_view();
		else
			v = view_origin;

		if (CVAR(chase_active)) {
			makevectors(view_angles);
			tracebox(v, '-4 -4 -4', '4 4 4', v - v_forward * CVAR(chase_back), MOVE_NORMAL, world);
			v = trace_endpos;
			tracebox(v, '-4 -4 -4', '4 4 4', v + v_up * CVAR(chase_up), MOVE_NORMAL, world);
			v = trace_endpos;
		}
		R_SetView(VF_ORIGIN, v);
	}
}

void Ent_Physic(float isnew)
{
	float f = ReadShort();
	physics = self;
	if (f & 1)
	{
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
		sv_friction_on_land = ReadCoord();
		float switches = ReadByte();
		sv_slicksurfaces_allowjump = switches & 2;
		sv_pogostick = switches & 4;
		sv_disable_crouch = switches & 8;
		sv_gameplayfix_q2airaccelerate = switches & 16;
		g_walljump = switches & 32;
		g_dodging = switches & 64;
		g_dodging_frozen = switches & 128;
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
	}
	if (f & 2)
	{
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
	if (f & 4)
	{
		self.pmove_origin_x = ReadCoord();
		self.pmove_origin_y = ReadCoord();
		self.pmove_origin_z = ReadCoord();
		self.pmove_velocity_x = ReadCoord();
		self.pmove_velocity_y = ReadCoord();
		self.pmove_velocity_z = ReadCoord();
		physics_is_player = f & 8;
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
		}
		else
		{
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
			self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BODY;

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
		if (f & 16384) {
			float dodging_flags = ReadByte();
			if (dodging_flags & 1) physics_last_dodging = ReadCoord();
			if (dodging_flags & 2) physics_last_FORWARD_KEY_time = ReadCoord();
			if (dodging_flags & 4) physics_last_BACKWARD_KEY_time = ReadCoord();
			if (dodging_flags & 8) physics_last_LEFT_KEY_time = ReadCoord();
			if (dodging_flags & 16) physics_last_RIGHT_KEY_time = ReadCoord();
		}
	}
}
