float rune_numspawns;

float g_rune_vitality_damage_factor;
float g_rune_vitality_max_health;
float g_rune_speed_jumpheight;
float g_rune_speed_moverate;
float g_rune_speed_atkrate;
float g_rune_defense_damage_factor;
float g_rune_ignite_damage_factor;
float g_rune_vampire_damage_factor;
float g_rune_vampire_max_health;
float g_rune_stun_moverate;
float g_rune_stun_time;
float g_runes_carried_runes_max;
float g_runes_drop_runes_max;
float g_runes_respawntime;
float g_runes_count;
//float g_runematch_rune_glow_color;
//float g_runematch_rune_glow_size;
float g_runes_shuffletime;
float g_runes;
string sv_model_rune_ignite;
string sv_model_rune_speed;
string sv_model_rune_vitality;
string sv_model_rune_hacker;
string sv_model_rune_defense;
string sv_model_rune_vampire;
string sv_model_rune_stun;
string sv_model_rune_decor;

.float runes;
.entity rune_stun;

/*QUAKED spawnfunc_rune_spawn_point (1 0 0) (-16 -16 -24) (16 16 24)
spawn point for runes in runematch
*/

void(void) spawnfunc_rune_spawn_point {
	if(!g_runes || !cvar("g_runes_fixedspawns")) {
		remove(self);
		return;
	}
	setsize(self, '-12 -12 -35', '12 12 0');
	entity_droptofloor();
	++rune_numspawns;
}

// only used if using rune spawns at all
entity(void) rune_find_spawnpoint {
	entity e;
	if(rune_numspawns < g_runes_count)
		return world;

	random_selection_init();
	for(e = world; (e = find(e, classname, "rune_spawn_point")); )
		if(e.owner == world)
			random_selection_add(e, 0, string_null, e.cnt, 0);

	return random_selection_chosen_ent;
}

float(entity e) rune_spawn_somewhere {
	entity spot;
	spot = rune_find_spawnpoint();
	if(spot) {
		spot.owner = e;
		setorigin(e, spot.origin);
		e.owner = spot;
		spot.owner = e;
		return TRUE;
	} else {
		if(entity_move_to_random_location(e, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256)) {
			// great
			makevectors(self.angles),
			self.velocity = v_forward * 250;
			self.angles = '0 0 0';
			return TRUE;
		} else {
			// sorry, can't spawn, better luck next frame
			return FALSE;
		}
	}
}

void(entity e) rune_unmark_spot {
	if(e.owner.classname == "rune_spawn_point") {
		e.owner.owner = world;
		e.owner = world;
	}
}

float(float r) rune_count {
	float i, n = 0;
	for (i = RUNE_FIRST; i <= RUNE_LAST; i *= 2)
		if (r & i)
			n++;

	return n;
}

vector(float r) rune_colormod {
	vector _color;
	if(r == RUNE_IGNITE)
		_color = '255 0 0';
	else if(r == RUNE_DEFENSE)
		_color = '0 0 255';//'0 102 255';//
	else if(r == RUNE_REGEN)
		_color = '0 204 0';//'0 255 0';
	else if(r == RUNE_SPEED)
		_color = 0.35*'185 185 0';//255 230 0';//'255 255 0';
	else if(r == RUNE_VAMPIRE)
		_color = '64 0 128';//'108 0 217';//'128 0 255';//'179 0 204';//
	else if(r == RUNE_HACKER)
		_color = '64 128 128';//'108 0 217';//'128 0 255';//'179 0 204';//
	else if(r == RUNE_STUN)
		_color = '128 128 192';//'108 0 217';//'128 0 255';//'179 0 204';//

	return _color * (1 / 255);
}

void(void) rune_respawn;

void(void) rune_carried_think {
	float rcount, rnum;
	vector ang;
	entity rune;
	if(self.owner.classname != "player" || time < map_starttime) {
		rune_respawn();
		return;
	}
	self.nextthink = time + 0.1;
	// count runes my owner holds
	rcount = 0;
	rune = find(world, classname, "rune");
	while(rune) {
		if(rune.owner == self.owner)
			rcount = rcount + 1;
		if(rune == self)
			rnum = rcount;
		rune = find(rune, classname, "rune");
	}
	ang_y = rnum*(360 / rcount) + math_mod(time, 360)*45;//180;
	makevectors(ang);
	setorigin(self, v_forward*32);
}

void(void) rune_touch {
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT) {
		self.think = rune_respawn;
		self.nextthink = time;
		return;
	}
	if(other.classname != "player" || PLAYER_DEAD(other))
		return;

	if(self.wait > time)
		return; // "notouch" time isn't finished

	if (rune_count(other.runes) >= g_runes_carried_runes_max)
		return;

	if (self.runes & other.runes)
		return;

	// detach from the spawn point you're on
	rune_unmark_spot(self);
	self.owner = other;
	setattachment(self, other, "");
	self.enemy.alpha = -1;
	other.runes = other.runes | self.runes;
	//self.think = stdproc_nothing;
	//self.nextthink = 0;
	self.think = rune_carried_think;
	self.nextthink = time;
	self.touch = stdproc_nothing;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	setorigin(self, self.origin);
	bprint("^3", other.netname, "^7 has picked up ", rune_name(self.runes & (RUNE_LAST*2-1)), "^7");
	bprint("\n");
	sound (other, CHAN_TRIGGER, "misc/mediumhealth.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	entity e;
	if (self.runes & RUNE_HACKER)
		FOR_EACH_PLAYER(e)
			e.entcs.SendFlags |= 16;
}

void(void) rune_respawn {
	rune_unmark_spot(self);
	if(rune_spawn_somewhere(self)) {
		self.solid = SOLID_TRIGGER;
		self.touch = rune_touch;
		self.think = rune_respawn;
		self.movetype = MOVETYPE_TOSS;
		self.nextthink = time + g_runes_respawntime + random() * g_runes_shuffletime;
	} else {
		// try again later
		self.think = rune_respawn;
		self.nextthink = time;
	}
}

void(entity pl, entity e) rune_drop {
	//entity pl;
	//pl = e.owner;
	// detach from player
	setattachment(e, world, "");
	e.owner = world;
	// don't instantly touch player again
	e.wait = time + 1; // "notouch" time
	e.movetype = MOVETYPE_TOSS;
	e.solid = SOLID_TRIGGER;
	// reposition itself if not picked up soon
	e.think = rune_respawn;
	e.nextthink = time + g_runes_respawntime + g_runes_shuffletime * random();
	e.touch = rune_touch;
	pl.runes = pl.runes - (pl.runes & e.runes);
	// toss from player
	setorigin(e, pl.origin + '0 0 10');
	e.velocity = '0 0 200' + '0 100 0'*random_2() + '100 0 0'*random_2();
	e.enemy.alpha = 0;
	bprint("^3", pl.netname, "^7 has lost ", rune_name(e.runes & (RUNE_LAST*2-1)), "^7");
	bprint("\n");
}

// player died, drop runes
void(entity pl) rune_drop_all {
	entity rune;
	float rcount, r, numtodrop;
	rune = world;
	rcount = r = 0;
	rune = find(rune, classname, "rune");
	while(rune) {
		if(rune.owner == pl)
			rcount = rcount + 1;

		rune = find(rune, classname, "rune");
	}
	numtodrop = g_runes_drop_runes_max;
	rune = world;
	do {
		rune = find(rune, classname, "rune");
		if(!rune)
			break;

		if(rune.owner != pl)
			continue;

		rune_drop(pl, rune);
		if(numtodrop <= 0) {
			rune.think = rune_respawn;
			rune.nextthink = time;
		}
		numtodrop = numtodrop - 1;
		rcount = rcount - 1;
	} while(rune);
}

void(void) rune_reset {
	if(self.owner)
		if(self.owner.classname != "rune_spawn_point")
			rune_drop_all(self.owner);

	rune_respawn();
}

void(void) rune_spawn_all {
	float rn, runes_enabled, i;
	entity e;
	if(self)
		remove(self);

	runes_enabled  = 0;
	if (cvar("g_runes_ignite")) {
		runes_enabled |= RUNE_IGNITE;
	}
	if (cvar("g_runes_vitality")) {
		runes_enabled |= RUNE_REGEN;
	}
	if (cvar("g_runes_vampire")) {
		runes_enabled |= RUNE_VAMPIRE;
	}
	if (cvar("g_runes_defense")) {
		runes_enabled |= RUNE_DEFENSE;
	}
	if (cvar("g_runes_speed")) {
		runes_enabled |= RUNE_SPEED;
	}
	if (cvar("g_runes_hacker")) {
		runes_enabled |= RUNE_HACKER;
	}
	if (cvar("g_runes_stun")) {
		runes_enabled |= RUNE_STUN;
	}
	random_queue_start();
	for(rn = RUNE_FIRST; rn <= RUNE_LAST; rn *= 2) {
		if not(runes_enabled & rn)
			continue;

		random_queue_push(world, rn, "");
	}
	for (i = 0; i < g_runes_count; i++) {
		if not(random_queue_next_circle())
			break;

		rn = random_queue_float();
		e = spawn();
		e.runes = rn;
		e.classname = "rune";
		e.touch = rune_touch;
		e.think = rune_respawn;
		e.nextthink = time;
		e.movetype = MOVETYPE_TOSS;
		e.solid = SOLID_TRIGGER;
		e.flags = FL_ITEM;
		e.reset = rune_reset;
		e.modelflags |= MF_ROTATE;
		if (rn == RUNE_SPEED && sv_model_rune_speed != "")
			setmodel(e, sv_model_rune_speed);
		else if (rn == RUNE_IGNITE && sv_model_rune_ignite != "")
			setmodel(e, sv_model_rune_ignite);
		else if (rn == RUNE_VAMPIRE && sv_model_rune_vampire != "")
			setmodel(e, sv_model_rune_vampire);
		else if (rn == RUNE_DEFENSE && sv_model_rune_defense != "")
			setmodel(e, sv_model_rune_defense);
		else if (rn == RUNE_REGEN && sv_model_rune_vitality != "")
			setmodel(e, sv_model_rune_vitality);
		else if (rn == RUNE_HACKER && sv_model_rune_hacker != "")
			setmodel(e, sv_model_rune_hacker);
		else if (rn == RUNE_STUN && sv_model_rune_stun != "")
			setmodel(e, sv_model_rune_stun);
		else
			setmodel(e, "models/runematch/rune.mdl"); // precision set below

		e.enemy = spawn();
		if (sv_model_rune_decor != "")
			setmodel(e.enemy, sv_model_rune_decor);
		else
			setmodel(e.enemy, "models/runematch/curse.mdl");

		setattachment(e.enemy, e, "");
		setsize(e, '-12 -12 -35', '12 12 0');
		e.enemy.colormod = e.colormod = rune_colormod(rn);
		e.effects = e.enemy.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;//EF_ADDITIVE;// | EF_FULLBRIGHT;
		e.glow_size = 50;
		//e.glow_color = 0;
	}
	random_queue_end();
}

var float() rune_JumpVelocityMod_NextLink;
float() rune_JumpVelocityMod {
	float jump_mod = 1;
	if(self.runes & RUNE_SPEED)
		jump_mod = g_rune_speed_jumpheight;

	return jump_mod * rune_JumpVelocityMod_NextLink();
}

var float() rune_WeaponRateFactor_NextLink;
float() rune_WeaponRateFactor {
	float f = rune_WeaponRateFactor_NextLink();
	if(self.runes & RUNE_SPEED)
		return f * g_rune_speed_atkrate;

	return f;
}

var float() rune_SpeedMod_NextLink;
float() rune_SpeedMod {
	float maxspd_mod = rune_SpeedMod_NextLink();
	if(self.runes & RUNE_SPEED)
		maxspd_mod = maxspd_mod * g_rune_speed_moverate;

	if (self.rune_stun)
		maxspd_mod = maxspd_mod * (1 - (1 - g_rune_stun_moverate) * (max(0, self.rune_stun.alpha) / g_rune_stun_time));

	return maxspd_mod;
}

void(void) rune_healer_think {
	if (self.owner.classname == "player")
	if (PLAYER_REALLY_ALIVE(self.owner))
		item_give_to(self, self.owner);

	remove(self);
}

void(float health_amount, float _delay, entity _owner) rune_healer_spawn {
	if (health_amount < 1 && health_amount > -1)
		return;

	entity e = spawn();
	e.classname = "healer";
	e.reset = stdproc_remove;
	e.health = health_amount;
	if (health_amount > 0)
		e.max_health = (g_rune_vampire_max_health ? g_rune_vampire_max_health : 999);
	else
		e.max_health = 999;

	e.think = rune_healer_think;
	e.spawnshieldtime = TRUE;
	e.owner = _owner;
	if (health_amount > 0)
		e.noise = "misc/minihealth.wav";
	else
		e.noise = "misc/bodyimpact1.wav";

	e.nextthink = time + _delay;
}

void rune_defense_attack_lightning(vector start, vector end, vector to) {
	effect_lightningarc(start, end);
}

entity rune_defense_attack_chain;

void(void) rune_defense_attack_think {
	traceline(self.owner.origin, self.enemy.origin, MOVE_NOMONSTERS, world);
	vector v;
	entity e;
	if (trace_fraction < 1) {
		v = WarpZone_FindNearestOrigin(self.owner.origin, self.enemy.origin, 1);
		if (trace_fraction < 1)
			goto finish;
	} else
		v = self.enemy.origin;

	damage(self.enemy, self.owner, self.owner, self.dmg, DEATH_HURTTRIGGER, self.enemy.origin, '0 0 0');
	WarpZone_DrawEffectTriangle(self.owner.origin, self.owner.origin, v, rune_defense_attack_lightning);
:finish
	if (self == rune_defense_attack_chain)
		rune_defense_attack_chain = self.chain;
	else
		for (e = rune_defense_attack_chain; e; e = e.chain)
			if (e.chain == self) {
				e.chain = self.chain;
				break;
			}
	remove(self);
}

void(entity from, entity to, float d) defense_attack_spawn {
	entity e;
	for (e = rune_defense_attack_chain; e; e = e.chain)
		if (e.owner == from)
		if (e.enemy == to)
			break;

	if (e) {
		e.dmg = e.dmg + d;
		return;
	}
	e = spawn();
	e.classname = "defense_attack";
	e.owner = from;
	e.enemy = to;
	e.dmg = d;
	e.think = rune_defense_attack_think;
	e.nextthink = time;
	e.chain = rune_defense_attack_chain;
	rune_defense_attack_chain = e;
}

void(void) rune_stun_think {
	if (self != self.owner.rune_stun) {
		remove(self);
		remove(self.enemy);
		return;
	}
	self.alpha = self.alpha - frametime;
	self.enemy.alpha = self.alpha;
	if (self.alpha < 0) {
		remove(self);
		remove(self.enemy);
		self.owner.rune_stun = world;
		return;
	}
	self.nextthink = time;
}

float rune_targ_prev_deadflag;
float rune_targ_prev_runes;
var void(entity targ, entity attacker, float deathtype) rune_DamageForceModsSet_NextLink;
void(entity targ, entity attacker, float deathtype) rune_DamageForceModsSet {
	rune_targ_prev_runes = targ.runes;
	rune_targ_prev_deadflag = targ.deadflag;
	rune_DamageForceModsSet_NextLink(attacker, targ, deathtype);
}

var void(entity targ, entity attacker, float _damage, vector force) rune_DamageForceDone_NextLink;
void(entity targ, entity attacker, float _damage, vector force) rune_DamageForceDone {
	float d;
	entity e;
	if(targ.classname == "player") {
		if(attacker.classname == "player") {
			if(attacker != targ && PLAYER_REALLY_ALIVE(attacker) && (!teamplay || attacker.team != targ.team)) {
				if (attacker.runes & RUNE_STUN) {
					if not(targ.rune_stun) {
						e = spawn();
						e.nextthink = time;
						e.think = rune_stun_think;
						e.owner = targ;
						e.scale = 0.25;
						e.enemy = spawn();
						e.enemy.scale = 0.25;
						e.enemy.customizeentityforclient = weapon_model_customize;
						e.enemy.owner = targ;
						targ.rune_stun = e;
						setattachment(targ.rune_stun, targ, "");
						setmodel(e, "models/teamfx/electricityarcs_player.md3");
						setmodel(e.enemy, "models/teamfx/electricityarcs_player.md3");
						e.enemy.viewmodelforclient = targ;
					}
					targ.rune_stun.alpha = g_rune_stun_time;
				}
				if (attacker.runes & RUNE_IGNITE)
				if ((d = _damage * g_rune_ignite_damage_factor) >= 1)
					fire_add_damage(targ, world, d, 5, DEATH_FIRE);

				if (rune_targ_prev_deadflag == DEAD_NO) {
					if (attacker.runes & RUNE_VAMPIRE)
					if ((d = _damage * g_rune_vampire_damage_factor) >= 1)
					if (attacker.health < g_rune_vampire_max_health)
						rune_healer_spawn(d, 0.5, attacker);

					if (rune_targ_prev_runes & RUNE_DEFENSE)
					if ((d = _damage * g_rune_defense_damage_factor) >= 1)
						defense_attack_spawn(targ, attacker, d);
				}
			}
		}
		if (targ.runes & RUNE_REGEN)
		if ((d = _damage * g_rune_vitality_damage_factor) >= 1)
		if (targ.health < g_rune_vitality_max_health)
			rune_healer_spawn(d, 1, targ);
	}
	rune_DamageForceDone_NextLink(targ, attacker, _damage, force);
}

var void(float killed) rune_PlayerClear_NextLink;
void(float killed) rune_PlayerClear {
	rune_drop_all(self);
	self.runes = 0;
	if (self.rune_stun)
		self.rune_stun.alpha = -1;

	rune_PlayerClear_NextLink(killed);
}

var void(entity e) rune_SpectateCopy_NextLink;
void(entity e) rune_SpectateCopy {
	self.runes = e.runes;
	rune_SpectateCopy_NextLink(e);
}

var float(entity plr, entity targ) rune_PlayerVisibleThroughWallFor_NextLink;
float(entity plr, entity targ) rune_PlayerVisibleThroughWallFor {
	if (targ.runes & RUNE_HACKER)
	if (PLAYER_ALIVE(plr))
		return TRUE;

	return rune_PlayerVisibleThroughWallFor_NextLink(plr, targ);
}

var float(entity plr, entity targ) rune_PlayerCanSeeHealthFor_NextLink;
float(entity plr, entity targ) rune_PlayerCanSeeHealthFor {
	if (plr.runes & RUNE_HACKER)
		return TRUE;

	return rune_PlayerCanSeeHealthFor_NextLink(plr, targ);
}

void(void) rune_init {
	CACHE_CVAR(g_runes);
	if not(g_runes)
		return;

	precache_model ("models/runematch/curse.mdl");
	precache_model ("models/runematch/rune.mdl");
	precache_model("models/teamfx/electricityarcs_player.md3");
	precache_sound("misc/minihealth.wav");
	precache_sound("misc/mediumhealth.wav");
	precache_sound("misc/bodyimpact1.wav");
	CACHE_CVAR(g_rune_vitality_damage_factor);
	CACHE_CVAR(g_rune_vitality_max_health);
	CACHE_CVAR(g_rune_speed_jumpheight);
	CACHE_CVAR(g_rune_speed_moverate);
	CACHE_CVAR(g_rune_vampire_damage_factor);
	CACHE_CVAR(g_rune_vampire_max_health);
	CACHE_CVAR(g_rune_speed_atkrate);
	CACHE_CVAR(g_rune_defense_damage_factor);
	CACHE_CVAR(g_rune_ignite_damage_factor);
	CACHE_CVAR(g_rune_stun_moverate);
	CACHE_CVAR(g_rune_stun_time);
	CACHE_CVAR(g_runes_carried_runes_max);
	CACHE_CVAR(g_runes_drop_runes_max);
	CACHE_CVAR(g_runes_respawntime);
	CACHE_CVAR(g_runes_count);
	//CACHE_CVAR(g_runematch_rune_glow_color);
	//CACHE_CVAR(g_runematch_rune_glow_size);
	CACHE_CVAR(g_runes_shuffletime);
	CACHE_CVAR_STR(sv_model_rune_ignite);
	if (sv_model_rune_ignite != "")
		precache_model(sv_model_rune_ignite);

	CACHE_CVAR_STR(sv_model_rune_speed);
	if (sv_model_rune_speed != "")
		precache_model(sv_model_rune_speed);

	CACHE_CVAR_STR(sv_model_rune_vitality);
	if (sv_model_rune_vitality != "")
		precache_model(sv_model_rune_vitality);

	CACHE_CVAR_STR(sv_model_rune_hacker);
	if (sv_model_rune_hacker != "")
		precache_model(sv_model_rune_hacker);

	CACHE_CVAR_STR(sv_model_rune_defense);
	if (sv_model_rune_defense != "")
		precache_model(sv_model_rune_defense);

	CACHE_CVAR_STR(sv_model_rune_vampire);
	if (sv_model_rune_vampire != "")
		precache_model(sv_model_rune_vampire);

	CACHE_CVAR_STR(sv_model_rune_stun);
	if (sv_model_rune_stun != "")
		precache_model(sv_model_rune_stun);

	CACHE_CVAR_STR(sv_model_rune_decor);
	if (sv_model_rune_vampire != "")
		precache_model(sv_model_rune_decor);

	rune_JumpVelocityMod_NextLink = GameHookChain_JumpVelocityMod;
	GameHookChain_JumpVelocityMod = rune_JumpVelocityMod;
	rune_SpeedMod_NextLink = GameHookChain_SpeedMod;
	GameHookChain_SpeedMod = rune_SpeedMod;
	rune_WeaponRateFactor_NextLink = GameHookChain_WeaponRateFactor;
	GameHookChain_WeaponRateFactor = rune_WeaponRateFactor;
	rune_DamageForceDone_NextLink = GameHookChain_DamageForceDone;
	GameHookChain_DamageForceDone = rune_DamageForceDone;
	rune_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = rune_PlayerClear;
	rune_SpectateCopy_NextLink = GameHookChain_SpectateCopy;
	GameHookChain_SpectateCopy = rune_SpectateCopy;
	rune_PlayerVisibleThroughWallFor_NextLink = GameHookChain_PlayerVisibleThroughWallFor;
	GameHookChain_PlayerVisibleThroughWallFor = rune_PlayerVisibleThroughWallFor;
	rune_PlayerCanSeeHealthFor_NextLink = GameHookChain_PlayerCanSeeHealthFor;
	GameHookChain_PlayerCanSeeHealthFor = rune_PlayerCanSeeHealthFor;
	rune_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = rune_DamageForceModsSet;
	entity e;
	e = spawn();
	e.think = rune_spawn_all;
	e.nextthink = time + 0.1;
	addstat(STAT_RUNES, AS_INT, runes);
}
