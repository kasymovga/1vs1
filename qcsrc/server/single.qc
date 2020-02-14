float single_level_finished;
float _single_transit_weapons;
float single_secrets_found;
float single_secrets_total;
entity single_secrets_controller;

var void() Single_Shutdown_NextLink;
void Single_Shutdown() {
	registercvar("_single_transit_weapons", "0");
	cvar_set_builtin("_single_transit_weapons", ftos(_single_transit_weapons | weapon_spawned_list | start_weapons)); //builting function for avoid campaign wrapper
	Single_Shutdown_NextLink();
}

void Single_EndLevel() {
	single_level_finished = TRUE;
	entity e;
	FOR_EACH_PLAYER(e)
		e.winning = 1;

	campaign_won = TRUE;

	if (self.netname != "") {
		cvar_set("nextmap", self.netname);
		campaign_map_transition = TRUE;
	}
}

float Single_WinningCondition() {
	score_winning_condition_helper(); // set worldstatus
	return single_level_finished;
}

string Single_GameOverMessageMod(string s) {
	if (campaign_won) {
		string msg = strcat("^2Level finished\n", "Secrets: ", ftos(single_secrets_found), "/", ftos(single_secrets_total));
		return msg;
	} else
		return "^1Game over";
}

float Single_DeathHandle() {
	single_level_finished = TRUE;
	campaign_won = FALSE;
	campaign_map_transition = TRUE;
	return FALSE;
}

void Single_IceFrozenStatus() {
	entity e;
	FOR_EACH_PLAYER(e) {
		if (e.deadflag == DEAD_NO)
			return;
	}
	single_level_finished = TRUE;
	campaign_won = FALSE;
}

float Single_IceSkipDeathHandle() {
	return !self.wasplayer;
}

void Single_IceUnfroze() {
	return;
}

void single_init_delayed(void) {
	entity e;
	string s;
	entity map_target;
	for (e = nextent(world); e; e = nextent(e)) {
		if (e.target != "")
		if (substring(e.target, 0, 9) == "endlevel:") {
			s = substring(e.target, 9, -1);
			map_target = spawn();
			map_target.netname = strzone(s);
			print("endlevel with nextmap: ", s, "\n");
			map_target.targetname = e.target;
			map_target.use = Single_EndLevel;
		}
	}
	_single_transit_weapons = cvar_builtin("_single_transit_weapons"); //builtin to avoid campaign intercepting
	float i, j;
	for(i = WEP_FIRST, j = 1; i < WEP_LAST; ++i, j *= 2) {
		if (_single_transit_weapons & j)
			weapon_precache(i);
	}
}

void Single_SetNewParms() {
	parm5 = start_health;
	parm6 = start_armorvalue;
	parm7 = start_ammo_shells;
	parm8 = start_ammo_nails;
	parm9 = start_ammo_rockets;
	parm10 = start_ammo_cells;
	parm11 = start_weapons;
	parm12 = FALSE;
}

void Single_SetChangeParms() {
	if (self.classname == "player" && (self.deadflag == DEAD_NO || campaign_won)) {
		parm5 = self.health;
		parm6 = self.armorvalue;
		parm7 = self.ammo_shells;
		parm8 = self.ammo_nails;
		parm9 = self.ammo_rockets;
		parm10 = self.ammo_cells;
		parm11 = self.weapons;
		parm12 = TRUE;
	} else {
		Single_SetNewParms();
	}
}

.float default_equip;
void Single_DecodeLevelParms() {
	if (parm12) {
		self.health = parm5;
		self.armorvalue = parm6;
		self.ammo_shells = parm7;
		self.ammo_nails = parm8;
		self.ammo_rockets = parm9;
		self.ammo_cells = parm10;
		self.weapons = parm11;
		self.default_equip = FALSE;
	} else {
		self.default_equip = TRUE; //Hack for force default equip
	}
}

float Single_ForbidSpectators() {
	if not(self.default_equip) //For just connected players who carried equip from previous level
		return TRUE;

	return FALSE;
}

var float(void) single_player_equip_handle_next;
float(void) single_player_equip_handle {
	if (self.default_equip)
		return single_player_equip_handle_next();

	return TRUE;
}

float Single_SameLevel() {
	if (game == GAME_COOP)
	if (cvar("timelimit") < 0) //Endmatch
		return FALSE;

	return !campaign_won;
}

float Single_MonsterTeamSwitchable() {
	return FALSE;
}

var void() Single_PlayerPreThink_NextLink;
void Single_PlayerPreThink() {
	self.items &~= (IT_KEY1 | IT_KEY2);
	self.items |= self.keys;
	Single_PlayerPreThink_NextLink();
}

var void(entity) Single_Spawn_NextLink;
void Single_Spawn(entity e) {
	self.default_equip = TRUE;
	Single_Spawn_NextLink(e);
}

void(entity attacker) single_MonsterKilled {
	if (attacker.classname == "player")
		score_player_add(attacker, SP_SCORE, self.frags);
}

void Single_Init() {
	GameHook_SameLevel = Single_SameLevel;
	GameHook_ForbidSpectators = Single_ForbidSpectators;
	single_player_equip_handle_next = gamehook_chain_player_equip_handle;
	gamehook_chain_player_equip_handle = single_player_equip_handle;
	GameHook_WinningCondition = Single_WinningCondition;
	GameHook_GameOverMessageMod = Single_GameOverMessageMod;
	GameHook_DeathHandle = Single_DeathHandle;
	GameHook_SetNewParms = Single_SetNewParms;
	GameHook_SetChangeParms = Single_SetChangeParms;
	GameHook_DecodeLevelParms = Single_DecodeLevelParms;
	GameHook_MonsterTeamSwitchable = Single_MonsterTeamSwitchable;
	Single_PlayerPreThink_NextLink = GameHookChain_PlayerPreThink;
	GameHookChain_PlayerPreThink = Single_PlayerPreThink;
	Single_Spawn_NextLink = GameHookChain_Spawn;
	GameHookChain_Spawn = Single_Spawn;
	Single_Shutdown_NextLink = GameHookChain_Shutdown;
	GameHookChain_Shutdown = Single_Shutdown;
	GameHook_MonsterKilled = single_MonsterKilled;
	entity e = spawn();
	e.targetname = "endlevel";
	e.use = Single_EndLevel;
	entity_initialize(world, single_init_delayed, INITPRIO_GAMETYPE);
}

void(void) single_secret_controller_use {
	single_secrets_found++;
	single_secrets_controller.message = strcat("^2Secrets found: ^3", ftos(single_secrets_found), "^2/^3", ftos(single_secrets_total));
	GameStatus_Set(single_secrets_controller.message , 2);
}

void(void) single_secret_controller_reset {
	single_secrets_found = 0;
}

void(void) spawnfunc_single_secret {
	single_secrets_total++;
	self.noise = "misc/strength_respawn.wav";
	if (self.message == "") {
		self.message = "You found a secret area!";
	}
	self.spawnflags = self.spawnflags | SPAWNFLAG_PLAYERONLY;
	if not(single_secrets_controller) {
		single_secrets_controller = spawn();
		single_secrets_controller.targetname = "single_secrets_controller";
		single_secrets_controller.use = single_secret_controller_use;
		single_secrets_controller.reset = single_secret_controller_reset;
	}
	self.target = "single_secrets_controller";
	spawnfunc_trigger_once();
}
