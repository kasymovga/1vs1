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
float physics_send(entity to, float sf);

void(void) physics_on_jump_hook {
	if (physics_crouch)
		anim_set(self, self.anim_duckjump, FALSE, TRUE, TRUE);
	else
		anim_set(self, self.anim_jump, FALSE, TRUE, TRUE);

	if(g_jump_grunt)
		sound(self, CHAN_PLAYER, self.playersound_jump, VOL_BASE, ATTN_NORM);

	self.restart_jump = -1; // restart jump anim next time
	self.oldvelocity_z = physics_velocity_z;
}

void(void) physics_check_water_jump_hook {
	self.teleport_time = time + 2;	// safety net
}

float(void) physics_jump_velocity_mod {
	return GameHookChain_JumpVelocityMod();
}

void(void) physics_landing_hook {
	if(self.lastground < time - 0.3)
		physics_velocity = physics_velocity * (1 - sv_friction_on_land);
}

float(entity a) physics_is_flying {
	if(a.flags & FL_ONGROUND)
		return 0;
	if(a.waterlevel)
		return 0;
	return 1;
}

.float wasFlying;
void(void) physics_check_ground_hook {
	self.flags = physics_flags;
	self.waterlevel = physics_waterlevel;
	if (physics_is_player)
	if (self.wasFlying) {
		if (self.waterlevel) {
			self.nextstep = time + 0.5;
			sound(self, CHAN_PLAYER, "misc/outwater.wav", VOL_BASE, ATTN_NORM);
		} else {
			if(self.flags & FL_ONGROUND)
			if(time >= self.ladder_time)
			if (self.lastground < time - 0.3)
			if not(self.hook)
			{
				self.nextstep = time + 0.2;
				trace_dphitq3surfaceflags = 0;
				tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
				if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS)
				{
					if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
						sound(self, CHAN_PLAYER, randomsound("misc/metalhitground", 4), VOL_BASE, ATTN_NORM);
					else
						sound(self, CHAN_PLAYER, randomsound("misc/hitground", 4), VOL_BASE, ATTN_NORM);
				}
			}
		}
	}
	self.wasFlying = physics_is_flying(self);
}

void(void) physics_on_crouch_hook {
	anim_set(self, self.anim_duck, FALSE, TRUE, TRUE);
}

float(void) physics_use_jetpack {
	float trying_use_jetpack = (self.items & IT_JETPACK) && self.BUTTON_HOOK;
	// we get here if we ran out of ammo
	if (trying_use_jetpack && (!g_jetpack_fuel || self.ammo_fuel >= 0.01 || self.items & IT_UNLIMITED_WEAPON_AMMO))
		return TRUE;

	if(trying_use_jetpack && !(buttons_prev & 32))
		sprint(self, "You don't have any fuel for the ^2Jetpack\n");
	return FALSE;
}

void(float fuel_fact) physics_jetpack_hook {
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel -= g_jetpack_fuel * frametime * fuel_fact;
	self.items |= IT_USING_JETPACK;

	// jetpack also inhibits health regeneration, but only for 1 second
	self.pauseregen_finished = max(self.pauseregen_finished, time + g_balance_pause_fuel_regen);
}

float(float fvel) physics_jetpack_velocity_mod {
	if(g_jetpack_fuel && !(self.items & IT_UNLIMITED_WEAPON_AMMO))
		return min(1, self.ammo_fuel / (g_jetpack_fuel * frametime * fvel));

	return 1;
}

.string lastclassname;
.float last_maxspeedmod;
float(void) physics_max_speed_mod {
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

.float last_physics_ladder;
.float last_can_use_jetpack;
.float buttons_old;
.vector v_angle_old;
.vector movement_old;
void(void) physics_frame_end_hook {
	self.last_physics_ladder = physics_ladder;
	self.last_can_use_jetpack = (self.items & IT_JETPACK) && (!g_jetpack_fuel || self.ammo_fuel >= 0.01 || (self.items & IT_UNLIMITED_WEAPON_AMMO));
}

.float() PlayerPhysplug;

void(void) physics_frame_begin_hook {
	float buttons;
	float f;
	GameHook_PhysicFrameBegin();
	buttons = self.BUTTON_ATCK + 2 * self.BUTTON_JUMP + 4 * self.BUTTON_ATCK2 + 8 * self.BUTTON_ZOOM + 16 * self.BUTTON_CROUCH + 32 * self.BUTTON_HOOK + 64 * self.BUTTON_USE + 128 * (self.movement_x < 0) + 256 * (self.movement_x > 0) + 512 * (self.movement_y < 0) + 1024 * (self.movement_y > 0);

	if(buttons != self.buttons_old || physics_movement != self.movement_old || self.v_angle != self.v_angle_old || self.deadflag != DEAD_NO)
		self.parm_idlesince = time;

	buttons_prev = self.buttons_old;
	self.buttons_old = buttons;
	self.movement_old = physics_movement;
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
		}
		self.shtest_next = time + SHTEST_DELTA;
		self.shtest_accumulator = 0;
	}
	self.shtest_accumulator += frametime;
#endif

	if (clienttype(self) == CLIENTTYPE_BOT)
		bot_think();

    if(physics_plug)
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


	if not(self.fixangle)
	if not(PLAYER_REALLY_DEAD(self)) {
		self.angles_x = 0;
		self.angles_y = self.v_angle_y;
		self.angles_z = 0;
	}
	self.items &~= IT_USING_JETPACK;
	physics_button_crouch = self.BUTTON_CROUCH;
}

void SV_PlayerPhysics()
{
	if (self.player_physic)
		self.player_physic.SendFlags |= 4;

	if(self.classname == "player")
	{
		float allowed_to_move = 0;
		if (time >= game_starttime || restart_active)
		if not(gameover)
		if (GameHook_PlayerAllowedToMove())
			allowed_to_move = 1;

		if (allowed_to_move) {
			self.movetype = MOVETYPE_QCWALK;
		} else {
			physics_velocity = '0 0 0';
			self.movetype = MOVETYPE_NONE;
		}
	}
	physics_flags = self.flags;
	physics_velocity = self.velocity;
	physics_cantjump = PLAYER_DEAD(self);
	physics_deadflag = self.deadflag;
	physics_crouch = self.crouch;
	physics_button_jump = self.BUTTON_JUMP;
	physics_v_angle = self.v_angle;
	physics_is_player = (self.classname == "player");
	physics_ladder = (time < self.ladder_time);
	physics_ladder_iswater = (self.ladder_entity.classname == "func_water");
	physics_gravity_factor = (self.gravity ? self.gravity : 1);
	physics_teleport_time = self.teleport_time - time;
	physics_plug = self.PlayerPhysplug;
	if (physics_ladder_iswater)
	{
		physics_ladder_speed = self.ladder_entity.speed;
		physics_ladder_watertype = self.ladder_entity.watertype;
		physics_ladder_top = self.ladder_entity.origin_z + self.ladder_entity.maxs_z;
	}
	physics_movement = self.movement;
	physics_movetype = self.movetype;
	physics_waterlevel = self.waterlevel;
	physics_watertype = self.watertype;
	physics_player();
	if(physics_flags & FL_ONGROUND)
		self.lastground = time;
	self.crouch = physics_crouch;
	self.flags = physics_flags;
	self.velocity = physics_velocity;
	self.waterlevel = physics_waterlevel;
	self.watertype = physics_watertype;
}

var void() physics_RealClientConnect_NextLink;
void physics_RealClientConnect()
{
	if not(self.player_physic)
	{
		self.player_physic = spawn();
		self.player_physic.viewmodelforclient = self;
		self.player_physic.owner = self;
		net_link_entity(self.player_physic, FALSE, 0, physics_send);
	}
	self.player_physic.SendFlags = 3;
	physics_RealClientConnect_NextLink();
}

var void() physics_RealClientDisconnect_NextLink;
void physics_RealClientDisconnect()
{
	if (self.player_physic)
		remove(self.player_physic);

	physics_RealClientDisconnect_NextLink();
}

float(string s) physics_cvar {
	string sv_s = s;
	if (substring(s, 0, 3) == "sv_") {
		s = substring(s, 3, -1);
	}
	string g_s = strcat("g_", s);
	string g_s_v = cvar_string(g_s);
	if (g_s_v != "") {
		cvar_set(sv_s, g_s_v);
		return cvar(g_s);
	}
	return cvar(sv_s);
}

float physics_initiated;
void(void) physics_init {
#define PHYSIC_CACHE_CVAR(x) x = physics_cvar(#x)
	//Common
	PHYSIC_CACHE_CVAR(sv_stepheight);
	PHYSIC_CACHE_CVAR(sv_gravity);
	PHYSIC_CACHE_CVAR(sv_maxairspeed);
	PHYSIC_CACHE_CVAR(sv_maxspeed);
	PHYSIC_CACHE_CVAR(sv_friction);
	PHYSIC_CACHE_CVAR(sv_accelerate);
	PHYSIC_CACHE_CVAR(sv_airaccelerate);
	PHYSIC_CACHE_CVAR(sv_airaccel_sideways_friction);
	PHYSIC_CACHE_CVAR(sv_airaccel_qw);
	PHYSIC_CACHE_CVAR(sv_stopspeed);
	PHYSIC_CACHE_CVAR(sv_airstopaccelerate);
	PHYSIC_CACHE_CVAR(sv_airstrafeaccelerate);
	PHYSIC_CACHE_CVAR(sv_maxairstrafespeed);
	PHYSIC_CACHE_CVAR(sv_aircontrol);
	PHYSIC_CACHE_CVAR(sv_warsowbunny_airforwardaccel);
	PHYSIC_CACHE_CVAR(sv_warsowbunny_accel);
	PHYSIC_CACHE_CVAR(sv_warsowbunny_topspeed);
	PHYSIC_CACHE_CVAR(sv_warsowbunny_turnaccel);
	PHYSIC_CACHE_CVAR(sv_warsowbunny_backtosideratio);
	PHYSIC_CACHE_CVAR(sv_jumpvelocity);
	PHYSIC_CACHE_CVAR(sv_gameplayfix_q2airaccelerate);
	PHYSIC_CACHE_CVAR(sv_friction_on_land);
	CACHE_CVAR(g_stepairslowdown);
	CACHE_CVAR(g_jetpack_acceleration_side);
	CACHE_CVAR(g_jetpack_acceleration_up);
	CACHE_CVAR(g_jetpack_antigravity);
	CACHE_CVAR(g_jetpack_maxspeed_side);
	CACHE_CVAR(g_jetpack_maxspeed_up);
	PHYSIC_CACHE_CVAR(sv_slicksurfaces);
	PHYSIC_CACHE_CVAR(sv_slicksurfaces_allowjump);
	PHYSIC_CACHE_CVAR(sv_pogostick);
	PHYSIC_CACHE_CVAR(sv_disable_crouch);
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
	//Server-side only
	CACHE_CVAR(g_jetpack_fuel);
	CACHE_CVAR(speedmeter);
	CACHE_CVAR(sv_spectator_speed_multiplier);
	CACHE_CVAR(g_jump_grunt);
	CACHE_CVAR(g_dodging_sound);
	CACHE_CVAR(g_walljump_smokeparticle_num);
	if (physics_initiated) {
		entity e;
		FOR_EACH_REALCLIENT(e) {
			e.player_physic.SendFlags |= 3;
		}
	} else {
		physics_RealClientConnect_NextLink = GameHookChain_RealClientConnect;
		GameHookChain_RealClientConnect = physics_RealClientConnect;
		physics_RealClientDisconnect_NextLink = GameHookChain_RealClientDisconnect;
		GameHookChain_RealClientDisconnect = physics_RealClientDisconnect;
		physics_initiated = TRUE;
	}
}

float(entity to, float sf) physics_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_PHYSIC);
	entity oldself = self;
	self = self.owner;
	float dodging_flags;
	if not(sf & 3)
	{
		if (self.classname == "player") sf |= 8;
		if (self.last_physics_ladder) sf |= 32;
		if (self.ladder_entity.classname == "func_water") sf |= 64;
		if (self.last_can_use_jetpack) sf |= 128;
		if (self.crouch) sf |= 256;
		if (self.last_maxspeedmod != 1) sf |= 512;
		if (self.movetype != MOVETYPE_QCWALK) sf |= 1024;
		if (self.gravity && self.gravity != 1) sf |= 2048;
		if (self.teleport_time - time >= 0) sf |= 4096;
		if (self.lastwj > 0) sf |= 8192;
		if (g_dodging || g_dodging_frozen) {
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
		WriteCoord(MSG_ENTITY, g_stepairslowdown);
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
		if (g_dodging || g_dodging_frozen) {
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
			WriteCoord(MSG_ENTITY, physics_jump_velocity_mod());
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

void(entity pl) physics_mark_as_teleported {
	if (pl.player_physic)
		pl.player_physic.SendFlags |= 4096;

	pl.teleport_time = time;
}
