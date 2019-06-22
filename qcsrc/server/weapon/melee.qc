.float melee_time;
.float melee_lastthink;
.float melee_startthink;

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

void weapon_melee_attack_think()
{
	float melee_frame;
	melee_frame = min(time - self.melee_lastthink, self.melee_startthink + g_balance_melee_time - self.melee_lastthink);
	if (melee_frame < 0)
	{
		self.think = stdproc_remove;
		self.nextthink = self.melee_startthink + g_balance_melee_animtime;
		return;
	}
	float damage_factor = (g_balance_melee_onehit ? 1 : (melee_frame / g_balance_melee_time));
	makevectors(self.owner.v_angle);
	antilag_begin(self.owner);
	weapon_setup_shot(self.owner, 0, "", (self.dmg ? 1 : 0));
	float _damage;
	if (self.dmg)
		_damage = self.dmg;
	else
		_damage = g_balance_melee_damage;

	WarpZone_TraceLine(w_shotorg - (w_shotdir * 20), w_shotorg + w_shotdir * g_balance_melee_distance, MOVE_NORMAL, self);
	antilag_end();
	if (trace_fraction < 1)
	if (trace_ent)
	if (trace_ent.takedamage)
	{
		if (self.dmg)
			damage_record_hits(self.owner, trace_ent, WEP_MELEE, 1, _damage * damage_factor);

		damage(trace_ent, self.owner, self.owner, _damage * damage_factor,
				WEP_MELEE, trace_endpos, WarpZone_TransformVelocity(WarpZone_trace_transform, w_shotdir) * g_balance_melee_force * damage_factor + '0 0 1' * g_balance_melee_force_up * damage_factor);

		if (g_balance_melee_onehit)
		{
			self.think = stdproc_remove;
			self.nextthink = self.melee_startthink + g_balance_melee_animtime;
			return;
		}
	}
	self.melee_lastthink = time;
	self.nextthink = time + g_balance_melee_ticrate;
}

void weapon_melee_attack (float melee_type, float axe)
{
	if (melee_type == 2)
	if (Akimbo_Active(self) > 1) //g_balance_melee 2 suppose that weapon not used, so not duplicate attack for akimbo
		return;

	sound (Akimbo_Owner(self), CHAN_WEAPON, sv_sound_melee, VOL_BASE, ATTN_NORM);
	entity melee = spawn();
	melee.owner = Akimbo_Owner(self);
	melee.think = weapon_melee_attack_think;
	melee.nextthink = time + g_balance_melee_delay;
	melee.melee_startthink = melee.nextthink;
	melee.melee_lastthink = melee.nextthink;
	melee.nextthink += g_balance_melee_ticrate; //avoid frame with zero melee_frame
	melee.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	melee.dmg = axe;
	if (melee_type == 2)
	{
		setmodel(melee, self.model);
		melee.angles = sv_player_melee_angles;
		melee.colormap = self.colormap;
		setorigin(melee, sv_player_melee_origin);
		anim_set(melee, self.anim_melee2, FALSE, TRUE, TRUE);
		melee.customizeentityforclient = weapon_model_customize;
		melee.viewmodelforclient = self;
	}
	self.bot_melee = FALSE;
}

float weapon_melee_possible()
{
	if not(Akimbo_Owner(self).crouch && !g_balance_melee_allow_crouched)
	if (self.weapon != WEP_CAMPINGRIFLE || g_balance_campingrifle_hotreload)
	if (g_balance_melee || (self.weapon == WEP_MELEE))
		return TRUE;
	return FALSE;
}

void weapon_melee_attack_check()
{
	if (self.weapon != self.switchweapon)
		return;

	float w_save = self.weapon;
	self.switchweapon = self.weapon = WEP_MELEE;
	float axe = ((w_save == WEP_MELEE) && (g_balance_melee != 2));
	if (weapon_prepareattack(0, g_balance_melee_refire))
	{
		weapon_melee_attack(g_balance_melee, axe);
		weapon_thinkf((axe ? WFRAME_FIRE1 : ((g_balance_melee == 2) ? WFRAME_MELEE2 : WFRAME_MELEE)), g_balance_melee_animtime, weapon_ready);
	}
	self.weapon = w_save;
	self.switchweapon = w_save;
}

void weapon_melee_init()
{
	CACHE_CVAR_STR(sv_sound_melee);
	precache_sound (sv_sound_melee);
	CACHE_CVAR(g_balance_melee);
	CACHE_CVAR(g_balance_melee_animtime);
	CACHE_CVAR(g_balance_melee_allow_crouched);
	CACHE_CVAR(g_balance_melee_delay);
	CACHE_CVAR(g_balance_melee_ticrate);
	CACHE_CVAR(g_balance_melee_time);
	CACHE_CVAR(g_balance_melee_damage);
	CACHE_CVAR(g_balance_melee_force);
	CACHE_CVAR(g_balance_melee_force_up);
	CACHE_CVAR(g_balance_melee_distance);
	CACHE_CVAR(g_balance_melee_onehit);
	CACHE_CVAR(g_balance_melee_refire);
	sv_player_melee_angles = stov(cvar_string("sv_player_melee_angles"));
	sv_player_melee_origin = stov(cvar_string("sv_player_melee_origin"));
	bot_melee_love = cvar("bot_melee");
}

float weapon_melee_aim()
{
	if (weapon_melee_possible())
	if (random() < bot_melee_love)
	if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
		self.bot_melee = bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE);
	return self.bot_melee;
}
