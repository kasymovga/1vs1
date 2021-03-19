float g_balance_melee;
float g_balance_melee_animtime;
float g_balance_melee_allow_crouched;
float g_balance_melee_delay;
float g_balance_melee_ticrate;
float g_balance_melee_time;
float g_balance_melee_damage;
float g_balance_melee_force;
float g_balance_melee_force_up;
float g_balance_melee_distance;
float g_balance_melee_onehit;
float g_balance_melee_refire;
vector sv_player_melee_angles;
vector sv_player_melee_origin;
string sv_sound_melee;

float bot_melee_love;

void(void) weapon_melee_attack_think {
	if (self.cnt < 0 || self.owner.playerid != self.playerid) {
		remove(self);
		return;
	}
	self.cnt = self.cnt - 1;
	float damage_factor = (g_balance_melee_onehit ? 1 : (1 / self.count));
	makevectors(self.owner.v_angle);
	antilag_begin(self.owner);
	weapon_setup_shot(self.owner, 0, "", (self.dmg ? 1 : 0));
	float _damage;
	if (self.dmg)
		_damage = self.dmg;
	else
		_damage = g_balance_melee_damage;

	WarpZone_TraceLine(weapon_shotorg - (weapon_shotdir * 20), weapon_shotorg + weapon_shotdir * g_balance_melee_distance, MOVE_NORMAL, self);
	antilag_end();
	if (trace_fraction < 1)
	if (trace_ent)
	if (trace_ent.takedamage) {
		if (self.dmg)
			damage_record_hits(self.owner, trace_ent, WEP_MELEE, 1, _damage * damage_factor);

		damage(trace_ent, self.owner, self.owner, _damage * damage_factor,
				WEP_MELEE, trace_endpos, WarpZone_TransformVelocity(WarpZone_trace_transform, weapon_shotdir) * g_balance_melee_force * damage_factor + '0 0 1' * g_balance_melee_force_up * damage_factor);
		if (g_balance_melee_onehit) {
			remove(self);
			return;
		}
	}
	self.delay = self.delay + g_balance_melee_ticrate;
	self.nextthink = self.delay;
}

void weapon_melee_attack (float melee_type, float axe)
{
	if (melee_type == 2)
	if (akimbo_active(self) > 1) //g_balance_melee 2 suppose that weapon not used, so not duplicate attack for akimbo
		return;

	sound(akimbo_owner(self), CHAN_WEAPON, sv_sound_melee, VOL_BASE, ATTN_NORM);
	entity melee = spawn();
	melee.owner = akimbo_owner(self);
	melee.think = weapon_melee_attack_think;
	melee.delay = melee.nextthink = time + g_balance_melee_delay;
	melee.cnt = melee.count = max(1, 1 + ceil(g_balance_melee_time / g_balance_melee_ticrate));
	melee.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	melee.dmg = axe;
	melee.playerid = melee.owner.playerid;
	if (melee_type == 2)
	{
		setmodel(melee, self.body.playermodel);
		melee.angles = sv_player_melee_angles;
		melee.colormap = self.colormap;
		setorigin(melee, sv_player_melee_origin);
		anim_set(melee, self.anim_melee2, FALSE, TRUE, TRUE);
		melee.customizeentityforclient = weapon_model_customize;
		melee.viewmodelforclient = self;
	}
}

float weapon_melee_possible()
{
	if not(akimbo_owner(self).crouch && !g_balance_melee_allow_crouched)
	if (g_balance_melee)
		return TRUE;

	return FALSE;
}

void weapon_melee_attack_check()
{
	if (self.weapon != self.switchweapon)
		return;

	float w_save = self.weapon;
	self.switchweapon = self.weapon = WEP_MELEE;
	if (self.weapon_think == weapon_ready)
	if (weapon_prepareattack(0, g_balance_melee_refire))
	{
		weapon_melee_attack(g_balance_melee, 0);
		weapon_thinkf(((g_balance_melee == 2) ? WFRAME_MELEE2 : WFRAME_MELEE), g_balance_melee_animtime, weapon_ready);
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
void weapon_melee_init()
{
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
	CVAR_CACHE(g_balance_melee_force_up);
	CVAR_CACHE(g_balance_melee_distance);
	CVAR_CACHE(g_balance_melee_onehit);
	CVAR_CACHE(g_balance_melee_refire);
	sv_player_melee_angles = stov(cvar_string("sv_player_melee_angles"));
	sv_player_melee_origin = stov(cvar_string("sv_player_melee_origin"));
	bot_melee_love = cvar("bot_melee");
	if not(weapon_melee_init_done) {
		weapon_melee_init_done = 1;
		weapon_melee_bot_aim_next = gamehook_chain_bot_aim;
		gamehook_chain_bot_aim = weapon_melee_bot_aim;
	}
}
