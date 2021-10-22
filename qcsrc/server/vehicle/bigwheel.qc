#define BIGWHEEL_VIEW_BACK 400
#define BIGWHEEL_VIEW_UP 120
#define BIGWHEEL_VIEW_START_OFFSET 60
#define BIGWHEEL_MIN '-75 -75 5'
#define BIGWHEEL_MAX '75 75 150'
float g_vehicle_bigwheel_pushfactor;
float g_vehicle_bigwheel_speed;
float g_vehicle_bigwheel_speed_stop;
float g_vehicle_bigwheel_speed_drift;
float g_vehicle_bigwheel_turnspeed;
float g_vehicle_bigwheel_health;
float g_vehicle_bigwheel_movement_inertia;
float g_vehicle_bigwheel_laser_damage;
float g_vehicle_bigwheel_laser_edgedamage;
float g_vehicle_bigwheel_laser_radius;
float g_vehicle_bigwheel_laser_force;
float g_vehicle_bigwheel_laser_spread;
float g_vehicle_bigwheel_laser_speed;
float g_vehicle_bigwheel_laser_refire;

float(entity to, float sf) vehicle_bigwheel_physics_send;
void(float eject) vehicle_bigwheel_exit;
void() vehicle_bigwheel_enter;

void(entity e) vehicle_bigwheel_screech {
	if (e.dmg < time) {
		e.dmg = time + 1;
		sound(e, CHAN_WEAPON, self.noise3, VOL_BASE, ATTN_NORM);
	}
	if (e.gun1.dmg < time) {
		e.dmg = time + 0.1;
		pointparticles(particleeffectnum("smoking"), e.origin, '0 0 0', 1);
	}
}

void(void) vehicle_bigwheel_attack_laser {
	if (self.gun1.attack_finished_single > time)
		return;

	self.phase++;
	if (self.phase > 3)
		self.phase = 0;

	makevectors(self.angles);
	if (self.phase == 0)
		weapon_shotorg = self.origin + v_forward * 20 + v_right * 70 + v_up * 70;
	else if (self.phase == 1)
		weapon_shotorg = self.origin + v_forward * 20 - v_right * 70 + v_up * 70;
	else if (self.phase == 2)
		weapon_shotorg = self.origin + v_forward * 20 + v_right * 70 + v_up * 80;
	else
		weapon_shotorg = self.origin + v_forward * 20 - v_right * 70 + v_up * 80;

	damage_record_fires(self.owner, WEP_HLAC, 1);
	sound(self, CHAN_WEAPON, "weapons/lasergun_fire.wav", VOL_BASE, ATTN_NORM);
	pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg, weapon_shotdir * 1000, 1);
	entity proj = projectile(TRUE, PROJECTILE_HLAC, TRUE, self);
	projectile_setup(proj, weapon_shotorg, WEP_HLAC, g_vehicle_bigwheel_laser_damage,
			g_vehicle_bigwheel_laser_edgedamage, g_vehicle_bigwheel_laser_radius, g_vehicle_bigwheel_laser_force, 0);
	proj.realowner = self.owner;
	proj.velocity = (v_forward + randomvec() * g_vehicle_bigwheel_laser_spread) * g_vehicle_bigwheel_laser_speed;
	weapon_setup_projectile_velocity(proj);
	proj.touch = projectile_touch_explode;
	proj.think = stdproc_remove;
	proj.nextthink = time + 5;
	self.gun1.attack_finished_single = time + g_vehicle_bigwheel_laser_refire;
}

float vehicle_bigwheel_physics_hook() {
	entity player,mybigwheel;
	player = self;
	mybigwheel = self.vehicle;
	player.BUTTON_ZOOM = 0;
	player.BUTTON_CROUCH = 0;
	player.switchweapon = 0;
	if(player.BUTTON_HOOK || player.BUTTON_USE || (mybigwheel.bot_nextthink && mybigwheel.bot_nextthink < time)) {
		vehicle_extract_player(player, FALSE);
		return 1;
	}
	if(map_finished) {
		mybigwheel.velocity = '0 0 0';
		return 1;
	}
	self = mybigwheel;
	if(mybigwheel.flags & FL_ONGROUND)
		mybigwheel.wasFlying = 0;
	else
		mybigwheel.wasFlying = 1;

	vehicle_stdproc_regen();
	if (player.BUTTON_ATCK) {
		vehicle_bigwheel_attack_laser();
	}
	player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
	float s1 = g_vehicle_car_speed;
	float s2 = g_vehicle_car_speed_stop;
	float s3 = g_vehicle_car_speed_drift;
	float s4 = g_vehicle_car_turnspeed;
	float s5 = g_vehicle_car_movement_inertia;
	g_vehicle_car_speed = g_vehicle_bigwheel_speed;
	g_vehicle_car_speed_stop = g_vehicle_bigwheel_speed_stop;
	g_vehicle_car_speed_drift = g_vehicle_bigwheel_speed_drift;
	g_vehicle_car_turnspeed = g_vehicle_bigwheel_turnspeed;
	g_vehicle_car_movement_inertia = g_vehicle_bigwheel_movement_inertia;
	g_vehicle_car_align = 0;
	physics_car();
	g_vehicle_car_speed = s1;
	g_vehicle_car_speed_stop = s2;
	g_vehicle_car_speed_drift = s3;
	g_vehicle_car_turnspeed = s4;
	g_vehicle_car_movement_inertia = s5;
	mybigwheel.movement = physics_movement;
	if (physics_movement_x && (physics_flags & FL_ONGROUND)) {
		makevectors(mybigwheel.angles);
		if (mybigwheel.attack_finished_single < time) {
			mybigwheel.attack_finished_single = time + 3;
			sound(mybigwheel, CHAN_PROJECTILE, self.noise2, VOL_BASE, ATTN_NORM);
		}
		float forwardspeed = v_forward * mybigwheel.velocity;
		if (physics_movement_x > 0 && forwardspeed < g_vehicle_bigwheel_speed * 0.5) {
			vehicle_bigwheel_screech(mybigwheel);
		} else if (physics_movement_x < 0 && forwardspeed > -g_vehicle_bigwheel_speed * 0.5) {
			vehicle_bigwheel_screech(mybigwheel);
		}
	}
	vehicle_adjust_player_position(player, mybigwheel, CAR_VIEW_START_OFFSET, CAR_VIEW_BACK, CAR_VIEW_UP);
	self = player;
	return 1;
}

void(void) vehicle_bigwheel_think {
	if not(self.owner) {
		physics_movetype = MOVETYPE_QCWALK;
		physics_flags = self.flags;
		physics_velocity = self.velocity;
		physics_gravity_factor = (self.gravity ? self.gravity : 1);
		physics_update_status();
		self.flags = physics_flags;
		if (physics_flags & FL_ONGROUND) {
			self.velocity = physics_velocity;
			movelib_beak_simple(g_vehicle_bigwheel_speed_stop * frametime);
			self.angles_x *= -1;
			makevectors(self.angles);
			self.angles_x *= -1;
			physics_velocity = self.velocity;
		}
		physics_move();
		self.velocity = physics_velocity;
	}
	self.nextthink = time;
	makevectors(self.angles);
	float rotation_speed = v_forward * self.velocity;
	float oldframe = self.frame;
	if (self.movement_x > 0 || rotation_speed > 400)
		self.frame = 2;
	else if (self.movement_x < 0 || rotation_speed < -400)
		self.frame = 4;
	else if (rotation_speed > 10)
		self.frame = 1;
	else if (rotation_speed < -10)
		self.frame = 3;
	else
		self.frame = 0;

	if (oldframe != self.frame) {
		BITXOR_ASSIGN(self.effects, EFFECT_TELEPORT_BIT);
	}
}

void(void) vehicle_bigwheel_enter {
	if not(vehicle_enter(self.angles, vehicle_bigwheel_physics_hook, vehicle_bigwheel_physics_send))
		return;

	if (self.noise != "")
		sound(self, CHAN_VOICE, self.noise, VOL_BASE, ATTN_NORM);

	self.colormap = self.owner.colormap;
	vehicle_stdproc_setcolormod();
}

void(float eject) vehicle_bigwheel_exit {
	self.think = vehicle_bigwheel_think;
	self.nextthink = time;
	self.colormap = 1024;
	self.movement_x = 0;
	sound_stop(self, CHAN_VOICE);
	vehicle_stdproc_setcolormod();
}

void(void) vehicle_bigwheel_touch {
	push_touch();
	if (self.owner || other.classname != "player")
		return;

	vehicle_bigwheel_enter();
}

void(void) vehicle_bigwheel_spawn {
	self.think = vehicle_bigwheel_think;
	self.nextthink = time;
	self.health = self.health_max;
	self.event_damage = vehicle_stdproc_damage;
	self.iscreature = TRUE;
	self.movetype = MOVETYPE_QCWALK;
	self.solid = SOLID_SLIDEBOX;
	self.takedamage = DAMAGE_AIM;
	self.touch = vehicle_bigwheel_touch;
	self.alpha = 1;
	self.colormap = 1024;
	self.deadflag = DEAD_NO;
	self.bot_attack = TRUE;
	self.pushfactor = g_vehicle_bigwheel_pushfactor;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	setorigin(self,self.enemy.origin);
	self.angles = self.enemy.angles;
	vehicle_stdproc_setcolormod();
	pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);
}

void(void) vehicle_bigwheel_blowup {
	damage_radius (self, self, 100, 15, 250, world, 250, WEP_ROCKET_LAUNCHER, world);
	self.alpha = -1;
	self.nextthink = time + 10;
	self.think = vehicle_bigwheel_spawn;
	self.velocity = '0 0 0';
	setorigin(self,self.tur_aimpos);
}

void(void) vehicle_bigwheel_die {
	self.health = 0;
	self.event_damage = NULL;
	self.iscreature = FALSE;
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.touch = stdproc_nothing;
	self.deadflag = DEAD_DEAD;
	self.think = vehicle_bigwheel_blowup;
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

void(void) vehicle_bigwheel_dinit {
	self.enemy = spawn();
	self.enemy.angles = self.angles;
	setorigin(self.enemy, self.origin);
	if (self.team && !team_mode)
		self.team = 0;
	else
		self.enemy.team = self.team;

	if (self.netname == "")
		self.netname = "bigwheel";

	self.vehicle_flags = VHF_HEALTHREGEN | VHF_HIDEPLAYER;
	self.cvar_basename = "g_vehicle_bigwheel";
	self.gun1 = spawn();
	setmodel(self, self.message2);
	setmodel(self.gun1, self.weaponmodel);
	setattachment(self.gun1, self, "tag_head");
	setsize(self, BIGWHEEL_MIN, BIGWHEEL_MAX);
	self.customizeentityforclient = vehicle_stdproc_customize;
	vehicle_bigwheel_spawn();
	self.vehicle_die = vehicle_bigwheel_die;
	self.vehicle_exit = vehicle_bigwheel_exit;
	self.vehicle_spawn = vehicle_bigwheel_spawn;
	self.reset = vehicle_reset;
}

float vehicle_bigwheel_init_done;
void(void) vehicle_bigwheel_init {
	if (vehicle_bigwheel_init_done)
		return;

	vehicle_init();
	vehicle_bigwheel_init_done = TRUE;
	CVAR_CACHE(g_vehicle_bigwheel_pushfactor);
	CVAR_CACHE(g_vehicle_bigwheel_movement_inertia);
	CVAR_CACHE(g_vehicle_bigwheel_speed_stop);
	CVAR_CACHE(g_vehicle_bigwheel_speed_drift);
	CVAR_CACHE(g_vehicle_bigwheel_speed);
	CVAR_CACHE(g_vehicle_bigwheel_turnspeed);
	CVAR_CACHE(g_vehicle_bigwheel_laser_damage);
	CVAR_CACHE(g_vehicle_bigwheel_laser_edgedamage);
	CVAR_CACHE(g_vehicle_bigwheel_laser_radius);
	CVAR_CACHE(g_vehicle_bigwheel_laser_force);
	CVAR_CACHE(g_vehicle_bigwheel_laser_spread);
	CVAR_CACHE(g_vehicle_bigwheel_laser_speed);
	CVAR_CACHE(g_vehicle_bigwheel_laser_refire);
	precache_model(self.message2);
	precache_model(self.weaponmodel);
	precache_model("models/onslaught/gen_gib1.md3");
	precache_model("models/onslaught/gen_gib2.md3");
	precache_model("models/onslaught/gen_gib3.md3");
}

float(entity to, float sf) vehicle_bigwheel_physics_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_PHYSICS_CAR);
	net_write_short(MSG_ENTITY, sf);
	if (sf & 1) {
		vehicle_write_common(BIGWHEEL_MIN, BIGWHEEL_MAX, BIGWHEEL_VIEW_START_OFFSET, BIGWHEEL_VIEW_BACK, BIGWHEEL_VIEW_UP);
		net_write_coord(MSG_ENTITY, g_vehicle_bigwheel_speed_stop);
		net_write_coord(MSG_ENTITY, g_vehicle_bigwheel_speed);
		net_write_coord(MSG_ENTITY, g_vehicle_bigwheel_turnspeed);
		net_write_coord(MSG_ENTITY, g_vehicle_bigwheel_movement_inertia);
		net_write_coord(MSG_ENTITY, g_vehicle_bigwheel_speed_drift);
		net_write_short(MSG_ENTITY, num_for_edict(self.vehicle));
		net_write_byte(MSG_ENTITY, 0);
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

void(void) spawnfunc_vehicle_bigwheel {
	self.message2 = self.model;
	if (self.message2 == "") {
		self.message2 = "models/turrets/ewheel-base2.md3";
		self.scale = 3;
	}
	if (self.weaponmodel == "") {
		self.weaponmodel = "models/turrets/ewheel-gun1.md3";
	}
	vehicle_bigwheel_init();
	if (self.noise != "")
		precache_sound(self.noise);

	if (self.noise2 == "")
		self.noise2 = "desertfactory/steam_fade.ogg";

	if (self.noise3 == "")
		self.noise3 = "desertfactory/steam_burst.wav";

	precache_sound(self.noise2);
	precache_sound(self.noise3);
	precache_sound("weapons/lasergun_fire.wav");
	vehicle_stdproc_init("bigwheel", vehicle_bigwheel_dinit);
}
