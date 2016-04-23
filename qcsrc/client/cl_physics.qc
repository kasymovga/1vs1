#define PMF_JUMP_HELD 1
#define PMF_DUCKED 4
#define PMF_ONGROUND 8

.float pmove_flags;
float physic_button_crouch;
float pmove_onground;
float physic_maxspeedmod;
float physic_jump_velocity_factor;


const float unstick_count = 27;
vector unstick_offsets[unstick_count] =
{
// 1 no nudge (just return the original if this test passes)
	'0.000   0.000  0.000',
// 6 simple nudges
	' 0.000  0.000  0.125', '0.000  0.000 -0.125',
	'-0.125  0.000  0.000', '0.125  0.000  0.000',
	' 0.000 -0.125  0.000', '0.000  0.125  0.000',
// 4 diagonal flat nudges
	'-0.125 -0.125  0.000', '0.125 -0.125  0.000',
	'-0.125  0.125  0.000', '0.125  0.125  0.000',
// 8 diagonal upward nudges
	'-0.125  0.000  0.125', '0.125  0.000  0.125',
	' 0.000 -0.125  0.125', '0.000  0.125  0.125',
	'-0.125 -0.125  0.125', '0.125 -0.125  0.125',
	'-0.125  0.125  0.125', '0.125  0.125  0.125',
// 8 diagonal downward nudges
	'-0.125  0.000 -0.125', '0.125  0.000 -0.125',
	' 0.000 -0.125 -0.125', '0.000  0.125 -0.125',
	'-0.125 -0.125 -0.125', '0.125 -0.125 -0.125',
	'-0.125  0.125 -0.125', '0.125  0.125 -0.125',
};

void PM_ClientMovement_Unstick()
{
	float i;
	for (i = 0; i < unstick_count; i++)
	{
		vector neworigin = unstick_offsets[i] + self.origin;
		tracebox(neworigin, self.crouch_mins, self.crouch_maxs, neworigin, MOVE_NORMAL, self);
		if (!trace_startsolid)
		{
			setorigin(self, neworigin);
			return;// true;
		}
	}
}

void PM_ClientMovement_UpdateStatus(float ground)
{
	// make sure player is not stuck
	PM_ClientMovement_Unstick();

	// set crouched
	if (physic_button_crouch)
	{
		// wants to crouch, this always works..
		if (!physic_crouch)
		{
			physic_crouch = TRUE;
			self.mins = self.crouch_mins;
			self.maxs = self.crouch_maxs;
			self.view_ofs = self.crouch_view_ofs;
		}
	}
	else
	{
		// wants to stand, if currently crouching we need to check for a
		// low ceiling first
		if (physic_crouch)
		{
			tracebox(self.origin, self.stand_mins, self.stand_maxs, self.origin, MOVE_NORMAL, self);
			if (!trace_startsolid)
			{
				physic_crouch = FALSE;
				self.mins = self.stand_mins;
				self.maxs = self.stand_maxs;
				self.view_ofs = self.stand_view_ofs;
			}
		}
	}

	if(ground)
	{
		tracebox(self.origin + '0 0 1', self.mins, self.maxs, self.origin - '0 0 1', MOVE_NORMAL, self);
		float f;
		if (trace_fraction < 1.0 && trace_plane_normal_z > 0.7)// && (f = self.velocity * trace_plane_normal) <= 0)
		{
			physic_flags |= FL_ONGROUND;

			// this code actually "predicts" an impact; so let's clip velocity first
			self.velocity -= f * trace_plane_normal;
		}
		else
		{
			physic_flags &~= FL_ONGROUND;
		}
	}

	// set watertype/waterlevel
	vector origin1 = self.origin;
	origin1_z += self.mins_z + 1;
	physic_waterlevel = WATERLEVEL_NONE;

	float thepoint = pointcontents(origin1);

	physic_watertype = (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME);

	if(physic_watertype)
	{
		physic_waterlevel = WATERLEVEL_WETFEET;
		origin1_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		thepoint = pointcontents(origin1);
		if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
		{
			physic_waterlevel = WATERLEVEL_SWIMMING;
			origin1_z = self.origin_z + 22;
			thepoint = pointcontents(origin1);
			if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
				physic_waterlevel = WATERLEVEL_SUBMERGED;
		}
	}

}

void PM_ClientMovement_Move()
{
	float bump;
	float t;
	float f;
	vector neworigin;
	vector currentorigin2;
	vector neworigin2;
	vector primalvelocity;

	vector trace1_endpos = '0 0 0';
	vector trace2_endpos = '0 0 0';
	vector trace3_endpos = '0 0 0';
	float trace1_fraction = 0;
	float trace2_fraction = 0;
	float trace3_fraction = 0;
	vector trace1_plane_normal = '0 0 0';
	vector trace2_plane_normal = '0 0 0';
	vector trace3_plane_normal = '0 0 0';
	primalvelocity = physic_velocity;
	for(bump = 0, t = input_timelength; bump < 8 && physic_velocity != '0 0 0'; bump++)
	{
		neworigin = self.origin + t * physic_velocity;
		tracebox(self.origin, self.mins, self.maxs, neworigin, MOVE_NORMAL, self);
		trace1_endpos = trace_endpos;
		trace1_fraction = trace_fraction;
		trace1_plane_normal = trace_plane_normal;
		if(trace1_fraction < 1 && trace1_plane_normal_z == 0)
		{
			// may be a step or wall, try stepping up
			// first move forward at a higher level
			currentorigin2 = self.origin;
			currentorigin2_z += sv_stepheight;
			neworigin2 = neworigin;
			neworigin2_z += sv_stepheight;
			tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
			trace2_endpos = trace_endpos;
			trace2_fraction = trace_fraction;
			trace2_plane_normal = trace_plane_normal;
			if(!trace_startsolid)
			{
				// then move down from there
				currentorigin2 = trace2_endpos;
				neworigin2 = trace2_endpos;
				neworigin2_z = self.origin_z;
				tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
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
				}
			}
		}

		// check if it moved at all
		if(trace1_fraction >= 0.001)
			setorigin(self, trace1_endpos);

		// check if it moved all the way
		if(trace1_fraction == 1)
			break;

		// this is only really needed for nogravityonground combined with gravityunaffectedbyticrate
		// <LordHavoc> I'm pretty sure I commented it out solely because it seemed redundant
		// this got commented out in a change that supposedly makes the code match QW better
		// so if this is broken, maybe put it in an if(cls.protocol != PROTOCOL_QUAKEWORLD) block
		//if(trace1_plane_normal_z > 0.7)
		//	physic_flags |= FL_ONGROUND;

		t -= t * trace1_fraction;

		f = (physic_velocity * trace1_plane_normal);
		physic_velocity = physic_velocity - f * trace1_plane_normal;
	}
	//physic_velocity = primalvelocity;
}

float Physic_MaxSpeedMod()
{
	return physic_maxspeedmod;
}

float Physic_JumpVelocityFactor()
{
	return physic_jump_velocity_factor;
}

void Physic_CheckGroundHook()
{
}

void Physic_CheckWaterJumpHook()
{
}

float Physic_CanUseJetPack()
{
	return 0;
}

float Physic_JetPackVelocityFactor(float fvel)
{
	return 1;
}

void Physic_JetPackHook(float fuel_fact)
{
}

void Physic_OnJumpHook()
{
}

void Physic_LandingHook()
{
}

void Physic_FrameBeginHook()
{
}

void Physic_FrameEndHook()
{
	if (physic_movetype == MOVETYPE_WALK)
		physic_velocity_z -= physic_gravity_factor * sv_gravity * frametime;

}

entity physic;

.vector pmove_origin;
vector CSQCPlayer_SetCamera()
{
	if(physic && servercommandframe && clientcommandframe)
	{
		float frametime_save = frametime;
		float i;
		float first_print = 1;
		float n = clientcommandframe + 1;
		entity oldself = self;
		self = physic;
		self.origin = self.pmove_origin;
		pmove_org = self.origin;
		self.velocity = physic_velocity = pmove_vel;
		
		for (i = servercommandframe + 1; i <= n; i++)
		{
			if not(RetrieveMovementFrame(i))
				break;

			frametime = input_timelength;
			physic_button_crouch = input_buttons & 16;
			physic_movement = input_movevalues;
			physic_v_angle = input_angles;
			physic_button_jump = input_buttons & 2;
			self.angles_y = input_angles_y;
			
			PM_ClientMovement_UpdateStatus(TRUE);
			PlayerPhysics();
			PM_ClientMovement_Move();
		}

		self = oldself;
		frametime = frametime_save;
		return physic.origin + physic.view_ofs;
	}
	else
		return pmove_org + '0 0 1' * getstati(STAT_VIEWHEIGHT);
}

void Ent_Physic(float isnew)
{
	float f = ReadCoord();
	physic = self;
	physic.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
	if (isnew)
	{
		cvar_clientsettemp("cl_movement_replay", "0");
	}
	if (f & 1)
	{
		sv_stepheight = ReadCoord();
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
		sv_warsowbunny_airforwardaccel = ReadCoord();
		sv_warsowbunny_accel = ReadCoord();
		sv_warsowbunny_topspeed = ReadCoord();
		sv_warsowbunny_turnaccel = ReadCoord();
		sv_warsowbunny_backtosideratio = ReadCoord();
		sv_jumpvelocity = ReadCoord();
		sv_gameplayfix_q2airaccelerate = ReadCoord();
		sv_friction_on_land = ReadCoord();
		g_jetpack_acceleration_side = ReadCoord();
		g_jetpack_acceleration_up = ReadCoord();
		g_jetpack_antigravity = ReadCoord();
		g_jetpack_maxspeed_side = ReadCoord();
		g_jetpack_maxspeed_up = ReadCoord();
		sv_slicksurfaces = ReadCoord();
		sv_slicksurfaces_allowjump = ReadCoord();
		sv_pogostick = ReadCoord();
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
	}
	if (f & 8)
	{
		physic_movetype = ReadByte();
		physic_gravity_factor = ReadCoord();
		float recv_flags = ReadByte();
		physic_is_player = recv_flags & 1;
		physic_deadflag = recv_flags & 2;
		physic_maxspeedmod = ReadCoord();
		physic_ladder = recv_flags & 4;	
		physic_ladder_iswater = recv_flags & 8;	
		if (physic_ladder && physic_ladder_iswater)
		{
			physic_ladder_speed = ReadCoord();
			physic_ladder_watertype = ReadCoord();
			physic_ladder_top = ReadCoord();
		}
		physic_jump_velocity_factor = ReadCoord();
	}
	if (isnew)
	{
		self.mins = self.stand_mins;
		self.maxs = self.stand_maxs;
		self.view_ofs = self.stand_view_ofs;
	}
}
