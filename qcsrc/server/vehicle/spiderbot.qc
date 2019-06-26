#define MODEL_SPIDERBOT_FORWARD_START 1
#define MODEL_SPIDERBOT_FORWARD_END 31
#define MODEL_SPIDERBOT_FORWARD_LENGTH 31

#define MODEL_SPIDERBOT_BACKWARDS_START 32
#define MODEL_SPIDERBOT_BACKWARDS_END 62
#define MODEL_SPIDERBOT_BACKWARDS_LENGTH 31

#define MODEL_SPIDERBOT_LEFT_START 63
#define MODEL_SPIDERBOT_LEFT_END 93
#define MODEL_SPIDERBOT_LEFT_LENGTH 31

#define MODEL_SPIDERBOT_RIGHT_START 94
#define MODEL_SPIDERBOT_RIGHT_END 124
#define MODEL_SPIDERBOT_RIGHT_LENGTH 31

#define MODEL_SPIDERBOT_JUMP_START 125
#define MODEL_SPIDERBOT_JUMP_END 155
#define MODEL_SPIDERBOT_JUMP_LENGTH 31

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
	spider.anim_start = 0;
	spider.anim_end = 0;
	spider.frame = 5;

}

void(void) vehicle_spiderbot_rocket_explode {
	w_deathtypestring = "dident escape the rocket barrage";
	damage_radius (self, self.realowner,
	 g_vehicle_spiderbot_rocket_damage,
	 g_vehicle_spiderbot_rocket_edgedamage,
	 g_vehicle_spiderbot_rocket_radius, world,
	 g_vehicle_spiderbot_rocket_force, WEP_ROCKET_LAUNCHER, world);
	remove (self);
}

void(void) vehicle_spiderbot_rocket_touch {
	PROJECTILE_TOUCH;
	vehicle_spiderbot_rocket_explode();
}

void(void) vehicle_spiderbot_rocket_think {
	vector newdir,olddir;
	self.nextthink  = time;
	if (self.realowner.deadflag != DEAD_NO) {
		vehicle_spiderbot_rocket_explode();
		return;
	}
	if not (self.realowner.vehicle) {
		projectile_update(self);
		return;
	}
	self.touch = vehicle_spiderbot_rocket_touch;
	olddir = normalize(self.velocity);
	newdir = normalize(self.realowner.cursor_trace_endpos - self.origin);
	newdir += randomvec() * g_vehicle_spiderbot_rocket_noise;
	self.velocity = normalize(olddir + newdir * g_vehicle_spiderbot_rocket_turnrate) * g_vehicle_spiderbot_rocket_speed;
	projectile_update(self);
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
	missile				 = projectile(FALSE, PROJECTILE_ROCKET, FALSE, self); // no culling, has fly sound
	setorigin(missile,gettaginfo(self.tur_head,gettagindex(self.tur_head,"tag_fire")));
	te_explosion (missile.origin);
	missile.classname = "spiderbot_rocket";
	missile.realowner = self.owner;
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = 75;
	missile.nextthink = time;// 0.2;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.velocity = normalize(v_forward + (v_up * g_vehicle_spiderbot_rocket_up) + randomvec() * g_vehicle_spiderbot_rocket_spread) * g_vehicle_spiderbot_rocket_speed;
	missile.angles = vectoangles(missile.velocity);
	missile.think = vehicle_spiderbot_rocket_think;
	missile.solid = SOLID_BBOX;
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
	bullet_begin(10000);
	bullet(v, v_forward, g_vehicle_spiderbot_minigun_spread, 10000, 5, g_vehicle_spiderbot_minigun_damage, 0, 0, WEP_UZI, particleeffectnum("EF_MGTURRETTRAIL"), 0, 0);
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
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
}

void(void) vehicle_spiderbot_miniguns_do {
	if ((self.owner.BUTTON_ATCK) && (self.owner.vehicle_heat < 1) && (self.tur_head.attack_finished_single < time)) {
		float rotation;
		rotation = 720 * sys_ticrate / g_vehicle_spiderbot_minigun_refire;
		float mod_rotation = mod(rotation, 90);
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
	player.switchweapon = 0;
	if(player.BUTTON_HOOK || player.BUTTON_USE || (spider.bot_nextthink && spider.bot_nextthink < time)) {
		vehicle_extract_player(player, FALSE);
		return 1;
	}
	if(gameover) {
		spider.velocity = '0 0 0';
		return 1;
	}
	self = spider;
	if(spider.flags & FL_ONGROUND) {
		if (self.wasFlying || vlen(self.velocity) > 100)
		if (self.nextstep <= time) {
			sound(self, CHAN_PLAYER, randomsound("misc/metalhitground", 4), VOL_BASE, ATTN_NORM);
			self.nextstep = time + 0.2;
		}
		spider.wasFlying = 0;
		if(player.BUTTON_JUMP) {
			player.BUTTON_JUMP = 0;
			spider.anim_start = MODEL_SPIDERBOT_JUMP_START;
			spider.anim_end   = MODEL_SPIDERBOT_JUMP_END;
			spider.frame = 4;
		} else {
			if(vlen(player.movement) == 0) {
				vehicle_spiderbot_stop(spider);
			} else {
				if(player.movement_x != 0) {
					if(player.movement_x > 0) {
						spider.anim_start = MODEL_SPIDERBOT_FORWARD_START;
						spider.anim_end   = MODEL_SPIDERBOT_FORWARD_END;
						spider.frame = 0;
					} else if(player.movement_x < 0) {
						spider.anim_start = MODEL_SPIDERBOT_BACKWARDS_START;
						spider.anim_end   = MODEL_SPIDERBOT_BACKWARDS_END;
						spider.frame = 1;
					}
				} else if(player.movement_y != 0) {
					if(player.movement_y < 0) {
						spider.anim_start = MODEL_SPIDERBOT_LEFT_START;
						spider.anim_end   = MODEL_SPIDERBOT_LEFT_END;
						spider.frame = 2;
					} else if(player.movement_y > 0) {
						spider.anim_start = MODEL_SPIDERBOT_RIGHT_START;
						spider.anim_end   = MODEL_SPIDERBOT_RIGHT_END;
						spider.frame = 3;
					}
				}

			}
		}
	} else
		spider.wasFlying = 1;

	//anim_do();
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
	//player.angles_x *= -1;
	vehicle_adjust_player_position(player, spider, SPIDERBOT_VIEW_START_OFFSET, SPIDERBOT_VIEW_BACK, SPIDERBOT_VIEW_UP);
	player.angles = spider.angles;
	//spider.vehicle.angles = spider.angles;
	physics_velocity = '0 0 0';
	player.velocity = spider.velocity;
	self = player;
	//print("spider.angles_x=", ftos(spider.angles_x), "\n");
	//print("spider.tur_head.angles_x=", ftos(spider.tur_head.angles_x), "\n");
	//print("player.v_angle_x=", ftos(player.v_angle_x), "\n");
	if (spider.player_physic)
		spider.player_physic.SendFlags |= 2;

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
		physics_update_status(TRUE);
		self.flags = physics_flags;
		if(self.flags & FL_ONGROUND) {
			self.velocity = physics_velocity;
			movelib_beak_simple(g_vehicle_spiderbot_speed_stop * frametime);
			self.angles_x *= -1;
			makevectors(self.angles);
			self.angles_x *= -1;
			movelib_groundalign4point(75, 75, 1);
			physics_velocity = self.velocity;
		}
		physics_move();
		self.velocity = physics_velocity;

	}
	self.nextthink = time;
}

void(void) vehicle_spiderbot_enter {
	if not(vehicle_enter(self.tur_head.angles + self.angles, vehicle_spiderbot_physics_hook, HUD_SPIDERBOT, vehicle_spiderbot_physics_send))
		return;

	self.owner.vehicle_health = (self.health / self.health_max);
	self.owner.vehicle_shield = (self.vehicle_shield / self.shield_max);
	self.owner.vehicle_heat = self.vehicle_heat;
	self.colormap			 = self.owner.colormap;
	self.tur_head.colormap	= self.owner.colormap;
	vehicle_stdproc_setcolormod();
	self.tur_head.colormap	= self.owner.colormap;
}

void(float eject) vehicle_spiderbot_exit {
	vehicle_stdproc_exit(eject, 160, 64, 160);
	entity e;
	for(e = findchain(classname,"spiderbot_rocket"); e; e = e.chain)
	{
		if(e.owner == self.owner)
		{
			e.realowner = self.owner;
			e.owner = world;
			//e.solid = SOLID_BBOX;
			//e.think = stdproc_nothing;
			//e.nextthink = -1;
		}
	}
	self.think = vehicle_spiderbot_think;
	self.nextthink = time;
	self.colormap			= 1024;
	self.tur_head.colormap   = 1024;
	vehicle_stdproc_setcolormod();
	vehicle_spiderbot_stop(self);
}

void(void) vector_spiderbot_touch {
	push_touch();
	if (self.owner || other.classname != "player")
		return;

	if not(player_can_use_vehicle(other))
		return;

	vehicle_spiderbot_enter();
}

//void spiderbot_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force);
void(void) vehicle_spiderbot_spawn {
	self.frame = 5;
	self.think = vehicle_spiderbot_think;
	self.nextthink = time;
	self.health = self.health_max;
	self.vehicle_shield = self.shield_max;
	self.event_damage = vehicle_stdproc_damage;
	self.iscreature = TRUE;
	self.movetype   = MOVETYPE_QCWALK;
	self.solid	  = SOLID_SLIDEBOX;
	self.takedamage = DAMAGE_AIM;
	self.touch	  = vector_spiderbot_touch;
	self.alpha	  = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = 1;
	self.tur_head.angles = '0 0 0';
	self.colormap = 1024;
	self.tur_head.colormap = 1024;
	self.deadflag	= DEAD_NO;
	self.bot_attack = TRUE;
	self.pushfactor = g_vehicle_spiderbot_pushfactor;
	setsize(self,spiderbot_MIN,spiderbot_MAX);
	setorigin(self,self.enemy.origin);
	self.angles = self.enemy.angles;
	vehicle_stdproc_setcolormod();
	pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);
}

void(void) vehicle_spiderbot_blowup {
	damage_radius (self, self, 100, 15, 250, world, 250, WEP_ROCKET_LAUNCHER, world);
	self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = -1;
	self.nextthink  = time + 10;
	self.think	  = vehicle_spiderbot_spawn;
	setorigin(self,self.tur_aimpos);
}

void(void) vehicle_spiderbot_die {
	self.health = 0;
	self.event_damage = stdproc_nothing;
	self.iscreature = FALSE;
	self.solid	  = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.touch	  = stdproc_nothing;
	self.deadflag	= DEAD_DEAD;
	self.frame = 0;
	self.tur_head.frame = 0;
	self.think = vehicle_spiderbot_blowup;
	self.nextthink = time;
	float i, f;
	for (i = 0; i < 10; i++) {
		f = random();
		if(f < 0.3)
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 11 + '0 0 20', "models/onslaught/gen_gib1.md3", 6, TRUE);
		else if(f > 0.7)
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 12 + '0 0 20', "models/onslaught/gen_gib2.md3", 6, TRUE);
		else
			onslaught_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 13 + '0 0 20', "models/onslaught/gen_gib3.md3", 6, TRUE);
	}
}

void(void) vehicle_spiderbot_dinit {
	self.enemy = spawn();
	self.enemy.angles = self.angles;
	setorigin(self.enemy, self.origin);
	if(self.team && !teamplay)
		self.team = 0;
	else
		self.enemy.team = self.team;

	addstat(STAT_HUD, AS_INT,  hud);
	addstat(STAT_SPIDERBOT_ROCKETS, AS_INT,   rockets);
	addstat(STAT_SPIDERBOT_RELOAD,  AS_FLOAT, rockets_reload);
	addstat(STAT_SPIDERBOT_HEAT,	AS_FLOAT, vehicle_heat);
	addstat(STAT_SPIDERBOT_HEALTH,  AS_FLOAT, vehicle_health);
	addstat(STAT_SPIDERBOT_SHIELD,  AS_FLOAT, vehicle_shield);
	if (self.netname == "")
		self.netname = "spiderbot";

	self.tur_head = spawn();
	self.gun1 = spawn();
	self.gun2 = spawn();
	//self.vehicle_viewport = spawn();
	self.vehicle_flags = VHF_HASSHIELD | VHF_SHIELDREGEN | VHF_HEALTHREGEN | VHF_HIDEPLAYER;
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
	self.tur_head.owner = self;
	self.customizeentityforclient = vehicle_stdproc_customize;
	//setorigin(self.vehicle_viewport,'35 0 -14');
	self.tur_aimpos = self.origin;
	vehicle_spiderbot_spawn();
	self.vehicle_die = vehicle_spiderbot_die;
	self.vehicle_exit = vehicle_spiderbot_exit;
	self.vehicle_spawn = vehicle_spiderbot_spawn;
	self.reset = vehicle_reset;
}

float vehicle_spiderbot_init_done;
void(void) vehicle_spiderbot_init {
	vehicle_init();
	if (vehicle_spiderbot_init_done)
		return;

	vehicle_spiderbot_init_done = TRUE;
	CACHE_CVAR(g_vehicle_spiderbot_head_pitchlimit_down);
	CACHE_CVAR(g_vehicle_spiderbot_head_pitchlimit_up);
	CACHE_CVAR(g_vehicle_spiderbot_head_pitchspeed);
	CACHE_CVAR(g_vehicle_spiderbot_head_turnlimit);
	CACHE_CVAR(g_vehicle_spiderbot_head_turnspeed);
	CACHE_CVAR(g_vehicle_spiderbot_jump_accel);
	CACHE_CVAR(g_vehicle_spiderbot_jump_up);
	CACHE_CVAR(g_vehicle_spiderbot_minigun_cooldown);
	CACHE_CVAR(g_vehicle_spiderbot_minigun_damage);
	CACHE_CVAR(g_vehicle_spiderbot_minigun_heat);
	CACHE_CVAR(g_vehicle_spiderbot_minigun_refire);
	CACHE_CVAR(g_vehicle_spiderbot_minigun_spread);
	CACHE_CVAR(g_vehicle_spiderbot_movement_inertia);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_damage);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_edgedamage);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_force);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_noise);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_radius);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_refire);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_reload);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_speed);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_spread);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_turnrate);
	CACHE_CVAR(g_vehicle_spiderbot_rocket_up);
	CACHE_CVAR(g_vehicle_spiderbot_speed_stop);
	CACHE_CVAR(g_vehicle_spiderbot_speed_strafe);
	CACHE_CVAR(g_vehicle_spiderbot_speed_walk);
	CACHE_CVAR(g_vehicle_spiderbot_turnspeed);
	CACHE_CVAR(g_vehicle_spiderbot_pushfactor);
	precache_model ( "models/vhshield.md3");
	precache_model ( "models/spiderbot/cp.md3");
	precache_model ( "models/spiderbot/spiderbot.dpm");
	precache_model ( "models/spiderbot/spiderbot_top.dpm");
	precache_model ( "models/spiderbot/spiderbot_barrels.dpm");
	precache_model ( "models/onslaught/gen_gib1.md3");
	precache_model ( "models/onslaught/gen_gib2.md3");
	precache_model ( "models/onslaught/gen_gib3.md3");
	precache_model ( "models/turrets/rocket.md3");
	precache_sound ( "weapons/uzi_fire.wav" );
	projectile_init(PROJECTILE_ROCKET);
}

float(entity to, float sf) vehicle_spiderbot_physics_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_PHYSIC_SPIDERBOT);
	WriteShort(MSG_ENTITY, sf);
	if (sf & 1) {
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_jump_accel);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_jump_up);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_speed_stop);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_speed_strafe);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_speed_walk);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_turnspeed);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_movement_inertia);
	}
	if (sf & 2) {
		WriteCoord(MSG_ENTITY, self.vehicle.angles_x);
		WriteCoord(MSG_ENTITY, self.vehicle.angles_y);
		WriteCoord(MSG_ENTITY, self.vehicle.angles_z);
		WriteCoord(MSG_ENTITY, self.vehicle.origin_x);
		WriteCoord(MSG_ENTITY, self.vehicle.origin_y);
		WriteCoord(MSG_ENTITY, self.vehicle.origin_z);
		WriteCoord(MSG_ENTITY, self.vehicle.velocity_x);
		WriteCoord(MSG_ENTITY, self.vehicle.velocity_y);
		WriteCoord(MSG_ENTITY, self.vehicle.velocity_z);
	}
	return TRUE;
}

void(void) spawnfunc_vehicle_spiderbot {
	vehicle_spiderbot_init();
	vehicle_stdproc_init("spiderbot", vehicle_spiderbot_dinit);
}
