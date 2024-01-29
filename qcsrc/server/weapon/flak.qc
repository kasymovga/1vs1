float g_balance_flak_magazinecapacity;
float g_balance_flak_primary_ammo;
float g_balance_flak_primary_animtime;
float g_balance_flak_primary_bounces;
float g_balance_flak_primary_bullets;
float g_balance_flak_primary_charge;
float g_balance_flak_primary_charge_spreadmod_side;
float g_balance_flak_primary_charge_spreadmod_vertical;
float g_balance_flak_primary_damage;
float g_balance_flak_primary_force;
float g_balance_flak_primary_gravityfactor;
float g_balance_flak_primary_recoil;
float g_balance_flak_primary_refire;
float g_balance_flak_primary_speed;
float g_balance_flak_primary_speed_up;
float g_balance_flak_primary_spread_side;
float g_balance_flak_primary_spread_vertical;
float g_balance_flak_reloadtime;
float g_balance_flak_secondary;
float g_balance_flak_secondary_ammo;
float g_balance_flak_secondary_animtime;
float g_balance_flak_secondary_bomb_damage;
float g_balance_flak_secondary_bomb_edgedamage;
float g_balance_flak_secondary_bomb_force;
float g_balance_flak_secondary_bomb_lifetime;
float g_balance_flak_secondary_bomb_radius;
float g_balance_flak_secondary_bomb_speed_up;
float g_balance_flak_secondary_bomb_speed;
float g_balance_flak_secondary_bounces;
float g_balance_flak_secondary_bullets;
float g_balance_flak_secondary_damage;
float g_balance_flak_secondary_force;
float g_balance_flak_secondary_gravityfactor;
float g_balance_flak_secondary_recoil;
float g_balance_flak_secondary_refire;
float g_balance_flak_secondary_speed;
float g_balance_flak_secondary_spread;

entity weapon_flak_charge_indicator;

var .float flak_buttonatck1;
var .float flak_buttonatck2;
.float flak_charge;
.float flak_ammoclip;

void(void) weapoon_flak_pellet_touch {
	PROJECTILE_TOUCH;
	if (other.solid == SOLID_BSP)
		effect_impact(self.origin, self.dmg, 0, 0, normalize(self.velocity), EFFECT_IMPACT_PELLET, self);

	if (other && other.takedamage) {
		entity o = self.realowner;
		weapon_score_hits(o, other, WEAPON_SUPERSHOTGUN, 1, self.dmg);
		damage(other, self, o, self.dmg, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity));
		self.cnt = 0;
	}
	if not(self.cnt) {
		remove(self);
		return;
	}
	self.cnt = self.cnt - 1;
	self.angles = vectoangles(self.velocity);
	self.owner = world;
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

entity(vector start, vector dir, float spread_side, float spread_ver, float pSpeed, float speed_up, float _damage, float force, float dtype, float gravityfactor, float bounces) weapon_flak_pellet {
	entity proj;
	proj = projectile(TRUE, PROJECTILE_BULLET_BIG, TRUE, self);
	projectile_setup(proj, start, 0, dtype, _damage, 0, 0, force, gravityfactor, (bounces ? MOVETYPE_BOUNCEMISSILE : MOVETYPE_FLY));
	proj.think = stdproc_remove;
	proj.nextthink = time + 10;
	proj.velocity = normalize(dir + random_2() * spread_side * v_right + random_2() * spread_ver * v_up) * pSpeed + '0 0 1' * speed_up;
	weapon_setup_projectile_velocity(proj);
	proj.touch = weapoon_flak_pellet_touch;
	proj.cnt = bounces;
	return proj;
}

void(void) weapon_flak_attack {
	float sc;
	float bounces;
	float spread_side = g_balance_flak_primary_spread_side;
	float spread_vertical = g_balance_flak_primary_spread_vertical;
	if (g_balance_flak_magazinecapacity) {
		self.flak_ammoclip -= 1;
	}
	if (g_balance_flak_primary_charge) {
		float charge = bound(0, self.flak_charge, 1);
		spread_side *= ((1 - charge) + g_balance_flak_primary_charge_spreadmod_side * charge);
		spread_vertical *= ((1 - charge) + g_balance_flak_primary_charge_spreadmod_vertical * charge);
	}
	bounces = g_balance_flak_primary_bounces;
	weapon_setup_shot(self, g_balance_flak_primary_recoil, "weapons/shotgun_fire.wav", g_balance_flak_primary_bullets);
	for (sc = 0; sc < g_balance_flak_primary_bullets; sc = sc + 1)
		weapon_flak_pellet(weapon_shotorg, weapon_shotdir, spread_side, spread_vertical,
				g_balance_flak_primary_speed, g_balance_flak_primary_speed_up,
				g_balance_flak_primary_damage, g_balance_flak_primary_force, WEAPON_SUPERSHOTGUN, g_balance_flak_primary_gravityfactor, bounces);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - g_balance_flak_primary_ammo;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, g_balance_shotgun_primary_ammo);
	casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);
	// muzzle flash for 1st person view
	weapon_flash(WEAPON_FLASH_SHOTGUN);
	self.flak_charge = 0;
}

void(void) weapon_flak_bomb_explode {
	float sc;
	entity e;
	if (self.movedir != '0 0 0') {
		makevectors(vectoangles(self.movedir));
		for (sc = 0; sc < g_balance_flak_secondary_bullets; sc++) {
			e = weapon_flak_pellet(ENTITY_CENTER(self), self.movedir, g_balance_flak_secondary_spread, g_balance_flak_secondary_spread,
					g_balance_flak_secondary_speed, 0,
					g_balance_flak_secondary_damage, g_balance_flak_secondary_force,
					WEAPON_SUPERSHOTGUN | HITTYPE_SECONDARY | HITTYPE_BOUNCE, g_balance_flak_secondary_gravityfactor, g_balance_flak_secondary_bounces);
			e.owner = NULL;
			e.realowner = self.owner;
		}
	} else {
		for (sc = 0; sc < g_balance_flak_secondary_bullets; sc++) {
			e = weapon_flak_pellet(ENTITY_CENTER(self), randomvec(), 0, 0,
					g_balance_flak_secondary_speed, 0,
					g_balance_flak_secondary_damage, g_balance_flak_secondary_force,
					WEAPON_SUPERSHOTGUN | HITTYPE_SECONDARY | HITTYPE_BOUNCE, g_balance_flak_secondary_gravityfactor, g_balance_flak_secondary_bounces);
			e.owner = NULL;
			e.realowner = self.owner;
		}
	}
	remove(self);
}

void(void) weapon_flak_bomb_touch {
	PROJECTILE_TOUCH;
	if (other) {
		if (other.solid == SOLID_BSP)
			self.movedir = normalize(self.velocity + trace_plane_normal * (trace_plane_normal * self.velocity) * 2);
		else
			self.movedir = normalize(self.velocity);
	} else
		self.movedir = normalize(self.velocity + trace_plane_normal * (trace_plane_normal * self.velocity) * 2);

	pointparticles(particleeffectnum("hagar_explode"), ENTITY_CENTER(self), self.velocity, 1);
	weapon_flak_bomb_explode();
}

void(void) weapon_flak_bomb {
	entity gren;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - g_balance_flak_secondary_ammo;

	if (g_balance_flak_magazinecapacity)
		self.flak_ammoclip -= 1;

	weapon_setup_shot(self, g_balance_flak_secondary_recoil, "weapons/grenade_fire.wav", 1);
	//weapon_shotdir = v_forward; // no TrueAim for grenades please
	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	gren = projectile(TRUE, PROJECTILE_RM_FLAK_BOMB, TRUE, self);
	projectile_setup(gren, weapon_shotorg, EFFECT_IMPACT_GRENADE, WEAPON_SUPERSHOTGUN | HITTYPE_SECONDARY, 0,
			0, 0, 0, 1, MOVETYPE_TOSS);
	gren.nextthink = time + g_balance_flak_secondary_bomb_lifetime;
	gren.think = projectile_think2use;
	gren.use = weapon_flak_bomb_explode;
	gren.touch = weapon_flak_bomb_touch;
	gren.velocity = weapon_shotdir * g_balance_flak_secondary_bomb_speed + v_up * g_balance_flak_secondary_bomb_speed_up;
	weapon_setup_projectile_velocity(gren);
}

float(entity to, float sf) weapon_flak_charge_indicator_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_RM_FLAK_CHARGE_INDICATOR);
	net_write_byte(MSG_ENTITY, sf & 7);
	if (sf & 1) {
		net_write_coord(MSG_ENTITY, g_balance_flak_primary_spread_side);
		net_write_coord(MSG_ENTITY, g_balance_flak_primary_charge_spreadmod_side);
		net_write_coord(MSG_ENTITY, 1 / g_balance_flak_primary_charge);
	}
	if (sf & 2) {
		net_write_coord(MSG_ENTITY, to.flak_charge);
		entity e = to.weaponentity;
		net_write_coord(MSG_ENTITY, e.shotorg_visual_x);
		net_write_coord(MSG_ENTITY, e.shotorg_visual_y);
		net_write_coord(MSG_ENTITY, e.shotorg_visual_z);
	}
	return TRUE;
}

float(void) weapon_flak_charge_indicator_customize {
	if (other.flak_charge) {
		self.SendFlags |= 2;
		return TRUE;
	}
	return FALSE;
}

void(void) weapon_flak_reloadandready {
	weapon_clip_reloadandready(ammo_shells, flak_ammoclip,
			g_balance_flak_primary_ammo, g_balance_flak_secondary_ammo, g_balance_flak_reloadtime);
}

void(void) weapon_flak_reload {
	weapon_clip_reload(ammo_shells, flak_ammoclip, g_balance_flak_primary_ammo,
			g_balance_flak_secondary_ammo, "weapons/campingrifle_reload.wav", g_balance_flak_reloadtime,
			weapon_flak_reloadandready);
}

float(float req) weapon_flak {
	if (req == WEAPON_REQUEST_AIM) {
		if (vlen(self.origin-self.enemy.origin)>200 || !g_balance_flak_secondary)
			self.flak_buttonatck1 = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.flak_buttonatck2 = bot_aim(1000000, 0, 0.001, FALSE);
	} else if (req == WEAPON_REQUEST_THINK) {
		if (g_balance_flak_magazinecapacity && (self.flak_ammoclip < 0 || (!self.flak_ammoclip && (self.flak_buttonatck1 || self.flak_buttonatck2)))) { // forced reload (e.g. because interrupted)
			if (self.switchweapon == self.weapon)
			if (self.weaponentity.state == WEAPON_STATE_READY)
				weapon_flak_reload();
		} else {
			if (g_balance_flak_primary_charge) {
				if (self.flak_buttonatck1) {
					if (weapon_prepareattack(0, -1)) {
						self.flak_charge += frametime / g_balance_flak_primary_charge;
						weapon_ready();
					}
				} else if (self.flak_charge) {
					if (weapon_prepareattack(0, g_balance_flak_primary_refire)) {
						weapon_flak_attack();
						weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_flak_primary_animtime, weapon_ready);
					}
				}
			} else {
				if (self.flak_buttonatck1)
				if (weapon_prepareattack(0, g_balance_flak_primary_refire)) {
					weapon_flak_attack();
					weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_flak_primary_animtime, weapon_ready);
				}
			}
			if (self.flak_buttonatck2)
			if (g_balance_flak_secondary)
			if (weapon_prepareattack(1, g_balance_flak_secondary_refire)) {
				weapon_flak_bomb();
				weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_flak_secondary_animtime, weapon_ready);
			}
		}
		if (g_balance_flak_magazinecapacity) {
			self.ammoclip = self.flak_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
		}
	} else if (req == WEAPON_REQUEST_RELOAD) {
		weapon_flak_reload();
	} else if (req == WEAPON_REQUEST_SETUP) {
		self.flak_charge = 0;
		weapon_clip_setup(g_balance_flak_magazinecapacity, ammo_shells, flak_ammoclip, g_balance_flak_primary_ammo, g_balance_flak_secondary_ammo);
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		if (g_balance_flak_magazinecapacity)
			self.flak_ammoclip = g_balance_flak_magazinecapacity;
	} else if (req == WEAPON_REQUEST_CLEAR) {
		self.flak_charge = 0;
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "used C++ and shot the leg out";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_deathtypestring = "was gunned by"; // unchecked: SECONDARY
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		weapon_flash_precache(WEAPON_FLASH_SHOTGUN);
		precache_sound("weapons/shotgun_fire.wav");
		precache_sound("weapons/grenade_fire.wav");
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_flak_magazinecapacity);
		CVAR_CACHE(g_balance_flak_primary_ammo);
		CVAR_CACHE(g_balance_flak_primary_animtime);
		CVAR_CACHE(g_balance_flak_primary_bounces);
		CVAR_CACHE(g_balance_flak_primary_bullets);
		CVAR_CACHE(g_balance_flak_primary_charge);
		CVAR_CACHE(g_balance_flak_primary_charge_spreadmod_side);
		CVAR_CACHE(g_balance_flak_primary_charge_spreadmod_vertical);
		CVAR_CACHE(g_balance_flak_primary_damage);
		CVAR_CACHE(g_balance_flak_primary_force);
		CVAR_CACHE(g_balance_flak_primary_gravityfactor);
		CVAR_CACHE(g_balance_flak_primary_recoil);
		CVAR_CACHE(g_balance_flak_primary_refire);
		CVAR_CACHE(g_balance_flak_primary_speed);
		CVAR_CACHE(g_balance_flak_primary_speed_up);
		CVAR_CACHE(g_balance_flak_primary_spread_side);
		CVAR_CACHE(g_balance_flak_primary_spread_vertical);
		CVAR_CACHE(g_balance_flak_reloadtime);
		CVAR_CACHE(g_balance_flak_secondary);
		CVAR_CACHE(g_balance_flak_secondary_ammo);
		CVAR_CACHE(g_balance_flak_secondary_animtime);
		CVAR_CACHE(g_balance_flak_secondary_bomb_damage);
		CVAR_CACHE(g_balance_flak_secondary_bomb_edgedamage);
		CVAR_CACHE(g_balance_flak_secondary_bomb_force);
		CVAR_CACHE(g_balance_flak_secondary_bomb_lifetime);
		CVAR_CACHE(g_balance_flak_secondary_bomb_radius);
		CVAR_CACHE(g_balance_flak_secondary_bomb_speed);
		CVAR_CACHE(g_balance_flak_secondary_bomb_speed_up);
		CVAR_CACHE(g_balance_flak_secondary_bounces);
		CVAR_CACHE(g_balance_flak_secondary_bullets);
		CVAR_CACHE(g_balance_flak_secondary_damage);
		CVAR_CACHE(g_balance_flak_secondary_force);
		CVAR_CACHE(g_balance_flak_secondary_gravityfactor);
		CVAR_CACHE(g_balance_flak_secondary_recoil);
		CVAR_CACHE(g_balance_flak_secondary_refire);
		CVAR_CACHE(g_balance_flak_secondary_speed);
		CVAR_CACHE(g_balance_flak_secondary_spread);
		if (cvar("g_balance_flak_swap_buttons")) {
			flak_buttonatck1 = BUTTON_ATCK2;
			flak_buttonatck2 = BUTTON_ATCK;
		} else {
			flak_buttonatck1 = BUTTON_ATCK;
			flak_buttonatck2 = BUTTON_ATCK2;
		}
		projectile_init(PROJECTILE_RM_FLAK_BOMB);
		weapon_ammo_limits(WEAPON_SUPERSHOTGUN, g_balance_flak_primary_ammo, g_balance_flak_secondary_ammo);
		dlc_require("flak");
		if (g_balance_flak_primary_charge) {
			if (weapon_flak_charge_indicator) {
				weapon_flak_charge_indicator.SendFlags |= 1;
			} else {
				weapon_flak_charge_indicator = spawn();
				weapon_flak_charge_indicator.customizeentityforclient = weapon_flak_charge_indicator_customize;
				net_link_entity(weapon_flak_charge_indicator, FALSE, 0, weapon_flak_charge_indicator_send);
			}
		}
	}
	return TRUE;
}

void(void) spawnfunc_weapon_flak {
	weapon_defaultspawnfunc(WEAPON_SUPERSHOTGUN);
}
