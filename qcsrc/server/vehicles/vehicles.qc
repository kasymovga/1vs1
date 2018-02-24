#ifdef VEHICLES_ENABLED
#include "spiderbot.qc"
#include "aircraft.qc"

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
    self.vehicle_enter      = self.vehicle_exit;
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
#endif
