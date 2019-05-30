
/*
Domination as a plugin for netquake mods
by LordHavoc (lordhavoc@ghdigital.com)

*/

float g_domination;
float g_domination_default_teams;
float g_domination_point_amt;
//float g_domination_point_capturetime;
float g_domination_point_fullbright;
float g_domination_point_glow;
float g_domination_point_rate;
float g_domination_teams_override;

#define DOMPOINTFRAGS frags

float ST_DOM_TICKS;
float SP_DOM_TICKS;
float SP_DOM_TAKES;

.float enemy_playerid;
.entity sprite;
.float captime;

void() dom_controlpoint_setup;

void() dom_spawnteams;

void dompoint_captured ()
{
	local entity head;
	local float old_delay, old_team, real_team;

	// now that the delay has expired, switch to the latest team to lay claim to this point
	head = self.owner;

	real_team = self.cnt;
	self.cnt = -1;

	self.dmg_inflictor = world;

	self.goalentity = head;
	self.model = head.mdl;
	self.modelindex = head.dmg;
	self.skin = head.skin;

	//bprint(head.message);
	//bprint("\n");

	//bprint(^3head.netname);
	//bprint(head.netname);
	//bprint(self.message);
	//bprint("\n");

	bprint("^3", head.netname, "^3", self.message, "\n");
	if(self.enemy.playerid == self.enemy_playerid)
		scores_player_add(self.enemy, SP_DOM_TAKES, 1);
	else
		self.enemy = world;

	if (head.noise != "")
		if(self.enemy)
			sound(self.enemy, CHAN_AUTO, head.noise, VOL_BASE, ATTN_NORM);
		else
			sound(self, CHAN_TRIGGER, head.noise, VOL_BASE, ATTN_NORM);
	if (head.noise1 != "")
		play2all(head.noise1);

	//self.nextthink = time + g_domination_point_rate;
	//self.think = dompointthink;

	if(g_domination_point_rate)
		self.delay = time + g_domination_point_rate;
	else
		self.delay = time + self.wait;

	// do trigger work
	old_delay = self.delay;
	old_team = self.team;
	self.team = real_team;
	self.delay = 0;
	activator = self;
	trigger_use_targets ();
	self.delay = old_delay;
	self.team = old_team;

	switch(self.goalentity.team)
	{
		case COLOR_TEAM1:
			WaypointSprite_UpdateSprites(self.sprite, "dom-red", "", "");
			break;
		case COLOR_TEAM2:
			WaypointSprite_UpdateSprites(self.sprite, "dom-blue", "", "");
			break;
		case COLOR_TEAM3:
			WaypointSprite_UpdateSprites(self.sprite, "dom-yellow", "", "");
			break;
		case COLOR_TEAM4:
			WaypointSprite_UpdateSprites(self.sprite, "dom-pink", "", "");
			break;
	}
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_DOMPOINT, colormapPaletteColor(self.goalentity.team - 1, 0));
	WaypointSprite_Ping(self.sprite);

	self.captime = time;
};

void AnimateDomPoint()
{
	if(self.pain_finished > time)
		return;
	self.pain_finished = time + self.t_width;
	if(self.nextthink > self.pain_finished)
		self.nextthink = self.pain_finished;

	self.frame = self.frame + 1;
	if(self.frame > self.t_length)
		self.frame = 0;
}

void dompointthink()
{
	local float waittime;
	local float fragamt;

	self.nextthink = time + 0.1;

	//self.frame = self.frame + 1;
	//if(self.frame > 119)
	//	self.frame = 0;
	AnimateDomPoint();

	// give points

	if (gameover || self.delay > time || time < game_starttime)	// game has ended, don't keep giving points
		return;

	waittime = g_domination_point_rate;
	if(!waittime)
		waittime = self.wait;
	self.delay = time + waittime;

	// give credit to the team
	// NOTE: this defaults to 0
	if (self.goalentity.netname != "")
	{
		fragamt = g_domination_point_amt;
		if(!fragamt)
			fragamt = self.DOMPOINTFRAGS;
		scores_team_add_to(self.goalentity.team, ST_SCORE, fragamt);
		scores_team_add_to(self.goalentity.team, ST_DOM_TICKS, fragamt);

		// give credit to the individual player, if he is still there
		if (self.enemy.playerid == self.enemy_playerid)
		{
			scores_player_add(self.enemy, SP_SCORE, fragamt);
			scores_player_add(self.enemy, SP_DOM_TICKS, fragamt);
		}
		else
			self.enemy = world;
	}
}

void dompointtouch()
{
	local entity head;
	if (other.classname != "player")
		return;
	if (other.health < 1)
		return;

	if(time < self.captime + 0.3)
		return;

	// only valid teams can claim it
	head = find(world, classname, "dom_team");
	while (head && head.team != other.team)
		head = find(head, classname, "dom_team");
	if (!head || head.netname == "" || head == self.goalentity)
		return;

	// delay capture

	self.team = self.goalentity.team; // this stores the PREVIOUS team!

	self.cnt = other.team;
	self.owner = head; // team to switch to after the delay
	self.dmg_inflictor = other;

	// self.state = 1;
	// self.delay = time + g_domination_point_capturetime;
	//self.nextthink = time + g_domination_point_capturetime;
	//self.think = dompoint_captured;

	// go to neutral team in the mean time
	head = find(world, classname, "dom_team");
	while (head && head.netname != "")
		head = find(head, classname, "dom_team");
	if(head == world)
		return;

	WaypointSprite_UpdateSprites(self.sprite, "dom-neut", "", "");
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_DOMPOINT, '0 1 1');
	WaypointSprite_Ping(self.sprite);

	self.goalentity = head;
	self.model = head.mdl;
	self.modelindex = head.dmg;
	self.skin = head.skin;

	self.enemy = other; // individual player scoring
	self.enemy_playerid = other.playerid;
	dompoint_captured();
};

/*QUAKED spawnfunc_dom_team (0 .5 .8) (-32 -32 -24) (32 32 32)
Team declaration for Domination gameplay, this allows you to decide what team
names and control point models are used in your map.

Note: If you use spawnfunc_dom_team entities you must define at least 3 and only two
can have netname set!  The nameless team owns all control points at start.

Keys:
"netname"
 Name of the team (for example Red Team, Blue Team, Green Team, Yellow Team, Life, Death, etc)
"cnt"
 Scoreboard color of the team (for example 4 is red and 13 is blue)
"model"
 Model to use for control points owned by this team (for example
 "progs/b_g_key.mdl" is a gold keycard, and "progs/b_s_key.mdl" is a silver
 keycard)
"skin"
 Skin of the model to use (for team skins on a single model)
"noise"
 Sound to play when this team captures a point.
 (this is a localized sound, like a small alarm or other effect)
"noise1"
 Narrator speech to play when this team captures a point.
 (this is a global sound, like "Red team has captured a control point")
*/

void spawnfunc_dom_team()
{
	if(!g_domination)
	{
		remove(self);
		return;
	}
	precache_model(self.model);
	if (self.noise != "")
		precache_sound(self.noise);
	if (self.noise1 != "")
		precache_sound(self.noise1);
	self.classname = "dom_team";
	setmodel(self, self.model); // precision not needed
	self.mdl = self.model;
	self.dmg = self.modelindex;
	self.model = "";
	self.modelindex = 0;
	// this would have to be changed if used in quakeworld
	if(self.cnt)
		self.team = self.cnt + 1; // WHY are these different anyway?

	team_teams_set_allowed(self.team);
};

void dom_controlpoint_setup()
{
	local entity head;
	// find the spawnfunc_dom_team representing unclaimed points
	head = find(world, classname, "dom_team");
	while(head && head.netname != "")
		head = find(head, classname, "dom_team");
	if (!head)
		entity_abort("no spawnfunc_dom_team with netname \"\" found\n");

	// copy important properties from spawnfunc_dom_team entity
	self.goalentity = head;
	setmodel(self, head.mdl); // precision already set
	self.skin = head.skin;

	self.cnt = -1;

	if(!self.message)
		self.message = " has captured a control point";

	if(!self.DOMPOINTFRAGS)
		self.DOMPOINTFRAGS = 1;
	if(!self.wait)
		self.wait = 5;

	if(!self.t_width)
		self.t_width = 0.02; // frame animation rate
	if(!self.t_length)
		self.t_length = 239; // maximum frame

	self.think = dompointthink;
	self.nextthink = time;
	self.touch = dompointtouch;
	self.solid = SOLID_TRIGGER;
	self.flags = FL_ITEM;
	setsize(self, '-32 -32 -32', '32 32 32');
	setorigin(self, self.origin + '0 0 20');
	entity_droptofloor();

	waypoint_spawnforitem(self);
	WaypointSprite_SpawnFixed("dom-neut", self.origin + '0 0 32', self, sprite);
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_DOMPOINT, '0 1 1');
};

/*QUAKED spawnfunc_dom_controlpoint (0 .5 .8) (-16 -16 -24) (16 16 32)
Control point for Domination gameplay.
*/
void spawnfunc_dom_controlpoint()
{
	if(!g_domination)
	{
		remove(self);
		return;
	}
	self.think = dom_controlpoint_setup;
	self.nextthink = time + 0.1;
	self.reset = dom_controlpoint_setup;

	if(!self.scale)
		self.scale = 0.6;

	//if(!self.glow_size)
	//	self.glow_size = g_domination_point_glow;
	self.effects = self.effects | EF_LOWPRECISION;
	if (g_domination_point_fullbright)
		self.effects |= EF_FULLBRIGHT;
};

// code from here on is just to support maps that don't have control point and team entities
void dom_spawnteam (string teamname, float teamcolor, string pointmodel, float pointskin, string capsound, string capnarration, string capmessage)
{
	local entity oldself;
	oldself = self;
	self = spawn();
	self.netname = teamname;
	self.cnt = teamcolor;
	self.model = pointmodel;
	self.skin = pointskin;
	self.noise = capsound;
	self.noise1 = capnarration;
	self.message = capmessage;
	spawnfunc_dom_team();
	self = oldself;
};

void dom_spawnpoint(vector org)
{
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "dom_controlpoint";
	self.think = spawnfunc_dom_controlpoint;
	self.nextthink = time;
	setorigin(self, org);
	spawnfunc_dom_controlpoint();
	self = oldself;
};

// spawn some default teams if the map is not set up for domination
void dom_spawnteams()
{
	float numteams;
	team_teams_set_count(0);
	if(g_domination_teams_override < 2)
		numteams = g_domination_default_teams;
	else
		numteams = g_domination_teams_override;
	// LordHavoc: edit this if you want to change defaults
	dom_spawnteam("Red", COLOR_TEAM1-1, "models/domination/dom_red.md3", 0, "domination/claim.wav", "", "Red team has captured a control point");
	dom_spawnteam("Blue", COLOR_TEAM2-1, "models/domination/dom_blue.md3", 0, "domination/claim.wav", "", "Blue team has captured a control point");
	if(numteams > 2)
		dom_spawnteam("Yellow", COLOR_TEAM3-1, "models/domination/dom_yellow.md3", 0, "domination/claim.wav", "", "Yellow team has captured a control point");
	if(numteams > 3)
		dom_spawnteam("Pink", COLOR_TEAM4-1, "models/domination/dom_pink.md3", 0, "domination/claim.wav", "", "Pink team has captured a control point");
	dom_spawnteam("", 0, "models/domination/dom_unclaimed.md3", 0, "", "", "");
};

void dom_delayedinit()
{
	local entity head;

	// if no teams are found, spawn defaults, if custom teams are set, use them
	if (find(world, classname, "dom_team") == world || g_domination_teams_override > 1)
		dom_spawnteams();
	// if no control points are found, spawn defaults
	if (find(world, classname, "dom_controlpoint") == world)
	{
		// if no supported map was found, make every deathmatch spawn a point
		head = find(world, classname, "info_player_deathmatch");
		while (head)
		{
			dom_spawnpoint(head.origin);
			head = find(head, classname, "info_player_deathmatch");
		}
	}

	float sp_domticks, sp_score;
	sp_score = sp_domticks = 0;
	if(cvar("g_domination_disable_frags"))
		sp_domticks = SFL_SORT_PRIO_PRIMARY;
	else
		sp_score = SFL_SORT_PRIO_PRIMARY;
	scores_basics(sp_score, sp_score, TRUE);
	ST_DOM_TICKS = scores_register_team_score("ticks", sp_domticks);
	SP_DOM_TICKS = scores_register_score("ticks", sp_domticks);
	SP_DOM_TAKES = scores_register_score("takes", 0);
};

entity dom_SelectSpawnPoint() {
	return spawn_select(TRUE);
}

float dom_FragLimitOverride() { return cvar("g_domination_point_limit"); }

float dom_LeadLimitOverride() { return cvar("g_domination_point_leadlimit"); }

void dom_init()
{
	g_domination = 1;
	CACHE_CVAR(g_domination_default_teams);
	CACHE_CVAR(g_domination_point_amt);
	//CACHE_CVAR(g_domination_point_capturetime);
	CACHE_CVAR(g_domination_point_fullbright);
	CACHE_CVAR(g_domination_point_glow);
	CACHE_CVAR(g_domination_point_rate);
	CACHE_CVAR(g_domination_teams_override);
	// we have to precache default models/sounds even if they might not be
	// used because spawnfunc_worldspawn is executed before any other entities are read,
	// so we don't even know yet if this map is set up for domination...
	precache_model("models/domination/dom_red.md3");
	precache_model("models/domination/dom_blue.md3");
	precache_model("models/domination/dom_yellow.md3");
	precache_model("models/domination/dom_pink.md3");
	precache_model("models/domination/dom_unclaimed.md3");
	precache_sound("domination/claim.wav");
	GameHook_SelectSpawnPoint = dom_SelectSpawnPoint;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_FragLimitOverride = dom_FragLimitOverride;
	GameHook_LeadLimitOverride = dom_LeadLimitOverride;
	GameHook_BotChooseRole = havocbot_chooserole_dom;
	entity_initialize(world, dom_delayedinit, INITPRIO_GAMETYPE);
};

