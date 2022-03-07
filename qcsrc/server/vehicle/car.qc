#define CAR_VIEW_BACK 400
#define CAR_VIEW_UP 120
#define CAR_VIEW_START_OFFSET 60
#define CAR_MIN '-90 -90 5'
#define CAR_MAX '90 90 105'
float g_vehicle_car_pushfactor;

float(entity to, float sf) vehicle_car_physics_send;
void vehicle_car_exit(float eject);
void vehicle_car_enter();

void vehicle_car_dorifto_effect_sound(entity mycar) {
	if (mycar.dmg < time ) {
		dlc_sound_follow(mycar, CHAN_WEAPON, self.noise3, VOL_BASE, ATTN_NORM);
		mycar.dmg = time + 2;
	}
}

void(entity mycar) vehicle_car_dorifto_effect_smoke_f {
	if (mycar.gun1.dmg < time) {
		mycar.gun1.dmg = time + 0.075;
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_f_r")), '0 0 0', 1);
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_f_l")), '0 0 0', 1);
	}
}

void(entity mycar) vehicle_car_dorifto_effect_smoke_b {
	if (mycar.gun2.dmg < time) {
		mycar.gun2.dmg = time + 0.075;
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_b_r")), '0 0 0', 1);
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_b_l")), '0 0 0', 1);
	}
}

float vehicle_car_physics_hook() {
	entity player,mycar;
	vector v1, v2;
	player = self;
	mycar = self.vehicle;
	player.BUTTON_ZOOM = 0;
	player.BUTTON_CROUCH = 0;
	player.switchweapon = 0;
	if(player.BUTTON_HOOK || player.BUTTON_USE || (mycar.bot_nextthink && mycar.bot_nextthink < time)) {
		vehicle_extract_player(player, FALSE);
		return 1;
	}
	if(map_finished) {
		mycar.velocity = '0 0 0';
		return 1;
	}
	self = mycar;
	if(mycar.flags & FL_ONGROUND)
		mycar.wasFlying = 0;
	else
		mycar.wasFlying = 1;

	//anim_do();
	vehicle_stdproc_regen();
	player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
	g_vehicle_car_align = 1;
	physics_car();
	makevectors(mycar.angles);
	v1 = v_forward;
	v1_z = 0;
	v2 = mycar.velocity;
	v2_z = 0;
	float a;
	float rotate_factor = normalize(v1) * v2;
	float rotate_factor_f = rotate_factor;
	float rotate_factor_b = rotate_factor;
	if (normalize(v1) * normalize(v2) < 0.75 && rotate_factor > 300) {
		if (mycar.flags & FL_ONGROUND) {
			if (rotate_factor > 700) {
				vehicle_car_dorifto_effect_sound(mycar);
				vehicle_car_dorifto_effect_smoke_f(mycar);
			} else if (self.dmg + 1 > time) {
				vehicle_car_dorifto_effect_smoke_b(mycar);
			}
		}
		rotate_factor_f = 0;
		rotate_factor_b = max(200, rotate_factor * 2);
		v1 = vectoangles(mycar.velocity);
		a = v1_y - mycar.angles_y;
		while (a > 180) a -= 360;
		while (a < -180) a += 360;
	} else if (rotate_factor < 1 && rotate_factor > -1) {
		a = 0;
	} else {
		a = player.v_angle_y - mycar.angles_y;
		while (a > 180) a -= 360;
		while (a < -180) a += 360;
		if (rotate_factor < 50) {
			a = -a;
			if (mycar.flags & FL_ONGROUND)
			if (physics_movement_x > 0) {
				rotate_factor_b = max(200, rotate_factor * 2);
				vehicle_car_dorifto_effect_smoke_b(mycar);
				vehicle_car_dorifto_effect_sound(mycar);
			}
		} else {
			if (mycar.flags & FL_ONGROUND)
			if (physics_movement_x < 0) {
				rotate_factor_f = 0;
				vehicle_car_dorifto_effect_smoke_f(mycar);
				vehicle_car_dorifto_effect_sound(mycar);
			}
		}
	}
	if (physics_movement_x) {
		if (mycar.attack_finished_single < time) {
			mycar.attack_finished_single = time + 3;
			dlc_sound_follow(mycar, CHAN_PROJECTILE, self.noise2, VOL_BASE, ATTN_NORM);
		}
	}
	mycar.gun1.gun1.angles_x = mycar.gun1.gun1.angles_x - rotate_factor_b * frametime;
	mycar.gun1.angles_x = mycar.gun1.angles_x - rotate_factor_f * frametime;
	mycar.gun2.gun2.angles_x = -mycar.gun1.gun1.angles_x;
	mycar.gun2.angles_x = -mycar.gun1.angles_x;
	mycar.gun2.angles_y = approach(mycar.gun2.angles_y, bound(-45, a, 45), frametime * 90);
	mycar.gun1.angles_y = -mycar.gun2.angles_y;
	vehicle_adjust_player_position(player, mycar, CAR_VIEW_START_OFFSET, CAR_VIEW_BACK, CAR_VIEW_UP);
	self = player;
	return 1;
}

void(void) vehicle_car_think {
	if not(self.owner) {
		physics_movetype = MOVETYPE_QCWALK;
		physics_flags = self.flags;
		physics_velocity = self.velocity;
		physics_gravity_factor = (self.gravity ? self.gravity : 1);
		physics_update_status();
		self.flags = physics_flags;
		if (physics_flags & FL_ONGROUND) {
			self.velocity = physics_velocity;
			movelib_beak_simple(g_vehicle_car_speed_stop * frametime);
			self.angles_x *= -1;
			makevectors(self.angles);
			self.angles_x *= -1;
			float as = self.maxs_x * 0.75;
			movelib_groundalign4point(as, as, 1);
			physics_velocity = self.velocity;
		}
		physics_move();
		self.velocity = physics_velocity;
		self.waterlevel = physics_waterlevel;
	}
	self.nextthink = time;
}

void(void) vehicle_car_enter {
	if not(vehicle_enter(self.angles, vehicle_car_physics_hook, vehicle_car_physics_send))
		return;

	if (self.noise != "")
		sound(self, CHAN_VOICE, self.noise, VOL_BASE, ATTN_NORM);

	self.colormap = self.owner.colormap;
	vehicle_stdproc_setcolormod();
}

void(float eject) vehicle_car_exit {
	self.nextthink = time;
	self.colormap = 1024;
	sound_stop(self, CHAN_VOICE);
	vehicle_stdproc_setcolormod();
}

void(void) vehicle_car_touch {
	push_touch();
	if (self.owner || other.classname != "player")
		return;

	vehicle_car_enter();
}

//void car_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force);
void(void) vehicle_car_spawn {
	self.think = vehicle_car_think;
	self.nextthink = time;
	self.health = self.health_max;
	self.event_damage = vehicle_stdproc_damage;
	self.iscreature = TRUE;
	self.movetype = MOVETYPE_PHYSICS;
	self.solid = SOLID_SLIDEBOX;
	self.takedamage = DAMAGE_AIM;
	self.touch = vehicle_car_touch;
	self.alpha = 1;
	self.colormap = 1024;
	self.deadflag = DEAD_NO;
	self.bot_attack = TRUE;
	self.pushfactor = g_vehicle_car_pushfactor;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	setorigin(self,self.enemy.origin);
	self.angles = self.enemy.angles;
	vehicle_stdproc_setcolormod();
	pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);
}

void(void) vehicle_car_blowup {
	damage_radius (self, self, 100, 15, 250, world, 250, WEP_ROCKET_LAUNCHER, world);
	self.alpha = -1;
	self.nextthink = time + 10;
	self.think = vehicle_car_spawn;
	self.velocity = '0 0 0';
	setorigin(self,self.tur_aimpos);
}

void(void) vehicle_car_die {
	self.health = 0;
	self.event_damage = NULL;
	self.iscreature = FALSE;
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.touch = stdproc_nothing;
	self.deadflag = DEAD_DEAD;
	self.think = vehicle_car_blowup;
	self.nextthink = time;
	float i, f;
	for (i = 0; i < 10; i++) {
		f = random();
		if (f < 0.3)
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 11 + '0 0 20', "models/onslaught/gen_gib1.md3", 6, TRUE);
		else if(f > 0.7)
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 12 + '0 0 20', "models/onslaught/gen_gib2.md3", 6, TRUE);
		else
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 13 + '0 0 20', "models/onslaught/gen_gib3.md3", 6, TRUE);
	}
}

void(void) car_dlc_reset {
	setattachment(self.gun1, self, "wheel_f_l");
	setattachment(self.gun2, self, "wheel_f_r");
	setattachment(self.gun1.gun1, self, "wheel_b_l");
	setattachment(self.gun2.gun2, self, "wheel_b_r");
}

void(void) vehicle_car_dinit {
	self.enemy = spawn();
	self.enemy.angles = self.angles;
	setorigin(self.enemy, self.origin);
	if (self.team && !team_mode)
		self.team = 0;
	else
		self.enemy.team = self.team;

	if (self.netname == "")
		self.netname = "car";

	//self.vehicle_viewport = spawn();
	self.vehicle_flags = VHF_HEALTHREGEN | VHF_HIDEPLAYER;
	self.cvar_basename = "g_vehicle_car";
	//setmodel (self.vehicle_viewport, "null");
	self.gun1 = spawn();
	self.gun1.effects = EFFECT_LOWPRECISION;
	self.gun2 = spawn();
	self.gun2.effects = EFFECT_LOWPRECISION;
	self.gun1.gun1 = spawn();
	self.gun1.gun1.effects = EFFECT_LOWPRECISION;
	self.gun2.gun2 = spawn();
	self.gun2.gun2.effects = EFFECT_LOWPRECISION;
	setmodel(self, self.message2);
	setmodel(self.gun1, self.weaponmodel);
	setmodel(self.gun2, self.weaponmodel);
	setmodel(self.gun1.gun1, self.weaponmodel);
	setmodel(self.gun2.gun2, self.weaponmodel);
	setsize(self, CAR_MIN, CAR_MAX);
	self.dlc_reset = car_dlc_reset;
	self.dlc_reset();
	self.customizeentityforclient = vehicle_stdproc_customize;
	//setorigin(self.vehicle_viewport,'35 0 -14');
	vehicle_car_spawn();
	self.vehicle_die = vehicle_car_die;
	self.vehicle_exit = vehicle_car_exit;
	self.vehicle_spawn = vehicle_car_spawn;
	self.reset = vehicle_reset;
}

float vehicle_car_init_done;
void(void) vehicle_car_init {
	if (vehicle_car_init_done)
		return;

	vehicle_init();
	dlc_require("car_v1");
	vehicle_car_init_done = TRUE;
	CVAR_CACHE(g_vehicle_car_pushfactor);
	CVAR_CACHE(g_vehicle_car_movement_inertia);
	CVAR_CACHE(g_vehicle_car_speed_stop);
	CVAR_CACHE(g_vehicle_car_speed_drift);
	CVAR_CACHE(g_vehicle_car_speed);
	CVAR_CACHE(g_vehicle_car_turnspeed);
	precache_model(self.message2);
	precache_model(self.weaponmodel);
	precache_model("models/onslaught/gen_gib1.md3");
	precache_model("models/onslaught/gen_gib2.md3");
	precache_model("models/onslaught/gen_gib3.md3");
	dlc_precache_sound(self.noise2);
	dlc_precache_sound(self.noise3);
}

float(entity to, float sf) vehicle_car_physics_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_PHYSICS_CAR);
	net_write_short(MSG_ENTITY, sf);
	if (sf & 1) {
		vehicle_write_common(CAR_MIN, CAR_MAX, CAR_VIEW_START_OFFSET, CAR_VIEW_BACK, CAR_VIEW_UP);
		net_write_coord(MSG_ENTITY, g_vehicle_car_speed_stop);
		net_write_coord(MSG_ENTITY, g_vehicle_car_speed);
		net_write_coord(MSG_ENTITY, g_vehicle_car_turnspeed);
		net_write_coord(MSG_ENTITY, g_vehicle_car_movement_inertia);
		net_write_coord(MSG_ENTITY, g_vehicle_car_speed_drift);
		net_write_short(MSG_ENTITY, num_for_edict(self.vehicle));
		net_write_byte(MSG_ENTITY, 1);
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

void(void) spawnfunc_vehicle_car {
	self.message2 = self.model;
	if (self.message2 == "")
		self.message2 = "models/car/car.md3";

	if (self.weaponmodel == "")
		self.weaponmodel = "models/car/wheel.md3";

	if (self.noise2 == "")
		self.noise2 = "car/engine.wav";

	if (self.noise3 == "")
		self.noise3 = "car/screech.wav";

	vehicle_car_init();
	if (self.noise != "")
		precache_sound(self.noise);

	vehicle_stdproc_init("car", vehicle_car_dinit);
}
