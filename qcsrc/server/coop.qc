float g_coop_monster_factor;
float g_coop_monster_base;

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
		self.effects &= ~EFFECT_STARDUST;
	} else {
		self.solid = SOLID_TRIGGER;
		self.effects |= EFFECT_STARDUST;
		if (self.alpha < 0)
			self.alpha = 0.01;
	}
	self.nextthink = time;
}

void(void) spawnfunc_coop_teleporter {
	if (gametype != GAMETYPE_COOP) {
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

float() coop_ice_skip_death_handle {
	return !self.wasplayer;
}

void(entity ignore) coop_ice_unfroze {
	return;
}


void() coop_ice_frozen_status {
	entity e;
	FOR_EACH_PLAYER(e) {
		if (e.deadflag == DEAD_NO)
			return;
	}
	single_level_finished = TRUE;
	campaign_won = FALSE;
}

void(void) coop_init_delayed {
	ice_hook_frozen_status = coop_ice_frozen_status;
	ice_hook_skip_death_handle = coop_ice_skip_death_handle;
	ice_hook_unfroze = coop_ice_unfroze;
	ice_init();
}

float coop_monster_quant_cache;
float coop_monster_quant_cache_time;
float() coop_monster_quant {
	if (self.spawnflags & MONSTER_SPAWN_STAYSTILL)
		return 1;

	if (coop_monster_quant_cache_time && coop_monster_quant_cache_time == time) {
		return coop_monster_quant_cache;
	}
	coop_monster_quant_cache_time = time;
	coop_monster_quant_cache = (g_coop_monster_base - g_coop_monster_factor);
	entity e;
	FOR_EACH_CLIENT(e) {
		if (e.classname == "player" && e.deadflag == DEAD_NO) {
			coop_monster_quant_cache += g_coop_monster_factor;
		}
	}
	coop_monster_quant_cache = 1 / max(coop_monster_quant_cache, 1);
	return coop_monster_quant_cache;
}

void(void) coop_init {
	single_init();
	CVAR_CACHE(g_coop_monster_factor);
	CVAR_CACHE(g_coop_monster_base);
	coop_player_clear_next = gamehook_chain_player_clear;
	gamehook_chain_player_clear = coop_player_clear;
	coop_observer_spawn_next = gamehook_chain_observer_spawn;
	gamehook_chain_observer_spawn = coop_observer_spawn;
	gamehook_monster_quant = coop_monster_quant;
	team_play_activate();
	team_teams_set_count(1);
	entity_initialize(world, coop_init_delayed, INITPRIO_GAMETYPE);
}
