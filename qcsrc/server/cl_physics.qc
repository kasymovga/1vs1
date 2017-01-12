.float restart_jump;
.entity player_physic;

float sv_doublejump;
float speedmeter;
float g_nick_flood_penalty_yellow;
float g_nick_flood_penalty_red;
float g_balance_rune_speed_combo_jumpheight;
float g_balance_rune_speed_jumpheight;
float g_balance_curse_slow_jumpheight;
float g_balance_curse_slow_moverate;
float g_balance_rune_speed_combo_moverate;
float g_balance_rune_speed_moverate;
float g_minstagib_speed_jumpheight;
float g_minstagib_speed_moverate;
float g_nexball_basketball_carrier_speed;
float sv_spectator_speed_multiplier;
float g_jump_grunt;
float sv_csqc_physic;
float g_walljump;
float g_walljump_delay;
float g_walljump_force;
float g_walljump_smokeparticle_num;
float g_walljump_velocity_xy_factor;
float g_walljump_velocity_z_factor;

.float ladder_time;
.entity ladder_entity;
.float swamp_slowdown;
.float lastground;
.float spectatorspeed;
.float doublejump_nextjumptime;

#if 0
float developer_shtest;
#define SHTEST_DELTA 10
#define SHTEST_THRESHOLD 1.1
.float shtest_next;
.float shtest_accumulator;
#endif

float buttons_prev;

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

	if(sv_doublejump)
	{
		// we're moving upwards at physic_velocity_z
		// only allow jumping after we got 3 units upwards
		// so we for sure leave the FL_ONGROUND check
		//
		// but as this sucks because of factoring in gravity, we'll just do it
		// for 4 units, and constant velocity
		self.doublejump_nextjumptime = time + 4 / max(40, physic_velocity_z); // max 0.1s blocking of jumps
	}
}

void Physic_CheckWaterJumpHook()
{
	self.teleport_time = time + 2;	// safety net
}

float Physic_JumpVelocityFactor()
{
	float jumpvelocity_factor = 1;
	if(self.runes & RUNE_SPEED)
	{
		if(self.runes & CURSE_SLOW)
			jumpvelocity_factor = g_balance_rune_speed_combo_jumpheight;
		else
			jumpvelocity_factor = g_balance_rune_speed_jumpheight;
	}
	else if(self.runes & CURSE_SLOW)
	{
		jumpvelocity_factor = g_balance_curse_slow_jumpheight;
	}

	if(g_minstagib && (self.items & IT_INVINCIBLE))
	{
		jumpvelocity_factor = jumpvelocity_factor * g_minstagib_speed_jumpheight;
	}

	return jumpvelocity_factor;
}

void Physic_LandingHook()
{
	if(speedmeter)
		dprint(strcat("landing velocity: ", vtos(physic_velocity), " (abs: ", ftos(vlen(physic_velocity)), ")\n"));
	if(self.jumppadcount > 1)
		dprint(strcat(ftos(self.jumppadcount), "x jumppad combo\n"));
	self.jumppadcount = 0;
	if(self.lastground < time - 0.3)
		physic_velocity = physic_velocity * (1 - sv_friction_on_land);
}

float IsFlying(entity a)
{
	if(a.flags & FL_ONGROUND)
		return 0;
	if(a.waterlevel >= WATERLEVEL_SWIMMING)
		return 0;
	traceline(a.origin, a.origin - '0 0 48', MOVE_NORMAL, a);
	if(trace_fraction < 1)
		return 0;
	return 1;
}

.float wasFlying;
void Physic_CheckGroundHook()
{
	if(physic_flags & FL_ONGROUND)
	if(self.wasFlying)
	{
		self.wasFlying = 0;

		if(self.waterlevel < WATERLEVEL_SWIMMING)
		if(time >= self.ladder_time)
		if not(self.hook)
		{
			self.nextstep = time + 0.3 + random() * 0.1;
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
	self.flags = physic_flags;
	if(IsFlying(self))
		self.wasFlying = 1;

	if(physic_is_player)
	if(sv_doublejump)
	{
		physic_flags &~= FL_ONGROUND;
		tracebox(self.origin + '0 0 1', self.mins, self.maxs, self.origin - '0 0 1', MOVE_NORMAL, self);
		if(trace_fraction < 1 && trace_plane_normal_z > 0.7)
			physic_flags |= FL_ONGROUND;
	}
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
	if(self.runes & RUNE_SPEED)
	{
		if(self.runes & CURSE_SLOW)
			maxspd_mod = maxspd_mod * g_balance_rune_speed_combo_moverate;
		else
			maxspd_mod = maxspd_mod * g_balance_rune_speed_moverate;
	}
	else if(self.runes & CURSE_SLOW)
		maxspd_mod = maxspd_mod * g_balance_curse_slow_moverate;

	if(g_minstagib && (self.items & IT_INVINCIBLE))
		maxspd_mod = maxspd_mod * g_minstagib_speed_moverate;

	if(self.in_swamp)
		maxspd_mod = maxspd_mod * self.swamp_slowdown; //cvar("g_balance_swamp_moverate");

	maxspd_mod = maxspd_mod * GameHook_SpeedMod();

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
void Physic_FrameEndHook()
{
	self.last_physic_ladder = physic_ladder;
	self.last_can_use_jetpack = (self.items & IT_JETPACK) && (!g_jetpack_fuel || self.ammo_fuel >= 0.01 || (self.items & IT_UNLIMITED_WEAPON_AMMO));
}

void Nixnex_GiveCurrentWeapon();
.float() PlayerPhysplug;

.vector movement_old;
.float buttons_old;
.vector v_angle_old;

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

float dodging_PlayerPhysics()
{
	float common_factor;
	float new_velocity_gain;
	float velocity_difference;
	float clean_up_and_do_nothing;
	float forcemod;
	forcemod = 1;

	new_velocity_gain = 0;
	clean_up_and_do_nothing = 0;

	if(!g_dodging)
		return 0;

	// when swimming, no dodging allowed..
	if (self.waterlevel >= WATERLEVEL_SWIMMING)
		clean_up_and_do_nothing = 1;

#if 0
	if(g_freezetag && self.freezetag_frozen) {
		if(g_freezetag_dodging_frozen)
			forcemod = g_freezetag_dodging_frozen_forcefactor;
		else
			clean_up_and_do_nothing = 1;
	}
#endif

	if (clean_up_and_do_nothing != 0) {
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
		return 0;
	}

	// make sure v_up, v_right and v_forward are sane
	makevectors(self.angles);

	// if we have e.g. 0.5 sec ramptime and a frametime of 0.25, then the ramp code
	// will be called ramp_time/frametime times = 2 times. so, we need to
	// add 0.5 * the total speed each frame until the dodge action is done..
	common_factor = frametime / g_dodging_ramp_time;

	// if ramp time is smaller than frametime we get problems ;D
	if (common_factor > 1)
		common_factor = 1;

	new_velocity_gain = self.dodging_velocity_gain - (common_factor * g_dodging_horiz_speed * forcemod);
	if (new_velocity_gain < 0)
		new_velocity_gain = 0;

	velocity_difference = self.dodging_velocity_gain - new_velocity_gain;

	// ramp up dodging speed by adding some velocity each frame.. TODO: do it! :D
	if (self.dodging_action == 1) {
		//disable jump key during dodge accel phase
		if (self.movement_z > 0) self.movement_z = 0;

		physic_velocity =
			  physic_velocity
			+ ((self.dodging_direction_y * velocity_difference) * v_right)
			+ ((self.dodging_direction_x * velocity_difference) * v_forward);

		self.dodging_velocity_gain = self.dodging_velocity_gain - velocity_difference;
	}

	// the up part of the dodge is a single shot action
	if (self.dodging_single_action == 1) {
		self.flags &~= FL_ONGROUND;

		physic_velocity =
			  physic_velocity
			+ (g_dodging_up_speed * forcemod * v_up);

		if (g_dodging_sound == 1)
			PlayerSound(playersound_jump, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);

		setanim(self, self.anim_jump, TRUE, FALSE, TRUE);

		self.dodging_single_action = 0;
	}

	// are we done with the dodging ramp yet?
	if((self.dodging_action == 1) && ((time - self.last_dodging_time) > g_dodging_ramp_time))
	{
		// reset state so next dodge can be done correctly
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
	}

	return 0;
}

.float lastwj;
void Physic_FrameBeginHook()
{
	float buttons;
	float f;
	GameHook_PhysicFrameBegin();
	buttons = self.BUTTON_ATCK + 2 * self.BUTTON_JUMP + 4 * self.BUTTON_ATCK2 + 8 * self.BUTTON_ZOOM + 16 * self.BUTTON_CROUCH + 32 * self.BUTTON_HOOK + 64 * self.BUTTON_USE + 128 * (self.movement_x < 0) + 256 * (self.movement_x > 0) + 512 * (self.movement_y < 0) + 1024 * (self.movement_y > 0);

	if(!sv_maxidle_spectatorsareidle || self.movetype == MOVETYPE_WALK)
	{
		if(buttons != self.buttons_old || physic_movement != self.movement_old || self.v_angle != self.v_angle_old)
			self.parm_idlesince = time;
	}
	buttons_prev = self.buttons_old;
	self.buttons_old = buttons;
	self.movement_old = physic_movement;
	self.v_angle_old = self.v_angle;

	if(time < self.nickspamtime)
	if(self.nickspamcount >= g_nick_flood_penalty_yellow)
	{
		// slight annoyance for nick change scripts
		physic_movement = -1 * physic_movement;
		self.BUTTON_ATCK = self.BUTTON_JUMP = self.BUTTON_ATCK2 = self.BUTTON_ZOOM = self.BUTTON_CROUCH = self.BUTTON_HOOK = self.BUTTON_USE = 0;

		if(self.nickspamcount >= g_nick_flood_penalty_red) // if you are persistent and the slight annoyance above does not stop you, I'll show you!
		{
			self.angles_x = random() * 360;
			self.angles_y = random() * 360;
			// at least I'm not forcing retardedview by also assigning to angles_z
			self.fixangle = 1;
		}
	}

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
		if (time >= game_starttime || restart_active)
		if (GameHook_PlayerAllowedToMove())
		{
			if(self.disableclientprediction == 2) {
				if(self.movetype == MOVETYPE_NONE)
					self.movetype = MOVETYPE_WALK;

				self.disableclientprediction = 0;
			}
		} else {
			physic_velocity = '0 0 0';
			self.movetype = MOVETYPE_NONE;
			self.disableclientprediction = 2;
		}
		physic_movetype = self.movetype;
	}

	//TODO: move to common part
	if (g_walljump)
	if not(physic_cantjump)
	if (physic_is_player)
	if (physic_movetype == MOVETYPE_WALK)
	if not(self.hook.state)
	if (physic_button_jump)
	if not(physic_flags & FL_ONGROUND)
	if (time - self.lastwj > g_walljump_delay)
	{
		local vector plane_normal;
		plane_normal = PlayerTouchWall ();
		if (plane_normal != '0 0 0')
		{
			self.lastwj = time;
			float wj_force = g_walljump_force;
			float wj_xy_factor = g_walljump_velocity_xy_factor;
			float wj_z_factor = g_walljump_velocity_z_factor;
			physic_velocity_x += plane_normal_x * wj_force;
			physic_velocity_x /= wj_xy_factor;
			physic_velocity_y += plane_normal_y * wj_force;
			physic_velocity_y /= wj_xy_factor;
			physic_velocity_z = sv_jumpvelocity * wj_z_factor;
			if (physic_crouch) physic_velocity_z *= -1; // thanks Synap for the idea
			self.oldvelocity = physic_velocity;
			pointparticles (particleeffectnum("smoke_ring"), trace_endpos, plane_normal, g_walljump_smokeparticle_num);
			PlayerSound (playersound_jump, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
		}
	}


	if (!self.fixangle)
	{
		self.angles_x = 0;
		self.angles_y = self.v_angle_y;
		self.angles_z = 0;
	}
	self.items &~= IT_USING_JETPACK;
	dodging_PlayerPhysics();

	physic_button_crouch = self.BUTTON_CROUCH;
}

void SV_PlayerPhysics()
{
	if (self.player_physic)
		self.player_physic.SendFlags |= 4;

	physic_flags = self.flags;
	physic_velocity = self.velocity;
	physic_cantjump = (self.deadflag || (self.health <= g_bloodloss) || (time < self.doublejump_nextjumptime));
	if (self.deadflag != DEAD_FREEZE)
		physic_deadflag = self.deadflag;
	else
		physic_deadflag = 0;

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
	CACHE_CVAR(sv_csqc_physic);

	//Server-side only
	CACHE_CVAR(g_jetpack_fuel);
	CACHE_CVAR(speedmeter);
	CACHE_CVAR(g_nick_flood_penalty_yellow);
	CACHE_CVAR(g_nick_flood_penalty_red);
	CACHE_CVAR(g_balance_rune_speed_combo_jumpheight);
	CACHE_CVAR(g_balance_rune_speed_jumpheight);
	CACHE_CVAR(g_balance_curse_slow_jumpheight);
#if 0
	CACHE_CVAR(developer_shtest);
#endif
	CACHE_CVAR(g_balance_curse_slow_moverate);
	CACHE_CVAR(g_balance_rune_speed_combo_moverate);
	CACHE_CVAR(g_balance_rune_speed_moverate);
	CACHE_CVAR(g_minstagib_speed_jumpheight);
	CACHE_CVAR(g_minstagib_speed_moverate);
	CACHE_CVAR(g_nexball_basketball_carrier_speed);
	CACHE_CVAR(sv_spectator_speed_multiplier);
	CACHE_CVAR(g_jump_grunt);
	CACHE_CVAR(sv_doublejump);
	CACHE_CVAR(sv_disable_crouch);
	CACHE_CVAR(g_walljump);
	CACHE_CVAR(g_walljump_delay);
	CACHE_CVAR(g_walljump_force);
	CACHE_CVAR(g_walljump_smokeparticle_num);
	CACHE_CVAR(g_walljump_velocity_xy_factor);
	CACHE_CVAR(g_walljump_velocity_z_factor);
	dodging_ReadCvars();
}

//3588
//2048
//1024
//512
//4

float Physic_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_PHYSIC);
	if not(sf & 3)
	{
		entity oldself = self;
		self = self.owner;
		if (self.classname == "player") sf |= 8;
		if (self.deadflag) sf |= 16;
		if (self.last_physic_ladder) sf |= 32;
		if (self.ladder_entity.classname == "func_water") sf |= 64;
		if (self.last_can_use_jetpack) sf |= 128;
		if (self.crouch) sf |= 256;
		if (self.last_maxspeedmod != 1) sf |= 512;
		if (self.movetype != MOVETYPE_WALK) sf |= 1024;
		if (self.gravity && self.gravity != 1) sf |= 2048;
		if (self.teleport_time - time >= 0) sf |= 4096;
		self = oldself;
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
				+ (sv_gameplayfix_q2airaccelerate ? 16 :0);
		WriteByte(MSG_ENTITY, switches);
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
		WriteCoord(MSG_ENTITY, self.owner.origin_x);
		WriteCoord(MSG_ENTITY, self.owner.origin_y);
		WriteCoord(MSG_ENTITY, self.owner.origin_z);
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
			WriteByte(MSG_ENTITY, self.owner.movetype);
		if (sf & 2048)
			WriteCoord(MSG_ENTITY, self.gravity);
		if (sf & 4096)
			WriteCoord(MSG_ENTITY, self.teleport_time - time);
	}
	return TRUE;
}

void PhysicClientClear(entity plr)
{
	if (plr.player_physic)
		remove(plr.player_physic);
}

void PhysicClientInit(entity plr)
{
	if (nex252_compat_mode || !sv_csqc_physic)
		return;
	if not(plr.player_physic)
	{
		plr.player_physic = spawn();
		plr.player_physic.viewmodelforclient = plr;
		plr.player_physic.owner = plr;
		Net_LinkEntity(plr.player_physic, FALSE, 0, Physic_SendEntity);
	}
	plr.player_physic.SendFlags = 3;
}
