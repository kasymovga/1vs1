#define WEAPON_EXTRA_COUNT_MAX 8
.float weapon_extra_clip[WEAPON_EXTRA_COUNT_MAX];
string weapon_extra_model[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_ammo_type[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_magazinecapacity[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_reloadtime[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_ammo[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_type[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_damage[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_headshotaddeddamage[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_flash[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_force[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_refire[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_animtime[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_shots[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_gravity[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_effect[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_muzzle[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_speed[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_spread[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_radius[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_impact_type[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_lifetime[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_up[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_primary_bounces[WEAPON_EXTRA_COUNT_MAX];
string weapon_extra_primary_sound[WEAPON_EXTRA_COUNT_MAX];
string weapon_extra_primary_message[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_ammo[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_type[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_damage[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_headshotaddeddamage[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_flash[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_force[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_refire[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_animtime[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_shots[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_gravity[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_effect[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_muzzle[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_speed[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_spread[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_radius[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_impact_type[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_lifetime[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_up[WEAPON_EXTRA_COUNT_MAX];
float weapon_extra_secondary_bounces[WEAPON_EXTRA_COUNT_MAX];
string weapon_extra_secondary_sound[WEAPON_EXTRA_COUNT_MAX];
string weapon_extra_secondary_message[WEAPON_EXTRA_COUNT_MAX];
enum {
	WEAPON_EXTRA_TYPE_NONE = 0,
	WEAPON_EXTRA_TYPE_BULLET,
	WEAPON_EXTRA_TYPE_RAIL,
	WEAPON_EXTRA_TYPE_PROJECTILE,
	WEAPON_EXTRA_TYPE_MELEE,
};

float(entity to, float f) weapon_extra_send {
	return TRUE;
}

float(string s) weapon_extra_type_from_name {
	switch (s) {
	case "bullet":
		return WEAPON_EXTRA_TYPE_BULLET;
	case "nex":
	case "rail":
		return WEAPON_EXTRA_TYPE_RAIL;
	case "projectile":
		return WEAPON_EXTRA_TYPE_PROJECTILE;
	case "melee":
		return WEAPON_EXTRA_TYPE_MELEE;
	case "":
		return WEAPON_EXTRA_TYPE_NONE;
	}
	print("Unknown extra weapon type: ", s, "\n");
	return 0;
}

void(void) weapon_extra_projectile_touch {
	if (self.cnt) {
		if not(other) {
			self.owner = NULL;
			if (self.cnt > 0) {
				self.cnt--;
			}
			return;
		}
	} else {
		projectile_touch_explode();
	}
	projectile_touch_explode();
}

float weapon_extra_draw_beam_particles_effect;
void(vector start, vector end, vector to) weapon_extra_draw_beam_particles {
	weapon_nex_whoosh(start, end);
	trailparticles(world, weapon_extra_draw_beam_particles_effect, start, end);
}

void(float num, float secondary, float t) weapon_extra_attack {
	float d, f, e, r, g, sp, m, hs, spr, hittype, c, it, fl;
	string s;
	float at = weapon_extra_ammo_type[num];
	if (secondary) {
		c = weapon_extra_secondary_shots[num];
		d = weapon_extra_secondary_damage[num];
		f = weapon_extra_secondary_force[num];
		s = weapon_extra_secondary_sound[num];
		e = weapon_extra_secondary_effect[num];
		m = weapon_extra_secondary_muzzle[num];
		r = weapon_extra_secondary_radius[num];
		g = weapon_extra_secondary_gravity[num];
		sp = weapon_extra_secondary_speed[num];
		spr = weapon_extra_secondary_spread[num];
		hs = weapon_extra_secondary_headshotaddeddamage[num];
		it = weapon_extra_secondary_impact_type[num];
		fl = weapon_extra_secondary_flash[num];
		hittype = self.weapon | HITTYPE_SECONDARY;
	} else {
		c = weapon_extra_primary_shots[num];
		d = weapon_extra_primary_damage[num];
		f = weapon_extra_primary_force[num];
		s = weapon_extra_primary_sound[num];
		e = weapon_extra_primary_effect[num];
		m = weapon_extra_primary_muzzle[num];
		r = weapon_extra_primary_radius[num];
		g = weapon_extra_primary_gravity[num];
		sp = weapon_extra_primary_speed[num];
		spr = weapon_extra_primary_spread[num];
		hs = weapon_extra_primary_headshotaddeddamage[num];
		it = weapon_extra_primary_impact_type[num];
		fl = weapon_extra_primary_flash[num];
		hittype = self.weapon;
	}
	if (weapon_extra_magazinecapacity[num])
		self.weapon_extra_clip[num] -= 1;

	if (c < 1) c = 1;
	switch (t) {
	case WEAPON_EXTRA_TYPE_BULLET:
		bullet_begin(sp);
		weapon_setup_shot(self, 0 /* TODO: recoil */, s, c);
		pointparticles(m, weapon_shotorg_visual, weapon_shotdir * 1000, 1);
		//weapon_shake(1); //TODO: shake effect
		for (float i = 0; i < c; i++)
			bullet(weapon_shotorg, weapon_shotdir, spr, sp,
					5, d, hs,
					f, it, self.weapon, e, g, r);

		bullet_end();
		break;
	case WEAPON_EXTRA_TYPE_RAIL:
		antilag_begin(self);
		weapon_setup_shot(self, 0 /* TODO: recoil */, s, c);
		pointparticles(m, weapon_shotorg_visual, weapon_shotdir * 1000, 1);
		for (float i = 0; i < c; i++) {
			//TODO: yoda
			damage_yoda = 0;
			damage_headshot = 0;
			damage_goodhits = 0;
			damage_headshotbonus = hs;
			bullet_railgun(weapon_shotorg, weapon_shotorg + (weapon_shotdir + randomvec() * spr) * WORLD_MAX_SHOT_DISTANCE, d, f, 0, 0, 0, 0, hittype);
			damage_headshotbonus = 0;
			weapon_extra_draw_beam_particles_effect = e;
			warpzone_draw_effect_triangle(weapon_shotorg, weapon_shotorg_visual,  warpzone_untransform_origin(warpzone_trace_transform, trace_endpos), weapon_extra_draw_beam_particles);
			// flash and burn the wall
			if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)) {
				effect_impact(trace_endpos, 10000, 0, 0, 800 * warpzone_transform_velocity(warpzone_trace_transform, weapon_shotdir), it, self);
			}
		}
		antilag_end();
		break;
	case WEAPON_EXTRA_TYPE_PROJECTILE:
		if not(e) return;
		weapon_setup_shot(self, 0 /* TODO: recoil */, s, c);
		pointparticles(m, weapon_shotorg_visual, weapon_shotdir * 1000, 1);
		entity proj;
		float up, bounces, lt;
		if (secondary) {
			up = weapon_extra_secondary_up[num];
			bounces = weapon_extra_secondary_bounces[num];
			lt = weapon_extra_secondary_lifetime[num];
		} else {
			up = weapon_extra_primary_up[num];
			bounces = weapon_extra_primary_bounces[num];
			lt = weapon_extra_primary_lifetime[num];
		}
		for (float i = 0; i < c; i++) {
			proj = projectile(TRUE, e, TRUE, self);
			projectile_setup(proj, weapon_shotorg, it, hittype, d,
					0 /* TODO: edgedamage */, r, f, g, (bounces ? MOVETYPE_BOUNCE : MOVETYPE_FLY));
			proj.touch = (bounces ? weapon_extra_projectile_touch : projectile_touch_explode);
			proj.cnt = bounces;
			proj.use = projectile_explode;
			proj.think = projectile_think2use;
			proj.nextthink = time + lt /* TODO: lifetime */;
			if (g)
				proj.velocity = (v_forward + randomvec() * spr) * sp + v_up * up;
			else
				proj.velocity = (weapon_shotdir + randomvec() * spr) * sp;

			weapon_setup_projectile_velocity(proj);
		}
		break;
	case WEAPON_EXTRA_TYPE_MELEE:
		weapon_melee_attack(1, d, s);
		break;
	}
	if (fl) {
		weapon_flash(fl);
	}
	if (at == IT_SHELLS)
		casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);
	else if (at == IT_NAILS)
		casing_spawn(((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 2, self);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
		float a;
		if (secondary)
			a = weapon_extra_secondary_ammo[num];
		else
			a = weapon_extra_primary_ammo[num];

		if (at)
			self.(item_counter_field(at)) -= a;
	}
}

#define WEAPON_EXTRA_RELOAD_FUNCS \
WEAPON_EXTRA_RELOAD(0) \
WEAPON_EXTRA_RELOAD(1) \
WEAPON_EXTRA_RELOAD(2) \
WEAPON_EXTRA_RELOAD(3) \
WEAPON_EXTRA_RELOAD(4) \
WEAPON_EXTRA_RELOAD(5) \
WEAPON_EXTRA_RELOAD(6) \
WEAPON_EXTRA_RELOAD(7) \

#define WEAPON_EXTRA_RELOAD(i) \
void(void) weapon_extra_reloadandready##i { weapon_clip_reloadandready(weapon_extra_magazinecapacity[i], item_counter_field(weapon_extra_ammo_type[i]), weapon_extra_clip[i], weapon_extra_primary_ammo[i], weapon_extra_secondary_ammo[i], weapon_extra_reloadtime[i]); } \
void(void) weapon_extra_reload##i { weapon_clip_reload(weapon_extra_magazinecapacity[i], item_counter_field(weapon_extra_ammo_type[i]), weapon_extra_clip[i], weapon_extra_primary_ammo[i], weapon_extra_secondary_ammo[i], "weapons/campingrifle_reload.wav", weapon_extra_reloadtime[i], weapon_extra_reloadandready##i); }
WEAPON_EXTRA_RELOAD_FUNCS
#undef WEAPON_EXTRA_RELOAD

void(float num) weapon_extra_reload {
	switch (num) {
	#define WEAPON_EXTRA_RELOAD(i) case i: weapon_extra_reload##i(); break;
	WEAPON_EXTRA_RELOAD_FUNCS
	#undef WEAPON_EXTRA_RELOAD
	}
}

#undef WEAPON_EXTRA_RELOAD_FUNCS

float(float req) weapon_extra_think {
	float extra_num = self.weapon - WEAPON_LAST - 1;
	float at, mc;
	if (req == WEAPON_REQUEST_AIM) {
		float pt = weapon_extra_primary_type[extra_num];
		float st = weapon_extra_secondary_type[extra_num];
		float secondary = 0;
		if (!st) {
			if (!pt) return TRUE; //weapon broken
			secondary = 0;
		} else if (random() > 0.5)
			secondary = 1;

		if (secondary) {
			switch (st) {
			case WEAPON_EXTRA_TYPE_BULLET:
				self.BUTTON_ATCK2 = bot_aim(weapon_extra_secondary_speed[extra_num], 0, 5, FALSE);
				break;
			case WEAPON_EXTRA_TYPE_RAIL:
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 1, FALSE);
				break;
			case WEAPON_EXTRA_TYPE_PROJECTILE:
				if (bot_aim(weapon_extra_secondary_speed[extra_num], weapon_extra_secondary_up[extra_num], 5, TRUE))
					self.BUTTON_ATCK2 = TRUE;

				break;
			case WEAPON_EXTRA_TYPE_MELEE:
				if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
				if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE)) {
					self.BUTTON_ATCK2 = TRUE;
				}
				break;
			}
		} else {
			switch (pt) {
			case WEAPON_EXTRA_TYPE_BULLET:
				self.BUTTON_ATCK = bot_aim(weapon_extra_primary_speed[extra_num], 0, 5, FALSE);
				break;
			case WEAPON_EXTRA_TYPE_RAIL:
				self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
				break;
			case WEAPON_EXTRA_TYPE_PROJECTILE:
				if (bot_aim(weapon_extra_primary_speed[extra_num], weapon_extra_primary_up[extra_num], 5, TRUE))
					self.BUTTON_ATCK = TRUE;

				break;
			case WEAPON_EXTRA_TYPE_MELEE:
				if (vlen(self.origin - self.enemy.origin) < g_balance_melee_distance * 2)
				if (bot_aim(g_balance_melee_distance * 100, 0, 0.1, FALSE)) {
					self.BUTTON_ATCK = TRUE;
				}
				break;
			}
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		float magazinecapacity = weapon_extra_magazinecapacity[extra_num];
		var .float extra_ammoclip = weapon_extra_clip[extra_num];
		if (magazinecapacity && (self.extra_ammoclip < 0 || (!self.extra_ammoclip && (self.BUTTON_ATCK || self.BUTTON_ATCK2)))) { // forced reload (e.g. because interrupted)
			if (self.switchweapon == self.weapon)
			if (self.weaponentity.state == WEAPON_STATE_READY)
				weapon_extra_reload(extra_num);
		} else if (!magazinecapacity || self.extra_ammoclip > 0) {
			float t = 0;
			if (self.BUTTON_ATCK && (t = weapon_extra_primary_type[extra_num])) {
				if (weapon_prepareattack(0, weapon_extra_primary_refire[extra_num])) {
					weapon_extra_attack(extra_num, FALSE, t);
					weapon_thinkf(WEAPON_FRAME_FIRE1, weapon_extra_primary_animtime[extra_num], weapon_ready);
				}
			} else if (self.BUTTON_ATCK2 && (t = weapon_extra_secondary_type[extra_num])) {
				if (weapon_prepareattack(0, weapon_extra_secondary_refire[extra_num])) {
					weapon_extra_attack(extra_num, TRUE, t);
					weapon_thinkf(WEAPON_FRAME_FIRE2, weapon_extra_primary_animtime[extra_num], weapon_ready);
				}
			}
		}
		if (magazinecapacity) {
			self.ammoclip = self.extra_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		weapon_flash_precache(weapon_extra_primary_flash[extra_num]);
		weapon_flash_precache(weapon_extra_secondary_flash[extra_num]);
		precache_sound(weapon_extra_primary_sound[extra_num]);
		precache_sound(weapon_extra_secondary_sound[extra_num]);
		precache_sound("weapons/campingrifle_reload.wav");
	} else if (req == WEAPON_REQUEST_CHECKAMMO1) {
		at = weapon_extra_ammo_type[extra_num];
		if (at) {
			return (weapon_extra_primary_ammo[extra_num] <= self.(item_counter_field(at)));
		}
	} else if (req == WEAPON_REQUEST_CHECKAMMO2) {
		at = weapon_extra_ammo_type[extra_num];
		if (at) {
			return (weapon_extra_secondary_ammo[extra_num] <= self.(item_counter_field(at)));
		}
	} else if (req == WEAPON_REQUEST_RELOAD) {
		mc = weapon_extra_magazinecapacity[extra_num];
		at = weapon_extra_ammo_type[extra_num];
		if (mc && at) {
			weapon_extra_reload(extra_num);
		}
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE) {
	} else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		if (weapon_deathtype & HITTYPE_SECONDARY) {
			weapon_deathtypestring = cvar_string(strcat("g_weapon_extra_", ftos(extra_num), "_secondary_message"));
			weapon_fragprefix = cvar_string(strcat("g_weapon_extra_", ftos(extra_num), "_secondary_fragprefix"));
		} else {
			weapon_deathtypestring = cvar_string(strcat("g_weapon_extra_", ftos(extra_num), "_primary_message"));
			weapon_fragprefix = cvar_string(strcat("g_weapon_extra_", ftos(extra_num), "_primary_fragprefix"));
		}
	} else if (req == WEAPON_REQUEST_SETUP) {
		mc = weapon_extra_magazinecapacity[extra_num];
		at = weapon_extra_ammo_type[extra_num];
		if (mc && at) {
			weapon_clip_checkmaxbullets(mc, item_counter_field(at), weapon_extra_clip[extra_num], weapon_extra_primary_ammo[extra_num], weapon_extra_secondary_ammo[extra_num]);
			if not(self.weapon_extra_clip[extra_num])
				self.weapon_extra_clip[extra_num] = -1;
		}
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		mc = weapon_extra_magazinecapacity[extra_num];
		if (mc)
			self.weapon_extra_clip[extra_num] = mc;
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		if (weapon_extra_primary_type[extra_num] == WEAPON_EXTRA_TYPE_PROJECTILE)
			projectile_init(weapon_extra_primary_effect[extra_num]);

		if (weapon_extra_secondary_type[extra_num] == WEAPON_EXTRA_TYPE_PROJECTILE)
			projectile_init(weapon_extra_secondary_effect[extra_num]);
	}
	return TRUE;
}

float(string s) weapon_extra_impact_type_from_name {
	switch (s) {
	case "bullet": return EFFECT_IMPACT_BULLET;
	case "pellet": return EFFECT_IMPACT_PELLET;
	case "rocket": return EFFECT_IMPACT_ROCKET;
	case "grenade": return EFFECT_IMPACT_GRENADE;
	case "plasma": return EFFECT_IMPACT_PLASMA;
	case "nex": return EFFECT_IMPACT_NEX;
	case "laser": return EFFECT_IMPACT_LASER;
	case "hagar": return EFFECT_IMPACT_HAGAR;
	case "crylink": return EFFECT_IMPACT_CRYLINK;
	case "crylink_big": return EFFECT_IMPACT_CRYLINK_BIG;
	}
	return 0;
}

float(string s) weapon_extra_projectile_type_from_name {
	switch (s) {
	case "bullet": return PROJECTILE_BULLET;
	case "bullet_big": return PROJECTILE_BULLET_BIG;
	case "bullet_glowing": return PROJECTILE_BULLET_GLOWING;
	case "rocket": return PROJECTILE_ROCKET;
	case "grenade": return PROJECTILE_GRENADE;
	case "grenade_bouncing": return PROJECTILE_GRENADE_BOUNCING;
	case "plasma": return PROJECTILE_ELECTRO_BEAM;
	case "plasma_ball": return PROJECTILE_ELECTRO;
	case "laser": return PROJECTILE_LASER;
	case "hagar": return PROJECTILE_HAGAR;
	case "hagar_stick": return PROJECTILE_HAGAR_STICK;
	case "crylink": return PROJECTILE_CRYLINK;
	}
	return 0;
}

void(void) weapon_extra_init {
	float at = 0, imp, t;
	string ats;
	string modelname;
	for (float i = 0; i < WEAPON_EXTRA_COUNT_MAX; i++) {
		modelname = str_zone_ifneeded(cvar_string(strcat("g_weapon_extra_", ftos(i), "_model")));
		if (modelname == "") continue;
		weapon_extra_model[i] = modelname;
		imp = cvar(strcat("g_weapon_extra_", ftos(i), "_impulse"));
		weapon_extra_magazinecapacity[i] = cvar(strcat("g_weapon_extra_", ftos(i), "_magazinecapacity"));
		ats = cvar_string(strcat("g_weapon_extra_", ftos(i), "_ammo_type"));
		switch (ats) {
		case "cells":
			at = IT_CELLS;
			break;
		case "bullets":
		case "nails":
			at = IT_NAILS;
			break;
		case "rockets":
			at = IT_ROCKETS;
			break;
		case "shells":
			at = IT_SHELLS;
			break;
		}
		weapon_extra_ammo_type[i] = at;
		weapon_extra_reloadtime[i] = cvar(strcat("g_weapon_extra_", ftos(i), "_reloadtime"));
		#define WEAPON_EXTRA_READ(name) weapon_extra_primary_##name[i] = cvar(strcat("g_weapon_extra_", ftos(i), "_primary_"#name)); weapon_extra_secondary_##name[i] = cvar(strcat("g_weapon_extra_", ftos(i), "_secondary_"#name));
		WEAPON_EXTRA_READ(damage)
		WEAPON_EXTRA_READ(headshotaddeddamage)
		WEAPON_EXTRA_READ(force)
		WEAPON_EXTRA_READ(refire)
		WEAPON_EXTRA_READ(animtime)
		WEAPON_EXTRA_READ(gravity)
		WEAPON_EXTRA_READ(shots)
		WEAPON_EXTRA_READ(radius)
		WEAPON_EXTRA_READ(speed)
		WEAPON_EXTRA_READ(spread)
		WEAPON_EXTRA_READ(ammo)
		WEAPON_EXTRA_READ(bounces)
		WEAPON_EXTRA_READ(up)
		WEAPON_EXTRA_READ(flash)
		WEAPON_EXTRA_READ(lifetime)
		#undef WEAPON_EXTRA_READ
		weapon_extra_primary_sound[i] = str_zone_ifneeded(cvar_string(strcat("g_weapon_extra_", ftos(i), "_primary_sound")));
		weapon_extra_primary_muzzle[i] = particleeffectnum(cvar_string(strcat("g_weapon_extra_", ftos(i), "_primary_muzzle")));
		t = weapon_extra_type_from_name(cvar_string(strcat("g_weapon_extra_", ftos(i), "_primary_type")));
		weapon_extra_primary_type[i] = t;
		if (t == WEAPON_EXTRA_TYPE_PROJECTILE)
			weapon_extra_primary_effect[i] = weapon_extra_projectile_type_from_name(cvar_string(strcat("g_weapon_extra_", ftos(i), "_primary_effect")));
		else
			weapon_extra_primary_effect[i] = particleeffectnum(cvar_string(strcat("g_weapon_extra_", ftos(i), "_primary_effect")));

		weapon_extra_primary_impact_type[i] = weapon_extra_impact_type_from_name(cvar_string(strcat("g_weapon_extra_", ftos(i), "_primary_impact_type")));
		weapon_extra_secondary_sound[i] = str_zone_ifneeded(cvar_string(strcat("g_weapon_extra_", ftos(i), "_secondary_sound")));
		weapon_extra_secondary_muzzle[i] = particleeffectnum(cvar_string(strcat("g_weapon_extra_", ftos(i), "_secondary_muzzle")));
		t = weapon_extra_type_from_name(cvar_string(strcat("g_weapon_extra_", ftos(i), "_secondary_type")));
		weapon_extra_secondary_type[i] = t;
		if (t == WEAPON_EXTRA_TYPE_PROJECTILE)
			weapon_extra_secondary_effect[i] = particleeffectnum(cvar_string(strcat("g_weapon_extra_", ftos(i), "_secondary_effect")));
		else
			weapon_extra_secondary_effect[i] = t = weapon_extra_projectile_type_from_name(cvar_string(strcat("g_weapon_extra_", ftos(i), "_secondary_effect")));

		weapon_extra_secondary_impact_type[i] = weapon_extra_impact_type_from_name(cvar_string(strcat("g_weapon_extra_", ftos(i), "_secondary_impact_type")));
		weapon_register(WEAPON_LAST + i + 1, weapon_extra_think, at, imp, 1, 0, 1, modelname, modelname, modelname);
	}
}

void(void) spawnfunc_weapon_extra {
	if (self.netname != "") {
		for (float i = WEAPON_LAST + 1; i < WEAPON_LAST_EXTRA; i++) {
			if (weapon_info(i).netname == self.netname) {
				weapon_defaultspawnfunc(i);
				break;
			}
		}
	} else
		remove(self);
}
