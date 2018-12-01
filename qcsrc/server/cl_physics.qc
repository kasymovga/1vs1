.float restart_jump;
.entity player_physic;

float speedmeter;
float sv_spectator_speed_multiplier;
float g_jump_grunt;
float sv_csqc_physic;

.float ladder_time;
.entity ladder_entity;
.float swamp_slowdown;
.float lastground;
.float spectatorspeed;

#if 0
float developer_shtest;
#define SHTEST_DELTA 10
#define SHTEST_THRESHOLD 1.1
.float shtest_next;
.float shtest_accumulator;
#endif

float buttons_prev;
float Physic_SendEntity(entity to, float sf);

void Physic_OnJumpHook()
{
	if (physic_crouch)
		setanim(self, self.anim_duckjump, FALSE, TRUE, TRUE);
	else
		setanim(self, self.anim_jump, FALSE, TRUE, TRUE);

	if(g_jump_grunt)
		PlayerSound(playersound_jump, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
	self.restart_jump = -1; // restart jump anim next time
	self.oldvelocity_z = physic_velocity_z;
}

void Physic_CheckWaterJumpHook()
{
	self.teleport_time = time + 2;	// safety net
}

float Physic_JumpVelocityFactor()
{
	return GameHookChain_JumpVelocityMod();
}

void Physic_LandingHook()
{
	if(speedmeter)
		dprint(strcat("landing velocity: ", vtos(physic_velocity), " (abs: ", ftos(vlen(physic_velocity)), ")\n"));
	if(self.lastground < time - 0.3)
		physic_velocity = physic_velocity * (1 - sv_friction_on_land);
}

float IsFlying(entity a)
{
	if(a.flags & FL_ONGROUND)
		return 0;
	if(a.waterlevel)
		return 0;
	return 1;
}

.float wasFlying;
void Physic_CheckGroundHook()
{
	if (physic_is_player)
	if (self.wasFlying) {
		if (self.waterlevel) {
			self.nextstep = time + 0.5;
			GlobalSound(globalsound_waterfall, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
		} else {
			if(self.flags & FL_ONGROUND)
			if(time >= self.ladder_time)
			if not(self.hook)
			{
				self.nextstep = time + 0.2;
				trace_dphitq3surfaceflags = 0;
				tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
				if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS)
				{
					if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
						GlobalSound(globalsound_metalfall, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
					else
						GlobalSound(globalsound_fall, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
				}
			}
		}
	}
	self.wasFlying = IsFlying(self);
}

void Physic_OnCrouchHook()
{
	setanim(self, self.anim_duck, FALSE, TRUE, TRUE);
}

float Physic_CanUseJetPack()
{
	float trying_use_jetpack = (self.items & IT_JETPACK) && self.BUTTON_HOOK;
	// we get here if we ran out of ammo
	if (trying_use_jetpack && (!g_jetpack_fuel || self.ammo_fuel >= 0.01 || self.items & IT_UNLIMITED_WEAPON_AMMO))
		return TRUE;

	if(trying_use_jetpack && !(buttons_prev & 32))
		sprint(self, "You don't have any fuel for the ^2Jetpack\n");
	return FALSE;
}

void Physic_JetPackHook(float fuel_fact)
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel -= g_jetpack_fuel * frametime * fuel_fact;
	self.items |= IT_USING_JETPACK;

	// jetpack also inhibits health regeneration, but only for 1 second
	self.pauseregen_finished = max(self.pauseregen_finished, time + g_balance_pause_fuel_regen);
}

float Physic_JetPackVelocityFactor(float fvel)
{
	if(g_jetpack_fuel && !(self.items & IT_UNLIMITED_WEAPON_AMMO))
		return min(1, self.ammo_fuel / (g_jetpack_fuel * frametime * fvel));
	return 1;
}

.string lastclassname;
.float last_maxspeedmod;
float Physic_MaxSpeedMod()
{
	float maxspd_mod = 1, spd;
	string temps;

	if(self.in_swamp)
		maxspd_mod = maxspd_mod * self.swamp_slowdown; //cvar("g_balance_swamp_moverate");

	maxspd_mod = maxspd_mod * GameHookChain_SpeedMod();

	if(self.classname != "player")
	{
		maxspd_mod = sv_spectator_speed_multiplier;
		if(!self.spectatorspeed)
			self.spectatorspeed = maxspd_mod;
		if(self.impulse && self.impulse <= 19)
		{
			if(self.lastclassname != "player")
			{
				if(self.impulse == 10 || self.impulse == 15 || self.impulse == 18)
					self.spectatorspeed = bound(1, self.spectatorspeed + 0.5, 5);
				else if(self.impulse == 11)
					self.spectatorspeed = maxspd_mod;
				else if(self.impulse == 12 || self.impulse == 16  || self.impulse == 19)
					self.spectatorspeed = bound(1, self.spectatorspeed - 0.5, 5);
				else if(self.impulse >= 1 && self.impulse <= 9)
					self.spectatorspeed = 1 + 0.5 * (self.impulse - 1);
			} // otherwise just clear
			self.impulse = 0;
		}
		maxspd_mod = self.spectatorspeed;
	}
	spd = max(sv_maxspeed, sv_maxairspeed) * maxspd_mod;
	if(self.speed != spd)
	{
		self.speed = spd;
		temps = ftos(spd);
		stuffcmd(self, strcat("cl_forwardspeed ", temps, "\n"));
		stuffcmd(self, strcat("cl_backspeed ", temps, "\n"));
		stuffcmd(self, strcat("cl_sidespeed ", temps, "\n"));
		stuffcmd(self, strcat("cl_upspeed ", temps, "\n"));
	}
	self.last_maxspeedmod = maxspd_mod;
	return maxspd_mod;
}

.float last_physic_ladder;
.float last_can_use_jetpack;
.float buttons_old;
.vector v_angle_old;
.vector movement_old;
void Physic_FrameEndHook()
{
	self.last_physic_ladder = physic_ladder;
	self.last_can_use_jetpack = (self.items & IT_JETPACK) && (!g_jetpack_fuel || self.ammo_fuel >= 0.01 || (self.items & IT_UNLIMITED_WEAPON_AMMO));
}

.float() PlayerPhysplug;

void Physic_FrameBeginHook()
{
	float buttons;
	float f;
	GameHook_PhysicFrameBegin();
	buttons = self.BUTTON_ATCK + 2 * self.BUTTON_JUMP + 4 * self.BUTTON_ATCK2 + 8 * self.BUTTON_ZOOM + 16 * self.BUTTON_CROUCH + 32 * self.BUTTON_HOOK + 64 * self.BUTTON_USE + 128 * (self.movement_x < 0) + 256 * (self.movement_x > 0) + 512 * (self.movement_y < 0) + 1024 * (self.movement_y > 0);

	if(buttons != self.buttons_old || physic_movement != self.movement_old || self.v_angle != self.v_angle_old || self.deadflag != DEAD_NO)
		self.parm_idlesince = time;

	buttons_prev = self.buttons_old;
	self.buttons_old = buttons;
	self.movement_old = physic_movement;
	self.v_angle_old = self.v_angle;
#if 0
	float shtest_score;
	if(time > self.shtest_next)
	{
		if(self.shtest_next > 0)
		{
			// self.shtest_accumulator:
			//   started at time - SHTEST_DELTA
			//   should be at SHTEST_DELTA
			shtest_score = self.shtest_accumulator / (SHTEST_DELTA + time - self.shtest_next);
			if(shtest_score > SHTEST_THRESHOLD)
				print("TIME PARADOX: shtest for ", self.netname, " said ", ftos(shtest_score), "\n");
			else if(developer_shtest)
				dprint("okay: shtest for ", self.netname, " said ", ftos(shtest_score), "\n");
		}
		self.shtest_next = time + SHTEST_DELTA;
		self.shtest_accumulator = 0;
	}
	self.shtest_accumulator += frametime;
#endif

	if (clienttype(self) == CLIENTTYPE_BOT)
		bot_think();

    if(physic_plug)
		return;

	if (self.punchangle != '0 0 0')
	{
		f = vlen(self.punchangle) - 10 * frametime;
		if (f > 0)
			self.punchangle = normalize(self.punchangle) * f;
		else
			self.punchangle = '0 0 0';
	}

	if (self.punchvector != '0 0 0')
	{
		f = vlen(self.punchvector) - 30 * frametime;
		if (f > 0)
			self.punchvector = normalize(self.punchvector) * f;
		else
			self.punchvector = '0 0 0';
	}
	if(self.classname == "player")
	{
		float allowed_to_move = 0;
		if (time >= game_starttime || restart_active)
		if (GameHook_PlayerAllowedToMove())
			allowed_to_move = 1;

		if (allowed_to_move)
		{
			if(self.disableclientprediction == 2) {
				if(self.movetype == MOVETYPE_NONE)
					self.movetype = MOVETYPE_WALK;

				PhysicMarkAsTeleported(self);
				self.disableclientprediction = 0;
			}
		} else {
			physic_velocity = '0 0 0';
			self.movetype = MOVETYPE_NONE;
			self.disableclientprediction = 2;
		}
		physic_movetype = self.movetype;
	}


	if (!self.fixangle)
	{
		self.angles_x = 0;
		self.angles_y = self.v_angle_y;
		self.angles_z = 0;
	}
	self.items &~= IT_USING_JETPACK;

	physic_button_crouch = self.BUTTON_CROUCH;
}

void SV_PlayerPhysics()
{
	if (self.player_physic)
		self.player_physic.SendFlags |= 4;

	physic_flags = self.flags;
	physic_velocity = self.velocity;
	physic_cantjump = PLAYER_DEAD(self);
	physic_deadflag = self.deadflag;
	physic_crouch = self.crouch;
	physic_button_jump = self.BUTTON_JUMP;
	physic_v_angle = self.v_angle;
	physic_is_player = (self.classname == "player");
	physic_ladder = (time < self.ladder_time);
	physic_ladder_iswater = (self.ladder_entity.classname == "func_water");
	physic_gravity_factor = self.gravity;
	physic_teleport_time = self.teleport_time - time;
	physic_plug = self.PlayerPhysplug;
	if (physic_ladder_iswater)
	{
		physic_ladder_speed = self.ladder_entity.speed;
		physic_ladder_watertype = self.ladder_entity.watertype;
		physic_ladder_top = self.ladder_entity.origin_z + self.ladder_entity.maxs_z;
	}
	physic_movement = self.movement;
	physic_movetype = self.movetype;
	physic_waterlevel = self.waterlevel;
	physic_watertype = self.watertype;
	PlayerPhysics();
	if(physic_flags & FL_ONGROUND)
		self.lastground = time;
	self.crouch = physic_crouch;
	self.flags = physic_flags;
	self.velocity = physic_velocity;
	self.waterlevel = physic_waterlevel;
	self.watertype = physic_watertype;
}

var void() Physic_RealClientConnect_NextLink;
void Physic_RealClientConnect()
{
	if not(self.player_physic)
	{
		self.player_physic = spawn();
		self.player_physic.viewmodelforclient = self;
		self.player_physic.owner = self;
		Net_LinkEntity(self.player_physic, FALSE, 0, Physic_SendEntity);
	}
	self.player_physic.SendFlags = 3;
	Physic_RealClientConnect_NextLink();
}

var void() Physic_RealClientDisconnect_NextLink;
void Physic_RealClientDisconnect()
{
	if (self.player_physic)
		remove(self.player_physic);

	Physic_RealClientDisconnect_NextLink();
}

void PhysicEnableCSQC() {
	if (sv_csqc_physic)
		return;

	sv_csqc_physic = TRUE;
	Physic_RealClientConnect_NextLink = GameHookChain_RealClientConnect;
	GameHookChain_RealClientConnect = Physic_RealClientConnect;
	Physic_RealClientDisconnect_NextLink = GameHookChain_RealClientDisconnect;
	GameHookChain_RealClientDisconnect = Physic_RealClientDisconnect;
}

void PhysicReadCvars()
{
	//Common
	CACHE_CVAR(sv_stepheight);
	CACHE_CVAR(sv_gravity);
	CACHE_CVAR(sv_maxairspeed);
	CACHE_CVAR(sv_maxspeed);
	CACHE_CVAR(sv_friction);
	CACHE_CVAR(sv_accelerate);
	CACHE_CVAR(sv_airaccelerate);
	CACHE_CVAR(sv_airaccel_sideways_friction);
	CACHE_CVAR(sv_airaccel_qw);
	CACHE_CVAR(sv_stopspeed);
	CACHE_CVAR(sv_airstopaccelerate);
	CACHE_CVAR(sv_airstrafeaccelerate);
	CACHE_CVAR(sv_maxairstrafespeed);
	CACHE_CVAR(sv_aircontrol);
	CACHE_CVAR(sv_warsowbunny_airforwardaccel);
	CACHE_CVAR(sv_warsowbunny_accel);
	CACHE_CVAR(sv_warsowbunny_topspeed);
	CACHE_CVAR(sv_warsowbunny_turnaccel);
	CACHE_CVAR(sv_warsowbunny_backtosideratio);
	CACHE_CVAR(sv_jumpvelocity);
	CACHE_CVAR(sv_gameplayfix_q2airaccelerate);
	CACHE_CVAR(sv_friction_on_land);
	CACHE_CVAR(g_jetpack_acceleration_side);
	CACHE_CVAR(g_jetpack_acceleration_up);
	CACHE_CVAR(g_jetpack_antigravity);
	CACHE_CVAR(g_jetpack_maxspeed_side);
	CACHE_CVAR(g_jetpack_maxspeed_up);
	CACHE_CVAR(sv_slicksurfaces);
	CACHE_CVAR(sv_slicksurfaces_allowjump);
	CACHE_CVAR(sv_pogostick);
	CACHE_CVAR(sv_disable_crouch);
	CACHE_CVAR(g_walljump);
	CACHE_CVAR(g_walljump_delay);
	CACHE_CVAR(g_walljump_force);
	CACHE_CVAR(g_walljump_velocity_xy_factor);
	CACHE_CVAR(g_walljump_velocity_z_factor);
	CACHE_CVAR(g_dodging);
	CACHE_CVAR(g_dodging_delay);
	CACHE_CVAR(g_dodging_frozen);
	CACHE_CVAR(g_dodging_frozen_delay);
	CACHE_CVAR(g_dodging_frozen_factor);
	CACHE_CVAR(g_dodging_horiz_speed);
	CACHE_CVAR(g_dodging_up_speed);
	if (cvar("sv_csqc_physic"))
		PhysicEnableCSQC();

	//Server-side only
	CACHE_CVAR(g_jetpack_fuel);
	CACHE_CVAR(speedmeter);
	CACHE_CVAR(sv_spectator_speed_multiplier);
	CACHE_CVAR(g_jump_grunt);
	CACHE_CVAR(g_dodging_sound);
	CACHE_CVAR(g_walljump_smokeparticle_num);
}

float Physic_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_PHYSIC);
	entity oldself = self;
	self = self.owner;
	float dodging_flags;
	if not(sf & 3)
	{
		if (self.classname == "player") sf |= 8;
		if (self.last_physic_ladder) sf |= 32;
		if (self.ladder_entity.classname == "func_water") sf |= 64;
		if (self.last_can_use_jetpack) sf |= 128;
		if (self.crouch) sf |= 256;
		if (self.last_maxspeedmod != 1) sf |= 512;
		if (self.movetype != MOVETYPE_WALK) sf |= 1024;
		if (self.gravity && self.gravity != 1) sf |= 2048;
		if (self.teleport_time - time >= 0) sf |= 4096;
		if (self.lastwj > 0) sf |= 8192;
		if (g_dodging) {
			dodging_flags = 0;
			if (self.last_dodging_time > 0) dodging_flags |= 1;
			if (self.last_FORWARD_KEY_time > 0) dodging_flags |= 2;
			if (self.last_BACKWARD_KEY_time > 0) dodging_flags |= 4;
			if (self.last_LEFT_KEY_time > 0) dodging_flags |= 8;
			if (self.last_RIGHT_KEY_time > 0) dodging_flags |= 16;
			if (dodging_flags)
				sf |= 16384;
		}
	}
	else
		sf = sf & 7;
	WriteShort(MSG_ENTITY, sf);
	if (sf & 1)
	{
		WriteCoord(MSG_ENTITY, sv_stepheight);
		WriteCoord(MSG_ENTITY, sv_gravity);
		WriteCoord(MSG_ENTITY, sv_maxairspeed);
		WriteCoord(MSG_ENTITY, sv_maxspeed);
		WriteCoord(MSG_ENTITY, sv_friction);
		WriteCoord(MSG_ENTITY, sv_accelerate);
		WriteCoord(MSG_ENTITY, sv_airaccelerate);
		WriteCoord(MSG_ENTITY, sv_airaccel_sideways_friction);
		WriteCoord(MSG_ENTITY, sv_airaccel_qw);
		WriteCoord(MSG_ENTITY, sv_stopspeed);
		WriteCoord(MSG_ENTITY, sv_airstopaccelerate);
		WriteCoord(MSG_ENTITY, sv_airstrafeaccelerate);
		WriteCoord(MSG_ENTITY, sv_maxairstrafespeed);
		WriteCoord(MSG_ENTITY, sv_aircontrol);
		WriteCoord(MSG_ENTITY, sv_warsowbunny_turnaccel);
		WriteCoord(MSG_ENTITY, sv_warsowbunny_airforwardaccel);
		WriteCoord(MSG_ENTITY, sv_warsowbunny_accel);
		WriteCoord(MSG_ENTITY, sv_warsowbunny_topspeed);
		WriteCoord(MSG_ENTITY, sv_warsowbunny_backtosideratio);
		WriteCoord(MSG_ENTITY, sv_jumpvelocity);
		WriteCoord(MSG_ENTITY, sv_friction_on_land);
		WriteCoord(MSG_ENTITY, g_jetpack_acceleration_side);
		WriteCoord(MSG_ENTITY, g_jetpack_acceleration_up);
		WriteCoord(MSG_ENTITY, g_jetpack_antigravity);
		WriteCoord(MSG_ENTITY, g_jetpack_maxspeed_side);
		WriteCoord(MSG_ENTITY, g_jetpack_maxspeed_up);
		float switches = (sv_slicksurfaces ? 1 : 0)
				+ (sv_slicksurfaces_allowjump ? 2 : 0)
				+ (sv_pogostick ? 4 : 0)
				+ (sv_disable_crouch ? 8 : 0)
				+ (sv_gameplayfix_q2airaccelerate ? 16 : 0)
				+ (g_walljump ? 32 : 0)
				+ (g_dodging ? 64 : 0)
				+ (g_dodging_frozen ? 128 : 0)
				;
		WriteByte(MSG_ENTITY, switches);
		if (g_walljump) {
			WriteCoord(MSG_ENTITY, g_walljump_delay);
			WriteCoord(MSG_ENTITY, g_walljump_force);
			WriteCoord(MSG_ENTITY, g_walljump_velocity_xy_factor);
			WriteCoord(MSG_ENTITY, g_walljump_velocity_z_factor);
		}
		if (g_dodging) {
			WriteCoord(MSG_ENTITY, g_dodging_horiz_speed);
			WriteCoord(MSG_ENTITY, g_dodging_up_speed);
			WriteCoord(MSG_ENTITY, g_dodging_delay);
			WriteCoord(MSG_ENTITY, g_dodging_frozen_delay);
			WriteCoord(MSG_ENTITY, g_dodging_frozen_factor);
		}
	}
	if (sf & 2)
	{
		WriteCoord(MSG_ENTITY, PL_CROUCH_MIN_x);
		WriteCoord(MSG_ENTITY, PL_CROUCH_MIN_y);
		WriteCoord(MSG_ENTITY, PL_CROUCH_MIN_z);
		WriteCoord(MSG_ENTITY, PL_CROUCH_MAX_x);
		WriteCoord(MSG_ENTITY, PL_CROUCH_MAX_y);
		WriteCoord(MSG_ENTITY, PL_CROUCH_MAX_z);
		WriteCoord(MSG_ENTITY, PL_MIN_x);
		WriteCoord(MSG_ENTITY, PL_MIN_y);
		WriteCoord(MSG_ENTITY, PL_MIN_z);
		WriteCoord(MSG_ENTITY, PL_MAX_x);
		WriteCoord(MSG_ENTITY, PL_MAX_y);
		WriteCoord(MSG_ENTITY, PL_MAX_z);
		WriteCoord(MSG_ENTITY, PL_CROUCH_VIEW_OFS_x);
		WriteCoord(MSG_ENTITY, PL_CROUCH_VIEW_OFS_y);
		WriteCoord(MSG_ENTITY, PL_CROUCH_VIEW_OFS_z);
		WriteCoord(MSG_ENTITY, PL_VIEW_OFS_x);
		WriteCoord(MSG_ENTITY, PL_VIEW_OFS_y);
		WriteCoord(MSG_ENTITY, PL_VIEW_OFS_z);
	}
	if (sf & 4)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
		WriteCoord(MSG_ENTITY, self.velocity_x);
		WriteCoord(MSG_ENTITY, self.velocity_y);
		WriteCoord(MSG_ENTITY, self.velocity_z);
		if ((sf & 32) && (sf & 64))
		{
			WriteCoord(MSG_ENTITY, self.ladder_entity.speed);
			WriteCoord(MSG_ENTITY, self.ladder_entity.watertype);
			WriteCoord(MSG_ENTITY, self.ladder_entity.origin_z + self.ladder_entity.maxs_z);
		}
		if (sf & 512)
		{
			WriteCoord(MSG_ENTITY, self.last_maxspeedmod);
			WriteCoord(MSG_ENTITY, Physic_JumpVelocityFactor());
		}
		if (sf & 1024)
			WriteByte(MSG_ENTITY, self.movetype);
		if (sf & 2048)
			WriteCoord(MSG_ENTITY, self.gravity);
		if (sf & 4096)
			WriteCoord(MSG_ENTITY, self.teleport_time - time);
		if (sf & 8192)
			WriteCoord(MSG_ENTITY, self.lastwj);
		if (sf & 16384) {
			WriteByte(MSG_ENTITY, dodging_flags);
			if (dodging_flags & 1) WriteCoord(MSG_ENTITY, self.last_dodging_time);
			if (dodging_flags & 2) WriteCoord(MSG_ENTITY, self.last_FORWARD_KEY_time);
			if (dodging_flags & 4) WriteCoord(MSG_ENTITY, self.last_BACKWARD_KEY_time);
			if (dodging_flags & 8) WriteCoord(MSG_ENTITY, self.last_LEFT_KEY_time);
			if (dodging_flags & 16) WriteCoord(MSG_ENTITY, self.last_RIGHT_KEY_time);
		}

	}
	self = oldself;
	return TRUE;
}

void PhysicMarkAsTeleported(entity pl) {
	if (pl.player_physic)
		pl.player_physic.SendFlags |= 4096;

	pl.teleport_time = time;
}
