float g_balance_crylink_primary_ammo;
float g_balance_crylink_primary_animtime;
float g_balance_crylink_primary_bouncedamagefactor;
float g_balance_crylink_primary_bounces;
float g_balance_crylink_primary_damage;
float g_balance_crylink_primary_edgedamage;
float g_balance_crylink_primary_force;
float g_balance_crylink_primary_middle_lifetime;
float g_balance_crylink_primary_other_lifetime;
float g_balance_crylink_primary_radius;
float g_balance_crylink_primary_refire;
float g_balance_crylink_primary_shots;
float g_balance_crylink_primary_speed;
float g_balance_crylink_primary_spread;
float g_balance_crylink_primary_star_lifetime;
float g_balance_crylink_secondary_ammo;
float g_balance_crylink_secondary_animtime;
float g_balance_crylink_secondary_bouncedamagefactor;
float g_balance_crylink_secondary_bounces;
float g_balance_crylink_secondary_damage;
float g_balance_crylink_secondary_edgedamage;
float g_balance_crylink_secondary_force;
float g_balance_crylink_secondary_line_lifetime;
float g_balance_crylink_secondary_middle_lifetime;
float g_balance_crylink_secondary_radius;
float g_balance_crylink_secondary_refire;
float g_balance_crylink_secondary_shots;
float g_balance_crylink_secondary_speed;
float g_balance_crylink_secondary_spread;

.float gravity;

var .float crylink_buttonatck1 = BUTTON_ATCK;
var .float crylink_buttonatck2 = BUTTON_ATCK2;

// NO bounce protection, as bounces are limited!
void(void) weapon_crylink_touch {
	PROJECTILE_TOUCH;
	if ((self.cnt <= 0) || (other.takedamage != DAMAGE_NO)) {
		projectile_explode();
		return;
	}
	damage_radius (self, self.realowner, self.dmg * self.lip, self.dmg_edge * self.lip, self.dmg_radius, world, self.dmg_force * self.lip, self.projectiledeathtype, other);
	self.cnt = self.cnt - 1;
	self.owner = world;
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void(void) weapon_crylink_attack {
	float counter;
	entity proj;
	vector s;
	vector forward, right, up;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_crylink_primary_ammo;

	weapon_setup_shot (self, 2, "weapons/crylink_fire.wav", g_balance_crylink_primary_shots);
	forward = v_forward;
	right = v_right;
	up = v_up;
	pointparticles(particleeffectnum("crylink_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, g_balance_crylink_primary_shots);
	while (counter < g_balance_crylink_primary_shots) {
		proj = projectile(TRUE, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), TRUE, self);
		projectile_setup(proj, weapon_shotorg, WEP_CRYLINK, g_balance_crylink_primary_damage,
				g_balance_crylink_primary_edgedamage, g_balance_crylink_primary_radius, g_balance_crylink_primary_force);

		proj.lip = g_balance_crylink_primary_bouncedamagefactor;
		proj.movetype = MOVETYPE_BOUNCEMISSILE;
		s = '0 0 0';
		if (counter == 0)
			s = '0 0 0';
		else {
			makevectors('0 360 0' * (0.75 + (counter - 0.5) / (g_balance_crylink_primary_shots - 1)));
			s_y = v_forward_x;
			s_z = v_forward_y;
		}
		s = s * g_balance_crylink_primary_spread;
		proj.velocity = (weapon_shotdir + right * s_y + up * s_z) * g_balance_crylink_primary_speed;
//		proj.velocity = (weapon_shotdir + randomvec() * g_balance_crylink_primary_spread) * g_balance_crylink_primary_speed;
		weapon_setup_projectile_velocity(proj);
		proj.touch = weapon_crylink_touch;
		proj.think = stdproc_remove;
		if(counter == 0)
			proj.nextthink = time + g_balance_crylink_primary_middle_lifetime;
		else if(counter <= 3)
			proj.nextthink = time + g_balance_crylink_primary_star_lifetime;
		else
			proj.nextthink = time + g_balance_crylink_primary_other_lifetime;

		proj.cnt = g_balance_crylink_primary_bounces;
		counter = counter + 1;
	}
}

void(void) weapon_crylink_attack2 {
	float counter;
	entity proj;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_crylink_secondary_ammo;

	weapon_setup_shot (self, 2, "weapons/crylink_fire2.wav", g_balance_crylink_secondary_shots);
	pointparticles(particleeffectnum("crylink_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, g_balance_crylink_secondary_shots);
	while (counter < g_balance_crylink_secondary_shots) {
		proj = projectile(TRUE, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), TRUE, self);
		projectile_setup(proj, weapon_shotorg, WEP_CRYLINK | HITTYPE_SECONDARY, g_balance_crylink_secondary_damage,
				g_balance_crylink_secondary_edgedamage, g_balance_crylink_secondary_radius, g_balance_crylink_secondary_force);

		proj.lip = g_balance_crylink_secondary_bouncedamagefactor;
		proj.movetype = MOVETYPE_BOUNCEMISSILE;
		proj.velocity = (weapon_shotdir + (((counter + 0.5) / g_balance_crylink_secondary_shots) * 2 - 1) * v_right * g_balance_crylink_secondary_spread) * g_balance_crylink_secondary_speed;
		weapon_setup_projectile_velocity(proj);
		proj.touch = weapon_crylink_touch;
		proj.think = stdproc_remove;
		if(counter == (g_balance_crylink_secondary_shots - 1) / 2)
			proj.nextthink = time + g_balance_crylink_secondary_middle_lifetime;
		else
			proj.nextthink = time + g_balance_crylink_secondary_line_lifetime;

		proj.cnt = g_balance_crylink_secondary_bounces;
		counter = counter + 1;
	}
}

void spawnfunc_weapon_crylink (void)
{
	weapon_defaultspawnfunc(WEP_CRYLINK);
}

float weapon_crylink(float req)
{
	if (req == WR_AIM)
	{
		if (random() > 0.15)
			self.crylink_buttonatck1 = bot_aim(g_balance_crylink_primary_speed, 0, g_balance_crylink_primary_middle_lifetime, FALSE);
		else
			self.crylink_buttonatck2 = bot_aim(g_balance_crylink_secondary_speed, 0, g_balance_crylink_secondary_middle_lifetime, FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.crylink_buttonatck1)
		if (weapon_prepareattack(0, g_balance_crylink_primary_refire))
		{
			weapon_crylink_attack();
			weapon_thinkf(WFRAME_FIRE1, g_balance_crylink_primary_animtime, weapon_ready);
		}
		if (self.crylink_buttonatck2)
		if (weapon_prepareattack(1, g_balance_crylink_secondary_refire))
		{
			weapon_crylink_attack2();
			weapon_thinkf(WFRAME_FIRE2, g_balance_crylink_secondary_animtime, weapon_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/crylink_fire.wav");
		precache_sound ("weapons/crylink_fire2.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_CRYLINK);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= g_balance_crylink_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_cells >= g_balance_crylink_secondary_ammo;
	else if (req == WR_SUICIDEMESSAGE)
	{
		weapon_deathtypestring = "succeeded at self-destructing himself with the Crylink";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(weapon_deathtype & HITTYPE_BOUNCE)
			weapon_deathtypestring = "could not hide from #'s Crylink"; // unchecked: SPLASH (SECONDARY can't be)
		else if(weapon_deathtype & HITTYPE_SPLASH)
			weapon_deathtypestring = "was too close to #'s Crylink"; // unchecked: SECONDARY
		else
			weapon_deathtypestring = "took a close look at #'s Crylink"; // unchecked: SECONDARY
	}
	else if (req == WR_CVAR_CACHE)
	{
		CVAR_CACHE(g_balance_crylink_primary_ammo);
		CVAR_CACHE(g_balance_crylink_primary_animtime);
		CVAR_CACHE(g_balance_crylink_primary_bouncedamagefactor);
		CVAR_CACHE(g_balance_crylink_primary_bounces);
		CVAR_CACHE(g_balance_crylink_primary_damage);
		CVAR_CACHE(g_balance_crylink_primary_edgedamage);
		CVAR_CACHE(g_balance_crylink_primary_force);
		CVAR_CACHE(g_balance_crylink_primary_middle_lifetime);
		CVAR_CACHE(g_balance_crylink_primary_other_lifetime);
		CVAR_CACHE(g_balance_crylink_primary_radius);
		CVAR_CACHE(g_balance_crylink_primary_refire);
		CVAR_CACHE(g_balance_crylink_primary_shots);
		CVAR_CACHE(g_balance_crylink_primary_speed);
		CVAR_CACHE(g_balance_crylink_primary_spread);
		CVAR_CACHE(g_balance_crylink_primary_star_lifetime);
		CVAR_CACHE(g_balance_crylink_secondary_ammo);
		CVAR_CACHE(g_balance_crylink_secondary_animtime);
		CVAR_CACHE(g_balance_crylink_secondary_bouncedamagefactor);
		CVAR_CACHE(g_balance_crylink_secondary_bounces);
		CVAR_CACHE(g_balance_crylink_secondary_damage);
		CVAR_CACHE(g_balance_crylink_secondary_edgedamage);
		CVAR_CACHE(g_balance_crylink_secondary_force);
		CVAR_CACHE(g_balance_crylink_secondary_line_lifetime);
		CVAR_CACHE(g_balance_crylink_secondary_middle_lifetime);
		CVAR_CACHE(g_balance_crylink_secondary_radius);
		CVAR_CACHE(g_balance_crylink_secondary_refire);
		CVAR_CACHE(g_balance_crylink_secondary_shots);
		CVAR_CACHE(g_balance_crylink_secondary_speed);
		CVAR_CACHE(g_balance_crylink_secondary_spread);
		projectile_init(PROJECTILE_CRYLINK);
		projectile_init(PROJECTILE_CRYLINK_BOUNCING);
		if (cvar("g_balance_crylink_swap_buttons")) {
			crylink_buttonatck1 = BUTTON_ATCK2;
			crylink_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}
