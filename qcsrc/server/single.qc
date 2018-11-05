float single_level_finished;

void Single_EndLevel() {
	single_level_finished = TRUE;
	entity e;
	FOR_EACH_PLAYER(e)
		e.winning = 1;

	campaign_won = TRUE;

	if (self.netname != "")
		cvar_set("nextmap", self.netname);
	else
		print("no nextmap found\n");
}

float Single_WinningCondition() {
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
}

void Single_SetNewParms() {
	parm5 = 100;
	parm6 = 0;
	parm7 = 25;
	parm8 = 0;
	parm9 = 0;
	parm10 = 0;
	parm11 = 3;
}

void Single_SetChangeParms() {
	if (self.classname == "player" && self.deadflag == DEAD_NO) {
		parm5 = self.health;
		parm6 = self.armorvalue;
		parm7 = self.ammo_shells;
		parm8 = self.ammo_nails;
		parm9 = self.ammo_rockets;
		parm10 = self.ammo_cells;
		parm11 = self.weapons;
	} else {
		Single_SetNewParms();
	}
}

void Single_DecodeLevelParms() {
	self.health = parm5;
	self.armorvalue = parm6;
	self.ammo_shells = parm7;
	self.ammo_nails = parm8;
	self.ammo_rockets = parm9;
	self.ammo_cells = parm10;
	self.weapons = parm11;
}

float Single_ForbidSpectators() {
	return TRUE;
}

float Single_EquipPlayer() {
	self.ammo_fuel = 0;
	if (self.wasplayer) {
		Single_SetNewParms();
		Single_DecodeLevelParms();
	}
	return TRUE;
}

float Single_SameLevel() {
	return !campaign_won;
}

float Single_MonsterTeamSwitchable() {
	return FALSE;
}

void Single_Init() {
	GameHook_SameLevel = Single_SameLevel;
	GameHook_ForbidSpectators = Single_ForbidSpectators;
	GameHook_EquipPlayer = Single_EquipPlayer;
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
	entity e = spawn();
	e.targetname = "endlevel";
	e.use = Single_EndLevel;
	InitializeEntity(world, single_init_delayed, INITPRIO_GAMETYPE);
	if (game == GAME_COOP) {
		ActivateTeamplay();
		SetTeamCount(1);
	}
}
