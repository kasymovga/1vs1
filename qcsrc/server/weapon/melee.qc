float g_balance_melee;
float g_balance_melee_animtime;
float g_balance_melee_allow_crouched;
float g_balance_melee_delay;
float g_balance_melee_ticrate;
float g_balance_melee_time;
float g_balance_melee_damage;
float g_balance_melee_force;
float g_balance_melee_distance;
float g_balance_melee_kick_damage;
float g_balance_melee_kick_force;
float g_balance_melee_kick_force_up;
float g_balance_melee_kick_onehit;
float g_balance_melee_onehit;
float g_balance_melee_refire;
string sv_sound_melee;
float bot_melee_love;
float WEAPON_MELEE_ABILITY;

void(void) weapon_melee_attack_think {
	if (self.cnt < 0 || self.owner.playerid != self.playerid) {
		remove(self);
		return;
	}
	self.cnt = self.cnt - 1;
	float onehit, force, force_up;
	float _damage;
	if (g_balance_melee == 2 && !self.dmg) {
		makevectors(self.owner.angles);
		onehit = g_balance_melee_kick_onehit;
		force = g_balance_melee_kick_force;
		force_up = g_balance_melee_kick_force_up;
		_damage = g_balance_melee_kick_damage;
	} else {
		makevectors(self.owner.v_angle);
		onehit = g_balance_melee_onehit;
		force = g_balance_melee_force;
		force_up = 0;
		if (self.dmg)
			_damage = self.dmg;
		else
			_damage = g_balance_melee_damage;

	}
	float damage_factor = (onehit ? 1 : (1 / self.count));
	antilag_begin(self.owner);
	weapon_setup_shot(self.owner, 0, "", (self.dmg ? 1 : 0));
	warpzone_trace_line(weapon_shotorg - (weapon_shotdir * 20), weapon_shotorg + weapon_shotdir * g_balance_melee_distance, TRACE_MOVE_NORMAL, self);
	antilag_end();
	if (trace_fraction < 1)
	if (trace_ent)
	if (trace_ent.takedamage) {
		if (self.dmg)
			damage_record_hits(self.owner, trace_ent, WEAPON_MELEE, 1, _damage * damage_factor);

		damage(trace_ent, self.owner, self.owner, _damage * damage_factor,
				WEAPON_MELEE, trace_endpos, warpzone_transform_velocity(warpzone_trace_transform, weapon_shotdir) * force * damage_factor + '0 0 1' * force_up * damage_factor);
		if (onehit) {
			remove(self);
			return;
		}
	}
	self.delay = self.delay + g_balance_melee_ticrate;
	self.nextthink = self.delay;
}

void(float melee_type, float extradmg, string snd) weapon_melee_attack {
	if (melee_type == 2)
	if (akimbo_active(self) > 1) //g_balance_melee 2 suppose that weapon not used, so not duplicate attack for akimbo
		return;

	sound(akimbo_owner(self), CHAN_WEAPON, snd, VOL_BASE, ATTN_NORM);
	entity melee = spawn();
	melee.owner = akimbo_owner(self);
	melee.think = weapon_melee_attack_think;
	melee.delay = melee.nextthink = time + g_balance_melee_delay;
	melee.cnt = melee.count = max(1, 1 + ceil(g_balance_melee_time / g_balance_melee_ticrate));
	melee.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	melee.dmg = extradmg;
	melee.playerid = melee.owner.playerid;
	if (melee_type == 2)
		thirdview_set(self, g_balance_melee_animtime, 100, 10);
}

float(void) weapon_melee_possible {
	entity ao = akimbo_owner(self);
	if not(ao.crouch && !g_balance_melee_allow_crouched)
	if (g_balance_melee || (ao.abilities & WEAPON_MELEE_ABILITY))
		return TRUE;

	return FALSE;
}

void(void) weapon_melee_attack_check {
	if (self.weapon != self.switchweapon)
		return;

	float w_save = self.weapon;
	self.switchweapon = self.weapon = WEAPON_MELEE;
	if (self.weapon_think == weapon_ready)
	if (weapon_prepareattack(0, g_balance_melee_refire)) {
		weapon_melee_attack(g_balance_melee, 0, sv_sound_melee);
		weapon_thinkf(((g_balance_melee == 2) ? WEAPON_FRAME_MELEE2 : WEAPON_FRAME_MELEE), g_balance_melee_animtime, weapon_ready);
	}
	self.weapon = w_save;
	self.switchweapon = w_save;
}

var float(void) weapon_melee_bot_aim_next;
float(void) weapon_melee_bot_aim {
	if (weapon_melee_possible())
	if (random() < bot_melee_love)
	if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2) {
		if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE)) {
			self.impulse = 20;
			return TRUE;
		} else
			return FALSE;
	}
	return weapon_melee_bot_aim_next();
}

float weapon_melee_init_done;
void(void) weapon_melee_init {
	CVAR_CACHE_STR(sv_sound_melee);
	precache_sound (sv_sound_melee);
	CVAR_CACHE(g_balance_melee);
	CVAR_CACHE(g_balance_melee_animtime);
	CVAR_CACHE(g_balance_melee_allow_crouched);
	CVAR_CACHE(g_balance_melee_delay);
	CVAR_CACHE(g_balance_melee_ticrate);
	CVAR_CACHE(g_balance_melee_time);
	CVAR_CACHE(g_balance_melee_damage);
	CVAR_CACHE(g_balance_melee_force);
	CVAR_CACHE(g_balance_melee_distance);
	CVAR_CACHE(g_balance_melee_kick_damage);
	CVAR_CACHE(g_balance_melee_kick_force);
	CVAR_CACHE(g_balance_melee_kick_force_up);
	CVAR_CACHE(g_balance_melee_kick_onehit);
	CVAR_CACHE(g_balance_melee_onehit);
	CVAR_CACHE(g_balance_melee_refire);
	bot_melee_love = cvar("bot_melee");
	if not(weapon_melee_init_done) {
		WEAPON_MELEE_ABILITY = ability_register("melee", NULL);
		weapon_melee_init_done = 1;
		weapon_melee_bot_aim_next = plugin_chain_bot_aim;
		plugin_chain_bot_aim = weapon_melee_bot_aim;
	}
}
