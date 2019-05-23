float g_balance_fireball_primary_ammo;
float g_balance_fireball_primary_animtime;
float g_balance_fireball_primary_damage;
float g_balance_fireball_primary_damageforcescale;
float g_balance_fireball_primary_damagetime;
float g_balance_fireball_primary_laserburntime;
float g_balance_fireball_primary_laserdamage;
float g_balance_fireball_primary_laseredgedamage;
float g_balance_fireball_primary_laserradius;
float g_balance_fireball_primary_lifetime;
float g_balance_fireball_primary_refire;
float g_balance_fireball_primary_speed;
float g_balance_fireball_primary_speed_up;
float g_balance_fireball_secondary_ammo;
float g_balance_fireball_secondary_animtime;
float g_balance_fireball_secondary_bfgdamage;
float g_balance_fireball_secondary_bfgforce;
float g_balance_fireball_secondary_bfgradius;
float g_balance_fireball_secondary_damage;
float g_balance_fireball_secondary_damageforcescale;
float g_balance_fireball_secondary_edgedamage;
float g_balance_fireball_secondary_force;
float g_balance_fireball_secondary_health;
float g_balance_fireball_secondary_laserburntime;
float g_balance_fireball_secondary_laserdamage;
float g_balance_fireball_secondary_laseredgedamage;
float g_balance_fireball_secondary_laserradius;
float g_balance_fireball_secondary_lifetime;
float g_balance_fireball_secondary_radius;
float g_balance_fireball_secondary_refire;
float g_balance_fireball_secondary_refire2;
float g_balance_fireball_secondary_speed;

.float bot_secondary_fireballmooth; // whatever a mooth is
.vector fireball_impactvec;
.float fireball_secondarytime;
var .float fireball_buttonatck1 = BUTTON_ATCK;
var .float fireball_buttonatck2 = BUTTON_ATCK2;

void W_Fireball_Explode (void)
{
	entity e;
	float dist;
	float points;
	vector dir;
	float d;

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	// 1. dist damage
	d = (self.owner.health + self.owner.armorvalue);
	damage_radius (self, self.realowner, g_balance_fireball_secondary_damage, g_balance_fireball_secondary_edgedamage, g_balance_fireball_secondary_radius, world, g_balance_fireball_secondary_force, self.projectiledeathtype, other);
	if(self.realowner.health + self.realowner.armorvalue >= d)
	if(!self.cnt)
	{
		modeleffect_spawn("models/sphere/sphere.md3", 0, 0, self.origin, '0 0 0', '0 0 0', '0 0 0', 0, g_balance_fireball_secondary_bfgradius, 0.2, 0.05, 0.25);

		// 2. bfg effect
		for(e = findradius(self.origin, g_balance_fireball_secondary_bfgradius); e; e = e.chain)
		if(e != self.owner) if(e.takedamage == DAMAGE_AIM) if(e.classname != "player" || !self.owner || teams_is_different(e, self))
		{
			// can we see fireball?
			traceline(e.origin + e.view_ofs, self.origin, MOVE_NORMAL, e);
			if(/* trace_startsolid || */ trace_fraction != 1) // startsolid should be never happening anyway
				continue;
			// can we see player who shot fireball?
			traceline(e.origin + e.view_ofs, self.realowner.origin + self.realowner.view_ofs, MOVE_NORMAL, e);
			if(trace_ent != self.realowner)
			if(/* trace_startsolid || */ trace_fraction != 1)
				continue;
			dist = vlen(self.origin - e.origin - e.view_ofs);
			points = (1 - sqrt(dist / g_balance_fireball_secondary_bfgradius));
			if(points <= 0)
				continue;
			dir = normalize(e.origin + e.view_ofs - self.origin);
			damage(e, self, self.realowner, g_balance_fireball_secondary_bfgdamage * points, self.projectiledeathtype | HITTYPE_BOUNCE | HITTYPE_SPLASH, e.origin + e.view_ofs, g_balance_fireball_secondary_bfgforce * dir);
			pointparticles(particleeffectnum("fireball_bfgdamage"), e.origin, -1 * dir, 1);
		}
	}

	remove (self);
}

void W_Fireball_TouchExplode (void)
{
	PROJECTILE_TOUCH;
	W_Fireball_Explode ();
}

void W_Fireball_LaserPlay(float dt, float dist, float _damage, float edgedamage, float burntime)
{
	entity e;
	float d;
	vector p;

	random_selection_init();
	for(e = findradius(self.origin, dist); e; e = e.chain)
	if(e != self.owner) if(e.takedamage == DAMAGE_AIM) if(e.classname != "player" || !self.owner || teams_is_different(e, self))
	{
		p = e.origin;
		p_x += e.mins_x + random() * (e.maxs_x - e.mins_x);
		p_y += e.mins_y + random() * (e.maxs_y - e.mins_y);
		p_z += e.mins_z + random() * (e.maxs_z - e.mins_z);
		d = vlen(self.origin - p);
		if(d < dist)
		{
			traceline(p, self.origin, MOVE_NORMAL, e);
			if(/* trace_startsolid || */ trace_fraction != 1)
				continue;
			e.fireball_impactvec = p;
			random_selection_add(e, 0, string_null, 1 / (1 + d), !fire_is_burning(e));
		}
	}
	if(random_selection_chosen_ent)
	{
		d = vlen(self.origin - random_selection_chosen_ent.fireball_impactvec);
		d = _damage + (edgedamage - _damage) * (d / dist);
		fire_add_damage(random_selection_chosen_ent, self.realowner, d * burntime, burntime, self.projectiledeathtype | HITTYPE_BOUNCE);
		//trailparticles(self, particleeffectnum("fireball_laser"), self.origin, random_selection_chosen_ent.fireball_impactvec);
		pointparticles(particleeffectnum("fireball_laser"), self.origin, random_selection_chosen_ent.fireball_impactvec - self.origin, 1);
	}
}

void W_Fireball_Think()
{
	if(time > self.pushltime)
	{
		self.cnt = 1;
		W_Fireball_Explode();
		return;
	}

	W_Fireball_LaserPlay(0.1, g_balance_fireball_secondary_laserradius, g_balance_fireball_secondary_laserdamage, g_balance_fireball_secondary_laseredgedamage, g_balance_fireball_secondary_laserburntime);

	self.nextthink = time + 0.1;
}

void W_Fireball_Damage (entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force)
{
	if(self.health <= 0)
		return;
	self.health = self.health - _damage;
	if (self.health <= 0)
	{
		self.cnt = 1;
		damage_prepare_explosion(attacker, W_Fireball_Explode);
	}
}

void W_Fireball_Attack2()
{
	local entity proj;

	weapon_setup_shot(self, 2, "weapons/fireball_fire2.wav", 1);

	pointparticles(particleeffectnum("fireball_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);

	proj = projectile(TRUE, PROJECTILE_FIREBALL, TRUE, self);
	proj.classname = "plasma_prim";
	proj.realowner = proj.owner;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = g_balance_fireball_secondary_damage;
	proj.pushltime = time + g_balance_fireball_secondary_lifetime;
	proj.use = W_Fireball_Explode;
	proj.think = W_Fireball_Think;
	proj.nextthink = time;
	proj.health = g_balance_fireball_secondary_health;
	proj.team = self.team;
	proj.event_damage = W_Fireball_Damage;
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = g_balance_fireball_secondary_damageforcescale;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_FIREBALL | HITTYPE_SECONDARY;
	setorigin(proj, w_shotorg);

	proj.movetype = MOVETYPE_FLY;
	proj.velocity = w_shotdir * g_balance_fireball_secondary_speed;
	weapon_setup_projectile_velocity(proj);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Fireball_TouchExplode;
}

void W_Fireball_AttackEffect(float i, vector f_diff)
{
	weapon_setup_shot(self, 0, "", 0);
	w_shotorg += f_diff_x * v_up + f_diff_y * v_right;
	pointparticles(particleeffectnum("fireball_preattack_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);
}

void W_Fireball_Attack2_Frame4()
{
	W_Fireball_Attack2();
	weapon_thinkf(WFRAME_FIRE1, g_balance_fireball_secondary_animtime, weapon_ready);
}

void W_Fireball_Attack2_Frame3()
{
	W_Fireball_AttackEffect(0, '+1.25 +3.75 0');
	weapon_thinkf(WFRAME_FIRE1, g_balance_fireball_secondary_animtime, W_Fireball_Attack2_Frame4);
}

void W_Fireball_Attack2_Frame2()
{
	W_Fireball_AttackEffect(0, '-1.25 +3.75 0');
	weapon_thinkf(WFRAME_FIRE1, g_balance_fireball_secondary_animtime, W_Fireball_Attack2_Frame3);
}

void W_Fireball_Attack2_Frame1()
{
	W_Fireball_AttackEffect(1, '+1.25 -3.75 0');
	weapon_thinkf(WFRAME_FIRE1, g_balance_fireball_secondary_animtime, W_Fireball_Attack2_Frame2);
}

void W_Fireball_Attack2_Frame0()
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_fireball_secondary_ammo;

	W_Fireball_AttackEffect(0, '-1.25 -3.75 0');
	sound (self, CHAN_WEAPON, "weapons/fireball_prefire2.wav", VOL_BASE, ATTN_NORM);
	weapon_thinkf(WFRAME_FIRE1, g_balance_fireball_secondary_animtime, W_Fireball_Attack2_Frame1);
}

void W_Firemine_Think()
{
	if(time > self.pushltime)
	{
		remove(self);
		return;
	}
	if (self.waterlevel > 0) {
		remove(self);
		return;
	}

	// make it "hot" once it leaves its owner
	if(self.owner)
	{
		if(vlen(self.origin - self.owner.origin - self.owner.view_ofs) > g_balance_fireball_primary_laserradius)
		{
			self.cnt += 1;
			if(self.cnt == 3)
				self.owner = world;
		}
		else
			self.cnt = 0;
	}

	W_Fireball_LaserPlay(0.1, g_balance_fireball_primary_laserradius, g_balance_fireball_primary_laserdamage, g_balance_fireball_primary_laseredgedamage, g_balance_fireball_primary_laserburntime);

	self.nextthink = time + 0.1;
}

void W_Firemine_Touch (void)
{
	PROJECTILE_TOUCH;
	if not(self.dmg)
		damage_record_hits(self.realowner, other, self.projectiledeathtype, 1, g_balance_fireball_primary_damage);

	if (other.takedamage == DAMAGE_AIM)
	if(fire_add_damage(other, self.realowner, g_balance_fireball_primary_damage, g_balance_fireball_primary_damagetime, self.projectiledeathtype | HITTYPE_HEADSHOT) >= 0)
	{
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void W_Fireball_Attack1()
{
	local entity proj;
	vector f_diff;
	float c;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_fireball_primary_ammo;

	c = mod(self.bulletcounter, 4);
	switch(c)
	{
		case 0:
			f_diff = '-1.25 -3.75 0';
			break;
		case 1:
			f_diff = '+1.25 -3.75 0';
			break;
		case 2:
			f_diff = '-1.25 +3.75 0';
			break;
		case 3:
		default:
			f_diff = '+1.25 +3.75 0';
			break;
	}
	weapon_setup_shot(self, 2, "weapons/fireball_fire.wav", 1);
	traceline(w_shotorg, w_shotorg + f_diff_x * v_up + f_diff_y * v_right, MOVE_NORMAL, self);
	w_shotorg = trace_endpos;

	pointparticles(particleeffectnum("fireball_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, 1);

	proj = projectile(TRUE, PROJECTILE_FIREMINE, TRUE, self);
	proj.gravity = 1;
	proj.realowner = proj.owner;
	proj.classname = "grenade";
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = g_balance_fireball_primary_damage;
	proj.movetype = MOVETYPE_BOUNCE;
	proj.projectiledeathtype = WEP_FIREBALL;
	proj.touch = W_Firemine_Touch;
	PROJECTILE_MAKETRIGGER(proj);
	setorigin(proj, w_shotorg);
	proj.think = W_Firemine_Think;
	proj.nextthink = time;
	proj.damageforcescale = g_balance_fireball_primary_damageforcescale;
	proj.velocity = w_shotdir * g_balance_fireball_primary_speed + v_up * g_balance_fireball_primary_speed_up;
	proj.pushltime = time + g_balance_fireball_primary_lifetime;
	weapon_setup_projectile_velocity(proj);

	proj.angles = vectoangles(proj.velocity);
}

void spawnfunc_weapon_fireball (void)
{
	weapon_defaultspawnfunc(WEP_FIREBALL);
}

float w_fireball(float req)
{
	if (req == WR_AIM)
	{
		self.fireball_buttonatck1 = FALSE;
		self.fireball_buttonatck2 = FALSE;
		if (self.bot_secondary_fireballmooth == 0)
		{
			if(bot_aim(g_balance_fireball_primary_speed, g_balance_fireball_primary_speed_up, g_balance_fireball_primary_lifetime, TRUE))
			{
				self.fireball_buttonatck1 = TRUE;
				if(random() < 0.01) self.bot_secondary_fireballmooth = 1;
			}
		}
		else
		{
			if(bot_aim(g_balance_fireball_secondary_speed, 0, g_balance_fireball_secondary_lifetime, FALSE))
			{
				self.fireball_buttonatck2 = TRUE;
				if(random() < 0.02) self.bot_secondary_fireballmooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if (self.fireball_buttonatck1)
		if (weapon_prepareattack(0, g_balance_fireball_primary_refire))
		{
			W_Fireball_Attack1();
			weapon_thinkf(WFRAME_FIRE2, g_balance_fireball_primary_animtime, weapon_ready);
		}
		if (self.fireball_buttonatck2)
		if (time >= self.fireball_secondarytime)
		if (weapon_prepareattack(1, g_balance_fireball_secondary_refire))
		{
			W_Fireball_Attack2_Frame0();
			self.fireball_secondarytime = time + g_balance_fireball_secondary_refire2;
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/sphere/sphere.md3");
		precache_sound ("weapons/fireball_fire.wav");
		precache_sound ("weapons/fireball_fire2.wav");
		precache_sound ("weapons/fireball_prefire2.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_FIREBALL);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_rockets >= g_balance_fireball_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_rockets >= g_balance_fireball_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "should have used a smaller gun";
		else
			w_deathtypestring = "forgot about some firemine";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				if(w_deathtype & HITTYPE_SPLASH) // BFG effect
				{
					w_deathtypestring = "could not hide from #'s fireball";
				}
				else // laser
				{
					w_deathtypestring = "saw the pretty lights of #'s fireball";
				}
			}
			else if(w_deathtype & HITTYPE_SPLASH)
				w_deathtypestring = "got too close to #'s fireball";
			else
				w_deathtypestring = "tasted #'s fireball";
		}
		else
		{
			if(w_deathtype & HITTYPE_HEADSHOT)
				w_deathtypestring = "tried to catch #'s firemine";
			else
				w_deathtypestring = "fatefully ignored #'s firemine";
		}
	}
	else if (req == WR_RESETPLAYER)
	{
		self.fireball_secondarytime = time;
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_fireball_primary_ammo);
		CACHE_CVAR(g_balance_fireball_primary_animtime);
		CACHE_CVAR(g_balance_fireball_primary_damage);
		CACHE_CVAR(g_balance_fireball_primary_damageforcescale);
		CACHE_CVAR(g_balance_fireball_primary_damagetime);
		CACHE_CVAR(g_balance_fireball_primary_laserburntime);
		CACHE_CVAR(g_balance_fireball_primary_laserdamage);
		CACHE_CVAR(g_balance_fireball_primary_laseredgedamage);
		CACHE_CVAR(g_balance_fireball_primary_laserradius);
		CACHE_CVAR(g_balance_fireball_primary_lifetime);
		CACHE_CVAR(g_balance_fireball_primary_refire);
		CACHE_CVAR(g_balance_fireball_primary_speed);
		CACHE_CVAR(g_balance_fireball_primary_speed_up);
		CACHE_CVAR(g_balance_fireball_secondary_ammo);
		CACHE_CVAR(g_balance_fireball_secondary_animtime);
		CACHE_CVAR(g_balance_fireball_secondary_bfgdamage);
		CACHE_CVAR(g_balance_fireball_secondary_bfgforce);
		CACHE_CVAR(g_balance_fireball_secondary_bfgradius);
		CACHE_CVAR(g_balance_fireball_secondary_damage);
		CACHE_CVAR(g_balance_fireball_secondary_damageforcescale);
		CACHE_CVAR(g_balance_fireball_secondary_edgedamage);
		CACHE_CVAR(g_balance_fireball_secondary_force);
		CACHE_CVAR(g_balance_fireball_secondary_health);
		CACHE_CVAR(g_balance_fireball_secondary_laserburntime);
		CACHE_CVAR(g_balance_fireball_secondary_laserdamage);
		CACHE_CVAR(g_balance_fireball_secondary_laseredgedamage);
		CACHE_CVAR(g_balance_fireball_secondary_laserradius);
		CACHE_CVAR(g_balance_fireball_secondary_lifetime);
		CACHE_CVAR(g_balance_fireball_secondary_radius);
		CACHE_CVAR(g_balance_fireball_secondary_refire);
		CACHE_CVAR(g_balance_fireball_secondary_refire2);
		CACHE_CVAR(g_balance_fireball_secondary_speed);
		projectile_init(PROJECTILE_FIREMINE);
		projectile_init(PROJECTILE_FIREBALL);
		if (cvar("g_balance_fireball_swap_buttons")) {
			fireball_buttonatck1 = BUTTON_ATCK2;
			fireball_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
};
