.float melee_damage;
.float melee_force;
.float melee_distance;
.float melee_time;
.float melee_lastthink;
.float melee_startthink;
.float melee_ticrate;

float g_balance_melee;
float g_balance_melee_animtime;
float g_balance_melee_delay;
float g_balance_melee_ticrate;
float g_balance_melee_time;
float g_balance_melee_damage;
float g_balance_melee_force;
float g_balance_melee_distance;
float g_balance_melee_refire;

float bot_melee_love;

void W_Melee_Attack_Think()
{
	float melee_frame;
	melee_frame = min(time - self.melee_lastthink, self.melee_startthink + self.melee_time - self.melee_lastthink);
	if (melee_frame < 0)
	{
		remove(self);
		return;
	}
	float damage_factor = melee_frame / self.melee_time;
	float frame_damage = self.melee_damage * damage_factor;
	float frame_force = self.melee_force * damage_factor;
	makevectors(self.owner.angles);
	W_SetupShot(self.owner, FALSE, 0, "", frame_damage);
	traceline_antilag(self.owner, w_shotorg - (w_shotdir * 20), w_shotorg + w_shotdir * self.melee_distance, MOVE_NORMAL, self, ANTILAG_LATENCY(self.owner));
	if (trace_fraction < 1)
	if (trace_ent)
	if (trace_ent.takedamage)
		Damage (trace_ent, self.owner, self.owner, frame_damage,
				WEP_MELEE, trace_endpos, w_shotdir * frame_force);
	self.melee_lastthink = time;
	self.nextthink = time + self.melee_ticrate;
}

void W_Melee_Attack ()
{
	sound (Akimbo_Owner(self), CHAN_WEAPON, cvar_string("sv_sound_melee"), VOL_BASE, ATTN_NORM);
	entity melee = spawn();
	melee.owner = Akimbo_Owner(self);
	melee.think = W_Melee_Attack_Think;
	melee.nextthink = time + g_balance_melee_delay;
	melee.melee_damage = g_balance_melee_damage;
	melee.melee_force = g_balance_melee_force;
	melee.melee_distance = g_balance_melee_distance;
	melee.melee_time = g_balance_melee_time;
	melee.melee_ticrate = g_balance_melee_ticrate;
	melee.melee_startthink = melee.nextthink;
	melee.melee_lastthink = melee.nextthink;
	melee.nextthink += melee.melee_ticrate; //avoid frame with zero melee_frame
	melee.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	self.bot_melee = FALSE;
}

float W_Melee_Possible()
{
	if (self.weapon != WEP_CAMPINGRIFLE)
	if (g_balance_melee || (self.weapon == WEP_LASER && (g_balance_laser_primary_melee || g_balance_laser_secondary_melee)))
		return TRUE;
	return FALSE;
}

void W_Melee_Attack_Check()
{
	if (weapon_prepareattack(0, g_balance_melee_refire))
	{
		W_Melee_Attack();
		weapon_thinkf(WFRAME_MELEE, g_balance_melee_animtime, w_ready);
	}
}

void Melee_Init()
{
	precache_sound (cvar_string("sv_sound_melee"));
	CACHE_CVAR(g_balance_melee);
	CACHE_CVAR(g_balance_melee_animtime);
	CACHE_CVAR(g_balance_melee_delay);
	CACHE_CVAR(g_balance_melee_ticrate);
	CACHE_CVAR(g_balance_melee_time);
	CACHE_CVAR(g_balance_melee_damage);
	CACHE_CVAR(g_balance_melee_force);
	CACHE_CVAR(g_balance_melee_distance);
	CACHE_CVAR(g_balance_melee_refire);
	bot_melee_love = cvar("bot_melee");
}

float W_Melee_Aim()
{
	if (W_Melee_Possible())
	if (random() < bot_melee_love)
	if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
		self.bot_melee = bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE);
	return self.bot_melee;
}
