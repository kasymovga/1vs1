float g_runematch;
float rune_numspawns;

float g_balance_curse_altruism_damage_factor;
float g_balance_curse_burning_damage_factor;
float g_balance_curse_vulner_damage_factor;
float g_balance_curse_venom_damage_factor;
float g_balance_rune_regen_damage_factor;
float g_balance_rune_regen_max_health;
float g_balance_rune_speed_combo_jumpheight;
float g_balance_rune_speed_jumpheight;
float g_balance_curse_slow_jumpheight;
float g_balance_curse_slow_moverate;
float g_balance_rune_speed_combo_moverate;
float g_balance_rune_speed_moverate;
float g_balance_rune_speed_combo_atkrate;
float g_balance_rune_speed_atkrate;
float g_balance_curse_slow_atkrate;
float g_balance_rune_defense_damage_factor;
float g_balance_rune_ignite_damage_factor;
float g_balance_rune_vampire_damage_factor;
float g_balance_rune_vampire_max_health;
float g_runematch_allow_same;
float g_runematch_carried_runes_max;
float g_runematch_curses;
float g_runematch_drop_runes_max;
float g_runematch_frags_killedby_runeholder;
float g_runematch_frags_killed_runeholder;
float g_runematch_frags_norune;
float g_runematch_pointamt;
float g_runematch_pointrate;
float g_runematch_respawntime;
float g_runematch_rune_alpha;
float g_runematch_rune_color_strength;
float g_runematch_rune_effects;
//float g_runematch_rune_glow_color;
//float g_runematch_rune_glow_size;
float g_runematch_shuffletime;
float g_runes;

.float runes;

/* rune ideas:

	Doom/Death
	Rune: When you damage enemies, you have a slight chance of instant-killing them (porportional to damage dealt / their health)
	Curse: When you are damaged, you have a chance of being instant-killed

	Vengence/Slothful
	Rune: The lower your health below 100, the more damage you deal (does not decrease your damage if you're above 100)
	Curse: The higher your health (up to 100), the less damage you deal (at 100 hp deal 1/5th damage)

*/

/*QUAKED spawnfunc_runematch_spawn_point (1 0 0) (-16 -16 -24) (16 16 24)
spawn point for runes in runematch
*/

var void() RuneMatch_ServerFrame_NextLink;
void RuneMatch_ServerFrame();

float RunematchHandleFrags(entity attacker, entity targ, float f);

void spawnfunc_runematch_spawn_point()
{
	if(!(g_runematch || g_runes) || !cvar("g_runematch_fixedspawns"))
	{
		remove(self);
		return;
	}

	setsize(self, '0 0 -35', '0 0 0');
	droptofloor();
	++rune_numspawns;
}

// only used if using rune spawns at all
entity rune_find_spawnpoint()
{
	entity e;

	if(rune_numspawns < RUNE_COUNT)
		return world;

	random_selection_init();

	for(e = world; (e = find(e, classname, "runematch_spawn_point")); )
		if(e.owner == world)
			random_selection_add(e, 0, string_null, e.cnt, 0);

	return random_selection_chosen_ent;
}

float rune_spawn_somewhere(entity e)
{
	entity spot;
	spot = rune_find_spawnpoint();
	if(spot)
	{
		spot.owner = e;
		setorigin(e, spot.origin);

		e.owner = spot;
		spot.owner = e;

		return TRUE;
	}
	else
	{
		if(MoveToRandomMapLocation(e, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
		{
			// great
			makevectors(self.angles),
			self.velocity = v_forward * 250;
			self.angles = '0 0 0';
			return TRUE;
		}
		else
		{
			// sorry, can't spawn, better luck next frame
			return FALSE;
		}
	}
}

void rune_unmark_spot(entity e)
{
	if(e.owner.classname == "runematch_spawn_point")
	{
		e.owner.owner = world;
		e.owner = world;
	}
}

float RunesCount(float r)
{
	float i, n = 0;
	for (i = RUNE_FIRST; i <= RUNE_LAST; i *= 2)
		if (r & i)
			n++;

	return n;
}

vector RuneColormod(float r)
{
	vector _color;
	if(r == RUNE_IGNITE)
		_color = '255 0 0';
	if(r == RUNE_DEFENSE)
		_color = '0 0 255';//'0 102 255';//
	if(r == RUNE_REGEN)
		_color = '0 204 0';//'0 255 0';
	if(r == RUNE_SPEED)
		_color = 0.35*'185 185 0';//255 230 0';//'255 255 0';
	if(r == RUNE_VAMPIRE)
		_color = '64 0 128';//'108 0 217';//'128 0 255';//'179 0 204';//
	if(r == RUNE_HACKER)
		_color = '64 128 128';//'108 0 217';//'128 0 255';//'179 0 204';//

	if(r == CURSE_BURNING)
		_color = '255 0 0';
	if(r == CURSE_VULNER)
		_color = '0 0 255';//'0 102 255';//
	if(r == CURSE_VENOM)
		_color = '0 204 0';//'0 255 0';
	if(r == CURSE_SLOW)
		_color = 0.5*'185 185 0';//'255 255 0';
	if(r == CURSE_ALTRUISM)
		_color = '179 0 204';//'128 0 255';
	if(r == CURSE_HACKED)
		_color = '64 128 128';

	return _color * (1 / 255) * g_runematch_rune_color_strength;
}

void rune_respawn();

void RuneCarriedThink()
{
	float rcount, rnum;
	vector ang;
	entity rune;

	if(self.owner.classname != "player" || time < game_starttime)
	{
		rune_respawn();
		return;
	}

	self.nextthink = time + 0.1;

	// count runes my owner holds
	rcount = 0;
	rune = find(world, classname, "rune");
	while(rune)
	{
		if(rune.owner == self.owner)
			rcount = rcount + 1;
		if(rune == self)
			rnum = rcount;
		rune = find(rune, classname, "rune");
	}
	ang_y = rnum*(360 / rcount) + mod(time, 360)*45;//180;

	makevectors(ang);
	setorigin(self, v_forward*32);
}

void rune_touch()
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		self.think = rune_respawn;
		self.nextthink = time;
		return;
	}

	if(other.classname != "player" || PLAYER_DEAD(other))
		return;

	if(self.wait > time)
		return; // "notouch" time isn't finished

	if (RunesCount(other.runes) >= g_runematch_carried_runes_max)
		return;

	// detach from the spawn point you're on
	rune_unmark_spot(self);

	self.owner = other;
	self.enemy.owner = other;
	setattachment(self, other, "");

	other.runes = other.runes | self.runes | self.enemy.runes;

	//self.think = SUB_Null;
	//self.nextthink = 0;
	self.think = RuneCarriedThink;
	self.nextthink = time;
	self.touch = SUB_Null;

	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	setorigin(self, self.origin);

	//sprint(other, strcat("^3You have picked up ",
	//	RuneName(self.runes & (RUNE_LAST*2-1)), " and "));
	//sprint(other, strcat(RuneName(self.enemy.runes & (CURSE_BURNING | CURSE_VULNER | CURSE_VENOM | CURSE_SLOW | CURSE_ALTRUISM)), "\n"));

	bprint("^3", other.netname, "^7 has picked up ",
		RuneName(self.runes & (RUNE_LAST*2-1)), "^7");
	float curses = self.enemy.runes & (CURSE_BURNING | CURSE_VULNER | CURSE_VENOM | CURSE_SLOW | CURSE_ALTRUISM);
	if (curses)
		bprint(" and ", RuneName(curses));
	bprint("\n");
	sound (other, CHAN_TRIGGER, "misc/mediumhealth.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	entity e;
	if (self.runes & RUNE_HACKER)
		FOR_EACH_PLAYER(e)
			e.entcs.SendFlags |= 16;

	if (self.runes & CURSE_HACKED)
		self.entcs.SendFlags |= 16;
}

void rune_respawn()
{
	rune_unmark_spot(self);
	if(rune_spawn_somewhere(self))
	{
		self.solid = SOLID_TRIGGER;
		self.touch = rune_touch;
		self.think = rune_respawn;
		self.movetype = MOVETYPE_TOSS;
		self.nextthink = time + g_runematch_shuffletime;//30 + random()*5; // fixme: cvar
	}
	else
	{
		// try again later
		self.think = rune_respawn;
		self.nextthink = time;
	}
}

entity FindRune(entity own, string clname, float r)
{
	entity rune;
	float _count, c;

	c = _count = 0;
	rune = world;

	do
	{
		rune = find(rune, classname, clname);
		if(!rune)
			rune = find(rune, classname, clname);
		if(!rune)
			break;
		if(rune.owner == own)
		{
			_count = _count + 1;
			if(_count >= r)
				return rune;
			if(r <= 1)
				return rune;
		}
		c = c + 1;
	}while(c < 30);
	return world;
}


void DropRune(entity pl, entity e)
{
	//entity pl;

	//pl = e.owner;
	// detach from player
	setattachment(e, world, "");
	e.owner = world;
	e.enemy.owner = world;
	// don't instantly touch player again
	e.wait = time + 1; // "notouch" time
	e.movetype = MOVETYPE_TOSS;
	e.solid = SOLID_TRIGGER;
	// reposition itself if not picked up soon
	e.think = rune_respawn;
	e.nextthink = time + g_runematch_respawntime;//15 + random()*5; // fixme: cvar
	e.touch = rune_touch;

	pl.runes = pl.runes - (pl.runes & (e.runes | e.enemy.runes));

	// toss from player
	setorigin(e, pl.origin + '0 0 10');
	e.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();


	bprint("^3", pl.netname, "^7 has lost ",
		RuneName(e.runes & (RUNE_LAST*2-1)), "^7");
	float curses = e.enemy.runes & (CURSE_BURNING | CURSE_VULNER | CURSE_VENOM | CURSE_SLOW | CURSE_ALTRUISM);
	if (curses)
		bprint(" and ", RuneName(curses));
	bprint("\n");
}

float RuneMatchesCurse(float r, float c)
{
	float cr;
	if(r & RUNE_IGNITE)
		cr = CURSE_BURNING;
	else if(r & RUNE_DEFENSE)
		cr = CURSE_VULNER;
	else if(r & RUNE_REGEN)
		cr = CURSE_VENOM;
	else if(r & RUNE_SPEED)
		cr = CURSE_SLOW;
	else if(r & RUNE_VAMPIRE)
		cr = CURSE_ALTRUISM;
	else return FALSE; // fixme: error?

	if(c & cr)
		return TRUE;
	return FALSE;
}

// player died, drop runes
// each rune should pair up with a random curse and then be tossed from the player
void DropAllRunes(entity pl)
{
	entity rune, curse;
	float rcount, ccount, r, c, rand, numtodrop, tries;

	entity curse1, rune1, curse2, rune2;

	rune = curse = world;
	rcount = ccount = r = c = 0;
	rune = find(rune, classname, "rune");
	while(rune)
	{
		if(rune.owner == pl)
			rcount = rcount + 1;
		rune = find(rune, classname, "rune");
	}
	curse = find(curse, classname, "curse");
	while(curse)
	{
		if(curse.owner == pl)
			ccount = ccount + 1;
		curse = find(curse, classname, "curse");
	}

	numtodrop = g_runematch_drop_runes_max;

	rune = curse = world;
	do
	{
		rune = find(rune, classname, "rune");
		if(!rune)
			break;
		if(rune.owner != pl)
			continue;


		// find a random curse
		tries = 15;
		if(ccount > 1 && !g_runematch_allow_same)
		{
			// avoid pairing runes and curses that match each other
			do{
				rand = floor(random()*ccount) + 1;
				curse = FindRune(pl, "curse", rand);
				tries = tries - 1;
			}while(RuneMatchesCurse(rune.runes, curse.runes) && tries > 0);
			if(tries <= 0)
			{
				bprint("warning: couldn't prevent same rune\n");
			}
		}
		else
		{
				rand = floor(random()*ccount) + 1;
				curse = FindRune(pl, "curse", rand);
		}

		if(!curse)
			error("Couldn't fine curse to bind rune to\n");

		// pair rune and curse

		rune1 = rune;
		curse1 = curse;
		rune2 = curse1.enemy;
		curse2 = rune1.enemy;

		if(rune1 != rune2) // not already attached to each other
		{
			rune1.enemy = curse1;
			curse1.enemy = rune1;
			setattachment(curse1, rune1, "");
			rune2.enemy = curse2;
			curse2.enemy = rune2;
			setattachment(curse2, rune2, "");
			//DropRune(pl, rune2);
			//ccount = ccount - 1;
			//rcount = rcount - 1;
		}
		DropRune(pl, rune1);

		if(numtodrop <=0)
		{
			rune1.think = rune_respawn;
			rune1.nextthink = time;
		}

		numtodrop = numtodrop - 1;

		ccount = ccount - 1;
		rcount = rcount - 1;

	}while(rune);
}

void rune_reset()
{
	if(self.owner)
		if(self.owner.classname != "runematch_spawn_point")
			DropAllRunes(self.owner);
	rune_respawn();
}

void spawn_runes()
{
	float rn, cs, runes_used, curses_used, numrunes;
	entity e;

	if(self)
		remove(self);

	// fixme: instead of placing them all now, why not
	// simply create them all and let them call rune_respawn() as their think?

	runes_used  = 0;
	curses_used = 0;

	numrunes = RUNE_COUNT;
	if not(cvar("g_runematch_ignite")) {
		runes_used |= RUNE_IGNITE;
		curses_used |= CURSE_BURNING;
		numrunes--;
	}
	if not(cvar("g_runematch_vitality")) {
		runes_used |= RUNE_REGEN;
		curses_used |= CURSE_VENOM;
		numrunes--;
	}
	if not(cvar("g_runematch_vampire")) {
		runes_used |= RUNE_VAMPIRE;
		curses_used |= CURSE_ALTRUISM;
		numrunes--;
	}
	if not(cvar("g_runematch_defense")) {
		runes_used |= RUNE_DEFENSE;
		curses_used |= CURSE_VULNER;
		numrunes--;
	}
	if not(cvar("g_runematch_speed")) {
		runes_used |= RUNE_SPEED;
		curses_used |= CURSE_SLOW;
		numrunes--;
	}
	if not(cvar("g_runematch_hacker")) {
		runes_used |= RUNE_HACKER;
		curses_used |= CURSE_HACKED;
		numrunes--;
	}
	if not(numrunes) {
		runes_used = 0;
		curses_used = 0;
	}

	while(numrunes > 0)
	{
		random_selection_init();
		for(rn = RUNE_FIRST; rn <= RUNE_LAST; rn *= 2)
			if not(runes_used & rn)
				random_selection_add(world, rn, string_null, 1, 1);
		rn = random_selection_chosen_float;

		if (g_runematch_curses) {
			random_selection_init();
			for(cs = CURSE_FIRST; cs <= CURSE_LAST; cs *= 2)
				if not(curses_used & cs)
					if not(!g_runematch_allow_same && cs == RuneMatchesCurse(rn, cs))
						random_selection_add(world, cs, string_null, 1, 1);
			cs = random_selection_chosen_float;
		} else
			cs = CURSE_NONE;

		if(!rn || !cs)
			error("No rune/curse left");

		runes_used |= rn;
		curses_used |= cs;

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
		setmodel(e, "models/runematch/rune.mdl"); // precision set below
		setsize(e, '0 0 -35', '0 0 0');

		e.enemy = spawn();
		e.enemy.enemy = e;
		e.enemy.classname = "curse";
		e.enemy.runes = cs;
		//e.enemy.avelocity = '300 500 200';
		setmodel(e.enemy, "models/runematch/curse.mdl"); // precision set below
		setorigin(e, '0 0 0');
		setattachment(e.enemy, e, "");

		e.colormod = RuneColormod(rn);
		e.enemy.colormod = RuneColormod(cs);

		e.alpha = e.enemy.alpha = g_runematch_rune_alpha;//0.78;
		e.effects = e.enemy.effects = g_runematch_rune_effects | EF_LOWPRECISION;//EF_ADDITIVE;// | EF_FULLBRIGHT;

		//e.glow_size = e.enemy.glow_size = g_runematch_rune_glow_size;
		//e.glow_color = e.enemy.glow_color = g_runematch_rune_glow_color;

		//rn = RUNE_FIRST;
		//cs = CURSE_FIRST;

		numrunes = numrunes - 1;
	}
}

float runematch_FragLimitOverride() { return cvar("g_runematch_point_limit"); }

float runematch_LeadLimitOverride() { return cvar("g_runematch_point_leadlimit"); }

var float() runematch_JumpVelocityMod_NextLink;
float runematch_JumpVelocityMod() {
	float jump_mod = 1;
	if(self.runes & RUNE_SPEED)
	{
		if(self.runes & CURSE_SLOW)
			jump_mod = g_balance_rune_speed_combo_jumpheight;
		else
			jump_mod = g_balance_rune_speed_jumpheight;
	}
	else if(self.runes & CURSE_SLOW)
	{
		jump_mod = g_balance_curse_slow_jumpheight;
	}
	return jump_mod * runematch_JumpVelocityMod_NextLink();
}

var float() runematch_WeaponRateFactor_NextLink;
float runematch_WeaponRateFactor() {
	float f = runematch_WeaponRateFactor_NextLink();
	if(self.runes & RUNE_SPEED)
	{
		if(self.runes & CURSE_SLOW)
			return f * g_balance_rune_speed_combo_atkrate;
		else
			return f * g_balance_rune_speed_atkrate;
	}
	else if(self.runes & CURSE_SLOW)
	{
		return f * g_balance_curse_slow_atkrate;
	}
	return f;
}

var float() runematch_SpeedMod_NextLink;
float runematch_SpeedMod() {
	float maxspd_mod = runematch_SpeedMod_NextLink();
	if(self.runes & RUNE_SPEED)
	{
		if(self.runes & CURSE_SLOW)
			maxspd_mod = maxspd_mod * g_balance_rune_speed_combo_moverate;
		else
			maxspd_mod = maxspd_mod * g_balance_rune_speed_moverate;
	}
	else if(self.runes & CURSE_SLOW)
		maxspd_mod = maxspd_mod * g_balance_curse_slow_moverate;

	return maxspd_mod;
}

void healer_think() {
	if (self.owner.classname == "player")
	if (PLAYER_REALLY_ALIVE(self.owner))
		Item_GiveTo(self, self.owner);

	remove(self);
}

void healer_spawn(float health_amount, float _delay, entity _owner) {
	if (health_amount < 1 && health_amount > -1)
		return;

	entity e = spawn();
	e.classname = "healer";
	e.reset = SUB_Remove;
	e.health = health_amount;
	if (health_amount > 0)
		e.max_health = (g_balance_rune_vampire_max_health ? g_balance_rune_vampire_max_health : 999);
	else
		e.max_health = 999;

	e.think = healer_think;
	e.spawnshieldtime = TRUE;
	e.owner = _owner;
	if (health_amount > 0)
		e.noise = "misc/minihealth.wav";
	else
		e.noise = "misc/bodyimpact1.wav";

	e.nextthink = time + _delay;
}

void defense_attack_lightning(vector start, vector end, vector to) {
	te_csqc_lightningarc(start, end);
}

entity defense_attack_chain;

void defense_attack_think() {
	traceline(self.owner.origin, self.enemy.origin, MOVE_NOMONSTERS, world);
	vector v;
	entity e;
	if (trace_fraction < 1) {
		v = WarpZone_FindNearestOrigin(self.owner.origin, self.enemy.origin, 1);
		if (trace_fraction < 1)
			goto finish;
	} else
		v = self.enemy.origin;

	Damage(self.enemy, self.owner, self.owner, self.dmg, DEATH_HURTTRIGGER, self.enemy.origin, '0 0 0');
	WarpZone_DrawEffectTriangle(self.owner.origin, self.owner.origin, v, defense_attack_lightning);
:finish
	if (self == defense_attack_chain)
		defense_attack_chain = self.chain;
	else
		for (e = defense_attack_chain; e; e = e.chain)
			if (e.chain == self) {
				e.chain = self.chain;
				break;
			}
	remove(self);
}

void defense_attack_spawn(entity from, entity to, float d) {
	entity e;
	for (e = defense_attack_chain; e; e = e.chain)
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
	e.think = defense_attack_think;
	e.nextthink = time;
	e.chain = defense_attack_chain;
	defense_attack_chain = e;
}

float runematch_targ_prev_deadflag;
float runematch_targ_prev_runes;
var void(entity targ, entity attacker, float deathtype) runematch_DamageForceModsSet_NextLink;
void(entity targ, entity attacker, float deathtype) runematch_DamageForceModsSet {
	runematch_targ_prev_runes = targ.runes;
	runematch_targ_prev_deadflag = targ.deadflag;
	runematch_DamageForceModsSet_NextLink(attacker, targ, deathtype);
}

var void(entity targ, entity attacker, float damage, vector force) runematch_DamageForceDone_NextLink;
void runematch_DamageForceDone(entity targ, entity attacker, float damage, vector force) {
	float d;
	if(targ.classname == "player") {
		if(attacker.classname == "player") {
			if(attacker != targ && PLAYER_REALLY_ALIVE(attacker))
			{
				if (runematch_targ_prev_runes & CURSE_ALTRUISM)
				if ((d = damage * g_balance_curse_altruism_damage_factor) >= 1)
					healer_spawn(d, 0.5, attacker);

				if (attacker.runes & RUNE_IGNITE)
				if ((d = damage * g_balance_rune_ignite_damage_factor) >= 1)
					Fire_AddDamage(targ, world, d, 5, DEATH_FIRE);

				if (runematch_targ_prev_deadflag == DEAD_NO) {
					if (attacker.runes & RUNE_VAMPIRE)
					if ((d = damage * g_balance_rune_vampire_damage_factor) >= 1)
					if (attacker.health < g_balance_rune_vampire_max_health)
						healer_spawn(d, 0.5, attacker);

					if (runematch_targ_prev_runes & RUNE_DEFENSE)
					if ((d = damage * g_balance_rune_defense_damage_factor) >= 1)
						defense_attack_spawn(targ, attacker, d);

					if (attacker.runes & CURSE_VULNER)
					if ((d = damage * g_balance_curse_vulner_damage_factor) >= 1)
						defense_attack_spawn(targ, attacker, d);
				}
			}
			if (PLAYER_REALLY_ALIVE(targ))
				if (targ.runes & CURSE_BURNING)
					if ((d = g_balance_curse_burning_damage_factor * damage) >= 1)
						Fire_AddDamage(targ, world, d, 5, DEATH_FIRE);
		}
		if (targ.runes & RUNE_REGEN)
		if ((d = damage * g_balance_rune_regen_damage_factor) >= 1)
		if (targ.health < g_balance_rune_regen_max_health)
			healer_spawn(d, 1, targ);

		if (targ.runes & CURSE_VENOM)
		if ((d = damage * g_balance_curse_venom_damage_factor) >= 1)
			healer_spawn(-d, 0.5, targ);
	}
	runematch_DamageForceDone_NextLink(targ, attacker, damage, force);
}

var void(float killed) runematch_PlayerClear_NextLink;
void runematch_PlayerClear(float killed) {
	DropAllRunes(self);
	self.runes = 0;
	runematch_PlayerClear_NextLink(killed);
}

void runematch_init()
{
	if (teamplay)
		SetTeamCount(bound(2, cvar("g_runematch_teams"), 4));

	g_runematch = 1;
	GameHook_FragsHandle = RunematchHandleFrags;
	GameHook_WinCountDown = stub_WinCountDown;
	GameHook_WarmupAllowed = false_WarmupAllowed;
	GameHook_FragLimitOverride = runematch_FragLimitOverride;
	GameHook_LeadLimitOverride = runematch_LeadLimitOverride;
	if (g_runematch_pointamt) {
		RuneMatch_ServerFrame_NextLink = GameHookChain_ServerFrame;
		GameHookChain_ServerFrame = RuneMatch_ServerFrame;
	}
}

var void(entity e) runematch_SpectateCopy_NextLink;
void runematch_SpectateCopy(entity e) {
	self.runes = e.runes;
	runematch_SpectateCopy_NextLink(e);
}

var float(entity plr, entity targ) runematch_PlayerVisibleThroughWallFor_NextLink;
float runematch_PlayerVisibleThroughWallFor(entity plr, entity targ) {
	if (targ.runes & RUNE_HACKER)
	if (PLAYER_ALIVE(plr))
		return TRUE;

	if (plr.runes & CURSE_HACKED)
		return TRUE;

	return runematch_PlayerVisibleThroughWallFor_NextLink(plr, targ);
}

var float(entity plr, entity targ) runematch_PlayerCanSeeHealthFor_NextLink;
float runematch_PlayerCanSeeHealthFor(entity plr, entity targ) {
	if (plr.runes & RUNE_HACKER)
		return TRUE;

	if (targ.runes & CURSE_HACKED)
		return TRUE;

	return runematch_PlayerCanSeeHealthFor_NextLink(plr, targ);
}

void runes_init() {
	CACHE_CVAR(g_runes);
	if not(g_runes)
	if not(g_runematch)
		return;

	PhysicEnableCSQC();
	precache_model ("models/runematch/curse.mdl");
	precache_model ("models/runematch/rune.mdl");
	precache_sound("misc/minihealth.wav");
	precache_sound("misc/mediumhealth.wav");
	precache_sound("misc/bodyimpact1.wav");
	CACHE_CVAR(g_balance_curse_altruism_damage_factor);
	CACHE_CVAR(g_balance_curse_burning_damage_factor);
	CACHE_CVAR(g_balance_curse_vulner_damage_factor);
	CACHE_CVAR(g_balance_rune_regen_damage_factor);
	CACHE_CVAR(g_balance_rune_regen_max_health);
	CACHE_CVAR(g_balance_curse_venom_damage_factor);
	CACHE_CVAR(g_balance_rune_speed_combo_jumpheight);
	CACHE_CVAR(g_balance_rune_speed_jumpheight);
	CACHE_CVAR(g_balance_curse_slow_jumpheight);
	CACHE_CVAR(g_balance_curse_slow_moverate);
	CACHE_CVAR(g_balance_rune_speed_combo_moverate);
	CACHE_CVAR(g_balance_rune_speed_moverate);
	CACHE_CVAR(g_balance_rune_vampire_damage_factor);
	CACHE_CVAR(g_balance_rune_vampire_max_health);
	CACHE_CVAR(g_balance_rune_speed_combo_atkrate);
	CACHE_CVAR(g_balance_rune_speed_atkrate);
	CACHE_CVAR(g_balance_curse_slow_atkrate);
	CACHE_CVAR(g_balance_rune_defense_damage_factor);
	CACHE_CVAR(g_balance_rune_ignite_damage_factor);
	CACHE_CVAR(g_runematch_allow_same);
	CACHE_CVAR(g_runematch_carried_runes_max);
	CACHE_CVAR(g_runematch_curses);
	CACHE_CVAR(g_runematch_drop_runes_max);
	CACHE_CVAR(g_runematch_frags_killedby_runeholder);
	CACHE_CVAR(g_runematch_frags_killed_runeholder);
	CACHE_CVAR(g_runematch_frags_norune);
	CACHE_CVAR(g_runematch_pointamt);
	CACHE_CVAR(g_runematch_pointrate);
	CACHE_CVAR(g_runematch_respawntime);
	CACHE_CVAR(g_runematch_rune_alpha);
	CACHE_CVAR(g_runematch_rune_color_strength);
	CACHE_CVAR(g_runematch_rune_effects);
	//CACHE_CVAR(g_runematch_rune_glow_color);
	//CACHE_CVAR(g_runematch_rune_glow_size);
	CACHE_CVAR(g_runematch_shuffletime);
	runematch_JumpVelocityMod_NextLink = GameHookChain_JumpVelocityMod;
	GameHookChain_JumpVelocityMod = runematch_JumpVelocityMod;
	runematch_SpeedMod_NextLink = GameHookChain_SpeedMod;
	GameHookChain_SpeedMod = runematch_SpeedMod;
	runematch_WeaponRateFactor_NextLink = GameHookChain_WeaponRateFactor;
	GameHookChain_WeaponRateFactor = runematch_WeaponRateFactor;
	runematch_DamageForceDone_NextLink = GameHookChain_DamageForceDone;
	GameHookChain_DamageForceDone = runematch_DamageForceDone;
	runematch_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = runematch_PlayerClear;
	runematch_SpectateCopy_NextLink = GameHookChain_SpectateCopy;
	GameHookChain_SpectateCopy = runematch_SpectateCopy;
	runematch_PlayerVisibleThroughWallFor_NextLink = GameHookChain_PlayerVisibleThroughWallFor;
	GameHookChain_PlayerVisibleThroughWallFor = runematch_PlayerVisibleThroughWallFor;
	runematch_PlayerCanSeeHealthFor_NextLink = GameHookChain_PlayerCanSeeHealthFor;
	GameHookChain_PlayerCanSeeHealthFor = runematch_PlayerCanSeeHealthFor;
	runematch_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = runematch_DamageForceModsSet;
	entity e;
	e = spawn();
	e.think = spawn_runes;
	e.nextthink = time + 0.1;
	addstat(STAT_RUNES, AS_INT, runes);
}

float runematch_point_time;

// give points to players who are holding runes
void RuneMatch_ServerFrame()
{
	entity rune;
	RuneMatch_ServerFrame_NextLink();

	if(gameover)
		return;

	if(runematch_point_time > time)
		return;

	runematch_point_time = time + g_runematch_pointrate;

	rune = world;
	while ((rune = find(rune, classname, "rune")))
		if (rune.owner.classname == "player")
			UpdateFrags(rune.owner, g_runematch_pointamt);
}

float RunematchHandleFrags(entity attacker, entity targ, float f)
{
	entity head;
	float arunes, trunes, newfrags;

	if(f <= 0)
		return f;
	if(attacker == targ)
		return f;

	arunes = trunes = 0;

	head = find(world, classname, "rune");
	while(head)
	{
		if(head.owner == attacker)
		{
			arunes = arunes + 1;
		}
		else if(head.owner == targ)
		{
			trunes = trunes + 1;
		}

		head = find(head, classname, "rune");
	}

	if(!arunes && !trunes)
		return f - 1 + g_runematch_frags_norune; // don't give points to players when no runes are involved.

	if(arunes)
	{	// got a kill while holding runes
		newfrags = newfrags + g_runematch_frags_killedby_runeholder;//5;
	}
	if(trunes)
	{	// killed an enemy holding runes
		newfrags = newfrags + g_runematch_frags_killed_runeholder;//5;
	}
	if(newfrags)
		f = f - 1 + newfrags;

	return f;
}
