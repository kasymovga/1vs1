#define AIRCRAFT_VIEW_BACK 400
#define AIRCRAFT_VIEW_UP 125
#define AIRCRAFT_VIEW_START_OFFSET 25
#define AIRCRAFT_MIN '-75 -75 -15'
#define AIRCRAFT_MAX '75 75 105'
float g_vehicle_aircraft_pushfactor;
float g_vehicle_aircraft_laser_refire;
float g_vehicle_aircraft_laser_damage;
float g_vehicle_aircraft_laser_edgedamage;
float g_vehicle_aircraft_laser_force;
float g_vehicle_aircraft_laser_speed;
float g_vehicle_aircraft_laser_radius;
float g_vehicle_aircraft_laser_heat;
float g_vehicle_aircraft_laser_cooldown;
float g_vehicle_aircraft_laser_spread;

float(entity to, float sf) vehicle_aircraft_physics_send;
void(float eject) vehicle_aircraft_exit;
void(void) vehicle_aircraft_enter;

void(void) vehicle_aircraft_engine_on {
	if not(self.cnt) {
		self.modelflags |= MF_ROCKET;
		sound_to_at(MSG_ALL, self, '0 0 0', CHAN_PLAYER, "misc/jetpack_fly.wav", VOL_BASE, ATTN_NORM);
		self.cnt = 1;
	}
}

void(void) vehicle_aircraft_engine_off {
	if (self.cnt) {
		self.modelflags &= ~MF_ROCKET;
		sound_stop_to(MSG_ALL, self, CHAN_PLAYER);
		self.cnt = 0;
	}
}

void() vehicle_aircraft_attack_laser {
	if (self.attack_finished_single > time || self.vehicle_heat > 1)
		return;

	self.phase = !self.phase;
	self.angles_x = -self.angles_x;
	makevectors(self.angles);
	self.angles_x = -self.angles_x;
	if (self.phase)
		weapon_shotorg = self.origin + v_forward * 60 + v_right * 15 + v_up * 25;
	else
		weapon_shotorg = self.origin + v_forward * 60 - v_right * 15 + v_up * 25;

	weapon_score_fires(self.owner, WEAPON_HLAC, 1);
	sound(self, CHAN_WEAPON, "weapons/lasergun_fire.wav", VOL_BASE, ATTN_NORM);
	pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg, weapon_shotdir * 1000, 1);
	entity proj = projectile(TRUE, PROJECTILE_HLAC, TRUE, self);
	projectile_setup(proj, weapon_shotorg, EFFECT_IMPACT_LASER, WEAPON_HLAC, g_vehicle_aircraft_laser_damage,
			g_vehicle_aircraft_laser_edgedamage, g_vehicle_aircraft_laser_radius, g_vehicle_aircraft_laser_force, 0, MOVETYPE_FLY);
	proj.realowner = self.owner;
	proj.velocity = (v_forward + randomvec() * self.vehicle_heat * g_vehicle_aircraft_laser_spread) * g_vehicle_aircraft_laser_speed;
	weapon_setup_projectile_velocity(proj);
	proj.touch = projectile_touch_explode;
	proj.think = stdproc_remove;
	proj.nextthink = time + 5;
	self.vehicle_heat += g_vehicle_aircraft_laser_heat * g_vehicle_aircraft_laser_refire;
	if(self.vehicle_heat >= 1) {
		self.vehicle_heat = 1;
		self.attack_finished_single = time + (1 / g_vehicle_aircraft_laser_cooldown);
	} else
		self.attack_finished_single = time + g_vehicle_aircraft_laser_refire;
}

void(void) vehicle_aircraft_pull_stop {
	if (self.gun1) {
		remove(self.gun1);
		self.gun1 = world;
		self.aiment = world;
		sound_stop(self, CHAN_TRIGGER);
	}
}

void(void) vehicle_aircraft_pull {
	if not(self.gun1) {
		self.gun1 = spawn();
		setmodel(self.gun1, "models/vhshield.md3");
		self.gun1.angles_x = 90;
		self.gun1.scale = 1.75;
		self.gun1.alpha = 0.5;
		self.gun1.colormod = '1.5 2 0.25';
		setattachment(self.gun1, self, "");
		setorigin(self.gun1, '0 0 -200');
	}
	if (self.gun1.nextstep < time) {
		self.gun1.angles_z += frametime * 180;
		self.gun1.nextstep = time + 1.5;
		sound(self, CHAN_TRIGGER, "ambient/machinerydrone01.wav", VOL_BASE, ATTN_NORM);
	}
	if not(self.aiment) {
		trace_box(self.origin, self.mins, self.maxs, self.origin - '0 0 100', TRACE_MOVE_NORMAL, self);
		if (trace_ent)
		if (trace_ent.movetype != MOVETYPE_NOCLIP)
		if (trace_ent.movetype != MOVETYPE_NONE)
		if (trace_ent.movetype != MOVETYPE_FOLLOW)
		if (trace_ent.solid == SOLID_SLIDEBOX || trace_ent.solid == SOLID_BBOX) {
			float _volume = (trace_ent.maxs_x - trace_ent.mins_x) * (trace_ent.maxs_y - trace_ent.mins_y) *  (trace_ent.maxs_z - trace_ent.mins_z);
			if (_volume < 3000 || _volume > 3000000) {
				return;
			}
			self.aiment = trace_ent;
			//self.aiment.disableclientprediction = TRUE;
		}
	} else {
		float zdistance = self.origin_z - self.mins_z - self.aiment.origin_z - self.aiment.maxs_z;
		vector center = (self.aiment.mins + self.aiment.maxs) * 0.5 + self.aiment.origin;
		vector delta = center - self.origin;
		float ldelta = vlen(delta);
		if (zdistance > 100 || zdistance < 0 || ldelta > 200 || (self.solid != SOLID_BBOX && self.solid != SOLID_SLIDEBOX)) {
			vehicle_aircraft_pull_stop();
			return;
		} else if (zdistance > 50) {
			self.aiment.velocity_z = self.velocity_z + (zdistance - 50) * 4;
		} else if (zdistance > 25) {
			self.aiment.velocity_z = self.velocity_z;
		} else {
			self.aiment.velocity_z = self.velocity_z - (zdistance - 25) * 2;
		}
		delta_z = 0;
		if (ldelta < 10)
			delta = '0 0 0';

		self.aiment.velocity_x = self.velocity_x - delta_x * 4;
		self.aiment.velocity_y = self.velocity_y - delta_y * 4;
		te_lightning1(self, self.origin, center);
	}
}

float(void) vehicle_aircraft_physics_hook {
    entity player,aircraft;
    player = self;
    aircraft = self.vehicle;
    player.BUTTON_ZOOM = 0;
    player.BUTTON_CROUCH = 0;
    if (player.BUTTON_HOOK || player.BUTTON_USE || (aircraft.bot_nextthink && aircraft.bot_nextthink < time)) {
		vehicle_extract_player(player, FALSE);
		return 1;
	}
    if (map_finished) {
		aircraft.velocity = '0 0 0';
		return 1;
	}
    //anim_do();
	self = aircraft;
    vehicle_stdproc_regen();
	if (player.BUTTON_ATCK) {
		vehicle_aircraft_attack_laser();
	}
	if (player.BUTTON_ATCK2) {
		vehicle_aircraft_pull();
	} else {
		vehicle_aircraft_pull_stop();
	}
    player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
	if (physics_movement != '0 0 0' || physics_button_jump)
		vehicle_aircraft_engine_on();
	else
		vehicle_aircraft_engine_off();

	vector o = self.origin;
	physics_aircraft();
	physics_triggers(o, self.origin, vlen(self.maxs - self.mins) / 2, 0);
	vehicle_adjust_player_position(player, aircraft, AIRCRAFT_VIEW_START_OFFSET, AIRCRAFT_VIEW_BACK, AIRCRAFT_VIEW_UP);
	self = player;
    return 1;
}

void(void) vehicle_aircraft_think {
	if(self.vehicle_heat > 0)
		self.vehicle_heat = max(self.vehicle_heat - g_vehicle_aircraft_laser_cooldown * sys_ticrate,0);

	if (self.owner) {
		self.owner.vehicle_heat = self.vehicle_heat;
	} else {
		physics_movetype = MOVETYPE_QCWALK;
		physics_flags = self.flags;
		physics_velocity = self.velocity;
		physics_gravity_factor = (self.gravity ? self.gravity : 1);
		physics_update_status();
		self.velocity = physics_velocity;
		self.flags = physics_flags;
		move_beak_simple(g_vehicle_aircraft_speed_stop * frametime);
		physics_velocity = self.velocity;
		physics_move();
		self.velocity = physics_velocity;
		self.waterlevel = physics_waterlevel;
	}
    self.nextthink = time;
}

void(void) vehicle_aircraft_enter {
	if not(vehicle_enter(self.angles, vehicle_aircraft_physics_hook, vehicle_aircraft_physics_send))
		return;

	self.colormap = self.owner.colormap;
	vehicle_stdproc_setcolormod();
}

void(float eject) vehicle_aircraft_exit {
	vehicle_aircraft_pull_stop();
	vehicle_aircraft_engine_off();
	self.nextthink = time;
	self.colormap = 1024;
	vehicle_stdproc_setcolormod();
}

void(void) vehicle_aircraft_touch {
	push_touch();
	if (self.owner || other.classname != "player")
		return;

    vehicle_aircraft_enter();
}

void(void) vehicle_aircraft_spawn {
	vehicle_stdproc_spawn(vehicle_aircraft_think, vehicle_aircraft_touch);
	self.colormap = 1024;
	vehicle_stdproc_setcolormod();
}

void(void) vehicle_aircraft_blowup {
	vehicle_blowup(100, 15, 250, 250);
}

void(void) vehicle_aircraft_die {
	vehicle_aircraft_engine_off();
	vehicle_stdproc_die(vehicle_aircraft_blowup);
	vehicle_explode(10);
}

void(void) vehicle_aircraft_dinit {
    if (self.netname == "")
		self.netname = "aircraft";

    self.vehicle_flags = VHF_HASSHIELD | VHF_SHIELDREGEN | VHF_HEALTHREGEN | VHF_HIDEPLAYER | VHF_HEAT;
    self.cvar_basename = "g_vehicle_aircraft";
	self.vehicle_heat = 0;
    setmodel(self, self.message2);
	setsize(self, AIRCRAFT_MIN, AIRCRAFT_MAX);
	self.scale = 0.6;
    vehicle_aircraft_spawn();
    self.vehicle_die = vehicle_aircraft_die;
    self.vehicle_exit = vehicle_aircraft_exit;
    self.vehicle_spawn = vehicle_aircraft_spawn;
	self.reset = vehicle_reset;
	self.pushfactor = g_vehicle_aircraft_pushfactor;
}

float vehicle_aircraft_init_done;
void(void) vehicle_aircraft_init {
	vehicle_init();
	if (vehicle_aircraft_init_done)
		return;

	vehicle_aircraft_init_done = TRUE;
	CVAR_CACHE(g_vehicle_aircraft_movement_inertia);
	CVAR_CACHE(g_vehicle_aircraft_pushfactor);
	CVAR_CACHE(g_vehicle_aircraft_speed);
	CVAR_CACHE(g_vehicle_aircraft_speed_stop);
	CVAR_CACHE(g_vehicle_aircraft_accel_up);
	CVAR_CACHE(g_vehicle_aircraft_turnspeed);
	CVAR_CACHE(g_vehicle_aircraft_laser_force);
	CVAR_CACHE(g_vehicle_aircraft_laser_refire);
	CVAR_CACHE(g_vehicle_aircraft_laser_damage);
	CVAR_CACHE(g_vehicle_aircraft_laser_edgedamage);
	CVAR_CACHE(g_vehicle_aircraft_laser_speed);
	CVAR_CACHE(g_vehicle_aircraft_laser_radius);
	CVAR_CACHE(g_vehicle_aircraft_laser_heat);
	CVAR_CACHE(g_vehicle_aircraft_laser_cooldown);
	CVAR_CACHE(g_vehicle_aircraft_laser_spread);
    precache_model("models/vhshield.md3");
    precache_model(self.message2);
	precache_sound("weapons/lasergun_fire.wav");
	precache_sound("ambient/machinerydrone01.wav");
}

float(entity to, float sf) vehicle_aircraft_physics_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_PHYSICS_AIRCRAFT);
	net_write_short(MSG_ENTITY, sf);
	if (sf & 1) {
		vehicle_write_common(AIRCRAFT_MIN, AIRCRAFT_MAX, AIRCRAFT_VIEW_START_OFFSET, AIRCRAFT_VIEW_BACK, AIRCRAFT_VIEW_UP);
		net_write_coord(MSG_ENTITY, g_vehicle_aircraft_accel_up);
		net_write_coord(MSG_ENTITY, g_vehicle_aircraft_speed);
		net_write_coord(MSG_ENTITY, g_vehicle_aircraft_speed_stop);
		net_write_coord(MSG_ENTITY, g_vehicle_aircraft_turnspeed);
		net_write_coord(MSG_ENTITY, g_vehicle_aircraft_movement_inertia);
		net_write_short(MSG_ENTITY, num_for_edict(self.vehicle));
	}
	if (sf & 2) {
		net_write_coord(MSG_ENTITY, self.vehicle.angles_x);
		net_write_coord(MSG_ENTITY, self.vehicle.angles_y);
		net_write_coord(MSG_ENTITY, self.vehicle.angles_z);
		net_write_coord(MSG_ENTITY, self.vehicle.origin_x);
		net_write_coord(MSG_ENTITY, self.vehicle.origin_y);
		net_write_coord(MSG_ENTITY, self.vehicle.origin_z);
		net_write_coord(MSG_ENTITY, self.vehicle.velocity_x);
		net_write_coord(MSG_ENTITY, self.vehicle.velocity_y);
		net_write_coord(MSG_ENTITY, self.vehicle.velocity_z);
	}
	return TRUE;
}

void(void) spawnfunc_vehicle_aircraft {
	self.message2 = self.model;
	if (self.message2 == "")
		self.message2 = "models/racers/waka.dpm";

	vehicle_aircraft_init();
	vehicle_stdproc_init("aircraft", vehicle_aircraft_dinit);
}
