void(entity plr, entity veh, float start_offs, float back, float up) vehicle_adjust_player_position {
	makevectors(plr.v_angle);
	vector v = veh.origin;
	v_z += start_offs;
	trace_box(v, '-8 -8 -8', '8 8 8', v - v_forward * back, MOVE_WORLDONLY, world);
	v = trace_endpos;
	trace_box(v, '-8 -8 -8', '8 8 8', v + v_up * up, MOVE_WORLDONLY, world);
	setorigin(plr, trace_endpos - plr.view_ofs);
}

float(entity plr, float eject) vehicle_extract_player {
	if not(plr.vehicle)
		return 0;

	entity e = self;
	e.vehicle_exit_time = time;
	self = plr.vehicle;
	self.vehicle_exit(eject);
	self = e;
    plr.PlayerPhysplug = physics_plug_null;
    plr.vehicle        = world;
	plr.view_ofs       = PL_VIEW_OFS;
	plr.hud            = HUD_NORMAL;
	plr.lastpushtime = time;
    setsize(plr,PL_MIN,PL_MAX);
	return 1;
}

float player_can_use_vehicle(entity plr) {
	if (plr.vehicle_exit_time >= time)
		return FALSE;

    if(plr.classname != "player")
        return FALSE;

	if not(player_can_fire(plr, FALSE))
		return FALSE;

    if(plr.vehicle != world)
        return FALSE;

	return TRUE;
}

void(void) vehicle_stdproc_setcolormod {
	turret_stdproc_setcolormod();
	if (self.vehicle)
		self.vehicle.colormod = self.colormod;
}

void(void) vehicle_stdproc_regen {
    float smax,hmax;
    smax = self.shield_max;
    hmax = self.health_max;
    if(self.vehicle_flags & VHF_HASSHIELD)
    if(self.vehicle_flags & VHF_SHIELDREGEN)
    if(self.vehicle_shield < smax)
    if(self.dmg_time + self.shield_regen_dmgpause < time) {
        self.vehicle_shield = min(self.vehicle_shield + self.shield_regen * sys_ticrate, smax);
        if(self.owner)
            self.owner.vehicle_shield = self.vehicle_shield / smax;
    }
    if(self.vehicle_flags & VHF_HEALTHREGEN)
    if(self.dmg_time + self.health_regen_dmgpause < time)
    if(self.health < hmax) {
        self.health = min(self.health + self.health_regen * sys_ticrate, hmax);
        if(self.owner)
            self.owner.vehicle_health = self.health / hmax;
    }
}

void(void) vehicle_shieldhit_think {
    self.alpha = self.alpha - 0.125;
    if not(self.alpha <= 0) {
        self.nextthink = time;
    } else {
        setmodel(self,"");
        self.alpha = -1;
    }
    //self.think = stdproc_remove;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) vehicle_stdproc_damage {
    float ddmg_take;
    self.dmg_time = time;
    if((self.vehicle_flags & VHF_HASSHIELD) && (self.vehicle_shield > 0)) {
        if not (self.killindicator)
            self.killindicator = spawn();

        entity sh;
        sh = self.killindicator;
        sh.colormod = '1 1 1';
        sh.alpha = 0.5;
        sh.scale  = (128 / vlen(self.maxs - self.mins))*2;
        //sh.scale = 1.25;
        sh.effects = EF_LOWPRECISION;
        sh.angles = vectoangles(normalize(hitloc - self.origin)) - self.angles;
        setmodel(sh,"models/vhshield.md3");
        setattachment(sh,self,"");
        sh.think = vehicle_shieldhit_think;
        sh.nextthink = time;
        self.vehicle_shield -= _damage;
        if(self.vehicle_shield < 0) {
            sh.colormod = '10 0 -1';
            ddmg_take = fabs(self.vehicle_shield);
            self.vehicle_shield = 0;
            self.health -= ddmg_take;
        }
    } else
        self.health -= _damage;

	if (random() < 0.5)
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit1.wav", VOL_BASE, ATTN_NORM);
	else
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);

    if(self.owner) {
        self.owner.vehicle_health = self.health / self.health_max;

        if(self.vehicle_flags & VHF_HASSHIELD)
            self.owner.vehicle_shield = self.vehicle_shield / cvar(strcat(self.cvar_basename,"_shield"));

    }
    if(self.health < 1) {
        if(self.owner)
            vehicle_extract_player(self.owner, TRUE);

        self.vehicle_die();
    }
}

void(void) vehicle_reset {
	if(self.owner)
		vehicle_extract_player(self.owner, TRUE);

	self.vehicle_spawn();
}

var void(float killed) vehicle_PlayerClear_NextLink;
void vehicle_PlayerClear(float killed) {
	vehicle_extract_player(self, TRUE);
	vehicle_PlayerClear_NextLink(killed);
}

var float(entity plr, entity viewer, float dalpha) vehicle_PlayerAlphaMod_NextLink;
float vehicle_PlayerAlphaMod(entity plr, entity viewer, float dalpha) {
	if (plr.vehicle)
	if (plr.vehicle.vehicle_flags & VHF_HIDEPLAYER)
		dalpha = -1;

	return vehicle_PlayerAlphaMod_NextLink(plr, viewer, dalpha);
}

var float(void) vehicle_ThrowWeaponHandle_NextLink;
float(void) vehicle_ThrowWeaponHandle {
	if (vehicle_extract_player(self, FALSE))
		return TRUE;

	return vehicle_ThrowWeaponHandle_NextLink();
}

var entity(entity) vehicle_player_entity_next_link;
entity(entity pl) vehicle_player_entity {
	if (pl.vehicle)
		return pl.vehicle;

	return vehicle_player_entity_next_link(pl);
}

float vehicle_init_done;
void(void) vehicle_init {
	if (vehicle_init_done)
		return;

	precache_sound("onslaught/ons_hit1.wav");
	precache_sound("onslaught/ons_hit2.wav");
	vehicle_init_done = TRUE;
	vehicle_PlayerClear_NextLink = gamehook_chain_player_clear;
	gamehook_chain_player_clear = vehicle_PlayerClear;
	vehicle_PlayerAlphaMod_NextLink = gamehook_chain_player_alpha_mod;
	gamehook_chain_player_alpha_mod = vehicle_PlayerAlphaMod;
	vehicle_ThrowWeaponHandle_NextLink = GameHookChain_ThrowWeaponHandle;
	GameHookChain_ThrowWeaponHandle = vehicle_ThrowWeaponHandle;
	vehicle_player_entity_next_link = gamehook_chain_player_entity;
	gamehook_chain_player_entity = vehicle_player_entity;
	addstat(STAT_HUD, AS_INT,  hud);
	addstat(STAT_SPIDERBOT_ROCKETS, AS_INT,   rockets);
	addstat(STAT_SPIDERBOT_RELOAD,  AS_FLOAT, rockets_reload);
	addstat(STAT_SPIDERBOT_HEAT,    AS_FLOAT, vehicle_heat);
	addstat(STAT_SPIDERBOT_HEALTH,  AS_FLOAT, vehicle_health);
	addstat(STAT_SPIDERBOT_SHIELD,  AS_FLOAT, vehicle_shield);
}

float(vector ang, float() phys_plug, float _hud, float(entity, float) phys_send) vehicle_enter {
    if (team_mode)
    if (self.team)
    if (self.team != other.team)
        return FALSE;

	if (_hud == HUD_SPIDERBOT) {
		other.vehicle_health = (self.health / self.health_max);
		if (self.vehicle_flags & VHF_HASSHIELD)
			other.vehicle_shield = (self.vehicle_shield / self.shield_max);
		else
			other.vehicle_shield = -1;

		if (self.vehicle_flags & VHF_HEAT)
			other.vehicle_heat = self.vehicle_heat;
		else
			other.vehicle_heat = -1;

		if (self.vehicle_flags & VHF_HASROCKETS) {
			other.rockets = self.rockets;
			other.rockets_reload = self.rockets_reload;
		} else {
			other.rockets = -1;
		}
	}
    self.owner = other;
    self.switchweapon = other.switchweapon;
    self.owner.angles         = self.angles;
    self.owner.takedamage     = DAMAGE_NO;
    self.owner.solid          = SOLID_NOT;
    self.owner.PlayerPhysplug = phys_plug;
    self.owner.vehicle        = self;
    self.owner.hud            = _hud;
    self.team                 = self.owner.team;
    if(clienttype(other) == CLIENTTYPE_REAL) {
        msg_entity = other;
        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);  // 10 = SVC_SETVIEWANGLES
        WriteAngle(MSG_ONE, ang_x);    // tilt
        WriteAngle(MSG_ONE, ang_y);    // yaw
        WriteAngle(MSG_ONE, 0);    // roll
		self.bot_nextthink = 0;
    } else {
		self.bot_nextthink = time + 5;
	}
	self.player_physic = spawn();
	self.player_physic.viewmodelforclient = self.owner;
	self.player_physic.vehicle = self;
	net_link_entity(self.player_physic, FALSE, 0, phys_send);
	return TRUE;
}

void(void) vehicle_speed_keeper_think { //something reset velocity to 0 0 0, fix this
	self.enemy.velocity = self.velocity;
	remove(self);
}

void(float eject, float eject_range, float exit_up, float range) vehicle_stdproc_exit {
	vector exit_origin;
	makevectors(self.angles);
	if(eject)
		exit_origin = self.origin + '0 0 1' * eject_range;
	else
		exit_origin = self.origin + v_forward * range + '0 0 1' * exit_up;

	trace_box(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
	if not(eject) {
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_right * range + '0 0 1' * exit_up;
			trace_box(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin + v_right * range + '0 0 1' * exit_up;
			trace_box(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_forward * range + '0 0 1' * exit_up;
			trace_box(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1)
			exit_origin = self.origin + '0 0 1' * exit_up;
	}
	exit_origin = trace_endpos;
    self.owner.switchweapon = self.switchweapon;
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
    self.owner.takedamage     = DAMAGE_AIM;
	player_body_setup(self.owner);
    if not(team_mode)
        self.team = 0;
    else
        self.team = self.enemy.team ;

	setorigin(self.owner, exit_origin);
	self.owner.velocity = self.velocity;
	if(eject) {
	    self.owner.velocity = self.owner.velocity + (v_up + v_forward * 0.25) * 750;
	}

	entity e = spawn();
	e.enemy = self.owner;
	e.velocity = self.velocity;
	e.think = vehicle_speed_keeper_think;
	e.nextthink = time;
	if (self.player_physic)
		remove(self.player_physic);

	self.owner.angles_x = 0;
	self.owner.angles_z = 0;
    self.owner = world;
}

float(void) vehicle_stdproc_customize {
    if(self.deadflag == DEAD_DEAD)
        return FALSE;

    return TRUE;
}

void(string name, void() delayed_init) vehicle_stdproc_init {
	self.health_max = cvar(strcat("g_vehicle_", name, "_health"));
	self.health_regen = cvar(strcat("g_vehicle_", name, "_health_regen"));
	self.health_regen_dmgpause = cvar(strcat("g_vehicle_", name, "_health_regen_dmgpause"));
	self.shield_max = cvar(strcat("g_vehicle_", name, "_shield"));
	self.shield_regen = cvar(strcat("g_vehicle_", name, "_shield_regen"));
	self.shield_regen_dmgpause = cvar(strcat("g_vehicle_", name, "_shield_regen_dmgpause"));
	entity_initialize(self, delayed_init, INITPRIO_DROPTOFLOOR);
}
