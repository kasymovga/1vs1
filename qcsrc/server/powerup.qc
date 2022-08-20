float g_powerup_strength_droppable;
float g_powerup_invisibility_droppable;
float g_powerup_shield_droppable;
float g_powerup_speed_droppable;
float g_powerup_invisibility_full_distance;
float g_balance_powerup_invincible_takedamage;
float g_balance_powerup_strength_damage;
float g_balance_powerup_strength_force;
float g_balance_powerup_strength_selfdamage;
float g_balance_powerup_strength_selfforce;

void(.float powerupfield, void(void) spawnfunc) powerup_drop {
	entity oldself;
	if (self.powerupfield > time) {
		entity e = spawn();
		e.classname = "droppedpowerup";
		setorigin(e, self.origin);
		oldself = self;
		self = e;
		spawnfunc();
		self = oldself;
		if not(wasfreed(e))
			e.powerupfield = self.powerupfield - time;
	}
}

var void(float killed) powerup_player_clear_next;
void(float killed) powerup_player_clear {
	if (killed) {
		if (g_powerup_strength_droppable)
			powerup_drop(strength_finished, item_spawnfunc_for("strength"));

		if (g_powerup_shield_droppable)
			powerup_drop(invincible_finished, item_spawnfunc_for("invincible"));

		if (g_powerup_invisibility_droppable)
			powerup_drop(invisibility_finished, item_spawnfunc_for("invisibility"));

		if (g_powerup_speed_droppable)
			powerup_drop(speed_finished, item_spawnfunc_for("speed"));
	}
	self.invincible_finished = 0;
	self.invisibility_finished = 0;
	self.strength_finished = 0;
	self.speed_finished = 0;
	powerup_player_clear_next(killed);
}

var void(entity e) powerup_spectator_copy_next;
void(entity e) powerup_spectator_copy {
	self.strength_finished = e.strength_finished;
	self.invincible_finished = e.invincible_finished;
	self.speed_finished = e.speed_finished;
	self.invisibility_finished = e.invisibility_finished;
	powerup_spectator_copy_next(e);
}

float powerup_init_done;
void() powerup_init {
	if (powerup_init_done)
		return;

	powerup_init_done = 1;
	CVAR_CACHE(g_powerup_strength_akimbo);
	CVAR_CACHE(g_powerup_strength_droppable);
	CVAR_CACHE(g_powerup_invisibility_droppable);
	CVAR_CACHE(g_powerup_shield_droppable);
	CVAR_CACHE(g_powerup_speed_droppable);
	CVAR_CACHE(g_powerup_invisibility_full_distance);
	CVAR_CACHE(g_balance_powerup_invincible_takedamage);
	CVAR_CACHE(g_balance_powerup_strength_damage);
	CVAR_CACHE(g_balance_powerup_strength_force);
	CVAR_CACHE(g_balance_powerup_strength_selfdamage);
	CVAR_CACHE(g_balance_powerup_strength_selfforce);
	powerup_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = powerup_player_clear;
	powerup_spectator_copy_next = plugin_chain_spectator_copy;
	plugin_chain_spectator_copy = powerup_spectator_copy;
}

var void(entity targ, entity attacker, float deathtype) powerup_invincible_damage_mods_set_next;
void(entity targ, entity attacker, float deathtype) powerup_invincible_damage_mods_set {
	if (targ.items & IT_INVINCIBLE)
	if (deathtype != DEATH_HURTTRIGGER) {
		plugin_chain_damage_mod = plugin_chain_damage_mod * g_balance_powerup_invincible_takedamage;
		if (deathtype == DEATH_SLIME || deathtype == DEATH_LAVA)
			plugin_chain_damage_mod = 0;
	}
	powerup_invincible_damage_mods_set_next(targ, attacker, deathtype);
}

var void() powerup_invincible_player_effects_next;
void() powerup_invincible_player_effects {
	if (self.items & IT_INVINCIBLE) {
		play_countdown(self.invincible_finished, "misc/poweroff.wav");
		self.effects = self.effects | (EFFECT_RED | EFFECT_ADDITIVE | EFFECT_FULLBRIGHT);
		if (time > self.invincible_finished) {
			self.items = self.items - (self.items & IT_INVINCIBLE);
			sprint(self, "^3Shield has worn off\n");
		}
	} else if (self.invincible_finished) {
		if (time < self.invincible_finished) {
			self.items = self.items | IT_INVINCIBLE;
			sprint(self, "^3Shield surrounds you\n");
		} else if (time > self.invincible_finished + 1) //1 second for fade effect on client
			self.invincible_finished = 0;
	}
	powerup_invincible_player_effects_next();
}

float powerup_invincible_init_done;
void() powerup_invincible_init {
	if (powerup_invincible_init_done)
		return;

	powerup_invincible_init_done = 1;
	powerup_init();
	addstat(STAT_INVINCIBLE_FINISHED, STAT_FLOAT, invincible_finished);
	powerup_invincible_player_effects_next = plugin_chain_player_effects;
	plugin_chain_player_effects = powerup_invincible_player_effects;
	powerup_invincible_damage_mods_set_next = plugin_chain_damage_mods_set;
	plugin_chain_damage_mods_set = powerup_invincible_damage_mods_set;
}

var void(entity targ, entity attacker, float deathtype) powerup_strength_damage_mods_set_next;
void(entity targ, entity attacker, float deathtype) powerup_strength_damage_mods_set {
	// apply strength multiplier
	if ((attacker.items & IT_STRENGTH)) {
		if(targ == attacker) {
			plugin_chain_damage_mod = plugin_chain_damage_mod * g_balance_powerup_strength_selfdamage;
			plugin_chain_damage_mod_force = plugin_chain_damage_mod_force * g_balance_powerup_strength_selfforce;
		} else {
			plugin_chain_damage_mod = plugin_chain_damage_mod * g_balance_powerup_strength_damage;
			plugin_chain_damage_mod_force = plugin_chain_damage_mod_force * g_balance_powerup_strength_force;
		}
	}
	powerup_strength_damage_mods_set_next(targ, attacker, deathtype);
}

var void() powerup_strength_player_effects_next;
void() powerup_strength_player_effects {
	if (self.items & IT_STRENGTH) {
		play_countdown(self.strength_finished, "misc/poweroff.wav");
		self.effects = self.effects | (EFFECT_BLUE | EFFECT_ADDITIVE | EFFECT_FULLBRIGHT);
		if (time > self.strength_finished) {
			self.items = self.items - (self.items & IT_STRENGTH);
			sprint(self, "^3Strength has worn off\n");
		}
	} else if (self.strength_finished) {
		if (time < self.strength_finished) {
			self.items = self.items | IT_STRENGTH;
			sprint(self, "^3Strength infuses your weapons with devastating power\n");
		} else if (time > self.strength_finished + 1) //1 second for fade effect on client
			self.strength_finished = 0;
	}
	powerup_strength_player_effects_next();
}

var void() powerup_strength_akimbo_player_effects_next;
void() powerup_strength_akimbo_player_effects {
	if (self.items & IT_STRENGTH) {
		play_countdown(self.strength_finished, "misc/poweroff.wav");
		if (time > self.strength_finished) {
			self.items = self.items - (self.items & IT_STRENGTH);
			sprint(self, "^3Akimbo has worn off\n");
		}
	} else if (self.strength_finished) {
		if (time < self.strength_finished) {
			self.items = self.items | IT_STRENGTH;
			sprint(self, "^3Akimbo: double gun, double fun\n");
		} else if (time > self.strength_finished + 1) //1 second for fade effect on client
			self.strength_finished = 0;
	}
	powerup_strength_akimbo_player_effects_next();
}

float powerup_strength_init_done;
void() powerup_strength_init {
	if (powerup_strength_init_done)
		return;

	powerup_strength_init_done = 1;
	powerup_init();
	addstat(STAT_STRENGTH_FINISHED, STAT_FLOAT, strength_finished);
	if (g_powerup_strength_akimbo) {
		powerup_strength_akimbo_player_effects_next = plugin_chain_player_effects;
		plugin_chain_player_effects = powerup_strength_akimbo_player_effects;
		return;
	}
	powerup_strength_player_effects_next = plugin_chain_player_effects;
	plugin_chain_player_effects = powerup_strength_player_effects;
	powerup_strength_damage_mods_set_next = plugin_chain_damage_mods_set;
	plugin_chain_damage_mods_set = powerup_strength_damage_mods_set;
}

var float() powerup_speed_weapon_rate_factor_next;
float() powerup_speed_weapon_rate_factor {
	if (time < self.speed_finished)
		return powerup_speed_weapon_rate_factor_next() * 0.666;

	return powerup_speed_weapon_rate_factor_next();
}

var void() powerup_speed_player_effects_next;
void() powerup_speed_player_effects {
	if (self.items & IT_SPEED) {
		play_countdown(self.speed_finished, "misc/poweroff.wav");
		if (time > self.speed_finished) {
			self.items = self.items - (self.items & IT_SPEED);
			sprint(self, "^3Speed has worn off\n");
		}
	} else if (self.speed_finished) {
		if (time < self.speed_finished) {
			self.items = self.items | IT_SPEED;
			sprint(self, "^3You are on speed\n");
		} else if (time > self.speed_finished + 1) //1 second for fade effect on client
			self.speed_finished = 0;
	}
	powerup_speed_player_effects_next();
}

var float() powerup_speed_physics_max_speed_mod_next;
float() powerup_speed_max_speed_mod {
	if (time < self.speed_finished)
		return powerup_speed_physics_max_speed_mod_next() * 1.5;

	return powerup_speed_physics_max_speed_mod_next();
}

float powerup_speed_init_done;
void() powerup_speed_init {
	if (powerup_speed_init_done)
		return;

	powerup_speed_init_done = 1;
	powerup_init();
	powerup_speed_physics_max_speed_mod_next = plugin_chain_physics_max_speed_mod;
	plugin_chain_physics_max_speed_mod = powerup_speed_max_speed_mod;
	powerup_speed_player_effects_next = plugin_chain_player_effects;
	plugin_chain_player_effects = powerup_speed_player_effects;
	powerup_speed_weapon_rate_factor_next = plugin_chain_weapon_rate_factor;
	plugin_chain_weapon_rate_factor = powerup_speed_weapon_rate_factor;
	addstat(STAT_SPEED_FINISHED, STAT_FLOAT, speed_finished);
}

var void() powerup_invisibility_player_effects_next;
void() powerup_invisibility_player_effects {
	if (self.items & IT_INVISIBILITY) {
		play_countdown(self.invisibility_finished, "misc/poweroff.wav");
		if (time > self.invisibility_finished) {
			self.items &= ~IT_INVISIBILITY;
			sprint(self, "^3Invisibility has worn off\n");
		}
	} else if (self.invisibility_finished) {
		if (time < self.invisibility_finished) {
			self.items |= IT_INVISIBILITY;
			sprint(self, "^3You are invisible\n");
		} else if (time > self.invisibility_finished + 1) //1 second for fade effect on client
			self.invisibility_finished = 0;
	}
	powerup_invisibility_player_effects_next();
}

var float(entity plr, entity viewer, float dalpha) powerup_invisibility_player_alpha_mod_next;
float(entity plr, entity viewer, float dalpha) powerup_invisibility_player_alpha_mod {
	if (time < plr.invisibility_finished) {
		if (g_powerup_invisibility_full_distance && vlen(plr.origin - viewer.origin) > g_powerup_invisibility_full_distance)
			dalpha = 0;
		else
			dalpha *= 0.05;
	}
	return powerup_invisibility_player_alpha_mod_next(plr, viewer, dalpha);
}

float powerup_invisibility_init_done;
void() powerup_invisibility_init {
	if (powerup_invisibility_init_done)
		return;

	powerup_invisibility_init_done = 1;
	powerup_init();
	powerup_invisibility_player_alpha_mod_next = plugin_chain_player_alpha_mod;
	plugin_chain_player_alpha_mod = powerup_invisibility_player_alpha_mod;
	powerup_invisibility_player_effects_next = plugin_chain_player_effects;
	plugin_chain_player_effects = powerup_invisibility_player_effects;
	addstat(STAT_INVISIBILITY_FINISHED, STAT_FLOAT, invisibility_finished);
}
