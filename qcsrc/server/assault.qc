#define ST_ASSAULT_OBJECTIVES 1
#define SP_ASSAULT_OBJECTIVES 4
void spawnfunc_func_breakable();
void target_objective_decrease_activate();
.entity assault_decreaser;
.entity assault_sprite;

void spawnfunc_info_player_attacker() {
	if(!g_assault)
	{
		remove(self);
		return;
	}
	self.team = COLOR_TEAM1; // red, gets swapped every round
	spawnfunc_info_player_deathmatch();
}

void spawnfunc_info_player_defender() {
	if(!g_assault)
	{
		remove(self);
		return;
	}
	self.team = COLOR_TEAM2; // blue, gets swapped every round
	spawnfunc_info_player_deathmatch();
}

// reset this objective. Used when spawning an objective
// and when a new round starts
void assault_objective_reset() {
	self.health = ASSAULT_VALUE_INACTIVE;
}

void assault_objective_use() {
	if(other.classname == "info_player_deathmatch") // a spawn, a spawn
		return;

	// activate objective
	self.health = 100;
	//print("^2Activated objective ", self.targetname, "=", etos(self), "\n");
	//print("Activator is ", activator.classname, "\n");

	entity oldself;
	oldself = self;

	for(self = world; (self = find(self, target, oldself.targetname)); )
	{
		if(self.classname == "target_objective_decrease")
			target_objective_decrease_activate();
	}

	self = oldself;
}

void spawnfunc_target_objective() {
	if(!g_assault)
	{
		remove(self);
		return;
	}
	self.classname = "target_objective";
	self.use = assault_objective_use;
	assault_objective_reset();
	self.reset = assault_objective_reset;
}


// decrease the health of targeted objectives
void assault_objective_decrease_use() {
	if(activator.team != assault_attacker_team) {
		// wrong team triggered decrease
		return;
	}

	if(other.assault_sprite.classname == "assault_decreaser_sprite")
		WaypointSprite_Disown(other.assault_sprite, waypointsprite_deadlifetime);
	else
		return; // already activated! cannot activate again!

	if(self.enemy.health < ASSAULT_VALUE_INACTIVE)
	{
		if(self.enemy.health - self.dmg > 0.5)
		{
			PlayerTeamScore_Add(activator, SP_SCORE, ST_SCORE, self.dmg);
			self.enemy.health = self.enemy.health - self.dmg;
		}
		else
		{
			PlayerTeamScore_Add(activator, SP_SCORE, ST_SCORE, self.enemy.health);
			PlayerTeamScore_Add(activator, SP_ASSAULT_OBJECTIVES, ST_ASSAULT_OBJECTIVES, 1);
			self.enemy.health = -1;

			entity oldself, oldactivator;

			oldself = self;
			self = oldself.enemy;
				oldactivator = activator;
				activator = oldself;
					SUB_UseTargets();
				activator = oldactivator;
			self = oldself;
		}
	}
}

void assault_setenemytoobjective()
{
	local entity objective;
	for(objective = world; (objective = find(objective, targetname, self.target)); ) {
		if(objective.classname == "target_objective") {
			if(self.enemy == world)
				self.enemy = objective;
			else
				objerror("more than one objective as target - fix the map!");
			break;
		}
	}

	if(self.enemy == world)
		objerror("no objective as target - fix the map!");
}

float assault_decreaser_sprite_visible(entity e)
{
	entity decreaser;

	decreaser = self.assault_decreaser;

	if(decreaser.enemy.health >= ASSAULT_VALUE_INACTIVE)
		return FALSE;

	return TRUE;
}

void target_objective_decrease_activate()
{
	entity ent, spr;
	self.owner = world;
	for(ent = world; (ent = find(ent, target, self.targetname)); )
	{
		if(ent.assault_sprite != world)
			WaypointSprite_Disown(ent.assault_sprite, waypointsprite_deadlifetime);

		spr = WaypointSprite_SpawnFixed("<placeholder>", 0.5 * (ent.absmin + ent.absmax), ent, assault_sprite);
		spr.assault_decreaser = self;
		spr.waypointsprite_visible_for_player = assault_decreaser_sprite_visible;
		spr.classname = "assault_decreaser_sprite";
		WaypointSprite_UpdateRule(spr, assault_attacker_team, SPRITERULE_TEAMPLAY);
		if(ent.classname == "func_assault_destructible")
			WaypointSprite_UpdateSprites(spr, "as-defend", "as-destroy", "as-destroy");
		else
			WaypointSprite_UpdateSprites(spr, "as-defend", "as-push", "as-push");
		WaypointSprite_UpdateTeamRadar(spr, RADARICON_OBJECTIVE, '1 0.5 0');
	}
}

void target_objective_decrease_findtarget()
{
	assault_setenemytoobjective();
}

//=============================================================================

void spawnfunc_target_objective_decrease() {
	if(!g_assault)
	{
		remove(self);
		return;
	}

	self.classname = "target_objective_decrease";

	if(!self.dmg) {
		self.dmg = 101;
	}
	self.use = assault_objective_decrease_use;
	self.health = ASSAULT_VALUE_INACTIVE;
	self.max_health = ASSAULT_VALUE_INACTIVE;
	self.enemy = world;

	InitializeEntity(self, target_objective_decrease_findtarget, INITPRIO_FINDTARGET);
}

// destructible walls that can be used to trigger target_objective_decrease
void spawnfunc_func_assault_destructible() {
	if(!g_assault)
	{
		remove(self);
		return;
	}
	self.spawnflags = 3;
	spawnfunc_func_breakable();
}

void assault_wall_think() {
	if(self.enemy.health < 0) {
		self.model = "";
		self.solid = SOLID_NOT;
	} else {
		self.model = self.mdl;
		self.solid = SOLID_BSP;
	}

	self.nextthink = time + 0.2;
}

void spawnfunc_func_assault_wall() {
	if(!g_assault)
	{
		remove(self);
		return;
	}
	self.classname = "func_assault_wall";
	self.mdl = self.model;
	setmodel(self, self.mdl);
	self.solid = SOLID_BSP;
	self.think = assault_wall_think;
	self.nextthink = time;
	InitializeEntity(self, assault_setenemytoobjective, INITPRIO_FINDTARGET);
}


void target_assault_roundend_reset() {
	self.winning = FALSE;
}

void target_assault_roundend_use() {
	self.winning = TRUE;
}

void spawnfunc_target_assault_roundend() {
	if(!g_assault)
	{
		remove(self);
		return;
	}
	self.winning = FALSE; // round not yet won by attackers
	self.classname = "target_assault_roundend";
	self.use = target_assault_roundend_use;
	self.cnt = FALSE; // first round
}

void assault_roundstart_use() {
	activator = self;
	SUB_UseTargets();

	entity ent,oldself;

	//(Re)spawn all turrets
	oldself = self;
	ent = find(world, classname, "turret_main");
	while(ent) {
		// Swap turret teams
		if(ent.team == COLOR_TEAM1)
			ent.team = COLOR_TEAM2;
		else
			ent.team = COLOR_TEAM1;

		self = ent;

		// Dubbles as teamchange
		turret_stdproc_respawn();
		//ent.turret_spawnfunc();

		ent = find(ent, classname, "turret_main");
	}
	self = oldself;
}

void spawnfunc_target_assault_roundstart() {
	if(!g_assault)
	{
		remove(self);
		return;
	}
	assault_attacker_team = COLOR_TEAM1;
	self.classname = "target_assault_roundstart";
	self.use = assault_roundstart_use;
	self.reset2 = assault_roundstart_use;
	InitializeEntity(self, assault_roundstart_use, INITPRIO_FINDTARGET);
}

// trigger new round
// reset objectives, toggle spawnpoints, reset triggers, ...
void assault_new_round() {
	//bprint("ASSAULT: new round\n");

	// up round counter

	// swap attacker/defender roles
	if(assault_attacker_team == COLOR_TEAM1) {
		assault_attacker_team = COLOR_TEAM2;
	} else {
		assault_attacker_team = COLOR_TEAM1;
	}


	local entity ent;
	for(ent = world; (ent = nextent(ent)); )
	{
		if(clienttype(ent) == CLIENTTYPE_NOTACLIENT)
		{
			if(ent.team_saved == COLOR_TEAM1)
				ent.team_saved = COLOR_TEAM2;
			else if(ent.team_saved == COLOR_TEAM2)
				ent.team_saved = COLOR_TEAM1;
		}
	}

	// reset the level with a countdown
	cvar_set("timelimit", ftos(ceil(time - game_starttime) / 60));
	ReadyRestartForce(); // sets game_starttime
}

// Assault winning condition: If the attackers triggered a round end (by fulfilling all objectives)
// they win. Otherwise the defending team wins once the timelimit passes.
float assault_WinningCondition(float ignore1, float ignore2)
{
	WinningConditionHelper(); // set worldstatus

	// as the timelimit has not yet passed just assume the defending team will win
	if(assault_attacker_team == COLOR_TEAM1)
	{
		SetWinners(team, COLOR_TEAM2);
	}
	else
	{
		SetWinners(team, COLOR_TEAM1);
	}

	local entity ent;
	ent = world;
	while ((ent = find(ent, classname, "target_assault_roundend")))
	{
		if(ent.winning)	// round end has been triggered by attacking team
		{
			bprint("ASSAULT: round completed...\n");
			ent.winning = FALSE;
			SetWinners(team, assault_attacker_team);

			TeamScore_AddToTeam(assault_attacker_team, ST_ASSAULT_OBJECTIVES, 666 - TeamScore_AddToTeam(assault_attacker_team, ST_ASSAULT_OBJECTIVES, 0));

			if(ent.cnt) // this was the second round
				return TRUE;
			else {
				ent.cnt = TRUE;
				local entity oldself;
				oldself = self;
				self = ent;
				assault_new_round();
				self = oldself;
			}
		}
	}

	return FALSE;
}

void assault_spawn(entity spot) {
	if(self.team == assault_attacker_team)
		centerprint(self, "You are attacking!");
	else
		centerprint(self, "You are defending!");
}

float assault_SpawnPointGood(entity spot) {
	if(spot.target == "")
		return TRUE;

	local entity ent;
	float good, found;
	ent = find(world, targetname, spot.target);
	while(ent) {
		if(ent.classname == "target_objective")
		{
			found = 1;
			if(ent.health < 0 || ent.health >= ASSAULT_VALUE_INACTIVE)
				return FALSE;

			good = 1;
		}
		ent = find(ent, targetname, spot.target);
	}
	if(found && !good)
		return FALSE;

	return TRUE;
}

float assault_ReadyRestartHard() { return TRUE; }

void assault_init() {
	GameHook_WinningCondition = assault_WinningCondition;
	GameHook_Spawn = assault_spawn;
	GameHook_SpawnPointGood = assault_SpawnPointGood;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_WarmupAllowed = false_WarmupAllowed;
	GameHook_ReadyRestartHard = assault_ReadyRestartHard;
	ScoreRules_basics(2, SFL_SORT_PRIO_SECONDARY, SFL_SORT_PRIO_SECONDARY, TRUE);
	ScoreInfo_SetLabel_TeamScore(  ST_ASSAULT_OBJECTIVES,    "objectives",      SFL_SORT_PRIO_PRIMARY);
	ScoreInfo_SetLabel_PlayerScore(SP_ASSAULT_OBJECTIVES,    "objectives",      SFL_SORT_PRIO_PRIMARY);
	ScoreRules_basics_end();
}
