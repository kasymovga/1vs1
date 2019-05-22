float g_balance_supershotgun_primary_ammo;
float g_balance_supershotgun_primary_animtime;
float g_balance_supershotgun_primary_ballistic;
float g_balance_supershotgun_primary_bounces;
float g_balance_supershotgun_primary_bulletconstant;
float g_balance_supershotgun_primary_bullets;
float g_balance_supershotgun_primary_damage;
float g_balance_supershotgun_primary_force;
float g_balance_supershotgun_primary_gravityfactor;
float g_balance_supershotgun_primary_refire;
float g_balance_supershotgun_primary_speed;
float g_balance_supershotgun_primary_spread;
float g_balance_supershotgun_secondary;
float g_balance_supershotgun_secondary_ammo;
float g_balance_supershotgun_secondary_animtime;
float g_balance_supershotgun_secondary_ballistic;
float g_balance_supershotgun_secondary_bounces;
float g_balance_supershotgun_secondary_bulletconstant;
float g_balance_supershotgun_secondary_bullets;
float g_balance_supershotgun_secondary_damage;
float g_balance_supershotgun_secondary_force;
float g_balance_supershotgun_secondary_gravityfactor;
float g_balance_supershotgun_secondary_refire;
float g_balance_supershotgun_secondary_speed;
float g_balance_supershotgun_secondary_spread;

void spawnfunc_weapon_supershotgun(); // defined in t_items.qc

void W_Supershotgun_Pellet_Touch()
{
	PROJECTILE_TOUCH;
	if(other.solid == SOLID_BSP)
		damage_info(self.origin, self.dmg, 0, 0, normalize(self.velocity), self.projectiledeathtype, self);
	if (other && other.takedamage)
	{
		entity o = self.realowner;
		damage_record_hits(o, other, WEP_SUPERSHOTGUN, 1, self.dmg);
		damage(other, self, o, self.dmg, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity));
		self.cnt = 0;
	}
	if not(self.cnt)
	{
		remove(self);
		return;
	}
	self.cnt = self.cnt - 1;
	self.angles = vectoangles(self.velocity);
	self.owner = world;
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void W_Supershotgun_Pellet(vector start, vector dir, float spread, float pSpeed, float _damage, float force, float dtype, float gravityfactor, float bounces)
{
	entity proj;
	proj = CSQCProjectile(TRUE, PROJECTILE_BULLET_BIG, TRUE);
	proj.classname = "bullet";
	proj.realowner = proj.owner = Akimbo_Owner(self);
	PROJECTILE_MAKETRIGGER(proj);
	proj.movetype = (gravityfactor ? MOVETYPE_BOUNCE : MOVETYPE_BOUNCEMISSILE);
	proj.gravity = gravityfactor;
	proj.think = SUB_Remove;
	proj.nextthink = time + 10;
	proj.velocity = normalize(dir + randomvec() * spread) * pSpeed;
	weapon_setup_projectile_velocity(proj);
	proj.angles = vectoangles(proj.velocity);
	setorigin(proj, start);
	proj.touch = W_Supershotgun_Pellet_Touch;
	proj.dmg = _damage;
	proj.dmg_force = force;
	proj.projectiledeathtype = dtype;
	proj.oldvelocity = proj.velocity;
	proj.cnt = bounces;
}

void W_Supershotgun_Attack(float secondary, float barrels, float ballistic)
{
	float a, b, f, d, s, spread, g, bc, dtype;
	float	sc;
	local entity flash;
	float hor_spread, hor_shift;
	vector shotdir_shifted;
	float bounces;

	if (secondary)
	{
		a = g_balance_supershotgun_secondary_ammo;
		f = g_balance_supershotgun_secondary_force;
		d = g_balance_supershotgun_secondary_damage;
		s = g_balance_supershotgun_secondary_speed;
		b = g_balance_supershotgun_secondary_bullets;
		bc = g_balance_supershotgun_secondary_bulletconstant;
		spread = g_balance_supershotgun_secondary_spread;
		g = g_balance_supershotgun_secondary_gravityfactor;
		dtype = WEP_SUPERSHOTGUN | HITTYPE_SECONDARY;
		bounces = g_balance_supershotgun_secondary_bounces;
	}
	else
	{
		a = g_balance_supershotgun_primary_ammo;
		f = g_balance_supershotgun_primary_force;
		d = g_balance_supershotgun_primary_damage;
		s = g_balance_supershotgun_primary_speed;
		b = g_balance_supershotgun_primary_bullets;
		bc = g_balance_supershotgun_primary_bulletconstant;
		spread = g_balance_supershotgun_primary_spread;
		g = g_balance_supershotgun_primary_gravityfactor;
		dtype = WEP_SUPERSHOTGUN;
		bounces = g_balance_supershotgun_primary_bounces;
	}
	if (ballistic)
		beginFireBallisticBullet(s);

	weapon_setup_shot (self, 5, "weapons/shotgun_fire.wav", b);

	if (barrels == 3)
	{
		hor_spread = spread * 1.5;
		hor_shift = 0;
	}
	else if (barrels == 2)
	{
		hor_spread = 0;
		hor_shift = spread * 0.25;
	}
	else if (barrels == 1)
	{
		hor_spread = 0;
		hor_shift = spread * -0.25;
	}
	shotdir_shifted = w_shotdir + v_right * hor_shift;
	if (ballistic)
	{
		for (sc = 0; sc < b; sc = sc + 1)
			fireBallisticBullet(w_shotorg, shotdir_shifted + hor_spread * (random() - 0.5) * v_right, spread, s, 5,
					d, 0, f, dtype, particleeffectnum("tr_bullet"), g, bc);
		endFireBallisticBullet();
	}
	else
	{
		for (sc = 0; sc < b; sc = sc + 1)
			W_Supershotgun_Pellet(w_shotorg, shotdir_shifted + hor_spread * (random() - 0.5) * v_right, spread, s + (s * random() * spread * 5),
					d, f, dtype, g, bounces);
	}
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - a;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg_visual, w_shotdir * 1000, g_balance_shotgun_primary_ammo);

	if (g_casings >= 1)
		for (sc = 0; sc < a; sc = sc + 1)
			casing_spawn (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	weapon_attach_to_shotorg(flash, '5 0 0');
}

void W_Supershotgun_Attack2()
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (self.ammo_shells < g_balance_supershotgun_secondary_ammo)
	{
		weapon_ready();
		return;
	}
	W_Supershotgun_Attack(TRUE, 2, g_balance_supershotgun_secondary_ballistic);
	weapon_thinkf(WFRAME_FIRE2, g_balance_supershotgun_secondary_refire - g_balance_supershotgun_secondary_animtime, weapon_ready);
}

float w_supershotgun(float req)
{
	if (req == WR_AIM)
		if(vlen(self.origin-self.enemy.origin)>200 || !g_balance_supershotgun_secondary)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, g_balance_supershotgun_primary_refire))
		{
			W_Supershotgun_Attack(FALSE, 3, g_balance_supershotgun_primary_ballistic);
			weapon_thinkf(WFRAME_FIRE1, g_balance_supershotgun_primary_animtime, weapon_ready);
		}
		if (self.BUTTON_ATCK2)
		if (g_balance_supershotgun_secondary)
		if (weapon_prepareattack(1, g_balance_supershotgun_secondary_refire))
		{
			W_Supershotgun_Attack(TRUE, 1, g_balance_supershotgun_secondary_ballistic);
			weapon_thinkf(WFRAME_FIRE2, g_balance_supershotgun_secondary_animtime, W_Supershotgun_Attack2);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/uziflash.md3");
		precache_sound ("misc/itempickup.wav");
		precache_sound ("weapons/shotgun_fire.wav");
		dlc_require("supershotgun");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_SUPERSHOTGUN);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_shells >= g_balance_supershotgun_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_shells >= g_balance_supershotgun_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "used C++ and shot the leg out";
	else if (req == WR_KILLMESSAGE)
	{
		w_deathtypestring = "was gunned by"; // unchecked: SECONDARY
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_supershotgun_primary_ammo);
		CACHE_CVAR(g_balance_supershotgun_primary_animtime);
		CACHE_CVAR(g_balance_supershotgun_primary_ballistic);
		CACHE_CVAR(g_balance_supershotgun_primary_bounces);
		CACHE_CVAR(g_balance_supershotgun_primary_bulletconstant);
		CACHE_CVAR(g_balance_supershotgun_primary_bullets);
		CACHE_CVAR(g_balance_supershotgun_primary_damage);
		CACHE_CVAR(g_balance_supershotgun_primary_force);
		CACHE_CVAR(g_balance_supershotgun_primary_gravityfactor);
		CACHE_CVAR(g_balance_supershotgun_primary_refire);
		CACHE_CVAR(g_balance_supershotgun_primary_speed);
		CACHE_CVAR(g_balance_supershotgun_primary_spread);
		CACHE_CVAR(g_balance_supershotgun_secondary);
		CACHE_CVAR(g_balance_supershotgun_secondary_ammo);
		CACHE_CVAR(g_balance_supershotgun_secondary_animtime);
		CACHE_CVAR(g_balance_supershotgun_secondary_ballistic);
		CACHE_CVAR(g_balance_supershotgun_secondary_bounces);
		CACHE_CVAR(g_balance_supershotgun_secondary_bulletconstant);
		CACHE_CVAR(g_balance_supershotgun_secondary_bullets);
		CACHE_CVAR(g_balance_supershotgun_secondary_damage);
		CACHE_CVAR(g_balance_supershotgun_secondary_force);
		CACHE_CVAR(g_balance_supershotgun_secondary_gravityfactor);
		CACHE_CVAR(g_balance_supershotgun_secondary_refire);
		CACHE_CVAR(g_balance_supershotgun_secondary_speed);
		CACHE_CVAR(g_balance_supershotgun_secondary_spread);
		CSQCProjectile_Init(PROJECTILE_BULLET_BIG);
	}
	return TRUE;
};

void(void) spawnfunc_weapon_supershotgun {
	weapon_defaultspawnfunc(WEP_SUPERSHOTGUN);
}
