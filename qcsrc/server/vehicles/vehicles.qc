#ifdef VEHICLES_ENABLED
#include "spiderbot.qc"
#include "aircraft.qc"
#include "doyoulikemycar.qc"

void vehicle_adjust_player_position(entity plr, entity veh, float start_offs, float back, float up) {
	makevectors(plr.v_angle);
	vector v = veh.origin;
	v_z += start_offs;
	tracebox(v, '-8 -8 -8', '8 8 8', v - v_forward * back, MOVE_WORLDONLY, world);
	v = trace_endpos;
	tracebox(v, '-8 -8 -8', '8 8 8', v + v_up * up, MOVE_WORLDONLY, world);
	setorigin(plr, trace_endpos);
}

float vehicle_extract_player(entity plr, float eject)
{
	if not(plr.vehicle)
		return 0;

	entity e = self;
	e.vehicle_exit_time = time;
	self = plr.vehicle;
	self.vehicle_exit(eject);
	self = e;
    plr.PlayerPhysplug = physic_plug_null;
    plr.vehicle        = world;
	plr.view_ofs       = PL_VIEW_OFS;
	plr.hud            = HUD_NORMAL;
	plr.event_damage   = PlayerDamage;
	plr.lastpushtime = time;
    setsize(plr,PL_MIN,PL_MAX);
	return 1;
}

float player_can_use_vehicle(entity plr) {
	if (plr.vehicle_exit_time >= time)
		return FALSE;

    if(plr.classname != "player")
        return FALSE;

	if not(PlayerCanFire(plr, FALSE))
		return FALSE;

    if(plr.vehicle != world)
        return FALSE;

	return TRUE;
}

void vehicle_stdproc_setcolormod() {
	turret_stdproc_setcolormod();
	if (self.vehicle)
		self.vehicle.colormod = self.colormod;
}

void vehicle_stdproc_regen()
{
    float smax,hmax;

    smax = self.shield_max;
    hmax = self.health_max;

    if(self.vehicle_flags & VHF_HASSHIELD)
    if(self.vehicle_flags & VHF_SHIELDREGEN)
    if(self.vehicle_shield < smax)
    if(self.dmg_time + self.shield_regen_dmgpause < time)
    {
        self.vehicle_shield = min(self.vehicle_shield + self.shield_regen * sys_ticrate, smax);

        if(self.owner)
            self.owner.vehicle_shield = self.vehicle_shield / smax;
    }

    if(self.vehicle_flags & VHF_HEALTHREGEN)
    if(self.dmg_time + self.health_regen_dmgpause < time)
    if(self.health < hmax)
    {
        self.health = min(self.health + self.health_regen * sys_ticrate, hmax);

        if(self.owner)
            self.owner.vehicle_health = self.health / hmax;
    }
}

void shieldhit_think()
{
    self.alpha = self.alpha - 0.125;
    if not(self.alpha <= 0)
    {
        self.nextthink = time;
    }
    else
    {
        setmodel(self,"");
        self.alpha = -1;
    }
    //self.think = SUB_Remove;
}

void vehicle_stdproc_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{

    float ddmg_take;

    self.dmg_time = time;

    if((self.vehicle_flags & VHF_HASSHIELD) && (self.vehicle_shield > 0))
    {
        if not (self.tur_head.enemy)
            self.tur_head.enemy = spawn();

        entity sh;

        sh = self.tur_head.enemy;
        sh.colormod = '1 1 1';
        sh.alpha = 0.5;
        sh.scale  = (128 / vlen(self.maxs - self.mins))*2;
        //sh.scale = 1.25;

        sh.effects = EF_LOWPRECISION;
        sh.angles = vectoangles(normalize(hitloc - self.origin)) - self.angles;

        setmodel(sh,"models/vhshield.md3");
        setattachment(sh,self,"");
        sh.think = shieldhit_think;
        sh.nextthink = time;


        self.vehicle_shield -= damage;
        if(self.vehicle_shield < 0)
        {
            sh.colormod = '10 0 -1';
            ddmg_take = fabs(self.vehicle_shield);
            self.vehicle_shield = 0;

            self.health -= ddmg_take;
        }
    }
    else
        self.health -= damage;

	if (random() < 0.5)
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit1.wav", VOL_BASE, ATTN_NORM);
	else
		sound(self, CHAN_TRIGGER, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);

    if(self.owner)
    {
        self.owner.vehicle_health = self.health / CCVAR("_health");

        if(self.vehicle_flags & VHF_HASSHIELD)
            self.owner.vehicle_shield = self.vehicle_shield / cvar(strcat(self.cvar_basename,"_shield"));

    }

    if(self.health <= 0)
    {
        if(self.owner)
            vehicle_extract_player(self.owner, VHEF_EJECT);

        self.vehicle_die();
    }


}

void bugmenot()
{
    self.vehicle_exit       = self.vehicle_exit;
    self.vehicle_die        = self.vehicle_exit;
    self.vehicle_spawn      = self.vehicle_exit;
    self.vehicle_message    = self.vehicle_exit;
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

float vehicles_init_done;
void vehicles_init() {
	if (vehicles_init_done)
		return;

	precache_sound("onslaught/ons_hit1.wav");
	precache_sound("onslaught/ons_hit2.wav");
	vehicles_init_done = TRUE;
	vehicle_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = vehicle_PlayerClear;
	vehicle_PlayerAlphaMod_NextLink = GameHookChain_PlayerAlphaMod;
	GameHookChain_PlayerAlphaMod = vehicle_PlayerAlphaMod;
	PhysicEnableCSQC();
}

float vehicle_enter(vector ang, float() phys_plug, float _hud, float(entity, float)phys_send ) {
    if(teamplay)
    if(self.team)
    if(self.team != other.team)
        return FALSE;

    self.owner = other;
    self.switchweapon = other.switchweapon;
    self.event_damage         = vehicle_stdproc_damage ;
    self.owner.angles         = self.angles;
    self.owner.takedamage     = DAMAGE_NO;
    self.owner.solid          = SOLID_NOT;
	if not(sv_csqc_physic)
		self.owner.movetype   = MOVETYPE_NOCLIP;

    self.owner.PlayerPhysplug = phys_plug;
    self.owner.vehicle        = self;
    self.owner.event_damage   = SUB_Null;
    self.owner.hud            = _hud;
    self.team                 = self.owner.team;
    if(clienttype(other) == CLIENTTYPE_REAL)
    {
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
	Net_LinkEntity(self.player_physic, FALSE, 0, phys_send);
	return TRUE;
}

void vehicle_speed_keeper_think() { //something reset velocity to 0 0 0, fix this
	self.enemy.velocity = self.velocity;
	remove(self);
}

void vehicle_stdproc_exit(float eject, float eject_range, float exit_up, float range) {
	vector exit_origin;
	makevectors(self.angles);
	if(eject)
		exit_origin = self.origin + '0 0 1' * eject_range;
	else
		exit_origin = self.origin + v_forward * range + '0 0 1' * exit_up;

	tracebox(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
	if not(eject) {
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_right * range + '0 0 1' * exit_up;
			tracebox(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin + v_right * range + '0 0 1' * exit_up;
			tracebox(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_forward * range + '0 0 1' * exit_up;
			tracebox(self.origin + '0 0 1' * exit_up, PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
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
    self.owner.solid          = SOLID_SLIDEBOX;
    self.owner.movetype       = MOVETYPE_WALK;
    if not (teamplay)
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

void vehicle_stdproc_die() {
    self.health = 0;
    self.event_damage = SUB_Null;
    self.iscreature = FALSE;
    self.solid      = SOLID_NOT;
    self.takedamage = DAMAGE_NO;
    self.touch      = SUB_Null;
    self.deadflag    = DEAD_DEAD;
}

void vehicle_stdproc_spawn() {
    self.health = self.health_max;
    self.vehicle_shield = self.shield_max;
    self.event_damage = vehicle_stdproc_damage;
    self.iscreature = TRUE;
    self.solid      = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;
	self.deadflag    = DEAD_NO;
    self.bot_attack = TRUE;
    self.event_damage = vehicle_stdproc_damage;
    setorigin(self,self.enemy.origin);
    self.angles = self.enemy.angles;
	antilag_teleported(self);
	vehicle_stdproc_setcolormod();
    pointparticles(particleeffectnum("teleport"), self.origin + (self.mins + self.maxs) * 0.5, '0 0 0', 1);
}

void vehicle_stdproc_prepare() {
	self.health_max = CCVAR("_health");
	self.health_regen = CCVAR("_health_regen");
	self.health_regen_dmgpause = CCVAR("_health_regen_dmgpause");
	self.shield_max = CCVAR("_shield");
	self.shield_regen = CCVAR("_shield_regen");
	self.shield_regen_dmgpause = CCVAR("_shield_regen_dmgpause");
	antilag_add(self);
}
#endif
