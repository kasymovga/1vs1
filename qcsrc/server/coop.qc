float g_coop_monster_factor;
float g_coop_monster_base;
float g_coop_item_share;
float g_coop_item_share_distance;

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
	if not(killed)
		score_player_set(self, SP_STATUS, 0);

	if (self.classname != "disconnecting")
		return;

	entity e;
	PLAYER_FOR_EACH(e) { //last alive player leave
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

void(void) coop_teleporter_touch {
	if not(other.classname == "player" && other.health > 0) return;
	entity t = find(NULL, targetname, self.target);
	if (t)
		teleport(self, other, t.origin, t.angles, '0 0 0', '0 0 0', '0 0 0', 0);
}

void(void) spawnfunc_coop_teleporter {
	if (game_type != GAME_TYPE_COOP) {
		remove(self);
		return;
	}
	precache_model("models/portal.md3");
	setmodel(self, "models/portal.md3");
	setsize(self, '-32 -32 0', '32 32 40');
	self.angles_x = 90;
	self.angles_z = 0;
	self.alpha = -1;
	self.think = coop_teleporter_think;
	self.use = coop_teleporter_use;
	self.touch = coop_teleporter_touch;
	self.solid = SOLID_TRIGGER;
	self.use();
}

var void() coop_observer_spawn_next;
void() coop_observer_spawn {
	coop_observer_spawn_next();
	entity e;
	float have_players;
	have_players = FALSE;
	PLAYER_FOR_EACH(e) { //last alive player become spectator
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

var void(entity ignore) coop_ice_unfroze_next;
void(entity ignore) coop_ice_unfroze {
	coop_ice_unfroze_next(ignore);
	score_player_set(self.owner, SP_STATUS, 0);
}

void() coop_ice_frozen_status {
	score_player_set(self, SP_STATUS, 1);
	entity e;
	PLAYER_FOR_EACH(e) {
		if (e.deadflag == DEAD_NO)
			return;
	}
	single_level_finished = TRUE;
	campaign_won = FALSE;
}

void(void) coop_init_delayed {
	plugin_ice_frozen_status = coop_ice_frozen_status;
	plugin_ice_skip_death_handle = coop_ice_skip_death_handle;
	coop_ice_unfroze_next = plugin_chain_ice_unfroze;
	plugin_chain_ice_unfroze = coop_ice_unfroze;
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
	CLIENT_FOR_EACH(e) {
		if (e.classname == "player" && e.deadflag == DEAD_NO) {
			coop_monster_quant_cache += g_coop_monster_factor;
		}
	}
	coop_monster_quant_cache = 1 / max(coop_monster_quant_cache, 1);
	return coop_monster_quant_cache;
}

void(entity attacker) coop_monster_killed {
	single_monster_killed(attacker);
	if (attacker.classname == "player") {
		score_team_add_to(attacker.team, ST_SCORE, self.frags);
	}
}

entity coop_item_give;
float coop_item_give_recursion;

var float(entity to, float f) coop_item_give_factor_next;
float(entity to, float f) coop_item_give_factor {
	if (coop_item_give && !coop_item_give_recursion) {
		entity item = coop_item_give;
		coop_item_give_recursion = TRUE;
		entity e, e2;
		e2 = spawn();
		vector o = ENTITY_CENTER(to), o2;
		PLAYER_FOR_EACH(e) {
			if (e != to && e.deadflag == DEAD_NO) {
				o2 = ENTITY_CENTER(e);
				if (vlen(o - o2) <= g_coop_item_share_distance) {
					te_lightning2(NULL, o, o2);
					copyentity(item, e2);
					item_give_to(e2, e);
				}
			}
		}
		remove(e2);
		coop_item_give_recursion = FALSE;
		coop_item_give = NULL;
	} else if (coop_item_give_recursion)
		f *= g_coop_item_share;

	return coop_item_give_factor_next(to, f);
}

var float(entity item, entity plr) coop_item_give_to_handle_next;
float(entity item, entity plr) coop_item_give_to_handle {
	coop_item_give = NULL;
	if ((item.flags & FL_POWERUP) //no powerups
			|| (item.flags & FL_WEAPON) //no weapons
			|| (item.items & (IT_KEY1 | IT_KEY2 | IT_KEY3)) //no keys
			|| coop_item_give_recursion //no recursion
			|| substring(item.classname, 0, 7) == "dropped") //no dropped item
		goto finish;

	coop_item_give = item;
:finish
	return coop_item_give_to_handle_next(item, plr);
}

void(void) coop_init {
	single_init();
	score_generic();
	SP_STATUS = score_register("status", 0);
	CVAR_CACHE(g_coop_monster_factor);
	CVAR_CACHE(g_coop_monster_base);
	CVAR_CACHE(g_coop_item_share);
	CVAR_CACHE(g_coop_item_share_distance);
	coop_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = coop_player_clear;
	coop_observer_spawn_next = plugin_chain_observer_spawn;
	plugin_chain_observer_spawn = coop_observer_spawn;
	plugin_monster_quant = coop_monster_quant;
	plugin_monster_killed = coop_monster_killed;
	coop_item_give_to_handle_next = plugin_chain_ItemGiveToHandle;
	plugin_chain_ItemGiveToHandle = coop_item_give_to_handle;
	if (g_coop_item_share) {
		coop_item_give_factor_next = plugin_chain_item_give_factor;
		plugin_chain_item_give_factor = coop_item_give_factor;
	}
	team_play_activate();
	team_teams_set_count(1);
	entity_initialize(world, coop_init_delayed, INITPRIO_GAMETYPE);
}
