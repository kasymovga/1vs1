float g_balance_electro_combo_comboradius;
float g_balance_electro_combo_damage;
float g_balance_electro_combo_edgedamage;
float g_balance_electro_combo_force;
float g_balance_electro_combo_radius;
float g_balance_electro_combo_speed;
float g_balance_electro_primary_ammo;
float g_balance_electro_primary_animtime;
float g_balance_electro_primary_comboradius;
float g_balance_electro_primary_damage;
float g_balance_electro_primary_edgedamage;
float g_balance_electro_primary_force;
float g_balance_electro_primary_lifetime;
float g_balance_electro_primary_lightning;
float g_balance_electro_primary_lightning_length;
float g_balance_electro_primary_radius;
float g_balance_electro_primary_refire;
float g_balance_electro_primary_speed;
float g_balance_electro_secondary;
float g_balance_electro_secondary_ammo;
float g_balance_electro_secondary_animtime;
float g_balance_electro_secondary_count;
float g_balance_electro_secondary_damage;
float g_balance_electro_secondary_damageforcescale;
float g_balance_electro_secondary_edgedamage;
float g_balance_electro_secondary_force;
float g_balance_electro_secondary_health;
float g_balance_electro_secondary_lifetime;
float g_balance_electro_secondary_radius;
float g_balance_electro_secondary_refire;
float g_balance_electro_secondary_refire2;
float g_balance_electro_secondary_speed;
float g_balance_electro_secondary_speed_up;
float g_balance_electro_secondary_spread;

.float electro_count;
.float electro_secondarytime;

void W_Plasma_Explode_Combo (void);

void W_Plasma_TriggerCombo(vector org, float rad, entity own)
{
	local entity e;
	e = findradius(org, rad);
	while (e)
	{
		if (e.classname == "plasma")
		{
			// see if there is line of sight to the combo ball
			traceline(org, e.origin, MOVE_NORMAL, e);
			if (trace_fraction == 1 || trace_ent == e)
			{
				// change owner to whoever caused the combo explosion
				e.owner = own;
				e.takedamage = DAMAGE_NO;
				e.classname = "plasma_chain";
				e.think = W_Plasma_Explode_Combo;
				e.nextthink = time + vlen(e.origin - org) / g_balance_electro_combo_speed; // delay combo chains, looks cooler
			}
		}
		e = e.chain;
	}
}

void W_Plasma_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						announce(self.owner, "announcer/male/electrobitch.wav");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	if (self.movetype == MOVETYPE_BOUNCE)
	{
		RadiusDamage (self, self.owner, g_balance_electro_secondary_damage, g_balance_electro_secondary_edgedamage, g_balance_electro_secondary_radius, world, g_balance_electro_secondary_force, self.projectiledeathtype, other);
	}
	else
	{
		W_Plasma_TriggerCombo(self.origin, g_balance_electro_primary_comboradius, self.owner);
		RadiusDamage (self, self.owner, g_balance_electro_primary_damage, g_balance_electro_primary_edgedamage, g_balance_electro_primary_radius, world, g_balance_electro_primary_force, self.projectiledeathtype, other);
	}

	remove (self);
}

void W_Plasma_Explode_Combo (void)
{

	W_Plasma_TriggerCombo(self.origin, g_balance_electro_combo_comboradius, self.owner);

	self.event_damage = SUB_Null;
	RadiusDamage (self, self.owner, g_balance_electro_combo_damage, g_balance_electro_combo_edgedamage, g_balance_electro_combo_radius, world, g_balance_electro_combo_force, WEP_ELECTRO | HITTYPE_BOUNCE, world); // use THIS type for a combo because primary can't bounce
	remove (self);
}

void W_Plasma_Touch (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM) {
		W_Plasma_Explode ();
	} else {
		spamsound (self, CHAN_PROJECTILE, "weapons/electro_bounce.wav", VOL_BASE, ATTN_NORM);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Plasma_TouchExplode (void)
{
	PROJECTILE_TOUCH;
	W_Plasma_Explode ();
}

void W_Plasma_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health <= 0)
		return;
	// note: combos are usually triggered by W_Plasma_TriggerCombo, not damage
	self.health = self.health - damage;
	if (self.health <= 0)
	{
		self.takedamage = DAMAGE_NO;
		self.nextthink = time;
		if (inflictor.classname == "plasma_chain" || inflictor.classname == "plasma_prim")
		{
			// change owner to whoever caused the combo explosion
			self.owner = inflictor.owner;
			self.classname = "plasma_chain";
			self.think = W_Plasma_Explode_Combo;
			self.nextthink = time + vlen(self.origin - inflictor.origin) / g_balance_electro_combo_speed; // delay combo chains, looks cooler
		}
		else
		{
			self.use = W_Plasma_Explode;
			self.think = adaptor_think2use;
		}
	}
}

.entity lightning_beam;
.float lightning_beam_length;
.vector lightning_beam_begin;
.vector lightning_beam_end;

void W_Electro_Attack_Lightning_Remove(entity own)
{
	if (own.lightning_beam)
	{
		stopsound(own.lightning_beam, CHAN_PROJECTILE);
		stopsound(own, CHAN_PROJECTILE);
		remove(own.lightning_beam);
		own.lightning_beam = world;
	}
}

void W_Electro_Attack_Lightning_Think()
{
	if (self.owner.weapon != WEP_ELECTRO)
	{
		remove(self);
		print("Abandoned electro beam detected and removed\n");
		return;
	}
	makevectors(self.owner.v_angle);
	W_SetupShot(self.owner, FALSE, 0, "", 0);
	traceline(w_shotorg, w_shotorg + w_shotdir * self.lightning_beam_length, MOVE_NORMAL, Akimbo_Owner(self.owner));
	self.lightning_beam_begin = w_shotorg_visual;
	self.lightning_beam_end = trace_endpos;
	setorigin(self, (self.owner.origin + trace_endpos) * 0.5);
	self.nextthink = time;
	self.SendFlags |= 2;
}

float W_Electro_Ligtning_Send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_LIGHTNING);

	WriteShort(MSG_ENTITY, num_for_edict(Akimbo_Owner(self.owner)));
	WriteCoord(MSG_ENTITY, self.lightning_beam_begin_x);
	WriteCoord(MSG_ENTITY, self.lightning_beam_begin_y);
	WriteCoord(MSG_ENTITY, self.lightning_beam_begin_z);
	WriteCoord(MSG_ENTITY, self.lightning_beam_end_x);
	WriteCoord(MSG_ENTITY, self.lightning_beam_end_y);
	WriteCoord(MSG_ENTITY, self.lightning_beam_end_z);
	WriteCoord(MSG_ENTITY, self.owner.weaponentity.shotorg_visual_x);
	WriteCoord(MSG_ENTITY, -self.owner.weaponentity.shotorg_visual_y);
	WriteCoord(MSG_ENTITY, self.owner.weaponentity.shotorg_visual_z);
	return TRUE;
}

void W_Electro_Attack_Lightning()
{
	float damage = g_balance_electro_primary_damage;
	W_SetupShot(self, FALSE, 0, "", damage);
	if (!self.lightning_beam) {
		self.lightning_beam = spawn();
		setorigin(self.lightning_beam, self.origin);
		self.lightning_beam.owner = self;
		self.lightning_beam.think = W_Electro_Attack_Lightning_Think;
		self.lightning_beam.nextthink = time;
		self.lightning_beam.lightning_beam_length = g_balance_electro_primary_lightning_length;
		self.lightning_beam.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
		sound(self.lightning_beam, CHAN_PROJECTILE, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
		sound(self, CHAN_WEAPON, "weapons/electro_fire.wav", VOL_BASE, ATTN_NORM);
		sound(self, CHAN_PROJECTILE, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
		Net_LinkEntity(self.lightning_beam, FALSE, 0, W_Electro_Ligtning_Send);
	}
	entity oldself = self;
	self = Akimbo_Owner(self);
	traceline_antilag(self, w_shotorg, w_shotorg + w_shotdir * self.lightning_beam.lightning_beam_length, MOVE_NORMAL, self.lightning_beam, ANTILAG_LATENCY(self));
	if (trace_fraction < 1)
	{
		if (trace_ent && trace_ent.takedamage)
		{
			Damage (trace_ent, self, self, damage, WEP_ELECTRO, trace_endpos, w_shotdir * g_balance_electro_primary_force);
			Damage_RecordDamage(self, WEP_ELECTRO, damage);
		}
		if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
			pointparticles(particleeffectnum("machinegun_impact"), trace_endpos, '0 0 0', 0);
		W_Plasma_TriggerCombo(trace_endpos, g_balance_electro_primary_comboradius, self);
	}
	self = oldself;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_electro_primary_ammo;
}

void W_Electro_Attack()
{
	local entity proj;

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 2, "weapons/electro_fire.wav", g_balance_electro_primary_damage);

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma_prim";
	proj.owner = Akimbo_Owner(self);
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = g_balance_electro_primary_damage;
	proj.use = W_Plasma_Explode;
	proj.think = adaptor_think2use;
	proj.nextthink = time + g_balance_electro_primary_lifetime;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO;
	setorigin(proj, w_shotorg);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_electro_primary_ammo;
	proj.movetype = MOVETYPE_FLY;
	proj.velocity = w_shotdir * g_balance_electro_primary_speed;
	W_SetupProjectileVelocity(proj);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Plasma_TouchExplode;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.flags = FL_PROJECTILE;

	//sound (proj, CHAN_PAIN, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
	//sounds bad

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO_BEAM, TRUE);
}

void W_Electro_Attack2()
{
	local entity proj;

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 2, "weapons/electro_fire2.wav", g_balance_electro_secondary_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma";
	proj.owner = Akimbo_Owner(self);
	proj.use = W_Plasma_Explode;
	proj.think = adaptor_think2use;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = g_balance_electro_secondary_damage;
	proj.nextthink = time + g_balance_electro_secondary_lifetime;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_electro_secondary_ammo;
	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	proj.velocity = (w_shotdir + randomvec() * g_balance_electro_secondary_spread) * g_balance_electro_secondary_speed + v_up * g_balance_electro_secondary_speed_up;
	W_SetupProjectileVelocity(proj);
	proj.touch = W_Plasma_Touch;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = g_balance_electro_secondary_damageforcescale;
	proj.health = g_balance_electro_secondary_health;
	proj.event_damage = W_Plasma_Damage;
	proj.flags = FL_PROJECTILE;

#if 0
	entity p2;
	p2 = spawn();
	copyentity(proj, p2);
	setmodel(p2, "models/ebomb.mdl");
	setsize(p2, proj.mins, proj.maxs);
#endif

	CSQCProjectile(proj, TRUE, PROJECTILE_ELECTRO, FALSE); // no culling, it has sound
}

void spawnfunc_weapon_electro (void)
{
	weapon_defaultspawnfunc(WEP_ELECTRO);
}

void w_electro_checkattack()
{
	if(self.electro_count > 1)
	if(self.BUTTON_ATCK2)
	if(weapon_prepareattack(1, -1))
	{
		W_Electro_Attack2();
		self.electro_count -= 1;
		weapon_thinkf(WFRAME_FIRE2, g_balance_electro_secondary_animtime, w_electro_checkattack);
		return;
	}

	w_ready();
}

void w_electro_checkattack_lightning()
{
	if(self.BUTTON_ATCK)
	if(weapon_prepareattack(0, -1))
	{
		W_Electro_Attack_Lightning();
		weapon_thinkf(WFRAME_DONTCHANGE, g_balance_electro_primary_refire, w_electro_checkattack_lightning);
		return;
	}
	W_Electro_Attack_Lightning_Remove(self);
	w_ready();
}

.float bot_secondary_electromooth;
float w_electro(float req)
{
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK=FALSE;
		self.BUTTON_ATCK2=FALSE;
		if(vlen(self.origin-self.enemy.origin) > g_balance_electro_secondary_speed)
			self.bot_secondary_electromooth = 0;
		if(self.bot_secondary_electromooth == 0)
		{
			local float aim_electro_speed;
			local float aim_electro_lifetime;
			if (g_balance_electro_primary_lightning)
			{
				aim_electro_speed = g_balance_electro_primary_lightning_length * 100;
				aim_electro_lifetime = 0.01;
			}
			else
			{
				aim_electro_speed = g_balance_electro_primary_speed;
				aim_electro_lifetime = g_balance_electro_primary_lifetime;
			}
			if(bot_aim(aim_electro_speed, 0, aim_electro_lifetime, FALSE))
			{
				self.BUTTON_ATCK = TRUE;
				if(g_balance_electro_secondary && random() < sys_ticrate)
					self.bot_secondary_electromooth = 1;
			}
		}
		else
		{
			if(bot_aim(g_balance_electro_secondary_speed, g_balance_electro_secondary_speed_up, g_balance_electro_secondary_lifetime, TRUE))
			{
				self.BUTTON_ATCK2 = TRUE;
				if(random() < sys_ticrate * 3) self.bot_secondary_electromooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, g_balance_electro_primary_refire))
		{
			if (g_balance_electro_primary_lightning)
			{
				W_Electro_Attack_Lightning();
				weapon_thinkf(WFRAME_FIRE1, g_balance_electro_primary_refire, w_electro_checkattack_lightning);
			}
			else
			{
				W_Electro_Attack();
				weapon_thinkf(WFRAME_FIRE1, g_balance_electro_primary_animtime, w_ready);
			}
		}
		if (self.BUTTON_ATCK2)
		if (time >= self.electro_secondarytime)
		if (g_balance_electro_secondary)
		if (weapon_prepareattack(1, g_balance_electro_secondary_refire))
		{
			W_Electro_Attack2();
			self.electro_count = g_balance_electro_secondary_count;
			weapon_thinkf(WFRAME_FIRE2, g_balance_electro_secondary_animtime, w_electro_checkattack);
			self.electro_secondarytime = time + g_balance_electro_secondary_refire2;
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/electro_bounce.wav");
		precache_sound ("weapons/electro_fire.wav");
		precache_sound ("weapons/electro_fire2.wav");
		precache_sound ("weapons/electro_impact.wav");
		precache_sound ("weapons/electro_impact_combo.wav");
		precache_sound ("weapons/electro_fly.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_ELECTRO);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= g_balance_electro_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_cells >= g_balance_electro_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "could not remember where he put plasma";
		else
			w_deathtypestring = "played with plasma";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(w_deathtype & HITTYPE_SPLASH) // unchecked: BOUNCE
				w_deathtypestring = "just noticed #'s blue ball";
			else // unchecked: BOUNCE
				w_deathtypestring = "got in touch with #'s blue ball";
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE) // combo
				w_deathtypestring = "felt the electrifying air of #'s combo";
			else if(w_deathtype & HITTYPE_SPLASH)
				w_deathtypestring = "got too close to #'s blue beam";
			else
				w_deathtypestring = "was blasted by #'s blue beam";
		}
	}
	else if (req == WR_RESETPLAYER)
		self.electro_secondarytime = time;
	else if (req == WR_CLEAR)
		W_Electro_Attack_Lightning_Remove(self);
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_electro_combo_comboradius);
		CACHE_CVAR(g_balance_electro_combo_damage);
		CACHE_CVAR(g_balance_electro_combo_edgedamage);
		CACHE_CVAR(g_balance_electro_combo_force);
		CACHE_CVAR(g_balance_electro_combo_radius);
		CACHE_CVAR(g_balance_electro_combo_speed);
		CACHE_CVAR(g_balance_electro_primary_ammo);
		CACHE_CVAR(g_balance_electro_primary_animtime);
		CACHE_CVAR(g_balance_electro_primary_comboradius);
		CACHE_CVAR(g_balance_electro_primary_damage);
		CACHE_CVAR(g_balance_electro_primary_edgedamage);
		CACHE_CVAR(g_balance_electro_primary_force);
		CACHE_CVAR(g_balance_electro_primary_lifetime);
		CACHE_CVAR(g_balance_electro_primary_lightning);
		CACHE_CVAR(g_balance_electro_primary_lightning_length);
		CACHE_CVAR(g_balance_electro_primary_radius);
		CACHE_CVAR(g_balance_electro_primary_refire);
		CACHE_CVAR(g_balance_electro_primary_speed);
		CACHE_CVAR(g_balance_electro_secondary);
		CACHE_CVAR(g_balance_electro_secondary_ammo);
		CACHE_CVAR(g_balance_electro_secondary_animtime);
		CACHE_CVAR(g_balance_electro_secondary_count);
		CACHE_CVAR(g_balance_electro_secondary_damage);
		CACHE_CVAR(g_balance_electro_secondary_damageforcescale);
		CACHE_CVAR(g_balance_electro_secondary_edgedamage);
		CACHE_CVAR(g_balance_electro_secondary_force);
		CACHE_CVAR(g_balance_electro_secondary_health);
		CACHE_CVAR(g_balance_electro_secondary_lifetime);
		CACHE_CVAR(g_balance_electro_secondary_radius);
		CACHE_CVAR(g_balance_electro_secondary_refire);
		CACHE_CVAR(g_balance_electro_secondary_refire2);
		CACHE_CVAR(g_balance_electro_secondary_speed);
		CACHE_CVAR(g_balance_electro_secondary_speed_up);
		CACHE_CVAR(g_balance_electro_secondary_spread);
	}
	return TRUE;
};
