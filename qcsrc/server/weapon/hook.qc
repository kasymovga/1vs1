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

.float hook_refire;
.float hook_time_hooked;
.float hook_time_fueldecrease;

void weapon_hook_explode_think (void)
{
	float dt, dmg_remaining_next, f;

	dt = time - self.teleport_time;
	dmg_remaining_next = pow(bound(0, 1 - dt / g_balance_hook_secondary_duration, 1), g_balance_hook_secondary_power);

	f = self.cnt - dmg_remaining_next;
	self.cnt = dmg_remaining_next;
	damage_record_fires(self.owner, WEP_HOOK, 1);
	damage_radius(self, self.owner, self.dmg * f, self.dmg_edge * f, self.dmg_radius, self.owner, self.dmg_force * f, self.projectiledeathtype, world);
	self.projectiledeathtype |= HITTYPE_NOINFO;
	if(dt < g_balance_hook_secondary_duration)
		self.nextthink = time + 0.05; // soon
	else
		remove(self);
}

void weapon_hook_explode2 (void) {
	self.event_damage = stdproc_nothing;
	self.touch = stdproc_nothing;
	self.effects |= EF_NODRAW;
	self.projectiledeathtype |= HITTYPE_NOTEAMDAMAGE;
	self.think = weapon_hook_explode_think;
	self.nextthink = time;
	self.teleport_time = time;
	self.cnt = 1;
	self.movetype = MOVETYPE_NONE;
}

void weapon_hook_touch2 (void)
{
	PROJECTILE_TOUCH;
	self.use();
}

void(void) weapon_hook_attack2 {
	entity gren;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_hook_secondary_ammo;

	weapon_setup_shot (self, 4, "weapons/hookbomb_fire.wav", 0);
	gren = projectile(TRUE, PROJECTILE_HOOKBOMB, TRUE, self);
	projectile_setup(gren, weapon_shotorg, WEP_HOOK | HITTYPE_SECONDARY, g_balance_hook_secondary_damage,
			g_balance_hook_secondary_edgedamage, g_balance_hook_secondary_radius, g_balance_hook_secondary_force);

	gren.movetype = MOVETYPE_TOSS;
	gren.nextthink = time + g_balance_hook_secondary_lifetime;
	gren.think = projectile_think2use;
	gren.use = weapon_hook_explode2;
	gren.touch = weapon_hook_touch2;
	gren.velocity = '0 0 1' * g_balance_hook_secondary_speed;
	gren.gravity = g_balance_hook_secondary_gravity;
	weapon_setup_projectile_velocity(gren);
}

void spawnfunc_weapon_hook (void) {
	weapon_defaultspawnfunc(WEP_HOOK);
}

float weapon_hook(float req)
{
	if (req == WR_AIM)
	{
		// ... sorry ...
	}
	else if (req == WR_THINK)
	{
		float button_hook = self.BUTTON_HOOK;
		if (self.BUTTON_ATCK || button_hook)
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
				weapon_thinkf(WFRAME_FIRE1, g_balance_hook_primary_animtime, weapon_ready);
			}
		}

		if (self.BUTTON_ATCK2)
		{
			if (weapon_prepareattack(1, g_balance_hook_secondary_refire))
			{
				weapon_hook_attack2();
				weapon_thinkf(WFRAME_FIRE2, g_balance_hook_secondary_animtime, weapon_ready);
			}
		}

		if(self.hook) // if hooked, no bombs, and increase the timer
			self.hook_refire = max(self.hook_refire, time + g_balance_hook_primary_refire);

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
							weapon_switch_force(self, weapon_best(self));
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
			if (self.BUTTON_ATCK || button_hook)
				self.hook_state &~= HOOK_RELEASING;
			else
				self.hook_state |= HOOK_RELEASING;
		}
		else
		{
			self.hook_state |= HOOK_PULLING;
			self.hook_state &~= HOOK_RELEASING;

			if (self.BUTTON_ATCK || button_hook)
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
		weapon_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE) {
		if(weapon_deathtype & HITTYPE_SECONDARY)
			weapon_deathtypestring = "has run into #'s gravity bomb";
		else {
			weapon_deathtypestring = "was hooked by";
			weapon_fragprefix = "^xF44HOOK";
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
		projectile_init(PROJECTILE_HOOKBOMB);
	}
	return TRUE;
}
