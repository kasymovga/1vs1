#define SPIDERBOT_VIEW_BACK 400
#define SPIDERBOT_VIEW_UP 140
#define SPIDERBOT_VIEW_START_OFFSET 70
#define SPIDERBOT_MIN '-75 -75 5'
#define SPIDERBOT_MAX '75 75 105'

float g_vehicle_spiderbot_head_pitchlimit_down;
float g_vehicle_spiderbot_head_pitchlimit_up;
float g_vehicle_spiderbot_head_pitchspeed;
float g_vehicle_spiderbot_head_turnlimit;
float g_vehicle_spiderbot_head_turnspeed;
float g_vehicle_spiderbot_minigun_cooldown;
float g_vehicle_spiderbot_minigun_damage;
float g_vehicle_spiderbot_minigun_heat;
float g_vehicle_spiderbot_minigun_refire;
float g_vehicle_spiderbot_minigun_spread;
float g_vehicle_spiderbot_rocket_damage;
float g_vehicle_spiderbot_rocket_edgedamage;
float g_vehicle_spiderbot_rocket_force;
float g_vehicle_spiderbot_rocket_noise;
float g_vehicle_spiderbot_rocket_radius;
float g_vehicle_spiderbot_rocket_refire;
float g_vehicle_spiderbot_rocket_reload;
float g_vehicle_spiderbot_rocket_speed;
float g_vehicle_spiderbot_rocket_spread;
float g_vehicle_spiderbot_rocket_turnrate;
float g_vehicle_spiderbot_rocket_up;
float g_vehicle_spiderbot_pushfactor;

float(entity to, float sf) vehicle_spiderbot_physics_send;
void(float eject) vehicle_spiderbot_exit;
void() vehicle_spiderbot_enter;

void(entity spider) vehicle_spiderbot_stop {
	spider.frame = 5; //stay
}

void(void) vehicle_spiderbot_rocket_think {
	vector newdir,olddir;
	if (self.fade_time <= time) {
		projectile_explode();
		return;
	}
	self.nextthink  = time;
	if (self.realowner.vehicle == self.owner) {
		olddir = normalize(self.velocity);
		newdir = normalize(self.realowner.cursor_trace_endpos - self.origin);
		newdir += randomvec() * g_vehicle_spiderbot_rocket_noise;
		self.velocity = normalize(olddir + newdir * g_vehicle_spiderbot_rocket_turnrate) * g_vehicle_spiderbot_rocket_speed;
	}
}

void(void) vehicle_spiderbot_rocket_do {
	entity missile;
	if(self.gun2.cnt > time)
		return;

	if(self.tur_head.frame > 7)
		self.tur_head.frame = 0;

	if not (self.owner.BUTTON_ATCK2)
		return;

	self.tur_head.frame += 1;
	if(self.tur_head.frame > 7)
		self.attack_finished_single = g_vehicle_spiderbot_rocket_reload;
	else
		self.attack_finished_single = g_vehicle_spiderbot_rocket_refire;

	self.gun2.cnt = time + self.attack_finished_single;
	sound (self, CHAN_WEAPON, "weapons/rocket_fire.wav", VOL_BASE, ATTN_NORM);
	weapon_score_fires(self.owner, WEAPON_ROCKET_LAUNCHER, 1);
	missile = projectile(FALSE, PROJECTILE_ROCKET, FALSE, self); // no culling, has fly sound
	projectile_setup(missile, gettaginfo(self.tur_head, gettagindex(self.tur_head, "tag_fire")), EFFECT_IMPACT_ROCKET, WEAPON_ROCKET_LAUNCHER,
			g_vehicle_spiderbot_rocket_damage, g_vehicle_spiderbot_rocket_edgedamage, g_vehicle_spiderbot_rocket_radius,
			g_vehicle_spiderbot_rocket_force, 0, MOVETYPE_FLY);
	te_explosion (missile.origin);
	missile.realowner = self.owner;
	missile.nextthink = time;// 0.2;
	missile.touch = projectile_touch_explode;
	missile.velocity = normalize(v_forward + (v_up * g_vehicle_spiderbot_rocket_up) + randomvec() * g_vehicle_spiderbot_rocket_spread) * g_vehicle_spiderbot_rocket_speed;
	missile.think = vehicle_spiderbot_rocket_think;
	missile.solid = SOLID_BBOX;
	missile.fade_time = time + 10;
}

void(void) vehicle_spiderbot_minigun_fire_flash_go {
	if (self.frame > 10){
		self.alpha = -1;
		setmodel(self,"");
		return;
	}
	self.frame = self.frame + 2;
	self.alpha = self.alpha - 0.2;
	self.nextthink = time + 0.02;
}

void(entity gun) vehicle_spiderbot_minigun_fire {
	entity flash;
	vector v;
	v = gettaginfo(gun,gettagindex(gun,"barrels"));
	v_forward = normalize(v_forward);
	sound (gun, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
	entity e = self;
	self = self.owner;
	weapon_score_fires(self, WEAPON_UZI, 1);
	bullet_begin(10000);
	bullet(v, v_forward, g_vehicle_spiderbot_minigun_spread, 10000, 5, g_vehicle_spiderbot_minigun_damage, 0, 0, EFFECT_IMPACT_BULLET, WEAPON_UZI, particleeffectnum("EFFECT_MGTURRETTRAIL"), 0, 100);
	self = e;
	bullet_end();
	if not(gun.enemy) {
		gun.enemy = spawn();
		setattachment(gun.enemy , gun, "barrels");
		setorigin(gun.enemy ,gun.enemy.origin + '48 0 0');
	}
	flash = gun.enemy; //spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.think = vehicle_spiderbot_minigun_fire_flash_go;
	flash.nextthink = time + 0.02;
	flash.frame = 2;
	flash.angles_z = flash.v_angle_z + random() * 180;
	flash.alpha = 1;
	flash.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION;
}

void(void) vehicle_spiderbot_miniguns_do {
	if ((self.owner.BUTTON_ATCK) && (self.owner.vehicle_heat < 1) && (self.tur_head.attack_finished_single < time)) {
		float rotation;
		rotation = 720 * sys_ticrate / g_vehicle_spiderbot_minigun_refire;
		float mod_rotation = math_mod(rotation, 90);
		if (mod_rotation < 10 || mod_rotation > 80)
			rotation += 30;

		self.gun1.angles_z += rotation;
		self.gun2.angles_z -= rotation;
		if(self.gun1.angles_z >= 360) {
			self.gun1.angles_z = 0;
			self.gun2.angles_z = 360;
		}
		vehicle_spiderbot_minigun_fire(self.gun1);
		vehicle_spiderbot_minigun_fire(self.gun2);
		self.vehicle_heat += g_vehicle_spiderbot_minigun_heat * g_vehicle_spiderbot_minigun_refire;
		if(self.vehicle_heat >= 1) {
			self.vehicle_heat = 1;
			self.tur_head.attack_finished_single = (1/g_vehicle_spiderbot_minigun_cooldown)+time;
		} else
			self.tur_head.attack_finished_single = g_vehicle_spiderbot_minigun_refire + time;
	}
}

float(void) vehicle_spiderbot_physics_hook {
	vector ad;
	entity player,spider;
	float ftmp,ftmp2;
	player = self;
	spider = self.vehicle;
	player.BUTTON_ZOOM = 0;
	player.BUTTON_CROUCH = 0;
	if(player.BUTTON_HOOK || player.BUTTON_USE || (spider.bot_nextthink && spider.bot_nextthink < time)) {
		vehicle_extract_player(player, FALSE);
		return 1;
	}
	if(map_finished) {
		spider.velocity = '0 0 0';
		return 1;
	}
	self = spider;
	if(spider.flags & FL_ONGROUND) {
		if(player.BUTTON_JUMP) {
			player.BUTTON_JUMP = 0;
			spider.frame = 4; //jump
		} else {
			if(vlen(player.movement) == 0) {
				vehicle_spiderbot_stop(spider);
			} else {
				if(player.movement_x != 0) {
					if(player.movement_x > 0) {
						spider.frame = 0; //walk forward
					} else if(player.movement_x < 0) {
						spider.frame = 1; //walk backward
					}
				} else if(player.movement_y != 0) {
					if(player.movement_y < 0) {
						spider.frame = 2; //walk left
					} else if(player.movement_y > 0) {
						spider.frame = 3; //walk right
					}
				}

			}
		}
	}
	vehicle_spiderbot_miniguns_do();
	vehicle_spiderbot_rocket_do();
	vehicle_stdproc_regen();
	player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
	player.rockets = spider.tur_head.frame;
	if(spider.gun2.cnt <= time)
		player.rockets_reload = 1;
	else
		player.rockets_reload = 1 - ((spider.gun2.cnt - time) /spider.attack_finished_single);

	physics_spiderbot();
	spider.tur_head.angles_x *= -1;
	spider.angles_x *= -1;
	//player.angles_x *= -1;
	//ad = player.v_angle - (spider.tur_head.angles + spider.angles);
	ad = player.v_angle -  (spider.tur_head.angles + spider.angles);
	// Rotate head
	ftmp = g_vehicle_spiderbot_head_turnspeed * frametime;
	ftmp2 = ftmp * -1;
	spider.tur_head.angles_y += bound(ftmp2, math_shortangle_f(ad_y, spider.tur_head.angles_y), ftmp);
	spider.tur_head.angles_y = bound(g_vehicle_spiderbot_head_turnlimit * -1,spider.tur_head.angles_y,g_vehicle_spiderbot_head_turnlimit);
	// Pitch head
	ftmp = g_vehicle_spiderbot_head_pitchspeed * frametime;
	ftmp2 = ftmp * -1;
	spider.tur_head.angles_x += bound(ftmp2, math_shortangle_f(ad_x, spider.tur_head.angles_x), ftmp);
	spider.tur_head.angles_x = bound(g_vehicle_spiderbot_head_pitchlimit_down,spider.tur_head.angles_x,g_vehicle_spiderbot_head_pitchlimit_up);
	spider.tur_head.angles_x *= -1;
	spider.angles_x *= -1;
	vehicle_adjust_player_position(player, spider, SPIDERBOT_VIEW_START_OFFSET, SPIDERBOT_VIEW_BACK, SPIDERBOT_VIEW_UP);
	self = player;
	return 1;
}

void(void) vehicle_spiderbot_think {
	if(self.vehicle_heat > 0)
		self.vehicle_heat = max(self.vehicle_heat - g_vehicle_spiderbot_minigun_cooldown * sys_ticrate,0);

	if (self.owner)
		self.owner.vehicle_heat = self.vehicle_heat;
	else {
		physics_movetype = MOVETYPE_QCWALK;
		physics_flags = self.flags;
		physics_velocity = self.velocity;
		physics_gravity_factor = (self.gravity ? self.gravity : 1);
		physics_update_status();
		self.flags = physics_flags;
		if(self.flags & FL_ONGROUND) {
			self.velocity = physics_velocity;
			move_beak_simple(g_vehicle_spiderbot_speed_stop * frametime);
			self.angles_x *= -1;
			makevectors(self.angles);
			self.angles_x *= -1;
			move_groundalign4point(75, 75, 1);
			physics_velocity = self.velocity;
		}
		physics_move();
		self.velocity = physics_velocity;
		self.waterlevel = physics_waterlevel;
	}
	self.nextthink = time;
}

void(void) vehicle_spiderbot_enter {
	if not(vehicle_enter(self.tur_head.angles + self.angles, vehicle_spiderbot_physics_hook, vehicle_spiderbot_physics_send))
		return;

	self.colormap = self.owner.colormap;
	self.tur_head.colormap = self.owner.colormap;
	vehicle_stdproc_setcolormod();
	self.tur_head.colormap = self.owner.colormap;
}

void(float eject) vehicle_spiderbot_exit {
	self.nextthink = time;
	self.colormap = 1024;
	self.tur_head.colormap = 1024;
	vehicle_stdproc_setcolormod();
	vehicle_spiderbot_stop(self);
}

void(void) vehicle_spiderbot_touch {
	push_touch();
	if (self.owner || other.classname != "player")
		return;

	vehicle_spiderbot_enter();
}

//void spiderbot_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force);
void(void) vehicle_spiderbot_spawn {
	vehicle_stdproc_spawn(vehicle_spiderbot_think, vehicle_spiderbot_touch);
	self.frame = 5;
	self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = 1;
	self.tur_head.angles = '0 0 0';
	self.colormap = 1024;
	self.tur_head.colormap = 1024;
	vehicle_stdproc_setcolormod();
}

void(void) vehicle_spiderbot_blowup {
	vehicle_blowup(100, 15, 250, 250);
}

void(void) vehicle_spiderbot_die {
	self.frame = 0;
	self.tur_head.frame = 0;
	vehicle_stdproc_die(vehicle_spiderbot_blowup);
	vehicle_explode(10);
}

void(void) vehicle_spiderbot_dinit {
	if (self.netname == "")
		self.netname = "spiderbot";

	self.tur_head = spawn();
	self.gun1 = spawn();
	self.gun2 = spawn();
	//self.vehicle_viewport = spawn();
	self.vehicle_flags = VHF_HASSHIELD | VHF_SHIELDREGEN | VHF_HEALTHREGEN | VHF_HIDEPLAYER | VHF_HASROCKETS | VHF_HEAT;
	self.cvar_basename = "g_vehicle_spiderbot";
	self.vehicle_heat = 0;
	vehicle_spiderbot_stop(self);
	//setmodel (self.vehicle_viewport, "null");
	setmodel(self, "null");
	setmodel(self, "models/spiderbot/spiderbot.dpm");
	setmodel(self.tur_head,"models/spiderbot/spiderbot_top.dpm");
	setmodel(self.gun1,"models/spiderbot/spiderbot_barrels.dpm");
	setmodel(self.gun2,"models/spiderbot/spiderbot_barrels.dpm");
	setattachment(self.tur_head, self, "tag_head");
	setattachment(self.gun1,self.tur_head,"tag_hardpoint01");
	setattachment(self.gun2,self.tur_head,"tag_hardpoint02");
	setsize(self,SPIDERBOT_MIN, SPIDERBOT_MAX);
	self.tur_head.owner = self;
	//setorigin(self.vehicle_viewport,'35 0 -14');
	vehicle_spiderbot_spawn();
	self.vehicle_die = vehicle_spiderbot_die;
	self.vehicle_exit = vehicle_spiderbot_exit;
	self.vehicle_spawn = vehicle_spiderbot_spawn;
	self.reset = vehicle_reset;
	self.pushfactor = g_vehicle_spiderbot_pushfactor;
}

float vehicle_spiderbot_init_done;
void(void) vehicle_spiderbot_init {
	vehicle_init();
	if (vehicle_spiderbot_init_done)
		return;

	vehicle_spiderbot_init_done = TRUE;
	CVAR_CACHE(g_vehicle_spiderbot_head_pitchlimit_down);
	CVAR_CACHE(g_vehicle_spiderbot_head_pitchlimit_up);
	CVAR_CACHE(g_vehicle_spiderbot_head_pitchspeed);
	CVAR_CACHE(g_vehicle_spiderbot_head_turnlimit);
	CVAR_CACHE(g_vehicle_spiderbot_head_turnspeed);
	CVAR_CACHE(g_vehicle_spiderbot_jump_accel);
	CVAR_CACHE(g_vehicle_spiderbot_jump_up);
	CVAR_CACHE(g_vehicle_spiderbot_minigun_cooldown);
	CVAR_CACHE(g_vehicle_spiderbot_minigun_damage);
	CVAR_CACHE(g_vehicle_spiderbot_minigun_heat);
	CVAR_CACHE(g_vehicle_spiderbot_minigun_refire);
	CVAR_CACHE(g_vehicle_spiderbot_minigun_spread);
	CVAR_CACHE(g_vehicle_spiderbot_movement_inertia);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_damage);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_edgedamage);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_force);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_noise);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_radius);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_refire);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_reload);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_speed);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_spread);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_turnrate);
	CVAR_CACHE(g_vehicle_spiderbot_rocket_up);
	CVAR_CACHE(g_vehicle_spiderbot_speed_stop);
	CVAR_CACHE(g_vehicle_spiderbot_speed_strafe);
	CVAR_CACHE(g_vehicle_spiderbot_speed_walk);
	CVAR_CACHE(g_vehicle_spiderbot_turnspeed);
	CVAR_CACHE(g_vehicle_spiderbot_pushfactor);
	precache_model("models/vhshield.md3");
	precache_model("models/spiderbot/cp.md3");
	precache_model("models/spiderbot/spiderbot.dpm");
	precache_model("models/spiderbot/spiderbot_top.dpm");
	precache_model("models/spiderbot/spiderbot_barrels.dpm");
	precache_model("models/onslaught/gen_gib1.md3");
	precache_model("models/onslaught/gen_gib2.md3");
	precache_model("models/onslaught/gen_gib3.md3");
	precache_model("models/turrets/rocket.md3");
	precache_sound("weapons/uzi_fire.wav");
	sound_random_precache("misc/metalfootstep0", 6);
	sound_random_precache("misc/metalhitground", 4);
}

float(entity to, float sf) vehicle_spiderbot_physics_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_PHYSICS_SPIDERBOT);
	net_write_short(MSG_ENTITY, sf);
	if (sf & 1) {
		vehicle_write_common(SPIDERBOT_MIN, SPIDERBOT_MAX, SPIDERBOT_VIEW_START_OFFSET, SPIDERBOT_VIEW_BACK, SPIDERBOT_VIEW_UP);
		net_write_coord(MSG_ENTITY, g_vehicle_spiderbot_jump_accel);
		net_write_coord(MSG_ENTITY, g_vehicle_spiderbot_jump_up);
		net_write_coord(MSG_ENTITY, g_vehicle_spiderbot_speed_stop);
		net_write_coord(MSG_ENTITY, g_vehicle_spiderbot_speed_strafe);
		net_write_coord(MSG_ENTITY, g_vehicle_spiderbot_speed_walk);
		net_write_coord(MSG_ENTITY, g_vehicle_spiderbot_turnspeed);
		net_write_coord(MSG_ENTITY, g_vehicle_spiderbot_movement_inertia);
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

void(void) spawnfunc_vehicle_spiderbot {
	vehicle_spiderbot_init();
	vehicle_stdproc_init("spiderbot", vehicle_spiderbot_dinit);
}
