void(void) coop_teleporter_think {
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

var void(float) coop_player_clear_next;
void(float killed) coop_player_clear {
	coop_player_clear_next(killed);
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

void(void) coop_teleporter_use {
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

void(void) spawnfunc_coop_teleporter {
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

var void() coop_observer_spawn_next;
void() coop_observer_spawn {
	coop_observer_spawn_next();
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
	ice_hook_frozen_status = coop_IceFrozenStatus;
	ice_hook_skip_death_handle = coop_IceSkipDeathHandle;
	ice_hook_unfroze = coop_IceUnfroze;
	ice_init();
}

void(void) coop_init {
	single_init();
	coop_player_clear_next = gamehook_chain_player_clear;
	gamehook_chain_player_clear = coop_player_clear;
	coop_observer_spawn_next = gamehook_chain_observer_spawn;
	gamehook_chain_observer_spawn = coop_observer_spawn;
	team_play_activate();
	team_teams_set_count(1);
	entity_initialize(world, coop_init_delayed, INITPRIO_GAMETYPE);
}
