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

void weapoon_supershotgun_touch()
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

void(vector start, vector dir, float spread, float pSpeed, float _damage, float force, float dtype, float gravityfactor, float bounces) weapon_supershotgun_pellet {
	entity proj;
	proj = projectile(TRUE, PROJECTILE_BULLET_BIG, TRUE, self);
	projectile_setup(proj, start, dtype, _damage, 0, 0, force);
	proj.movetype = (gravityfactor ? MOVETYPE_BOUNCE : MOVETYPE_BOUNCEMISSILE);
	proj.gravity = gravityfactor;
	proj.think = stdproc_remove;
	proj.nextthink = time + 10;
	proj.velocity = normalize(dir + randomvec() * spread) * pSpeed;
	weapon_setup_projectile_velocity(proj);
	proj.touch = weapoon_supershotgun_touch;
	proj.cnt = bounces;
}

void weapon_supershotgun_attack(float secondary, float barrels, float ballistic)
{
	float a, b, f, d, s, spread, g, bc, dtype;
	float	sc;
	local entity flash;
	float hor_spread = 0, hor_shift = 0;
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
		bullet_begin(s);

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
	shotdir_shifted = weapon_shotdir + v_right * hor_shift;
	if (ballistic)
	{
		for (sc = 0; sc < b; sc = sc + 1)
			bullet(weapon_shotorg, shotdir_shifted + hor_spread * (random() - 0.5) * v_right, spread, s, 5,
					d, 0, f, dtype, particleeffectnum("tr_bullet"), g, bc);
		bullet_end();
	}
	else
	{
		for (sc = 0; sc < b; sc = sc + 1)
			weapon_supershotgun_pellet(weapon_shotorg, shotdir_shifted + hor_spread * (random() - 0.5) * v_right, spread, s + (s * random() * spread * 5),
					d, f, dtype, g, bounces);
	}
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - a;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, g_balance_shotgun_primary_ammo);
	if not(secondary)
		casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);
	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.think = stdproc_remove;
	flash.nextthink = time + 0.06;
	flash.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION;
	weapon_attach_to_shotorg(flash, '5 0 0');
}

void weapon_supershotgun_attack2()
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (self.ammo_shells < g_balance_supershotgun_secondary_ammo)
	{
		weapon_ready();
		return;
	}
	weapon_supershotgun_attack(TRUE, 2, g_balance_supershotgun_secondary_ballistic);
	weapon_thinkf(WFRAME_FIRE2, g_balance_supershotgun_secondary_refire - g_balance_supershotgun_secondary_animtime, weapon_ready);
}

float weapon_supershotgun(float req)
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
			weapon_supershotgun_attack(FALSE, 3, g_balance_supershotgun_primary_ballistic);
			weapon_thinkf(WFRAME_FIRE1, g_balance_supershotgun_primary_animtime, weapon_ready);
		}
		if (self.BUTTON_ATCK2)
		if (g_balance_supershotgun_secondary)
		if (weapon_prepareattack(1, g_balance_supershotgun_secondary_refire))
		{
			weapon_supershotgun_attack(TRUE, 1, g_balance_supershotgun_secondary_ballistic);
			weapon_thinkf(WFRAME_FIRE2, g_balance_supershotgun_secondary_animtime, weapon_supershotgun_attack2);
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
		weapon_deathtypestring = "used C++ and shot the leg out";
	else if (req == WR_KILLMESSAGE)
	{
		weapon_deathtypestring = "was gunned by"; // unchecked: SECONDARY
	}
	else if (req == WR_CVAR_CACHE)
	{
		CVAR_CACHE(g_balance_supershotgun_primary_ammo);
		CVAR_CACHE(g_balance_supershotgun_primary_animtime);
		CVAR_CACHE(g_balance_supershotgun_primary_ballistic);
		CVAR_CACHE(g_balance_supershotgun_primary_bounces);
		CVAR_CACHE(g_balance_supershotgun_primary_bulletconstant);
		CVAR_CACHE(g_balance_supershotgun_primary_bullets);
		CVAR_CACHE(g_balance_supershotgun_primary_damage);
		CVAR_CACHE(g_balance_supershotgun_primary_force);
		CVAR_CACHE(g_balance_supershotgun_primary_gravityfactor);
		CVAR_CACHE(g_balance_supershotgun_primary_refire);
		CVAR_CACHE(g_balance_supershotgun_primary_speed);
		CVAR_CACHE(g_balance_supershotgun_primary_spread);
		CVAR_CACHE(g_balance_supershotgun_secondary);
		CVAR_CACHE(g_balance_supershotgun_secondary_ammo);
		CVAR_CACHE(g_balance_supershotgun_secondary_animtime);
		CVAR_CACHE(g_balance_supershotgun_secondary_ballistic);
		CVAR_CACHE(g_balance_supershotgun_secondary_bounces);
		CVAR_CACHE(g_balance_supershotgun_secondary_bulletconstant);
		CVAR_CACHE(g_balance_supershotgun_secondary_bullets);
		CVAR_CACHE(g_balance_supershotgun_secondary_damage);
		CVAR_CACHE(g_balance_supershotgun_secondary_force);
		CVAR_CACHE(g_balance_supershotgun_secondary_gravityfactor);
		CVAR_CACHE(g_balance_supershotgun_secondary_refire);
		CVAR_CACHE(g_balance_supershotgun_secondary_speed);
		CVAR_CACHE(g_balance_supershotgun_secondary_spread);
		projectile_init(PROJECTILE_BULLET_BIG);
	}
	return TRUE;
}

void(void) spawnfunc_weapon_supershotgun {
	weapon_defaultspawnfunc(WEP_SUPERSHOTGUN);
}
