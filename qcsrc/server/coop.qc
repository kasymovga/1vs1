
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

var void(float) coop_PlayerClear_NextLink;
void coop_PlayerClear(float killed) {
	coop_PlayerClear_NextLink(killed);
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

var void() coop_ObserverSpawn_NextLink;
void() coop_ObserverSpawn {
	coop_ObserverSpawn_NextLink();
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

float() coop_IceSkipDeathHandle {
	return !self.wasplayer;
}

void() coop_IceUnfroze {
	return;
}


void() coop_IceFrozenStatus {
	entity e;
	FOR_EACH_PLAYER(e) {
		if (e.deadflag == DEAD_NO)
			return;
	}
	single_level_finished = TRUE;
	campaign_won = FALSE;
}

void(void) coop_init_delayed {
	IceHook_FrozenStatus = coop_IceFrozenStatus;
	IceHook_SkipDeathHandle = coop_IceSkipDeathHandle;
	IceHook_Unfroze = coop_IceUnfroze;
	Ice_Init();
}

void(void) coop_init {
	Single_Init();
	coop_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = coop_PlayerClear;
	coop_ObserverSpawn_NextLink = GameHookChain_ObserverSpawn;
	GameHookChain_ObserverSpawn = coop_ObserverSpawn;
	team_play_activate();
	team_teams_set_count(1);
	entity_initialize(world, coop_init_delayed, INITPRIO_GAMETYPE);
}
