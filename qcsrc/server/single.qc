float single_level_finished;
float _single_transit_weapons;

var void() Single_Shutdown_NextLink;
void Single_Shutdown() {
	registercvar("_single_transit_weapons", "0");
	cvar_set_builtin("_single_transit_weapons", ftos(_single_transit_weapons | weaponsInMap | start_weapons)); //builting function for avoid campaign wrapper
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
	WinningConditionHelper(); // set worldstatus
	return single_level_finished;
}

string Single_GameOverMessageMod(string s) {
	if (campaign_won)
		return "^2Level finished";
	else
		return "^1Game over";
}

float Single_Return0() {
	return 0;
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
	if (game == GAME_COOP) {
		IceHook_FrozenStatus = Single_IceFrozenStatus;
		IceHook_SkipDeathHandle = Single_IceSkipDeathHandle;
		IceHook_Unfroze = Single_IceUnfroze;
		Ice_Init();
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

float Single_EquipPlayerHandle() {
	if (self.default_equip)
		return FALSE;

	return TRUE;
}

float Single_SameLevel() {
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

var void(float) Coop_PlayerClear_NextLink;
void Coop_PlayerClear(float killed) {
	Coop_PlayerClear_NextLink(killed);
	if (self.classname != "disconnecting")
		return;

	entity e;
	FOR_EACH_PLAYER(e) { //last alive player leave
		if (e != self)
		if (e.deadflag == DEAD_NO)
			return;
	}
	single_level_finished = TRUE;
	campaign_won = FALSE;
}

var void(entity) Single_Spawn_NextLink;
void Single_Spawn(entity e) {
	self.default_equip = TRUE;
	Single_Spawn_NextLink(e);
}

var void() Coop_ObserverSpawn_NextLink;
void() Coop_ObserverSpawn {
	Coop_ObserverSpawn_NextLink();
	entity e;
	float have_players;
	have_players = FALSE;
	FOR_EACH_PLAYER(e) { //last alive player become spectator
		if (e != self) {
			if (e.deadflag == DEAD_NO)
				return;

			have_players = TRUE;
		}
	}
	if (have_players) {
		single_level_finished = TRUE;
		campaign_won = FALSE;
	}
}

void Single_Init() {
	GameHook_SameLevel = Single_SameLevel;
	GameHook_ForbidSpectators = Single_ForbidSpectators;
	if (game == GAME_COOP) {
		Coop_PlayerClear_NextLink = GameHookChain_PlayerClear;
		GameHookChain_PlayerClear = Coop_PlayerClear;
		Coop_ObserverSpawn_NextLink = GameHookChain_ObserverSpawn;
		GameHookChain_ObserverSpawn = Coop_ObserverSpawn;
	}
	GameHook_EquipPlayerHandle = Single_EquipPlayerHandle;
	GameHook_WinningCondition = Single_WinningCondition;
	GameHook_GameOverMessageMod = Single_GameOverMessageMod;
	GameHook_FragLimitOverride = Single_Return0;
	GameHook_TimeLimitOverride = Single_Return0;
	GameHook_LeadLimitOverride = Single_Return0;
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
	entity e = spawn();
	e.targetname = "endlevel";
	e.use = Single_EndLevel;
	InitializeEntity(world, single_init_delayed, INITPRIO_GAMETYPE);
	if (game == GAME_COOP) {
		ActivateTeamplay();
		SetTeamCount(1);
	}
}

void coop_teleporter_think(void) {
	if (self.solid == SOLID_TRIGGER) {
		self.alpha = approach(self.alpha, 1, 1);
		if (self.alpha > 0.99)
			return;
	} else {
		self.alpha = approach(self.alpha, 0, 1);
		if (self.alpha < 0.01) {
			self.alpha = -1;
			return;
		}
	}
	self.nextthink = time;
}

void coop_teleporter_use(void) {
	if (self.solid == SOLID_TRIGGER) {
		self.solid = SOLID_NOT;
		self.effects &~= EF_STARDUST;
	} else {
		self.solid = SOLID_TRIGGER;
		self.effects |= EF_STARDUST;
		if (self.alpha < 0)
			self.alpha = 0.01;
	}
	self.nextthink = time;
}

void spawnfunc_coop_teleporter(void) {
	if (game != GAME_COOP) {
		remove(self);
		return;
	}
	precache_model("models/portal.md3");
	spawnfunc_trigger_teleport();
	setmodel(self, "models/portal.md3");
	setsize(self, '-32 -32 0', '32 32 40');
	self.angles_x = 90;
	self.angles_z = 0;
	self.alpha = -1;
	self.think = coop_teleporter_think;
	self.use = coop_teleporter_use;
	self.use();
}
