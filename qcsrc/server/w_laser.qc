void(float imp) W_SwitchWeapon;

void W_Laser_Touch (void)
{
	PROJECTILE_TOUCH;

	self.event_damage = SUB_Null;
	if (self.dmg)
		RadiusDamage (self, self.owner, cvar("g_balance_laser_secondary_damage"), cvar("g_balance_laser_secondary_edgedamage"), cvar("g_balance_laser_secondary_radius"), world, cvar("g_balance_laser_secondary_force"), self.projectiledeathtype, other);
	else
		RadiusDamage (self, self.owner, cvar("g_balance_laser_primary_damage"), cvar("g_balance_laser_primary_edgedamage"), cvar("g_balance_laser_primary_radius"), world, cvar("g_balance_laser_primary_force"), self.projectiledeathtype, other);

	remove (self);
}

.float melee_damage;
.float melee_force;
.float melee_distance;
.float melee_time;
.float melee_lastthink;
.float melee_startthink;
.float melee_ticrate;
.float melee_secondary;

void W_Laser_Attack_Gauntlet_Think()
{
	float melee_frame;
	melee_frame = min(time - self.melee_lastthink, self.melee_startthink + self.melee_time - time);
	if (melee_frame < 0)
	{
		remove(self);
		return;
	}
	float damage_factor = melee_frame / self.melee_time;
	float frame_damage = self.melee_damage * damage_factor;
	float frame_force = self.melee_force * damage_factor;
	makevectors(self.owner.angles);
	W_SetupShot(self.owner, FALSE, 0, "", self.melee_damage);
	traceline(w_shotorg - (w_shotdir * 20), w_shotorg + w_shotdir * self.melee_distance, MOVE_NORMAL, self);
	if (trace_fraction < 1)
	if (trace_ent)
	if (trace_ent.takedamage)
		Damage (trace_ent, self.owner, self.owner, frame_damage,
				WEP_LASER | (self.melee_secondary ? HITTYPE_SECONDARY : 0), trace_endpos, w_shotdir * frame_force);
	self.melee_lastthink = time;
	self.nextthink = time + self.melee_ticrate;
}

void W_Laser_Attack_Gauntlet (float issecondary)
{
	sound (self, CHAN_WEAPON, cvar_string("sv_sound_laser_gauntlet"), VOL_BASE, ATTN_NORM);
	entity melee = spawn();
	melee.owner = self;
	melee.think = W_Laser_Attack_Gauntlet_Think;
	melee.melee_secondary = issecondary;
	if (issecondary)
	{
		melee.nextthink = time + cvar("g_balance_laser_secondary_gauntlet_delay");
		melee.melee_damage = cvar("g_balance_laser_secondary_damage");
		melee.melee_force = cvar("g_balance_laser_secondary_force");
		melee.melee_distance = cvar("g_balance_laser_secondary_radius");
		melee.melee_time = cvar("g_balance_laser_secondary_gauntlet_time");
		melee.melee_ticrate = cvar("g_balance_laser_secondary_gauntlet_ticrate");
	}
	else
	{
		melee.nextthink = time + cvar("g_balance_laser_primary_gauntlet_delay");
		melee.melee_damage = cvar("g_balance_laser_primary_damage");
		melee.melee_force = cvar("g_balance_laser_primary_force");
		melee.melee_distance = cvar("g_balance_laser_primary_radius");
		melee.melee_time = cvar("g_balance_laser_primary_gauntlet_time");
		melee.melee_ticrate = cvar("g_balance_laser_primary_gauntlet_ticrate");
	}
	melee.melee_startthink = melee.nextthink;
	melee.melee_lastthink = melee.nextthink;
	melee.nextthink += melee.melee_ticrate; //avoid frame with zero melee_frame
}

void W_Laser_Attack (float issecondary)
{
	float ismelee = (issecondary ? cvar("g_balance_laser_secondary_gauntlet") : cvar("g_balance_laser_primary_gauntlet"));
	if (ismelee)
	{
		W_Laser_Attack_Gauntlet(issecondary);
		return;
	}
	local entity missile;
	vector s_forward;
	float a;

	if (issecondary)
		a = cvar("g_balance_laser_secondary_shotangle");
	else
		a = cvar("g_balance_laser_primary_shotangle");
	s_forward = v_forward * cos(a * DEG2RAD) + v_up * sin(a * DEG2RAD);

	if(issecondary)
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", cvar("g_balance_laser_secondary_damage"));
	else
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", cvar("g_balance_laser_primary_damage"));
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = self;
	missile.classname = "laserbolt";
	missile.dmg = issecondary;
	missile.bot_dodge = TRUE;
	if (issecondary)
		missile.bot_dodgerating = cvar("g_balance_laser_secondary_damage");
	else
		missile.bot_dodgerating = cvar("g_balance_laser_primary_damage");

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_LASER;
	if(issecondary)
		missile.projectiledeathtype |= HITTYPE_SECONDARY;

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	if (issecondary)
		missile.velocity = w_shotdir * cvar("g_balance_laser_secondary_speed");
	else
		missile.velocity = w_shotdir * cvar("g_balance_laser_primary_speed");
	W_SetupProjectileVelocity(missile);
	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = W_Laser_Touch;
	missile.think = SUB_Remove;
	if (issecondary)
		missile.nextthink = time + cvar("g_balance_laser_secondary_lifetime");
	else
		missile.nextthink = time + cvar("g_balance_laser_primary_lifetime");

	missile.flags = FL_PROJECTILE;

	CSQCProjectile(missile, TRUE, PROJECTILE_LASER, TRUE);
}

void spawnfunc_weapon_laser (void)
{
	weapon_defaultspawnfunc(WEP_LASER);
}

float w_laser(float req)
{
	local float r1;
	local float r2;
	if (req == WR_AIM)
	{
		if(cvar("g_balance_laser_secondary"))
		{
			r1 = cvar("g_balance_laser_primary_damage");
			r2 = cvar("g_balance_laser_secondary_damage");
			if (random() * (r2 + r1) > r1)
				self.BUTTON_ATCK2 = bot_aim(cvar("g_balance_laser_secondary_speed"), 0, cvar("g_balance_laser_secondary_lifetime"), FALSE);
			else
				self.BUTTON_ATCK = bot_aim(cvar("g_balance_laser_primary_speed"), 0, cvar("g_balance_laser_primary_lifetime"), FALSE);
		}
		else
			self.BUTTON_ATCK = bot_aim(cvar("g_balance_laser_primary_speed"), 0, cvar("g_balance_laser_primary_lifetime"), FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, cvar("g_balance_laser_primary_refire")))
		{
			W_Laser_Attack(FALSE);
			weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_laser_primary_animtime"), w_ready);
		}
		if (self.BUTTON_ATCK2)
		{
			if(cvar("g_balance_laser_secondary"))
			{
				if (weapon_prepareattack(0, cvar("g_balance_laser_secondary_refire")))
				{
					W_Laser_Attack(TRUE);
					weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_laser_secondary_animtime"), w_ready);
				}
			}
			else
			{
				if(self.switchweapon == WEP_LASER) // don't do this if already switching
					W_SwitchWeapon (self.cnt);
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/lasergun_fire.wav");
		precache_sound (cvar_string("sv_sound_laser_gauntlet"));
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_LASER);
	else if (req == WR_CHECKAMMO1)
		return TRUE;
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "lasered himself to hell";
	else if (req == WR_RELOAD)
	{
		if (cvar("g_balance_laser_secondary_gauntlet"))
		{
			W_Laser_Attack_Gauntlet(TRUE);
			weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_laser_secondary_animtime"), w_ready);
		}

	}
	else if (req == WR_KILLMESSAGE)
	{
		if (((w_deathtype & HITTYPE_SECONDARY) ? cvar("g_balance_laser_secondary_gauntlet") : cvar("g_balance_laser_primary_gauntlet")))
			w_deathtypestring = "was smashed to death by"; // unchecked: SPLASH
		else
			w_deathtypestring = "was lasered to death by"; // unchecked: SPLASH
	}
	return TRUE;
};
