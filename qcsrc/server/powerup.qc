float g_powerup_strength_droppable;
float g_powerup_invisibility_droppable;
float g_powerup_shield_droppable;
float g_powerup_speed_droppable;
float g_balance_powerup_invincible_takedamage;
float g_balance_powerup_strength_damage;
float g_balance_powerup_strength_force;
float g_balance_powerup_strength_selfdamage;
float g_balance_powerup_strength_selfforce;

void(.float powerupfield, string _model, string _sound, string _name, float it) powerup_drop {
	entity oldself;
	if (self.powerupfield > time) {
		entity e = spawn();
		e.classname = "droppedpowerup";
		e.powerupfield = self.powerupfield - time;
		setorigin(e, self.origin);
		oldself = self;
		self = e;
		item_start(_model, _sound, 0, 0, _name, it, 0, FL_POWERUP, item_generic_pickupevalfunc, 100000);
		self = oldself;
	}
}

var void(float killed) powerup_player_clear_next;
void(float killed) powerup_player_clear {
	if (killed) {
		if (g_powerup_strength_droppable)
			powerup_drop(strength_finished, "models/items/g_strength.md3", "misc/powerup.wav", "Strength Powerup", IT_STRENGTH);

		if (g_powerup_shield_droppable)
			powerup_drop(invincible_finished, "models/items/g_invincible.md3", "misc/powerup_shield.wav", "Shield", IT_INVINCIBLE);

		if (g_powerup_invisibility_droppable)
			powerup_drop(invisibility_finished, "models/items/g_strength.md3", "misc/powerup.wav", "Invisibility", IT_INVISIBILITY);

		if (g_powerup_speed_droppable)
			powerup_drop(speed_finished, "models/items/g_invincible.md3", "misc/powerup_shield.wav", "Shield", IT_SPEED);
	}
	self.invincible_finished = 0;
	self.invisibility_finished = 0;
	self.strength_finished = 0;
	self.speed_finished = 0;
	powerup_player_clear_next(killed);
}

var void(entity e) powerup_SpectateCopy_NextLink;
void(entity e) powerup_SpectateCopy {
	self.strength_finished = e.strength_finished;
	self.invincible_finished = e.invincible_finished;
	self.speed_finished = e.speed_finished;
	self.invisibility_finished = e.invisibility_finished;
	powerup_SpectateCopy_NextLink(e);
}

float powerup_init_done;
void() powerup_init {
	if (powerup_init_done)
		return;

	powerup_init_done = 1;
	CACHE_CVAR(g_powerup_strength_akimbo);
	CACHE_CVAR(g_powerup_strength_droppable);
	CACHE_CVAR(g_powerup_invisibility_droppable);
	CACHE_CVAR(g_powerup_shield_droppable);
	CACHE_CVAR(g_powerup_speed_droppable);
	CACHE_CVAR(g_balance_powerup_invincible_takedamage);
	CACHE_CVAR(g_balance_powerup_strength_damage);
	CACHE_CVAR(g_balance_powerup_strength_force);
	CACHE_CVAR(g_balance_powerup_strength_selfdamage);
	CACHE_CVAR(g_balance_powerup_strength_selfforce);
	powerup_player_clear_next = gamehook_chain_player_clear;
	gamehook_chain_player_clear = powerup_player_clear;
	powerup_SpectateCopy_NextLink = GameHookChain_SpectateCopy;
	GameHookChain_SpectateCopy = powerup_SpectateCopy;
}

var void(entity targ, entity attacker, float deathtype) powerup_invincible_DamageForceModsSet_NextLink;
void(entity targ, entity attacker, float deathtype) powerup_invincible_DamageForceModsSet {
	if (targ.items & IT_INVINCIBLE) {
		GameHook_DamageMod = GameHook_DamageMod * g_balance_powerup_invincible_takedamage;
		if (deathtype == DEATH_SLIME || deathtype == DEATH_LAVA)
			GameHook_DamageMod = 0;
	}
	powerup_invincible_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

var void() powerup_invincible_player_effects_next_link;
void() powerup_invincible_player_effects {
	if (self.items & IT_INVINCIBLE) {
		play_countdown(self.invincible_finished, "misc/poweroff.wav");
		self.effects = self.effects | (EF_RED | EF_ADDITIVE | EF_FULLBRIGHT);
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
	powerup_invincible_player_effects_next_link();
}

float powerup_invincible_init_done;
void() powerup_invincible_init {
	if (powerup_invincible_init_done)
		return;

	powerup_invincible_init_done = 1;
	powerup_init();
	addstat(STAT_INVINCIBLE_FINISHED, AS_FLOAT, invincible_finished);
	powerup_invincible_player_effects_next_link = gamehook_chain_player_effects;
	gamehook_chain_player_effects = powerup_invincible_player_effects;
	powerup_invincible_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = powerup_invincible_DamageForceModsSet;
}

var void(entity targ, entity attacker, float deathtype) powerup_strength_DamageForceModsSet_NextLink;
void(entity targ, entity attacker, float deathtype) powerup_strength_DamageForceModsSet {
	// apply strength multiplier
	if ((attacker.items & IT_STRENGTH)) {
		if(targ == attacker) {
			GameHook_DamageMod = GameHook_DamageMod * g_balance_powerup_strength_selfdamage;
			GameHook_ForceMod = GameHook_ForceMod * g_balance_powerup_strength_selfforce;
		} else {
			GameHook_DamageMod = GameHook_DamageMod * g_balance_powerup_strength_damage;
			GameHook_ForceMod = GameHook_ForceMod * g_balance_powerup_strength_force;
		}
	}
	powerup_strength_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

var void() powerup_strength_player_effects_next_link;
void() powerup_strength_player_effects {
	if (self.items & IT_STRENGTH) {
		play_countdown(self.strength_finished, "misc/poweroff.wav");
		self.effects = self.effects | (EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT);
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
	powerup_strength_player_effects_next_link();
}

var void() powerup_strength_akimbo_player_effects_next_link;
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
	powerup_strength_akimbo_player_effects_next_link();
}

float powerup_strength_init_done;
void() powerup_strength_init {
	if (powerup_strength_init_done)
		return;

	powerup_strength_init_done = 1;
	powerup_init();
	addstat(STAT_STRENGTH_FINISHED, AS_FLOAT, strength_finished);
	if (g_powerup_strength_akimbo) {
		powerup_strength_akimbo_player_effects_next_link = gamehook_chain_player_effects;
		gamehook_chain_player_effects = powerup_strength_akimbo_player_effects;
		return;
	}
	powerup_strength_player_effects_next_link = gamehook_chain_player_effects;
	gamehook_chain_player_effects = powerup_strength_player_effects;
	powerup_strength_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = powerup_strength_DamageForceModsSet;
}

var float() powerup_speed_WeaponRateFactor_NextLink;
float() powerup_speed_WeaponRateFactor {
	if (time < self.speed_finished)
		return powerup_speed_WeaponRateFactor_NextLink() * 0.666;

	return powerup_speed_WeaponRateFactor_NextLink();
}

var void() powerup_speed_player_effects_next_link;
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
	powerup_speed_player_effects_next_link();
}

var float() powerup_speed_SpeedMod_NextLink;
float() powerup_speed_SpeedMod {
	if (time < self.speed_finished)
		return powerup_speed_SpeedMod_NextLink() * 1.5;

	return powerup_speed_SpeedMod_NextLink();
}

float powerup_speed_init_done;
void() powerup_speed_init {
	if (powerup_speed_init_done)
		return;

	powerup_speed_init_done = 1;
	powerup_init();
	powerup_speed_SpeedMod_NextLink = GameHookChain_SpeedMod;
	GameHookChain_SpeedMod = powerup_speed_SpeedMod;
	powerup_speed_player_effects_next_link = gamehook_chain_player_effects;
	gamehook_chain_player_effects = powerup_speed_player_effects;
	powerup_speed_WeaponRateFactor_NextLink = GameHookChain_WeaponRateFactor;
	GameHookChain_WeaponRateFactor = powerup_speed_WeaponRateFactor;
	addstat(STAT_SPEED_FINISHED, AS_FLOAT, speed_finished);
}

var void() powerup_invisibility_player_effects_next_link;
void() powerup_invisibility_player_effects {
	if (self.items & IT_INVISIBILITY) {
		play_countdown(self.invisibility_finished, "misc/poweroff.wav");
		if (time > self.invisibility_finished) {
			self.items &~= IT_INVISIBILITY;
			sprint(self, "^3Invisibility has worn off\n");
		}
	} else if (self.invisibility_finished) {
		if (time < self.invisibility_finished) {
			self.items |= IT_INVISIBILITY;
			sprint(self, "^3You are invisible\n");
		} else if (time > self.invisibility_finished + 1) //1 second for fade effect on client
			self.invisibility_finished = 0;
	}
	powerup_invisibility_player_effects_next_link();
}

var float(entity plr, entity viewer, float dalpha) powerup_invisibility_PlayerAlphaMod_NextLink;
float(entity plr, entity viewer, float dalpha) powerup_invisibility_PlayerAlphaMod {
	if (time < plr.invisibility_finished)
		dalpha *= 0.05;

	return powerup_invisibility_PlayerAlphaMod_NextLink(plr, viewer, dalpha);
}

float powerup_invisibility_init_done;
void() powerup_invisibility_init {
	if (powerup_invisibility_init_done)
		return;

	powerup_invisibility_init_done = 1;
	powerup_init();
	powerup_invisibility_PlayerAlphaMod_NextLink = GameHookChain_PlayerAlphaMod;
	GameHookChain_PlayerAlphaMod = powerup_invisibility_PlayerAlphaMod;
	powerup_invisibility_player_effects_next_link = gamehook_chain_player_effects;
	gamehook_chain_player_effects = powerup_invisibility_player_effects;
	addstat(STAT_INVISIBILITY_FINISHED, AS_FLOAT, invisibility_finished);
}
