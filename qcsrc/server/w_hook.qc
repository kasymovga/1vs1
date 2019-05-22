float g_balance_hook_primary_animtime;
float g_balance_hook_primary_fuel;
float g_balance_hook_primary_hooked_fuel;
float g_balance_hook_primary_hooked_time_free;
float g_balance_hook_primary_hooked_time_max;
float g_balance_hook_primary_refire;
float g_balance_hook_secondary_ammo;
float g_balance_hook_secondary_animtime;
float g_balance_hook_secondary_damage;
float g_balance_hook_secondary_duration;
float g_balance_hook_secondary_edgedamage;
float g_balance_hook_secondary_force;
float g_balance_hook_secondary_gravity;
float g_balance_hook_secondary_lifetime;
float g_balance_hook_secondary_power;
float g_balance_hook_secondary_radius;
float g_balance_hook_secondary_refire;
float g_balance_hook_secondary_speed;

.float dmg;
.float dmg_edge;
.float dmg_radius;
.float dmg_force;
.float dmg_power;
.float dmg_duration;
.float dmg_last;
.float hook_refire;
.float hook_time_hooked;
.float hook_time_fueldecrease;

void W_Hook_ExplodeThink (void)
{
	float dt, dmg_remaining_next, f;

	dt = time - self.teleport_time;
	dmg_remaining_next = pow(bound(0, 1 - dt / self.dmg_duration, 1), self.dmg_power);

	f = self.dmg_last - dmg_remaining_next;
	self.dmg_last = dmg_remaining_next;
	damage_record_fires(self.owner, WEP_HOOK, 1);
	damage_radius (self, self.owner, self.dmg * f, self.dmg_edge * f, self.dmg_radius, self.owner, self.dmg_force * f, self.projectiledeathtype, world);
	self.projectiledeathtype |= HITTYPE_BOUNCE;
	//damage_radius (self, world, self.dmg * f, self.dmg_edge * f, self.dmg_radius, world, self.dmg_force * f, self.projectiledeathtype, world);

	if(dt < self.dmg_duration)
		self.nextthink = time + 0.05; // soon
	else
		remove(self);
}

void W_Hook_Explode2 (void)
{
	self.event_damage = SUB_Null;
	self.touch = SUB_Null;
	self.effects |= EF_NODRAW;

	self.think = W_Hook_ExplodeThink;
	self.nextthink = time;
	self.dmg = g_balance_hook_secondary_damage;
	self.dmg_edge = g_balance_hook_secondary_edgedamage;
	self.dmg_radius = g_balance_hook_secondary_radius;
	self.dmg_force = g_balance_hook_secondary_force;
	self.dmg_power = g_balance_hook_secondary_power;
	self.dmg_duration = g_balance_hook_secondary_duration;
	self.teleport_time = time;
	self.dmg_last = 1;
	self.movetype = MOVETYPE_NONE;
}

void W_Hook_Touch2 (void)
{
	PROJECTILE_TOUCH;
	self.use();
}

void W_Hook_Attack2()
{
	local entity gren;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_hook_secondary_ammo;
	W_SetupShot (self, 4, "weapons/hookbomb_fire.wav", 0);

	gren = CSQCProjectile(TRUE, PROJECTILE_HOOKBOMB, TRUE);
	gren.owner = self;
	gren.classname = "hookbomb";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = g_balance_hook_secondary_damage;
	gren.movetype = MOVETYPE_TOSS;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_HOOK | HITTYPE_SECONDARY;
	setorigin(gren, w_shotorg);

	gren.nextthink = time + g_balance_hook_secondary_lifetime;
	gren.think = adaptor_think2use;
	gren.use = W_Hook_Explode2;
	gren.touch = W_Hook_Touch2;

	gren.velocity = '0 0 1' * g_balance_hook_secondary_speed;
	if(g_projectiles_newton_style)
		gren.velocity = gren.velocity + self.velocity;

	gren.gravity = g_balance_hook_secondary_gravity;
	W_SetupProjectileVelocity(gren);

	gren.angles = '0 0 0';
}

void spawnfunc_weapon_hook (void)
{
	if(g_grappling_hook) // offhand hook
	{
		item_start_failed = TRUE;
		remove(self);
		return;
	}
	weapon_defaultspawnfunc(WEP_HOOK);
}

float w_hook(float req)
{
	if (req == WR_AIM)
	{
		// ... sorry ...
	}
	else if (req == WR_THINK)
	{
		float button_hook = self.BUTTON_HOOK;
		if (self.BUTTON_ATCK || (!(self.items & IT_JETPACK) && button_hook))
		{
			if(!self.hook)
			if not(self.hook_state & HOOK_WAITING_FOR_RELEASE)
			if not(self.hook_state & HOOK_FIRING)
			if (time > self.hook_refire)
			if (weapon_prepareattack(0, -1))
			{
				if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
					self.ammo_cells = self.ammo_cells - g_balance_hook_primary_fuel;
				self.hook_state |= HOOK_FIRING;
				weapon_thinkf(WFRAME_FIRE1, g_balance_hook_primary_animtime, w_ready);
			}
		}

		if (self.BUTTON_ATCK2)
		{
			if (weapon_prepareattack(1, g_balance_hook_secondary_refire))
			{
				W_Hook_Attack2();
				weapon_thinkf(WFRAME_FIRE2, g_balance_hook_secondary_animtime, w_ready);
			}
		}

		if(self.hook)
		{
			// if hooked, no bombs, and increase the timer
			self.hook_refire = max(self.hook_refire, time + g_balance_hook_primary_refire);

			// hook also inhibits health regeneration, but only for 1 second
			if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
				self.pauseregen_finished = max(self.pauseregen_finished, time + g_balance_pause_fuel_regen);
		}

		if(self.hook && self.hook.state == 1)
		{
			if (g_balance_hook_primary_hooked_time_max > 0)
			{
				if ( time > self.hook_time_hooked + g_balance_hook_primary_hooked_time_max )
					self.hook_state |= HOOK_REMOVING;
			}
			if (g_balance_hook_primary_hooked_fuel > 0)
			{
				if ( time > self.hook_time_fueldecrease )
				{
					if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
					{
						if ( self.ammo_cells >= (time - self.hook_time_fueldecrease) * g_balance_hook_primary_hooked_fuel )
						{
							self.ammo_cells -= (time - self.hook_time_fueldecrease) * g_balance_hook_primary_hooked_fuel;
							self.hook_time_fueldecrease = time;
							// decrease next frame again
						}
						else
						{
							self.ammo_cells = 0;
							self.hook_state |= HOOK_REMOVING;
							W_SwitchWeapon_Force(self, w_getbestweapon(self));
						}
					}
				}
			}
		}
		else
		{
			self.hook_time_hooked = time;
			self.hook_time_fueldecrease = time + g_balance_hook_primary_hooked_time_free;
		}

		if (self.BUTTON_CROUCH)
		{
			self.hook_state &~= HOOK_PULLING;
			if (self.BUTTON_ATCK || (!(self.items & IT_JETPACK) && button_hook))
				self.hook_state &~= HOOK_RELEASING;
			else
				self.hook_state |= HOOK_RELEASING;
		}
		else
		{
			self.hook_state |= HOOK_PULLING;
			self.hook_state &~= HOOK_RELEASING;

			if (self.BUTTON_ATCK || (!(self.items & IT_JETPACK) && button_hook))
			{
				// already fired
				if(self.hook)
					self.hook_state |= HOOK_WAITING_FOR_RELEASE;
			}
			else
			{
				self.hook_state |= HOOK_REMOVING;
				self.hook_state &~= HOOK_WAITING_FOR_RELEASE;
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/hook_impact.wav"); // done by g_hook.qc
		precache_sound ("weapons/hook_fire.wav");
		precache_sound ("weapons/hookbomb_fire.wav");
		hook_init(TRUE);
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_HOOK);
		self.hook_state &~= HOOK_WAITING_FOR_RELEASE;
	}
	else if (req == WR_CHECKAMMO1)
	{
		if(self.hook)
			return self.ammo_cells > 0;
		else
			return self.ammo_cells >= g_balance_hook_primary_fuel;
	}
	else if (req == WR_CHECKAMMO2)
	{
		return self.ammo_cells >= g_balance_hook_secondary_ammo;
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE) {
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "has run into #'s gravity bomb";
		else {
			w_deathtypestring = "was hooked by";
			w_fragprefix = "^xF44HOOK";
		}
	} else if (req == WR_RESETPLAYER)
	{
		self.hook_refire = time;
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_hook_primary_animtime);
		CACHE_CVAR(g_balance_hook_primary_fuel);
		CACHE_CVAR(g_balance_hook_primary_hooked_fuel);
		CACHE_CVAR(g_balance_hook_primary_hooked_time_free);
		CACHE_CVAR(g_balance_hook_primary_hooked_time_max);
		CACHE_CVAR(g_balance_hook_primary_refire);
		CACHE_CVAR(g_balance_hook_secondary_ammo);
		CACHE_CVAR(g_balance_hook_secondary_animtime);
		CACHE_CVAR(g_balance_hook_secondary_damage);
		CACHE_CVAR(g_balance_hook_secondary_duration);
		CACHE_CVAR(g_balance_hook_secondary_edgedamage);
		CACHE_CVAR(g_balance_hook_secondary_force);
		CACHE_CVAR(g_balance_hook_secondary_gravity);
		CACHE_CVAR(g_balance_hook_secondary_lifetime);
		CACHE_CVAR(g_balance_hook_secondary_power);
		CACHE_CVAR(g_balance_hook_secondary_radius);
		CACHE_CVAR(g_balance_hook_secondary_refire);
		CACHE_CVAR(g_balance_hook_secondary_speed);
		CSQCProjectile_Init(PROJECTILE_HOOKBOMB);
	}
	return TRUE;
};
