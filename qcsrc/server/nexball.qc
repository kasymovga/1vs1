//EF_BRIGHTFIELD|EF_BRIGHTLIGHT|EF_DIMLIGHT|EF_BLUE|EF_RED|EF_FLAME
float ST_NEXBALL_GOALS;
float SP_NEXBALL_GOALS;
float SP_NEXBALL_FAULTS;
#define BALL_EFFECTMASK 1229
#define BALL_MINS '-16 -16 -16'  // The model is 24*24*24
#define BALL_MAXS '16 16 16'
#define BALL_ATTACHORG '10 0 10'
#define BALL_POV '30 0 -16'
#define BALL_SPRITECOLOR '.91 .85 .62'
#define BALL_FOOT   1
#define BALL_BASKET 2
#define BALL_HOCKEY 4
//spawnflags
#define GOAL_TOUCHPLAYER 1
//goal types
#define GOAL_FAULT -1
#define GOAL_OUT -2

float g_nexball;
float g_nexball_basketball_carrier_speed;
float g_nexball_football_boost_forward;
float g_nexball_football_boost_up;
float g_nexball_football_melee_boost_forward;
float g_nexball_football_melee_boost_up;
float g_nexball_football_physics;
float g_nexball_hockey_boost_forward;
float g_nexball_hockey_bouncefactor;
float g_nexball_hockey_melee_boost_forward;
float g_nexball_hockey_melee_boost_up;
float g_nexball_delay_idle;
float g_nexball_basketball_delay_hold;
float g_nexball_basketball_delay_hold_forteam;
float g_nexball_basketball_effects_default;
float g_nexball_basketball_teamsteal;
float g_nexball_ball_explosive_radius;
float g_nexball_ball_explosive_damage;
float g_nexball_ball_explosive_force;
float g_nexball_ball_scale;
float balls;
float ball_scale;
float nb_teams;
.float metertime;
.float metertime_stat;
// Nexball
.entity ballcarried;
float g_nexball_meter_period;


float g_balance_nexball_primary_shootatmaxmeter;
float g_balance_nexball_primary_speed;
float g_nexball_basketball_meter;
float g_nexball_basketball_meter_maxpower;
float g_nexball_basketball_meter_minpower;
float g_nexball_delay_collect;
float g_nexball_delay_goal;
float g_nexball_delay_start;

.float teamtime;
.float explosive;
.entity pov_ball;

float w_nexball_carrier_think();
var void() nexball_PlayerPreThink_NextLink;
void nexball_PlayerPreThink();
void nb_delayedinit();
void ResetBall();
void basketball_touch();
void football_touch();
void hockey_touch();
void DropBall(entity ball, vector org, vector vel);

var void(float killed) nb_PlayerClear_NextLink;
void nb_PlayerClear(float killed) {
	if(self.ballcarried)
		DropBall(self.ballcarried, self.origin, self.velocity);

	nb_PlayerClear_NextLink(killed);
}

var float() nb_SpeedMod_NextLink;
float nb_SpeedMod() {
	float f = nb_SpeedMod_NextLink();
	if(self.ballcarried)
		return g_nexball_basketball_carrier_speed * f;

	return f;
}

float nb_FragLimitOverride() {
	return cvar("g_nexball_goallimit");
}

float nb_LeadLimitOverride() {
	return cvar("g_nexball_goalleadlimit");
}

float nb_WeaponFrameHandle() {
	if not(Akimbo_Owner(self).ballcarried)
		return FALSE;

	w_nexball_carrier_think();
	return TRUE;
}

float nb_ReloadAllowed() {
	if (self.ballcarried)
		return FALSE;

	return TRUE;
}

var float(float ignore) nb_ThrowWeaponAllowed_NextLink;
float nb_ThrowWeaponAllowed(float ignore) {
	if (self.ballcarried)
		return FALSE;

	return nb_ThrowWeaponAllowed_NextLink(ignore);
}

float nb_RadarShowEnemiesAllowed() {
	return TRUE;
}

var void(entity e) nb_SpectateCopy_NextLink;
void nb_SpectateCopy(entity e) {
	self.metertime = e.metertime;
}

float nb_PlayerIsCarrier(entity plr) { return plr.ballcarried != world; }
void nb_DropCarried(entity plr) { DropBall(plr.ballcarried, plr.origin, plr.velocity); }
float nb_TeleportationForbiddenFor(entity e) { return e.classname == "nexball_football" || e.classname == "nexball_basketball" || e.classname == "nexball_hockey"; }

void nb_init() // Called early (worldspawn stage)
{
	g_nexball = 1;
	CACHE_CVAR(g_nexball_meter_period); //sent with the client init entity
	if (g_nexball_meter_period <= 0)
		g_nexball_meter_period = 2; // avoid division by zero etc. due to silly users
	g_nexball_meter_period = rint(g_nexball_meter_period * 32) / 32; //Round to 1/32ths to send as a byte multiplied by 32
	addstat(STAT_NB_METERSTART, AS_FLOAT, metertime_stat);

	// General settings
	CACHE_CVAR(g_nexball_football_boost_forward);   //100
	CACHE_CVAR(g_nexball_football_boost_up);        //200
	CACHE_CVAR(g_nexball_football_melee_boost_forward);
	CACHE_CVAR(g_nexball_football_melee_boost_up);
	CACHE_CVAR(g_nexball_hockey_boost_forward);   //100
	CACHE_CVAR(g_nexball_hockey_bouncefactor);   //0.9
	CACHE_CVAR(g_nexball_hockey_melee_boost_forward);   //300
	CACHE_CVAR(g_nexball_hockey_melee_boost_up);   //100
	CACHE_CVAR(g_nexball_delay_idle);               //10
	CACHE_CVAR(g_nexball_football_physics);         //0
	CACHE_CVAR(g_nexball_ball_scale);
	CACHE_CVAR(g_nexball_ball_explosive_radius);
	CACHE_CVAR(g_nexball_ball_explosive_damage);
	CACHE_CVAR(g_nexball_ball_explosive_force);
	CACHE_CVAR(g_balance_nexball_primary_shootatmaxmeter);
	CACHE_CVAR(g_balance_nexball_primary_speed);
	CACHE_CVAR(g_nexball_basketball_meter);
	CACHE_CVAR(g_nexball_basketball_meter_maxpower);
	CACHE_CVAR(g_nexball_basketball_meter_minpower);
	CACHE_CVAR(g_nexball_delay_collect);
	CACHE_CVAR(g_nexball_delay_goal);
	CACHE_CVAR(g_nexball_delay_start);
	CACHE_CVAR(g_nexball_basketball_carrier_speed);

	nb_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = nb_PlayerClear;
	nexball_PlayerPreThink_NextLink = GameHookChain_PlayerPreThink;
	GameHookChain_PlayerPreThink = nexball_PlayerPreThink;
	nb_SpeedMod_NextLink = GameHookChain_SpeedMod;
	GameHookChain_SpeedMod = nb_SpeedMod;
	GameHook_FragLimitOverride = nb_FragLimitOverride;
	GameHook_LeadLimitOverride = nb_LeadLimitOverride;
	GameHook_WeaponFrameHandle = nb_WeaponFrameHandle;
	GameHook_ReloadAllowed = nb_ReloadAllowed;
	nb_ThrowWeaponAllowed_NextLink = GameHookChain_ThrowWeaponAllowed;
	GameHookChain_ThrowWeaponAllowed = nb_ThrowWeaponAllowed;
	nb_SpectateCopy_NextLink = GameHookChain_SpectateCopy;
	GameHookChain_SpectateCopy = nb_SpectateCopy;
	GameHook_PlayerIsCarrier = nb_PlayerIsCarrier;
	GameHook_DropCarried = nb_DropCarried;
	GameHook_TeleportationForbiddenFor = nb_TeleportationForbiddenFor;
	InitializeEntity(world, nb_delayedinit, INITPRIO_GAMETYPE);
	precache_model ("models/elaser.mdl");
	precache_sound ("nexball/shoot1.wav");
	precache_sound ("nexball/shoot2.wav");
}

float OtherTeam(float t)  //works only if there are two teams on the map!
{
	entity e;
	e = find(world, classname, "nexball_team");
	if (e.team == t)
		e = find(e, classname, "nexball_team");
	return e.team;
}

void ball_restart (void)
{
	if(self.owner)
		DropBall(self, self.owner.origin, '0 0 0');
	ResetBall();
}

void nexball_PlayerPreThink (void)
{
	local entity oldself;
	self.items &~= IT_KEY1;
	if (self.ballcarried)
	{
		if (self.ballcarried.teamtime && (self.ballcarried.teamtime < time))
		{
			bprint("The ", ColoredTeamName(self.team), " held the ball for too long.\n");
			oldself = self;
			self = self.ballcarried;
			DropBall(self, self.owner.origin, '0 0 0');
			ResetBall();
			self = oldself;
		} else
			self.items |= IT_KEY1;
	}
	nexball_PlayerPreThink_NextLink();
}

void relocate_nexball (void)
{
	tracebox(self.origin, BALL_MINS * g_nexball_ball_scale, BALL_MAXS * g_nexball_ball_scale, self.origin, TRUE, self);
	if (trace_startsolid)
	{
		vector o;
		o = self.origin;
		if(!move_out_of_solid(self))
			objerror("could not get out of solid at all!");
		print("^1NOTE: this map needs FIXING. ", self.classname, " at ", vtos(o - '0 0 1'));
		print(" needs to be moved out of solid, e.g. by '", ftos(self.origin_x - o_x));
		print(" ", ftos(self.origin_y - o_y));
		print(" ", ftos(self.origin_z - o_z), "'\n");
		self.origin = o;
	}
}

void DropOwner (void)
{
	local entity ownr;
	ownr = self.owner;
	DropBall(self, ownr.origin, ownr.velocity);
	makevectors(ownr.v_angle_y * '0 1 0');
	ownr.velocity += ('0 0 0.75' - v_forward) * 1000;
	ownr.flags &~= FL_ONGROUND;
}

void HideWeapon(entity e) {
	e.message2 = e.weaponname;
	e.weaponname = "";
	e.weaponentity.cnt = 0;
	e.exteriorweaponentity.cnt = 0;
	entity akimbo_ghost = Akimbo_Ghost(e);
	if (akimbo_ghost)
	if (e != akimbo_ghost)
		HideWeapon(akimbo_ghost);
}

void UnhideWeapon(entity e) {
	e.weaponname = e.message2;
	e.weaponentity.cnt = 0;
	e.exteriorweaponentity.cnt = 0;
	entity akimbo_ghost = Akimbo_Ghost(e);
	if (akimbo_ghost)
	if (e != akimbo_ghost)
		UnhideWeapon(akimbo_ghost);
}

void GiveBall (entity plyr, entity ball)
{
	local entity ownr;

	if ((ownr = ball.owner))
	{
		ownr.effects &~= g_nexball_basketball_effects_default;
		ownr.ballcarried = world;
		if (ownr.metertime)
			ownr.metertime_stat = ownr.metertime = 0;

		WaypointSprite_Kill(ownr.waypointsprite_attachedforcarrier);
	}
	else
	{
		WaypointSprite_Kill(ball.waypointsprite_attachedforcarrier);
	}

	float tag_found;
	if((tag_found = gettagindex(plyr, "tag_weapon")))
	{
		ball.tag_index = tag_found;
		ball.tag_entity = self.owner;
	}
	else
		setattachment(ball, plyr, "bip01 r hand");

	setorigin(ball, BALL_ATTACHORG);

	plyr.pov_ball = spawn();
	plyr.pov_ball.owner = plyr;
	plyr.pov_ball.solid = SOLID_NOT;
	plyr.pov_ball.classname = "pov_ball";
	plyr.pov_ball.customizeentityforclient = CL_Weaponentity_CustomizeEntityForClient;
	plyr.pov_ball.viewmodelforclient = plyr;
	setmodel(plyr.pov_ball, ball.model);
	setorigin(plyr.pov_ball, BALL_POV);

	if (ball.team != plyr.team)
		ball.teamtime = time + g_nexball_basketball_delay_hold_forteam;

	ball.owner = ball.pusher = plyr; //"owner" is set to the player carrying, "pusher" to the last player who touched it
	ball.team = plyr.team;
	HideWeapon(plyr);
	plyr.ballcarried = ball;
	ball.dropperid = plyr.playerid;

	plyr.effects |= g_nexball_basketball_effects_default;
	ball.effects &~= g_nexball_basketball_effects_default;

	ball.velocity = '0 0 0';
	ball.movetype = MOVETYPE_NONE;
	ball.touch = SUB_Null;
	ball.effects |= EF_NOSHADOW;
	ball.scale = 1; // scale down.

	WaypointSprite_AttachCarrier("nb-ball", plyr);
	WaypointSprite_UpdateRule(plyr.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_UpdateTeamRadar(plyr.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, BALL_SPRITECOLOR);

	if (g_nexball_basketball_delay_hold)
	{
		ball.think = DropOwner;
		ball.nextthink = time + g_nexball_basketball_delay_hold;
	}
}

void DropBall (entity ball, vector org, vector vel)
{
	ball.effects |= g_nexball_basketball_effects_default;
	ball.effects &~= EF_NOSHADOW;
	ball.owner.effects &~= g_nexball_basketball_effects_default;

	setattachment(ball, world, "");
	setorigin (ball, org);
	ball.movetype = MOVETYPE_BOUNCE;
	ball.flags &~= FL_ONGROUND;
	ball.scale = ball_scale;
	ball.velocity = vel;
	ball.ctf_droptime = time;
	ball.touch = basketball_touch;
	ball.think = ResetBall;
	ball.nextthink = min(time + g_nexball_delay_idle, ball.teamtime);

	if (ball.owner.metertime)
		ball.owner.metertime_stat = ball.owner.metertime = 0;

	WaypointSprite_Kill(ball.owner.waypointsprite_attachedforcarrier);
	WaypointSprite_AttachCarrier("nb-ball", ball);
	WaypointSprite_UpdateRule(ball.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_UpdateTeamRadar(ball.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, BALL_SPRITECOLOR);

	remove(ball.owner.pov_ball);
	ball.owner.pov_ball = world;
	ball.owner.ballcarried = world;
	UnhideWeapon(ball.owner);
	ball.owner = world;
}

void InitBall (void)
{
	if (gameover) return;
	self.flags &~= FL_ONGROUND;
	if (self.classname == "nexball_hockey")
		self.movetype = MOVETYPE_BOUNCEMISSILE;
	else
		self.movetype = MOVETYPE_BOUNCE;
	if (self.classname == "nexball_basketball")
		self.touch = basketball_touch;
	else if (self.classname == "nexball_football")
		self.touch = football_touch;
	else if (self.classname == "nexball_hockey")
	{
		self.touch = hockey_touch;
	}
	self.solid = SOLID_TRIGGER;
	setmodel(self, self.mdl);
	setsize(self, BALL_MINS * g_nexball_ball_scale, BALL_MAXS * g_nexball_ball_scale);
	self.cnt = 0;
	self.think = ResetBall;
	self.nextthink = time + g_nexball_delay_idle + 3;
	self.teamtime = 0;
	self.pusher = world;
	self.team = FALSE;
	sound (self, CHAN_PROJECTILE, self.noise1, VOL_BASE, ATTN_NORM);
	WaypointSprite_Ping(self.waypointsprite_attachedforcarrier);
}

void ResetBall (void)
{
	if (self.cnt < 2) { // step 1
		if (time == self.teamtime)
			bprint("The ", ColoredTeamName(self.team), " held the ball for too long.\n");
		self.touch = SUB_Null;
		self.movetype = MOVETYPE_NOCLIP;
		self.velocity = '0 0 0'; // just in case?
		self.cnt = 2;
		self.nextthink = time;
	} else if (self.cnt < 4) { // step 2 and 3
//		dprint("Step ", ftos(self.cnt), ": Calculated velocity: ", vtos(self.spawnorigin - self.origin), ", time: ", ftos(time), "\n");
		self.velocity = (self.spawnorigin - self.origin) * (self.cnt - 1); // 1 or 0.5 second movement
		self.nextthink = time + 0.5;
		self.cnt += 1;
	} else { // step 4
//		dprint("Step 4: time: ", ftos(time), "\n");
		if (vlen(self.origin - self.spawnorigin) > 10) // should not happen anymore
			dprint("The ball moved too far away from its spawn origin.\nOffset: ",
			       vtos(self.origin - self.spawnorigin), " Velocity: ", vtos(self.velocity), "\n");
		self.velocity = '0 0 0';
		setorigin(self, self.spawnorigin); // make sure it's positioned correctly anyway
		self.movetype = MOVETYPE_NONE;
		self.think = InitBall;
		self.nextthink = max(time, game_starttime) + g_nexball_delay_start;
	}
}

void football_touch (void)
{
	if (other.solid == SOLID_BSP) {
		if (time > self.lastground + 0.1)
		{
			sound (self, CHAN_PROJECTILE, self.noise, VOL_BASE, ATTN_NORM);
			self.lastground = time;
		}
		if (vlen(self.velocity) && !self.cnt)
			self.nextthink = time + g_nexball_delay_idle;
		return;
	}
	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;
	if (!self.cnt)
		self.nextthink = time + g_nexball_delay_idle;

	self.pusher = other;
	self.team = other.team;

	if (g_nexball_football_physics == -1) { // MrBougo try 1, before decompiling Rev's original
		if (vlen(other.velocity))
			self.velocity = other.velocity * 1.5 + '0 0 1' * g_nexball_football_boost_up;
	} else if (g_nexball_football_physics == 1) { // MrBougo's modded Rev style: partially independant of the height of the aiming point
		makevectors(other.v_angle);
		self.velocity = other.velocity + v_forward * g_nexball_football_boost_forward + '0 0 1' * g_nexball_football_boost_up;
	} else if (g_nexball_football_physics == 2) { // 2nd mod try: totally independant. Really playable!
		makevectors(other.v_angle_y * '0 1 0');
		self.velocity = other.velocity + v_forward * g_nexball_football_boost_forward + v_up * g_nexball_football_boost_up;
	} else { // Revenant's original style (from the original mod's disassembly, acknowledged by Revenant)
		makevectors(other.v_angle);
		self.velocity = other.velocity + v_forward * g_nexball_football_boost_forward + v_up * g_nexball_football_boost_up;
	}
	if (other.weaponentity.wframe == WFRAME_MELEE || other.weaponentity.wframe == WFRAME_MELEE2 || (other.weapon == WEP_MELEE && other.weaponentity.wframe == WFRAME_FIRE1))
	{
		makevectors(other.v_angle);
		self.velocity = self.velocity + v_forward * g_nexball_football_melee_boost_forward + v_up * g_nexball_football_melee_boost_up;
	}
	self.avelocity = -250 * v_forward;  // maybe there is a way to make it look better?
}

void hockey_touch (void)
{
	if (other.solid == SOLID_BSP) {
		self.velocity_z = 0;
		self.velocity_x = self.velocity_x * g_nexball_hockey_bouncefactor;
		self.velocity_y = self.velocity_y * g_nexball_hockey_bouncefactor;
		if (time > self.lastground + 0.1)
		{
			sound (self, CHAN_PROJECTILE, self.noise, VOL_BASE, ATTN_NORM);
			self.lastground = time;
		}
		return;
	}
	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;
	if (!self.cnt)
		self.nextthink = time + g_nexball_delay_idle;

	self.pusher = other;
	self.team = other.team;

	makevectors(other.v_angle_y * '0 1 0');
	self.velocity = other.velocity + v_forward * g_nexball_hockey_boost_forward;
	self.velocity_z = 0;
	if (other.weaponentity.wframe == WFRAME_MELEE || other.weaponentity.wframe == WFRAME_MELEE2 || (other.weapon == WEP_MELEE && other.weaponentity.wframe == WFRAME_FIRE1))
	{
		self.velocity = self.velocity + v_forward * g_nexball_hockey_melee_boost_forward;
		self.velocity_z = g_nexball_hockey_melee_boost_up;
	}
	self.avelocity = '0 -180 0' + ('0 360 0' * random());
}

void basketball_touch (void)
{
	if (other.ballcarried || !GameHookChain_PlayerCanBeCarrier(other)) {
		football_touch();
		return;
	}
	if (!self.cnt && other.classname == "player" && (other.playerid != self.dropperid || time > self.ctf_droptime + g_nexball_delay_collect)) {
		if (other.health <= 0)
			return;
		GiveBall(other, self);
	} else if (other.solid == SOLID_BSP) {
		sound (self, CHAN_PROJECTILE, self.noise, VOL_BASE, ATTN_NORM);
		if (vlen(self.velocity) && !self.cnt)
			self.nextthink = min(time + g_nexball_delay_idle, self.teamtime);
	}
}

void GoalTouch (void)
{
	entity ball;
	float isclient, pscore, otherteam;
	string pname;

	if (gameover) return;
	if ((self.spawnflags & GOAL_TOUCHPLAYER) && other.ballcarried)
		ball = other.ballcarried;
	else
		ball = other;
	if (ball.classname != "nexball_basketball")
	if (ball.classname != "nexball_football")
	if (ball.classname != "nexball_hockey")
		return;
	if ((!ball.pusher && self.team != GOAL_OUT) || ball.cnt)
		return;
	EXACTTRIGGER_TOUCH;


	if(nb_teams == 2)
		otherteam = OtherTeam(ball.team);

	if((isclient = ball.pusher.flags & FL_CLIENT))
		pname = ball.pusher.netname;
	else
		pname = "Someone (?)";

	if        (ball.team == self.team) //owngoal (regular goals)
	{
		bprint("Boo! ", pname, "^7 scored a goal against his own team!\n");
		pscore = -1;
	} else if (self.team == GOAL_FAULT) {
		if (nb_teams == 2)
			bprint(ColoredTeamName(otherteam), " gets a point due to ", pname, "^7's silliness.\n");
		else
			bprint(ColoredTeamName(ball.team), " loses a point due to ", pname, "^7's silliness.\n");
		pscore = -1;
	} else if (self.team == GOAL_OUT) {
		if ((self.spawnflags & GOAL_TOUCHPLAYER) && ball.owner)
			bprint(pname, "^7 went out of bounds.\n");
		else
			bprint("The ball was returned.\n");
		pscore = 0;
	} else {                           //score
		bprint("Goaaaaal! ", pname, "^7 scored a point for the ", ColoredTeamName(ball.team), ".\n");
		pscore = 1;
	}

	sound (ball, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NONE);

	if(ball.team && pscore)
	{
		if (nb_teams == 2 && pscore < 0)
			scores_team_add_to(otherteam, ST_NEXBALL_GOALS, -pscore);
		else
			scores_team_add_to(ball.team, ST_NEXBALL_GOALS, pscore);
	}
	if (isclient)
	{
		if (pscore > 0)
			scores_player_add(ball.pusher, SP_NEXBALL_GOALS, pscore);
		else if (pscore < 0)
			scores_player_add(ball.pusher, SP_NEXBALL_FAULTS, -pscore);
	}

	if (ball.owner) // Happens on spawnflag GOAL_TOUCHPLAYER
		DropBall(ball, ball.owner.origin, ball.owner.velocity);

	WaypointSprite_Ping(ball.waypointsprite_attachedforcarrier);

	ball.cnt = 1;
	ball.think = ResetBall;
	if (ball.classname == "nexball_basketball")
		ball.touch = football_touch; // better than SUB_Null: football control until the ball gets reset
	ball.nextthink = time + g_nexball_delay_goal * (self.team != GOAL_OUT);
	if (ball.explosive)
	{
		local float i;
		local vector expl_orig;
		local entity temp;
		RadiusDamage(ball, ball.pusher, g_nexball_ball_explosive_damage, 0, g_nexball_ball_explosive_radius, ball, g_nexball_ball_explosive_force, DEATH_HURTTRIGGER, world);
		for (i = 0; i < 16; i++)
		{
			expl_orig = ball.origin + '-100 -100 0' + random() * '200 0 0' + random() * '0 200 0' + random() * '0 0 200';
			pointparticles(particleeffectnum("rocket_explode"), expl_orig, '0 0 0', 1);
			temp = spawn();
			setorigin(temp, expl_orig);
			sound(temp, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
			remove(temp);
		}
		ball.cnt = 4;
		ball.solid = SOLID_NOT;
		setmodel(ball, "");
		ball.velocity = '0 0 0';
	}
}

//=======================//
//       team ents       //
//=======================//
void spawnfunc_nexball_team (void)
{
	if(!g_nexball) { remove(self); return; }
	self.team = self.cnt + 1;
	SetAllowedTeam(self.team);
}

void nb_spawnteam (string teamname, float teamcolor)
{
	dprint("^2spawned team ", teamname, "\n");
	local entity e;
	e = spawn();
	e.classname = "nexball_team";
	e.netname = teamname;
	e.cnt = teamcolor;
	entity oldself = self;
	self = e;
	spawnfunc_nexball_team();
	self = oldself;
};

void nb_spawnteams (void)
{
	float t_r, t_b, t_y, t_p;
	entity e;
	for(e = world; (e = find(e, classname, "nexball_goal")); )
	{
		switch(e.team)
		{
			case COLOR_TEAM1: if(!t_r) { nb_spawnteam ("Red", e.team-1)   ; t_r = 1; } break;
			case COLOR_TEAM2: if(!t_b) { nb_spawnteam ("Blue", e.team-1)  ; t_b = 1; } break;
			case COLOR_TEAM3: if(!t_y) { nb_spawnteam ("Yellow", e.team-1); t_y = 1; } break;
			case COLOR_TEAM4: if(!t_p) { nb_spawnteam ("Pink", e.team-1)  ; t_p = 1; } break;
		}
	}
}

void nb_delayedinit (void)
{
	if (find(world, classname, "nexball_team") == world)
		nb_spawnteams();

	teams_check_allowed(world);
	nb_teams = 4 + c1 + c2 + c3 + c4;
	scores_basics(0, 0, TRUE);
	ST_NEXBALL_GOALS = scores_register_team_score("goals", SFL_SORT_PRIO_PRIMARY);
	SP_NEXBALL_GOALS = scores_register_score("goals", SFL_SORT_PRIO_PRIMARY);
	SP_NEXBALL_FAULTS = scores_register_score("faults", SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER);
}

//=======================//
//      spawnfuncs       //
//=======================//

void SpawnBall (void)
{
	if(!g_nexball) { remove(self); return; }

//	balls += 4; // using the remaining bits to count balls will leave more than the max edict count, so it's fine

	if (!self.model) {
		self.model = "models/nexball/ball.md3";
		self.scale = 1.3;
	}
	self.scale *= g_nexball_ball_scale;

	precache_model (self.model);
	setmodel (self, self.model);
	self.mdl = self.model;
	ball_scale = self.scale;

	relocate_nexball();
	self.spawnorigin = self.origin;

	self.effects = self.effects | EF_LOWPRECISION;

	if (cvar(strcat("g_", self.classname, "_trail"))) //nexball_basketball :p
	{
		self.glow_color = cvar("g_nexball_trail_color");
		self.glow_trail = TRUE;
	}

	self.movetype = MOVETYPE_FLY;

	if (!cvar("g_nexball_sound_bounce"))
		self.noise = "";
	else if (!self.noise)
		self.noise = "sound/nexball/bounce.wav";
		//bounce sound placeholder (FIXME)
	if (!self.noise1)
		self.noise1 = "sound/nexball/drop.wav";
		//ball drop sound placeholder (FIXME)
	if (!self.noise2)
		self.noise2 = "sound/nexball/steal.wav";
		//stealing sound placeholder (FIXME)
	if (self.noise) precache_sound (self.noise);
	precache_sound (self.noise1);
	precache_sound (self.noise2);

	WaypointSprite_AttachCarrier("nb-ball", self); // the ball's team is not set yet, no rule update needed
	WaypointSprite_UpdateTeamRadar(self.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, BALL_SPRITECOLOR);

	self.reset = ball_restart;
	self.think = InitBall;
	self.nextthink = game_starttime + g_nexball_delay_start;
	self.bot_pickup = TRUE;
	self.bot_pickupevalfunc = generic_pickupevalfunc;
	self.bot_pickupbasevalue = BOT_PICKUP_RATING_HIGH;
}

void spawnfunc_nexball_basketball (void)
{
	self.classname = "nexball_basketball";
	if not(balls & BALL_BASKET)
	{
		CACHE_CVAR(g_nexball_basketball_effects_default);
		CACHE_CVAR(g_nexball_basketball_delay_hold);
		CACHE_CVAR(g_nexball_basketball_delay_hold_forteam);
		CACHE_CVAR(g_nexball_basketball_teamsteal);
		g_nexball_basketball_effects_default = g_nexball_basketball_effects_default & BALL_EFFECTMASK;
	}
	if (!self.effects)
		self.effects = g_nexball_basketball_effects_default;
	self.solid = SOLID_TRIGGER;
	balls |= BALL_BASKET;
	self.bouncefactor = cvar("g_nexball_basketball_bouncefactor");
	self.bouncestop = cvar("g_nexball_basketball_bouncestop");
	SpawnBall();
}

void spawnfunc_nexball_football (void)
{
	self.classname = "nexball_football";
	self.solid = SOLID_TRIGGER;
	balls |= BALL_FOOT;
	self.bouncefactor = cvar("g_nexball_football_bouncefactor");
	self.bouncestop = cvar("g_nexball_football_bouncestop");
	SpawnBall();
}

void hockey_physic_controller_think(void)
{
	self.nextthink = time;
	if (self.ballcarried.cnt)
		return;
	tracebox(self.ballcarried.origin, BALL_MINS * g_nexball_ball_scale, BALL_MAXS * g_nexball_ball_scale, self.ballcarried.origin + '0 0 -1', MOVE_WORLDONLY, world);
	if (trace_fraction == 1)
	{
		self.ballcarried.velocity_z -= sv_gravity * frametime;
		setorigin(self.ballcarried, self.ballcarried.origin);
	}
}

.entity hockey_physic_controller;
void spawnfunc_nexball_hockey (void)
{
	self.classname = "nexball_hockey";
	self.solid = SOLID_TRIGGER;
	balls |= BALL_HOCKEY;
	self.hockey_physic_controller = spawn();
	self.hockey_physic_controller.ballcarried = self;
	self.hockey_physic_controller.think = hockey_physic_controller_think;
	self.hockey_physic_controller.nextthink = time;
	self.cnt = 4;
	SpawnBall();
}

void SpawnGoal (void)
{
	if(!g_nexball) { remove(self); return; }
	EXACTTRIGGER_INIT;
	self.classname = "nexball_goal";
	if (!self.noise)
		self.noise = "ctf/respawn.wav";
	precache_sound(self.noise);
	self.touch = GoalTouch;
}

void spawnfunc_nexball_redgoal (void)
{
	self.team = COLOR_TEAM1;
	SpawnGoal();
}
void spawnfunc_nexball_bluegoal (void)
{
	self.team = COLOR_TEAM2;
	SpawnGoal();
}
void spawnfunc_nexball_yellowgoal (void)
{
	self.team = COLOR_TEAM3;
	SpawnGoal();
}
void spawnfunc_nexball_pinkgoal (void)
{
	self.team = COLOR_TEAM4;
	SpawnGoal();
}

void spawnfunc_nexball_fault (void)
{
	self.team = GOAL_FAULT;
	if (!self.noise)
		self.noise = "misc/typehit.wav";
	SpawnGoal();
}

void spawnfunc_nexball_out (void)
{
	self.team = GOAL_OUT;
	if (!self.noise)
		self.noise = "misc/typehit.wav";
	SpawnGoal();
}

//
//Spawnfuncs preserved for compatibility
//

void spawnfunc_ball            (void) { spawnfunc_nexball_football(); }
void spawnfunc_ball_football   (void) { spawnfunc_nexball_football(); }
void spawnfunc_ball_basketball (void) { spawnfunc_nexball_basketball(); }
void spawnfunc_ball_hockey (void) { spawnfunc_nexball_hockey(); }
// The "red goal" is defended by blue team. A ball in there counts as a point for red.
void spawnfunc_ball_redgoal    (void) { spawnfunc_nexball_bluegoal(); } // I blame Revenant
void spawnfunc_ball_bluegoal   (void) { spawnfunc_nexball_redgoal(); }  // but he didn't mean to cause trouble :p
void spawnfunc_ball_fault      (void) { spawnfunc_nexball_fault(); }
void spawnfunc_ball_bound      (void) { spawnfunc_nexball_out(); }

//=======================//
//      Weapon code      //
//=======================//

void W_Nexball_Attack (float t)
{
	local entity ball;
	local float mul, mi, ma;
	if (!(ball = self.ballcarried))
		return;

	W_SetupShot (self, 4, "nexball/shoot1.wav",0);
	tracebox(w_shotorg, BALL_MINS * g_nexball_ball_scale, BALL_MAXS * g_nexball_ball_scale, w_shotorg, MOVE_WORLDONLY, world);
	if(trace_startsolid)
	{
		if(self.metertime)
			self.metertime = 0; // Shot failed, hide the power meter
		return;
	}

	//Calculate multiplier
	if (t < 0)
		mul = 1;
	else
	{
		mi = g_nexball_basketball_meter_minpower;
		ma = max(mi, g_nexball_basketball_meter_maxpower); // avoid confusion
		//One triangle wave period with 1 as max
		mul = 2 * mod(t, g_nexball_meter_period) / g_nexball_meter_period;
		if (mul > 1)
			mul = 2 - mul;
		mul = mi + (ma - mi) * mul; // range from the minimal power to the maximal power
	}
	DropBall (ball, w_shotorg, W_CalculateProjectileVelocity(self.velocity, w_shotdir * g_balance_nexball_primary_speed * mul));
	//TODO: use the speed_up cvar too ??
}

float w_nexball_carrier_think()
{
	if (self.BUTTON_ATCK || self.BUTTON_ATCK2)
	{
		if (g_nexball_basketball_meter)
		{
			if (!self.metertime)
				self.metertime = time;
		}
		else
			W_Nexball_Attack(-1);
	}
	if (self.metertime) {
		self.metertime_stat = (time - self.metertime) / g_nexball_meter_period;
		self.metertime_stat = (self.metertime_stat - floor(self.metertime_stat)) * 2;
		if (!self.BUTTON_ATCK ||
				(g_balance_nexball_primary_shootatmaxmeter && self.metertime + (g_nexball_meter_period / 2) < time))
			W_Nexball_Attack(time - self.metertime);
	}
	// DropBall or stealing will set metertime back to 0
	return TRUE;
}

void spawnfunc_nexball_redbase()
{
	if (g_nexball)
		WaypointSprite_SpawnFixed("redbase", self.origin + '0 0 37', self, sprite);
	else
		remove(self);
}

void spawnfunc_nexball_bluebase()
{
	if (g_nexball)
		WaypointSprite_SpawnFixed("bluebase", self.origin + '0 0 37', self, sprite);
	else
		remove(self);
}
