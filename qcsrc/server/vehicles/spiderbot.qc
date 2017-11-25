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

#define spiderbot_spawnpnt enemy

float g_vehicle_spiderbot_crush_dmg;
float g_vehicle_spiderbot_crush_force;
float g_vehicle_spiderbot_crush_minspeed;
float g_vehicle_spiderbot_head_pitchlimit_down;
float g_vehicle_spiderbot_head_pitchlimit_up;
float g_vehicle_spiderbot_head_pitchspeed;
float g_vehicle_spiderbot_head_turnlimit;
float g_vehicle_spiderbot_head_turnspeed;
float g_vehicle_spiderbot_health;
float g_vehicle_spiderbot_health_regen;
float g_vehicle_spiderbot_health_regen_dmgpause;
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
float g_vehicle_spiderbot_shield;
float g_vehicle_spiderbot_shield_regen;
float g_vehicle_spiderbot_shield_regen_dmgpause;

float SpiderbotPhysic_SendEntity(entity to, float sf);
void spiderbot_exit(float eject);
void spiderbot_enter();

void spiderbot_stop(entity spider) {
	spider.vehicle.anim_start = 0;
	spider.vehicle.anim_end = 0;
	spider.vehicle.frame = 5;

}

void spiderbot_rocket_explode()
{
    vector org2;

    if(self.event_damage != SUB_Null)
    {
        self.event_damage = SUB_Null;
        self.think = spiderbot_rocket_explode;
        self.nextthink = time;
        return;
    }

    org2 = findbetterlocation (self.origin, 16);
    w_deathtypestring = "dident escape the rocket barrage";

    RadiusDamage (self, self.realowner,
     g_vehicle_spiderbot_rocket_damage,
     g_vehicle_spiderbot_rocket_edgedamage,
     g_vehicle_spiderbot_rocket_radius, world,
     g_vehicle_spiderbot_rocket_force, WEP_ROCKET_LAUNCHER, world);

    remove (self);
}

void spiderbot_rocket_touch()
{
    PROJECTILE_TOUCH;
    spiderbot_rocket_explode();
}

void spiderbot_rocket_think()
{
    vector newdir,olddir;

    self.nextthink  = time;
    if (self.realowner.deadflag != DEAD_NO)
    {
        spiderbot_rocket_explode();
        return;
    }

    if not (self.realowner.vehicle)
    {
        UpdateCSQCProjectile(self);
        return;
    }

    self.touch      = spiderbot_rocket_touch;
    olddir = normalize(self.velocity);
    newdir = normalize(self.realowner.cursor_trace_endpos - self.origin);
    newdir += randomvec() * g_vehicle_spiderbot_rocket_noise;
    self.velocity = normalize(olddir + newdir * g_vehicle_spiderbot_rocket_turnrate) * g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(self);
}

void spiderbot_rocket_do()
{
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
    missile                 = CSQCProjectile(FALSE, PROJECTILE_ROCKET, FALSE); // no culling, has fly sound
    setorigin(missile,gettaginfo(self.tur_head,gettagindex(self.tur_head,"tag_fire")));
    te_explosion (missile.origin);

    missile.classname       = "spiderbot_rocket";
    missile.owner           = self;
    missile.realowner       = self.owner;
    missile.bot_dodge       = TRUE;
    missile.bot_dodgerating = 75;
    missile.nextthink       = time;// + 0.2;
    missile.movetype        = MOVETYPE_FLYMISSILE;
    missile.velocity        = normalize(v_forward + (v_up * g_vehicle_spiderbot_rocket_up) + randomvec() * g_vehicle_spiderbot_rocket_spread) * g_vehicle_spiderbot_rocket_speed;
    missile.angles          = vectoangles(missile.velocity);
    missile.think           = spiderbot_rocket_think;
    missile.solid           = SOLID_BBOX;
}

void spiderbot_minigun_fire_Flash_Go() {
	if (self.frame > 10){
		self.alpha = -1;
		setmodel(self,"");
		return;
	}

	self.frame = self.frame + 2;
	self.alpha = self.alpha - 0.2;
	self.nextthink = time + 0.02;
}

void spiderbot_minigun_fire(entity gun)
{

    entity flash;
    vector v;
    v = gettaginfo(gun,gettagindex(gun,"barrels"));
    v_forward = normalize(v_forward);

    sound (gun, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);

	antilag_prepare(self);
	fireBallisticBullet(v, v_forward, g_vehicle_spiderbot_minigun_spread, 10000, 5,
			g_vehicle_spiderbot_minigun_damage, 0, 0, WEP_UZI, particleeffectnum("EF_MGTURRETTRAIL"), 0, 0);

    if not (gun.enemy)
    {
        gun.enemy = spawn();
        setattachment(gun.enemy , gun, "barrels");
        setorigin(gun.enemy ,gun.enemy.origin + '48 0 0');
    }

    flash = gun.enemy; //spawn();
    setmodel(flash, "models/uziflash.md3"); // precision set below
    flash.think = spiderbot_minigun_fire_Flash_Go;
    flash.nextthink = time + 0.02;
    flash.frame = 2;
    flash.angles_z = flash.v_angle_z + random() * 180;
    flash.alpha = 1;
    flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
}

void spiderbot_miniguns_do()
{
    if ((self.owner.BUTTON_ATCK) && (self.owner.vehicle_heat < 1) && (self.tur_head.attack_finished_single < time))
    {
		float rotation;
		rotation = 720 * sys_ticrate / g_vehicle_spiderbot_minigun_refire;
		float mod_rotation = mod(rotation, 90);
		if (mod_rotation < 10 || mod_rotation > 80) rotation += 30;
        self.gun1.angles_z += rotation;
        self.gun2.angles_z -= rotation;
        if(self.gun1.angles_z >= 360)
        {
            self.gun1.angles_z = 0;
            self.gun2.angles_z = 360;
        }
		self.vehicle_hudmodel.gun1.angles_z = self.gun1.angles_z;
		self.vehicle_hudmodel.gun2.angles_z = self.gun2.angles_z;

        self = self.owner;
		spiderbot_minigun_fire(self.vehicle.gun1);
		spiderbot_minigun_fire(self.vehicle.gun2);
        self = self.vehicle;
        self.vehicle_heat += g_vehicle_spiderbot_minigun_heat * g_vehicle_spiderbot_minigun_refire;
        if(self.vehicle_heat >= 1)
        {
            self.vehicle_heat = 1;
            self.tur_head.attack_finished_single = (1/g_vehicle_spiderbot_minigun_cooldown)+time;
        }
        else
            self.tur_head.attack_finished_single = g_vehicle_spiderbot_minigun_refire + time;
    }
}
float spiderbot_physic_hook()
{
    vector ad;
    entity player,spider;
    float ftmp,ftmp2;

    player = self;
    spider = self.vehicle;

    player.BUTTON_ZOOM = 0;
    player.BUTTON_CROUCH = 0;
    player.switchweapon = 0;


    if(player.BUTTON_USE) {
		vehicle_extract_player(player, FALSE);
		return 1;
	}
    if(gameover) {
		spider.velocity = '0 0 0';
		return 1;
	}

    player.exteriormodeltoclient = spider.tur_head;

    self = spider;
    if(spider.flags & FL_ONGROUND)
    {
		if (self.wasFlying || vlen(self.velocity) > 100)
		if (self.nextstep <= time) {
			GlobalSound(globalsound_metalfall, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
			self.nextstep = time + 0.2;
		}

		spider.wasFlying = 0;
        if(player.BUTTON_JUMP)
        {
            player.BUTTON_JUMP = 0;
            spider.vehicle.anim_start = MODEL_SPIDERBOT_JUMP_START;
            spider.vehicle.anim_end   = MODEL_SPIDERBOT_JUMP_END;
            spider.vehicle.frame = 4;
        }
        else
        {
            if(vlen(player.movement) == 0)
            {
				spiderbot_stop(spider);
            }
            else
            {
                if(player.movement_x != 0)
                {
                    if(player.movement_x > 0)
                    {
                        spider.vehicle.anim_start = MODEL_SPIDERBOT_FORWARD_START;
                        spider.vehicle.anim_end   = MODEL_SPIDERBOT_FORWARD_END;
                        spider.vehicle.frame = 0;
                    }
                    else if(player.movement_x < 0)
                    {
                        spider.vehicle.anim_start = MODEL_SPIDERBOT_BACKWARDS_START;
                        spider.vehicle.anim_end   = MODEL_SPIDERBOT_BACKWARDS_END;
                        spider.vehicle.frame = 1;
                    }
                }
                else if(player.movement_y != 0)
                {
                    if(player.movement_y < 0)
                    {
                        spider.vehicle.anim_start = MODEL_SPIDERBOT_LEFT_START;
                        spider.vehicle.anim_end   = MODEL_SPIDERBOT_LEFT_END;
                        spider.vehicle.frame = 2;
                    }
                    else if(player.movement_y > 0)
                    {
                        spider.vehicle.anim_start = MODEL_SPIDERBOT_RIGHT_START;
                        spider.vehicle.anim_end   = MODEL_SPIDERBOT_RIGHT_END;
                        spider.vehicle.frame = 3;
                    }
                }

            }
        }
    } else
		spider.wasFlying = 1;

    //anim_do();
    spiderbot_miniguns_do();
    spiderbot_rocket_do();
    vehicle_stdproc_regen();

    player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
    player.rockets = spider.tur_head.frame;

    if(spider.gun2.cnt <= time)
        player.rockets_reload = 1;
    else
        player.rockets_reload = 1 - ((spider.gun2.cnt - time) /spider.attack_finished_single);

	physic_spiderbot();

    spider.tur_head.angles_x *= -1;
    spider.angles_x *= -1;
    //player.angles_x *= -1;

    //ad = player.v_angle - (spider.tur_head.angles + spider.angles);
    ad = player.v_angle -  (spider.tur_head.angles + spider.angles);

    // Rotate head
    ftmp = g_vehicle_spiderbot_head_turnspeed * frametime;
    ftmp2 = ftmp * -1;
    spider.tur_head.angles_y += bound(ftmp2,shortangle_f(ad_y,spider.tur_head.angles_y),ftmp);
    spider.tur_head.angles_y = bound(g_vehicle_spiderbot_head_turnlimit * -1,spider.tur_head.angles_y,g_vehicle_spiderbot_head_turnlimit);

    // Pitch head
    ftmp = g_vehicle_spiderbot_head_pitchspeed * frametime;
    ftmp2 = ftmp * -1;
    spider.tur_head.angles_x += bound(ftmp2,shortangle_f(ad_x,spider.tur_head.angles_x),ftmp);
    spider.tur_head.angles_x = bound(g_vehicle_spiderbot_head_pitchlimit_down,spider.tur_head.angles_x,g_vehicle_spiderbot_head_pitchlimit_up);

    spider.tur_head.angles_x *= -1;
    spider.angles_x *= -1;
    //player.angles_x *= -1;


	setorigin(player, spider.origin + '0 0 48');
	player.angles = spider.angles;
	//spider.vehicle.angles = spider.angles;
	physic_velocity = player.velocity = '0 0 0';
    self = player;
	//print("spider.angles_x=", ftos(spider.angles_x), "\n");
	//print("spider.tur_head.angles_x=", ftos(spider.tur_head.angles_x), "\n");
	//print("player.v_angle_x=", ftos(player.v_angle_x), "\n");
	spider.vehicle_hudmodel.angles_z = spider.angles_z;
	spider.vehicle_hudmodel.angles_y = spider.angles_y - player.v_angle_y + spider.tur_head.angles_y;
	spider.vehicle_hudmodel.angles_x = bound(-90, -1 * (spider.tur_head.angles_x + player.v_angle_x + spider.angles_x), 90) * cos(spider.vehicle_hudmodel.angles_y * DEG2RAD);

	if (spider.player_physic)
		spider.player_physic.SendFlags |= 2;

    return 1;
}

void spiderbot_think()
{
	if(self.vehicle_heat > 0)
		self.vehicle_heat = max(self.vehicle_heat - g_vehicle_spiderbot_minigun_cooldown * sys_ticrate,0);

	if (self.owner)
		self.owner.vehicle_heat = self.vehicle_heat;
    else if(self.flags & FL_ONGROUND)
    {
        movelib_beak_simple(g_vehicle_spiderbot_speed_stop * frametime);
        //movelib_groundalign4point(300,100);
    }

    self.nextthink = time;
}

void spiderbot_enter()
{
    // Remove this when bots know how to use the spiderbot
    if not (clienttype(other) == CLIENTTYPE_REAL)
        return;

    if(teamplay)
    if(self.team)
    if(self.team != other.team)
        return;

    self.owner = other;
    self.switchweapon = other.switchweapon;

    self.event_damage         = vehicle_stdproc_damage ;
    self.colormap             = self.owner.colormap;
    self.tur_head.colormap    = self.owner.colormap;
    self.vehicle_hudmodel.viewmodelforclient = self.owner;
    self.owner.angles         = self.angles;
    self.owner.takedamage     = DAMAGE_NO;
    self.owner.solid          = SOLID_NOT;
	if not(sv_csqc_physic)
		self.owner.movetype   = MOVETYPE_NOCLIP;

    self.owner.PlayerPhysplug = spiderbot_physic_hook;
    self.owner.vehicle        = self;
    self.owner.event_damage   = SUB_Null;
    self.owner.hud            = HUD_SPIDERBOT;
    self.owner.vehicle_health = (self.health / g_vehicle_spiderbot_health);
    self.owner.vehicle_shield = (self.vehicle_shield / g_vehicle_spiderbot_shield);
	self.owner.vehicle_heat = self.vehicle_heat;
    self.team                   = self.owner.team;
	setattachment(self.vehicle, other, "");
	setorigin(self.vehicle, '0 0 -48');
	vehicle_stdproc_setcolormod();

    if(clienttype(other) == CLIENTTYPE_REAL)
    {
        msg_entity = other;
        //WriteByte (MSG_ONE, SVC_SETVIEWPORT);
        //WriteEntity(MSG_ONE, self.vehicle_viewport);

        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);  // 10 = SVC_SETVIEWANGLES
        WriteAngle(MSG_ONE, self.tur_head.angles_x + self.angles_x);    // tilt
        WriteAngle(MSG_ONE, self.tur_head.angles_y + self.angles_y);    // yaw
        WriteAngle(MSG_ONE, 0);    // roll
		//other.angles_x = self.tur_head.angles_x + self.angles_x;
		//other.angles_y = self.tur_head.angles_y + self.angles_y;
		//other.fixangle = TRUE;
    }

    //WriteAngle(MSG_ONE, self.tur_head.angles_z + self.angles_z);    // roll
    //self.owner.view_ofs = '0 0 0';
    //self.tur_head.nodrawtoclient = self.owner;
	self.player_physic = spawn();
	self.player_physic.viewmodelforclient = self.owner;
	self.player_physic.vehicle = self;
	Net_LinkEntity(self.player_physic, FALSE, 0, SpiderbotPhysic_SendEntity);
}

void spiderbot_exit(float eject)
{
    entity e;
	vector exit_origin;
	makevectors(self.angles);
	if(eject)
		exit_origin = self.origin + '0 0 160';
	else
		exit_origin = self.origin + v_forward * 130 + '0 0 64';

	tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
	if not(eject) {
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_right * 130 + '0 0 64';
			tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin + v_right * 130 + '0 0 64';
			tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1) {
			exit_origin = self.origin - v_forward * 130 + '0 0 64';
			tracebox(self.origin + '0 0 20', PL_MIN, PL_MAX, exit_origin, MOVE_NOMONSTERS, self.owner);
		}
		if (trace_fraction < 1)
			exit_origin = self.origin + '0 0 64';
	}

	exit_origin = trace_endpos;
    self.frame = 5;
    e = findchain(classname,"spiderbot_rocket");
	setattachment(self.vehicle, self, "");
	setorigin(self.vehicle, '0 0 0');

    while(e)
    {
        if(e.owner == self.owner)
        {
            e.realowner = self.owner;
            e.owner = world;
            //e.solid = SOLID_BBOX;
            //e.think = SUB_Null;
            //e.nextthink = -1;
        }
        e = e.chain;
    }

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

    self.think = spiderbot_think;
    self.nextthink = time;
    self.owner.takedamage     = DAMAGE_AIM;
    self.owner.solid          = SOLID_SLIDEBOX;
    self.owner.movetype       = MOVETYPE_WALK;

	self.colormap            = 1024;
	self.tur_head.colormap   = 1024;

    if not (teamplay)
        self.team                = 0;
    else
        self.team = self.spiderbot_spawnpnt.team ;

	vehicle_stdproc_setcolormod();

	self.vehicle_hudmodel.viewmodelforclient = self;
	self.tur_head.nodrawtoclient             = self;

	setorigin(self.owner, exit_origin);
	if(eject)
	    self.owner.velocity = (v_up + v_forward * 0.25) * 750;

	if (self.player_physic)
		remove(self.player_physic);

	self.owner.angles_x = 0;
	self.owner.angles_z = 0;
    self.owner = world;
	spiderbot_stop(self);
	self.angles_x = -self.angles_x;
}

void spiderbot_touch()
{
    if(self.owner)
    {
        if(vlen(self.velocity) < g_vehicle_spiderbot_crush_minspeed)
            return;

        if(other.classname != "player")
            return;

		float f = vlen(self.velocity - other.velocity);
		if (f > g_vehicle_spiderbot_crush_minspeed) {
			f /= g_vehicle_spiderbot_speed_walk;
			Damage(other,self,self.owner,g_vehicle_spiderbot_crush_dmg * f,DEATH_TURRET,'0 0 0', normalize(other.origin - self.origin) * g_vehicle_spiderbot_crush_force * f);
		}
        return;
    }
	if not(player_can_use_vehicle(other))
		return;

    spiderbot_enter();
}

float spiderbot_customizeentityforclient()
{
	//if (self.owner == other) {
	//	if (self.alpha > 0)
	//		self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = -1;
	//} else if (self.alpha < 0)
	//	self.alpha = 1;

    if(self.deadflag == DEAD_DEAD)
        return FALSE;

    return TRUE;
}

//void spiderbot_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force);
void spiderbot_spawn()
{
    self.frame = 5;
    self.think = spiderbot_think;
    self.nextthink = time;

    self.health = CCVAR("_health");
    self.vehicle_shield = CCVAR("_shield");
    self.event_damage = vehicle_stdproc_damage;
    self.iscreature = TRUE;
    self.movetype   = MOVETYPE_WALK;
    self.solid      = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;
    self.touch      = spiderbot_touch;
    self.alpha      = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = 1;
    self.tur_head.angles = '0 0 0';
	self.colormap = 1024;
	self.tur_head.colormap = 1024;
	self.deadflag    = DEAD_NO;
    self.bot_attack = TRUE;

    setsize(self,spiderbot_MIN,spiderbot_MAX);

    setorigin(self,self.spiderbot_spawnpnt.origin);
    self.angles = self.spiderbot_spawnpnt.angles;

	vehicle_stdproc_setcolormod();

    pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);
}

void spiderbot_blowup()
{
    RadiusDamage (self, self, 100, 15, 250, world, 250, WEP_ROCKET_LAUNCHER, world);
    self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = -1;
    self.nextthink  = time + 10;
    self.think      = spiderbot_spawn;

    setorigin(self,self.tur_aimpos);
}

void spiderbot_die()
{

    self.health = 0;
    self.event_damage = SUB_Null;
    self.iscreature = FALSE;
    self.solid      = SOLID_NOT;
    self.takedamage = DAMAGE_NO;
    self.touch      = SUB_Null;
    self.deadflag    = DEAD_DEAD;
	self.vehicle_hudmodel.viewmodelforclient = self;
	self.frame = 0;
	self.tur_head.frame = 0;
	self.think = spiderbot_blowup;
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

void spiderbot_reset() {
	spiderbot_die();
	spiderbot_spawn();
}

void vewhicle_spiderbot_dinit()
{
    self.spiderbot_spawnpnt = spawn();
    self.spiderbot_spawnpnt.angles = self.angles;

    traceline(self.origin + '0 0 16', self.origin - '0 0 10000', MOVE_WORLDONLY, self);
    setorigin(self.spiderbot_spawnpnt,trace_endpos + '0 0 4');
    setorigin(self,self.spiderbot_spawnpnt.origin);

    if(self.team && !teamplay)
        self.team = 0;
    else
        self.spiderbot_spawnpnt.team = self.team;

    addstat(STAT_HUD, AS_INT,  hud);
	addstat(STAT_SPIDERBOT_ROCKETS, AS_INT,   rockets);
	addstat(STAT_SPIDERBOT_RELOAD,  AS_FLOAT, rockets_reload);
	addstat(STAT_SPIDERBOT_HEAT,    AS_FLOAT, vehicle_heat);
	addstat(STAT_SPIDERBOT_HEALTH,  AS_FLOAT, vehicle_health);
	addstat(STAT_SPIDERBOT_SHIELD,  AS_FLOAT, vehicle_shield);

    if (self.netname == "")      self.netname     = "spiderbot";

    self.tur_head = spawn();
    self.gun1 = spawn();
    self.gun2 = spawn();
    //self.vehicle_viewport = spawn();
    self.vehicle_hudmodel = spawn();
    self.vehicle_hudmodel.vehicle_hudmodel = spawn();
    self.vehicle_hudmodel.gun1 = spawn();
    self.vehicle_hudmodel.gun2 = spawn();
	setattachment(self.vehicle_hudmodel.gun1, self.vehicle_hudmodel.vehicle_hudmodel, "");
	setorigin(self.vehicle_hudmodel.gun1, '20 -20 20');
	self.vehicle_hudmodel.gun1.angles = '0 0 0';
	setattachment(self.vehicle_hudmodel.gun2, self.vehicle_hudmodel.vehicle_hudmodel, "");
	setorigin(self.vehicle_hudmodel.gun2, '20 20 20');
	self.vehicle_hudmodel.gun2.angles = '0 0 0';
	self.vehicle = spawn();
    self.vehicle_flags = VHF_HASSHIELD | VHF_SHIELDREGEN | VHF_HEALTHREGEN | VHF_HIDEPLAYER;
    self.cvar_basename = "g_vehicle_spiderbot";
	self.vehicle_heat = 0;

	spiderbot_stop(self);

    setmodel (self.vehicle_hudmodel, "null");
    setmodel (self.vehicle_hudmodel.vehicle_hudmodel, "models/spiderbot/cp.md3");
	setattachment(self.vehicle_hudmodel.vehicle_hudmodel, self.vehicle_hudmodel, "");
	setorigin (self.vehicle_hudmodel.vehicle_hudmodel, '-40 0 -20');
    //setmodel (self.vehicle_viewport, "null");
    setmodel(self, "null");
    setmodel(self.vehicle, "models/spiderbot/spiderbot.dpm");
    setmodel(self.tur_head,"models/spiderbot/spiderbot_top.dpm");
    setmodel(self.gun1,"models/spiderbot/spiderbot_barrels.dpm");
    setmodel(self.gun2,"models/spiderbot/spiderbot_barrels.dpm");
    setmodel(self.vehicle_hudmodel.gun1,"models/spiderbot/spiderbot_barrels.dpm");
    setmodel(self.vehicle_hudmodel.gun2,"models/spiderbot/spiderbot_barrels.dpm");

    setattachment(self.vehicle, self, "");
    setattachment(self.tur_head, self.vehicle, "tag_head");
    //setattachment(self.vehicle_hudmodel,self.tur_head,"");
    //setattachment(self.vehicle_viewport,self.vehicle_hudmodel,"");
    setattachment(self.gun1,self.tur_head,"tag_hardpoint01");
    setattachment(self.gun2,self.tur_head,"tag_hardpoint02");

    self.tur_head.owner = self;
    self.customizeentityforclient          = spiderbot_customizeentityforclient;

    //setorigin(self.vehicle_viewport,'35 0 -14');
    self.tur_aimpos = self.origin;
    spiderbot_spawn();

    self.vehicle_die = spiderbot_die;
    self.vehicle_exit = spiderbot_exit;
	self.reset = spiderbot_reset;
}

float vehicle_spiderbot_readcvars_done;
void vehicle_spiderbot_readcvars() {
	vehicles_init();
	if (vehicle_spiderbot_readcvars_done)
		return;

	vehicle_spiderbot_readcvars_done = TRUE;
	CACHE_CVAR(g_vehicle_spiderbot_crush_dmg);
	CACHE_CVAR(g_vehicle_spiderbot_crush_force);
	CACHE_CVAR(g_vehicle_spiderbot_crush_minspeed);
	CACHE_CVAR(g_vehicle_spiderbot_head_pitchlimit_down);
	CACHE_CVAR(g_vehicle_spiderbot_head_pitchlimit_up);
	CACHE_CVAR(g_vehicle_spiderbot_head_pitchspeed);
	CACHE_CVAR(g_vehicle_spiderbot_head_turnlimit);
	CACHE_CVAR(g_vehicle_spiderbot_head_turnspeed);
	CACHE_CVAR(g_vehicle_spiderbot_health);
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
	CACHE_CVAR(g_vehicle_spiderbot_shield);
	CACHE_CVAR(g_vehicle_spiderbot_shield_regen);
	CACHE_CVAR(g_vehicle_spiderbot_shield_regen_dmgpause);
	CACHE_CVAR(g_vehicle_spiderbot_speed_stop);
	CACHE_CVAR(g_vehicle_spiderbot_speed_strafe);
	CACHE_CVAR(g_vehicle_spiderbot_speed_walk);
	CACHE_CVAR(g_vehicle_spiderbot_turnspeed);
}

float SpiderbotPhysic_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_PHYSIC_SPIDERBOT);
	WriteShort(MSG_ENTITY, sf);
	if (sf & 1)
	{
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_jump_accel);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_jump_up);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_speed_stop);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_speed_strafe);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_speed_walk);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_turnspeed);
		WriteCoord(MSG_ENTITY, g_vehicle_spiderbot_movement_inertia);
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

void spawnfunc_vehicle_spiderbot()
{
	vehicle_spiderbot_readcvars();
    // g_turrets_common_precash();

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
	CSQCProjectile_Init(PROJECTILE_ROCKET);

    //self.team                = -1;
    self.think = vewhicle_spiderbot_dinit;
    self.nextthink = time + 0.5;
	self.health_max = g_vehicle_spiderbot_health;
	self.health_regen = g_vehicle_spiderbot_health_regen;
	self.health_regen_dmgpause = g_vehicle_spiderbot_health_regen_dmgpause;
	self.shield_max = g_vehicle_spiderbot_shield;
	self.shield_regen = g_vehicle_spiderbot_shield_regen;
	self.shield_regen_dmgpause = g_vehicle_spiderbot_shield_regen_dmgpause;
	PhysicEnableCSQC();
}
