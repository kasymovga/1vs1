#define car_spawnpnt enemy

float g_vehicle_car_crush_dmg;
float g_vehicle_car_crush_force;
float g_vehicle_car_crush_minspeed;
float g_vehicle_car_health;
float g_vehicle_car_health_regen;
float g_vehicle_car_health_regen_dmgpause;

float CarPhysic_SendEntity(entity to, float sf);
void car_exit(float eject);
void car_enter();

void dorifto_effect_sound(entity mycar) {
	if (mycar.dmg < time ) {
		sound(mycar, CHAN_WEAPON, "car/screech.wav", VOL_BASE, ATTN_NORM);
		mycar.dmg = time + 2;
	}
}

void dorifto_effect_smoke_f(entity mycar) {
	if (mycar.gun1.dmg < time) {
		mycar.gun1.dmg = time + 0.075;
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_f_r")), '0 0 0', 1);
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_f_l")), '0 0 0', 1);
	}
}

void dorifto_effect_smoke_b(entity mycar) {
	if (mycar.gun2.dmg < time) {
		mycar.gun2.dmg = time + 0.075;
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_b_r")), '0 0 0', 1);
		pointparticles(particleeffectnum("smoking"), gettaginfo(mycar, gettagindex(mycar, "wheel_b_l")), '0 0 0', 1);
	}
}

float car_physic_hook()
{
    entity player,mycar;
	vector v1, v2;

    player = self;
    mycar = self.vehicle;

    player.BUTTON_ZOOM = 0;
    player.BUTTON_CROUCH = 0;
    player.switchweapon = 0;


    if(player.BUTTON_USE || (mycar.bot_nextthink && mycar.bot_nextthink < time)) {
		vehicle_extract_player(player, FALSE);
		return 1;
	}
    if(gameover) {
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

	physic_car();
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
				dorifto_effect_sound(mycar);
				dorifto_effect_smoke_f(mycar);
			} else if (self.dmg + 1 > time) {
				dorifto_effect_smoke_b(mycar);
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
			if (physic_movement_x > 0) {
				rotate_factor_b = max(200, rotate_factor * 2);
				dorifto_effect_smoke_b(mycar);
				dorifto_effect_sound(mycar);
			}
		} else {
			if (mycar.flags & FL_ONGROUND)
			if (physic_movement_x < 0) {
				rotate_factor_f = 0;
				dorifto_effect_smoke_f(mycar);
				dorifto_effect_sound(mycar);
			}
		}
	}
	if (physic_movement_x) {
		if (mycar.attack_finished_single < time) {
			mycar.attack_finished_single = time + 3;
			sound(mycar, CHAN_PROJECTILE, "car/engine.wav", VOL_BASE, ATTN_NORM);
		}
	}
	mycar.gun1.gun1.angles_x = mycar.gun1.gun1.angles_x - rotate_factor_b * frametime;
	mycar.gun1.angles_x = mycar.gun1.angles_x - rotate_factor_f * frametime;

	mycar.gun2.gun2.angles_x = -mycar.gun1.gun1.angles_x;
	mycar.gun2.angles_x = -mycar.gun1.angles_x;

	mycar.gun2.angles_y = approach(mycar.gun2.angles_y, bound(-45, a, 45), frametime * 90);
	mycar.gun1.angles_y = -mycar.gun2.angles_y;

	vehicle_adjust_player_position(player, mycar, CAR_VIEW_START_OFFSET, CAR_VIEW_BACK, CAR_VIEW_UP);
	player.angles = mycar.angles;
	physic_velocity = '0 0 0';
	player.velocity = mycar.velocity;
    self = player;
	if (mycar.player_physic)
		mycar.player_physic.SendFlags |= 2;

    return 1;
}

void car_think()
{
    if(self.flags & FL_ONGROUND)
    {
        movelib_beak_simple(g_vehicle_car_speed_stop * frametime);
        //movelib_groundalign4point(300,100);
    }
    self.nextthink = time;
}

void car_enter()
{
    if(teamplay)
    if(self.team)
    if(self.team != other.team)
        return;

	if (self.noise != "")
		sound(self, CHAN_VOICE, self.noise, VOL_BASE, ATTN_NORM);

    self.owner = other;
    self.switchweapon = other.switchweapon;

    self.event_damage         = vehicle_stdproc_damage ;
    self.colormap             = self.owner.colormap;
    self.owner.angles         = self.angles;
    self.owner.takedamage     = DAMAGE_NO;
    self.owner.solid          = SOLID_NOT;
	if not(sv_csqc_physic)
		self.owner.movetype   = MOVETYPE_NOCLIP;

    self.owner.PlayerPhysplug = car_physic_hook;
    self.owner.vehicle        = self;
    self.owner.event_damage   = SUB_Null;
    self.owner.vehicle_health = (self.health / g_vehicle_car_health);
    self.team                   = self.owner.team;
	vehicle_stdproc_setcolormod();

    if(clienttype(other) == CLIENTTYPE_REAL)
    {
        msg_entity = other;
        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);  // 10 = SVC_SETVIEWANGLES
        WriteAngle(MSG_ONE, self.angles_x);    // tilt
        WriteAngle(MSG_ONE, self.angles_y);    // yaw
        WriteAngle(MSG_ONE, 0);    // roll
		self.bot_nextthink = 0;
    } else
		self.bot_nextthink = time + 5;
	self.player_physic = spawn();
	self.player_physic.viewmodelforclient = self.owner;
	self.player_physic.vehicle = self;
	Net_LinkEntity(self.player_physic, FALSE, 0, CarPhysic_SendEntity);
}

void car_exit(float eject)
{
	vector exit_origin;
	makevectors(self.angles);
	if(eject)
		exit_origin = self.origin + '0 0 160';
	else
		exit_origin = self.origin + v_forward * 150 + '0 0 64';

	tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
	if not(eject) {
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_right * 150 + '0 0 64';
			tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin + v_right * 150 + '0 0 64';
			tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_forward * 150 + '0 0 64';
			tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1)
			exit_origin = self.origin + '0 0 64';
	}
	stopsound(self, CHAN_VOICE);
	stopsound(self, CHAN_WEAPON);
	stopsound(self, CHAN_PROJECTILE);

	exit_origin = trace_endpos;

    self.owner.switchweapon = self.switchweapon;

    self.velocity = '0 0 0';
    if(clienttype(self.owner) == CLIENTTYPE_REAL)
    {
        msg_entity = self.owner;
        WriteByte (MSG_ONE, SVC_SETVIEWPORT);
        WriteEntity( MSG_ONE, self.owner);

        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);  // 10 = SVC_SETVIEWANGLES
        WriteAngle(MSG_ONE, 0);    // tilt
        WriteAngle(MSG_ONE, self.angles_y);    // yaw
        WriteAngle(MSG_ONE, 0);    // roll
    }

    self.think = car_think;
    self.nextthink = time;
    self.owner.takedamage     = DAMAGE_AIM;
    self.owner.solid          = SOLID_SLIDEBOX;
    self.owner.movetype       = MOVETYPE_WALK;

	self.colormap            = 1024;

    if not (teamplay)
        self.team                = 0;
    else
        self.team = self.car_spawnpnt.team ;

	vehicle_stdproc_setcolormod();
	setorigin(self.owner, exit_origin);
	if(eject)
	    self.owner.velocity = (v_up + v_forward * 0.25) * 750;

	if (self.player_physic)
		remove(self.player_physic);

	self.owner.angles_x = 0;
	self.owner.angles_z = 0;
    self.owner = world;
}

void car_touch()
{
    if(self.owner)
    {
        if(vlen(self.velocity) < g_vehicle_car_crush_minspeed)
            return;

        if(other.classname != "player")
            return;

		float f = vlen(self.velocity - other.velocity);
		if (f > g_vehicle_car_crush_minspeed) {
			f /= g_vehicle_car_speed;
			Damage(other,self,self.owner,g_vehicle_car_crush_dmg * f,DEATH_TURRET,'0 0 0', normalize(other.origin - self.origin) * g_vehicle_car_crush_force * f);
		}
        return;
    }
	if not(player_can_use_vehicle(other))
		return;

    car_enter();
}

float car_customizeentityforclient()
{
    if(self.deadflag == DEAD_DEAD)
        return FALSE;

    return TRUE;
}

//void car_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force);
void car_spawn()
{
    self.think = car_think;
    self.nextthink = time;

    self.health = CCVAR("_health");
    self.event_damage = vehicle_stdproc_damage;
    self.iscreature = TRUE;
    self.movetype   = MOVETYPE_WALK;
    self.solid      = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;
    self.touch      = car_touch;
    self.alpha      = 1;
	self.colormap = 1024;
	self.deadflag    = DEAD_NO;
    self.bot_attack = TRUE;

    setorigin(self,self.car_spawnpnt.origin);
    self.angles = self.car_spawnpnt.angles;

	vehicle_stdproc_setcolormod();

    pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);
}

void car_blowup()
{
    RadiusDamage (self, self, 100, 15, 250, world, 250, WEP_ROCKET_LAUNCHER, world);
    self.alpha = -1;
    self.nextthink  = time + 10;
    self.think      = car_spawn;

    setorigin(self,self.tur_aimpos);
}

void car_die()
{

    self.health = 0;
    self.event_damage = SUB_Null;
    self.iscreature = FALSE;
    self.solid      = SOLID_NOT;
    self.takedamage = DAMAGE_NO;
    self.touch      = SUB_Null;
    self.deadflag    = DEAD_DEAD;
	self.think = car_blowup;
	self.nextthink = time;

	float i, f;
	for (i = 0; i < 10; i++) {
		f = random();
		if(f < 0.3)
			ons_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 11 + '0 0 20', "models/onslaught/gen_gib1.md3", 6, TRUE);
		else if(f > 0.7)
			ons_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 12 + '0 0 20', "models/onslaught/gen_gib2.md3", 6, TRUE);
		else
			ons_throwgib(self.origin + '0 0 40', (100 * randomvec() - '1 1 1') * 13 + '0 0 20', "models/onslaught/gen_gib3.md3", 6, TRUE);
	}
}

void car_reset() {
	car_die();
	car_spawn();
}

void car_dlc_reset() {
	setattachment(self.gun1, self, "wheel_f_l");
	setattachment(self.gun2, self, "wheel_f_r");
	setattachment(self.gun1.gun1, self, "wheel_b_l");
	setattachment(self.gun2.gun2, self, "wheel_b_r");
}

void vewhicle_car_dinit()
{
    self.car_spawnpnt = spawn();
    self.car_spawnpnt.angles = self.angles;
    traceline(self.origin + '0 0 16', self.origin - '0 0 10000', MOVE_WORLDONLY, self);
    setorigin(self.car_spawnpnt,trace_endpos + '0 0 4');
    setorigin(self,self.car_spawnpnt.origin);

    if(self.team && !teamplay)
        self.team = 0;
    else
        self.car_spawnpnt.team = self.team;

    if (self.netname == "")      self.netname     = "car";

    //self.vehicle_viewport = spawn();
    self.vehicle_flags = VHF_HEALTHREGEN | VHF_HIDEPLAYER;
    self.cvar_basename = "g_vehicle_car";
	self.vehicle_heat = 0;

    //setmodel (self.vehicle_viewport, "null");
	self.gun1 = spawn();
	self.gun1.effects = EF_LOWPRECISION;
	self.gun2 = spawn();
	self.gun2.effects = EF_LOWPRECISION;
	self.gun1.gun1 = spawn();
	self.gun1.gun1.effects = EF_LOWPRECISION;
	self.gun2.gun2 = spawn();
	self.gun2.gun2.effects = EF_LOWPRECISION;
    setmodel(self, "models/car/car.md3");
    setmodel(self.gun1, "models/car/wheel.md3");
    setmodel(self.gun2, "models/car/wheel.md3");
    setmodel(self.gun1.gun1, "models/car/wheel.md3");
    setmodel(self.gun2.gun2, "models/car/wheel.md3");
    setsize(self,car_MIN,car_MAX);
	self.dlc_reset = car_dlc_reset;
	self.dlc_reset();
    self.customizeentityforclient          = car_customizeentityforclient;

    //setorigin(self.vehicle_viewport,'35 0 -14');
    car_spawn();

    self.vehicle_die = car_die;
    self.vehicle_exit = car_exit;
	self.reset = car_reset;
}

float vehicle_car_readcvars_done;
void vehicle_car_readcvars() {
	if (vehicle_car_readcvars_done)
		return;

	vehicles_init();
	dlc_require("car_v1");
	vehicle_car_readcvars_done = TRUE;
	CACHE_CVAR(g_vehicle_car_crush_dmg);
	CACHE_CVAR(g_vehicle_car_crush_force);
	CACHE_CVAR(g_vehicle_car_crush_minspeed);
	CACHE_CVAR(g_vehicle_car_health);
	CACHE_CVAR(g_vehicle_car_movement_inertia);
	CACHE_CVAR(g_vehicle_car_speed_stop);
	CACHE_CVAR(g_vehicle_car_speed);
	CACHE_CVAR(g_vehicle_car_turnspeed);
    precache_model ( "models/car/car.md3");
    precache_model ( "models/car/wheel.md3");
	precache_sound("car/engine.wav");
	precache_sound("car/screech.wav");
    precache_model ( "models/onslaught/gen_gib1.md3");
    precache_model ( "models/onslaught/gen_gib2.md3");
    precache_model ( "models/onslaught/gen_gib3.md3");
}

float CarPhysic_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_PHYSIC_CAR);
	WriteShort(MSG_ENTITY, sf);
	if (sf & 1)
	{
		WriteCoord(MSG_ENTITY, g_vehicle_car_speed_stop);
		WriteCoord(MSG_ENTITY, g_vehicle_car_speed);
		WriteCoord(MSG_ENTITY, g_vehicle_car_turnspeed);
		WriteCoord(MSG_ENTITY, g_vehicle_car_movement_inertia);
	}
	if (sf & 2)
	{
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

void spawnfunc_vehicle_car()
{
	vehicle_car_readcvars();
	if (self.noise != "")
		precache_sound(self.noise);

    //self.team                = -1;
    self.think = vewhicle_car_dinit;
    self.nextthink = time + 0.5;
	self.health_max = g_vehicle_car_health;
	self.health_regen = g_vehicle_car_health_regen;
	self.health_regen_dmgpause = g_vehicle_car_health_regen_dmgpause;
}
