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
float g_balance_fireball_primary_recoil;
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
float g_balance_fireball_secondary_recoil;
float g_balance_fireball_secondary_refire;
float g_balance_fireball_secondary_refire2;
float g_balance_fireball_secondary_speed;

.float bot_secondary_fireballmooth; // whatever a mooth is
.vector fireball_impactvec;
.float fireball_secondarytime;
var .float fireball_buttonatck1 = BUTTON_ATCK;
var .float fireball_buttonatck2 = BUTTON_ATCK2;

void(void) weapon_fireball_explode {
	entity e;
	float dist;
	float points;
	vector dir;
	// 1. dist damage
	if (!self.cnt) {
		vector o = ENTITY_CENTER(self);
		effect_model_spawn("models/sphere/sphere.md3", 0, 0, o, '0 0 0', '0 0 0', '0 0 0', 0, g_balance_fireball_secondary_bfgradius, 0.2, 0.05, 0.25);
		// 2. bfg effect
		vector e_o;
		for (e = findradius(o, g_balance_fireball_secondary_bfgradius); e; e = e.chain)
		if (e != self.owner) if(e.takedamage == DAMAGE_AIM) if(e.classname != "player" || !self.owner || team_is_different_teams(e, self)) {
			e_o = ENTITY_CENTER(e);
			// can we see fireball?
			trace_line(o, e_o, TRACE_MOVE_NORMAL, self);
			if (/* trace_startsolid || */ trace_fraction != 1 && trace_ent != e) // startsolid should be never happening anyway
				continue;

			dist = vlen(o - e_o);
			points = (1 - sqrt(dist / g_balance_fireball_secondary_bfgradius));
			if (points <= 0)
				continue;

			dir = normalize(e_o - o);
			damage(e, self, self.realowner, g_balance_fireball_secondary_bfgdamage * points, self.projectiledeathtype | HITTYPE_BOUNCE | HITTYPE_SPLASH, e_o, g_balance_fireball_secondary_bfgforce * dir);
			pointparticles(particleeffectnum("fireball_bfgdamage"), e_o, -1 * dir, 1);
		}
	}
	projectile_explode();
}

void(void) weapon_fireball_touchexplode {
	PROJECTILE_TOUCH;
	weapon_fireball_explode ();
}

void(float dt, float dist, float _damage, float edgedamage, float burntime) weapon_fireball_laser_play {
	entity e;
	float d;
	vector p;
	vector o = ENTITY_CENTER(self);
	random_selection_init();
	for (e = findradius(o, dist); e; e = e.chain)
	if (e != self.owner) if(e.takedamage == DAMAGE_AIM) if(e.classname != "player" || !self.owner || team_is_different_teams(e, self)) {
		p = ENTITY_CENTER(e);;
		p_x += e.mins_x + random() * (e.maxs_x - e.mins_x);
		p_y += e.mins_y + random() * (e.maxs_y - e.mins_y);
		p_z += e.mins_z + random() * (e.maxs_z - e.mins_z);
		d = vlen(o - p);
		if (d < dist) {
			trace_line(o, p, TRACE_MOVE_NORMAL, self);
			if (/* trace_startsolid || */ trace_fraction < 1 && trace_ent != e)
				continue;

			e.fireball_impactvec = p;
			random_selection_add(e, 0, NULL, 1 / (1 + d), !fire_is_burning(e));
		}
	}
	if (random_selection_chosen_ent) {
		d = vlen(o - random_selection_chosen_ent.fireball_impactvec);
		d = _damage + (edgedamage - _damage) * (d / dist);
		fire_add_damage(random_selection_chosen_ent, self.realowner, d * burntime, burntime, self.projectiledeathtype | HITTYPE_BOUNCE);
		//trailparticles(self, particleeffectnum("fireball_laser"), o, random_selection_chosen_ent.fireball_impactvec);
		pointparticles(particleeffectnum("fireball_laser"), o, random_selection_chosen_ent.fireball_impactvec - o, 1);
	}
}

void(void) weapon_fireball_think {
	if (time > self.pushltime) {
		self.cnt = 1;
		weapon_fireball_explode();
		return;
	}
	weapon_fireball_laser_play(0.1, g_balance_fireball_secondary_laserradius, g_balance_fireball_secondary_laserdamage, g_balance_fireball_secondary_laseredgedamage, g_balance_fireball_secondary_laserburntime);
	self.nextthink = time + 0.1;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) weapon_fireball_damage {
	if (self.health <= 0)
		return;

	self.health = self.health - _damage;
	if (self.health <= 0) {
		self.cnt = 1;
		damage_prepare_explosion(attacker, projectile_explode);
	}
}

void(void) weapon_fireball_attack2 {
	entity proj;
	weapon_setup_shot(self, g_balance_fireball_secondary_recoil, "weapons/fireball_fire2.wav", 1);
	pointparticles(particleeffectnum("fireball_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	proj = projectile(TRUE, PROJECTILE_FIREBALL, TRUE, self);
	projectile_setup(proj, weapon_shotorg, EFFECT_IMPACT_FIREBALL, WEAPON_FIREBALL | HITTYPE_SECONDARY, g_balance_fireball_secondary_damage,
			g_balance_fireball_secondary_edgedamage, g_balance_fireball_secondary_radius, g_balance_fireball_secondary_force, 0, MOVETYPE_FLY);
	proj.pushltime = time + g_balance_fireball_secondary_lifetime;
	proj.use = weapon_fireball_explode;
	proj.think = weapon_fireball_think;
	proj.nextthink = time;
	proj.health = g_balance_fireball_secondary_health;
	proj.team = self.team;
	proj.event_damage = weapon_fireball_damage;
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = g_balance_fireball_secondary_damageforcescale;
	proj.velocity = weapon_shotdir * g_balance_fireball_secondary_speed;
	weapon_setup_projectile_velocity(proj);
	proj.touch = weapon_fireball_touchexplode;
}

void(float i, vector f_diff) weapon_fireball_attack_effect {
	weapon_setup_shot(self, 0, "", 0);
	weapon_shotorg += f_diff_x * v_up + f_diff_y * v_right;
	pointparticles(particleeffectnum("fireball_preattack_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
}

void(void) weapon_fireball_attack2_frame4 {
	weapon_fireball_attack2();
	weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_fireball_secondary_animtime, weapon_ready);
}

void(void) weapon_fireball_attack2_frame3 {
	weapon_fireball_attack_effect(0, '+1.25 +3.75 0');
	weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_fireball_secondary_animtime, weapon_fireball_attack2_frame4);
}

void(void) weapon_fireball_attack2_frame2 {
	weapon_fireball_attack_effect(0, '-1.25 +3.75 0');
	weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_fireball_secondary_animtime, weapon_fireball_attack2_frame3);
}

void(void) weapon_fireball_attack2_frame1 {
	weapon_fireball_attack_effect(1, '+1.25 -3.75 0');
	weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_fireball_secondary_animtime, weapon_fireball_attack2_frame2);
}

void(void) weapon_fireball_attack2_frame0 {
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_fireball_secondary_ammo;

	weapon_fireball_attack_effect(0, '-1.25 -3.75 0');
	sound (self, CHAN_WEAPON, "weapons/fireball_prefire2.wav", VOL_BASE, ATTN_NORM);
	weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_fireball_secondary_animtime, weapon_fireball_attack2_frame1);
}

void(void) weapon_fireball_mine_think {
	if (time > self.pushltime) {
		remove(self);
		return;
	}
	if (self.waterlevel > 0) {
		remove(self);
		return;
	}
	// make it "hot" once it leaves its owner
	if (self.owner) {
		if (vlen(ENTITY_CENTER(self) - ENTITY_CENTER(self.owner)) > g_balance_fireball_primary_laserradius) {
			self.cnt += 1;
			if(self.cnt == 3)
				self.owner = world;
		} else
			self.cnt = 0;
	}
	weapon_fireball_laser_play(0.1, g_balance_fireball_primary_laserradius, g_balance_fireball_primary_laserdamage, g_balance_fireball_primary_laseredgedamage, g_balance_fireball_primary_laserburntime);
	self.nextthink = time + 0.1;
}

void(void) weapon_fireball_mine_touch {
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
	if (fire_add_damage(other, self.realowner, g_balance_fireball_primary_damage, g_balance_fireball_primary_damagetime, self.projectiledeathtype | HITTYPE_HEADSHOT) >= 0) {
		weapon_score_hits(self.realowner, other, self.projectiledeathtype, 1, g_balance_fireball_primary_damage);
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void(void) weapon_fireball_attack1 {
	entity proj;
	vector f_diff;
	float c;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_fireball_primary_ammo;

	c = math_mod(self.bulletcounter, 4);
	self.bulletcounter += 1;
	switch(c) {
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
	weapon_setup_shot(self, g_balance_fireball_primary_recoil, "weapons/fireball_fire.wav", 1);
	trace_line(weapon_shotorg, weapon_shotorg + f_diff_x * v_up + f_diff_y * v_right, TRACE_MOVE_NORMAL, self);
	weapon_shotorg = trace_endpos;
	pointparticles(particleeffectnum("fireball_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	proj = projectile(TRUE, PROJECTILE_FIREMINE, TRUE, self);
	projectile_setup(proj, weapon_shotorg, 0, WEAPON_FIREBALL, g_balance_fireball_primary_damage, 0, 0, 0, 1, MOVETYPE_BOUNCE);
	proj.solid = SOLID_CORPSE;
	proj.touch = weapon_fireball_mine_touch;
	proj.think = weapon_fireball_mine_think;
	proj.nextthink = time;
	proj.damageforcescale = g_balance_fireball_primary_damageforcescale;
	proj.velocity = weapon_shotdir * g_balance_fireball_primary_speed + v_up * g_balance_fireball_primary_speed_up;
	proj.pushltime = time + g_balance_fireball_primary_lifetime;
	weapon_setup_projectile_velocity(proj);
}

void(void) spawnfunc_weapon_fireball {
	weapon_defaultspawnfunc(WEAPON_FIREBALL);
}

float(float req) weapon_fireball {
	if (req == WEAPON_REQUEST_AIM) {
		self.fireball_buttonatck1 = FALSE;
		self.fireball_buttonatck2 = FALSE;
		if (self.bot_secondary_fireballmooth == 0) {
			if (bot_aim(g_balance_fireball_primary_speed, g_balance_fireball_primary_speed_up, g_balance_fireball_primary_lifetime, TRUE)) {
				self.fireball_buttonatck1 = TRUE;
				if(random() < 0.01) self.bot_secondary_fireballmooth = 1;
			}
		} else {
			if (bot_aim(g_balance_fireball_secondary_speed, 0, g_balance_fireball_secondary_lifetime, FALSE)) {
				self.fireball_buttonatck2 = TRUE;
				if(random() < 0.02) self.bot_secondary_fireballmooth = 0;
			}
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.fireball_buttonatck1)
		if (weapon_prepareattack(0, g_balance_fireball_primary_refire)) {
			weapon_fireball_attack1();
			weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_fireball_primary_animtime, weapon_ready);
		}
		if (self.fireball_buttonatck2)
		if (time >= self.fireball_secondarytime)
		if (weapon_prepareattack(1, g_balance_fireball_secondary_refire)) {
			weapon_fireball_attack2_frame0();
			self.fireball_secondarytime = time + g_balance_fireball_secondary_refire2;
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_model("models/sphere/sphere.md3");
		precache_sound("weapons/fireball_fire.wav");
		precache_sound("weapons/fireball_fire2.wav");
		precache_sound("weapons/fireball_prefire2.wav");
	} else if (req == WEAPON_REQUEST_SETUP) {
		self.bulletcounter = 0;
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE) {
		if(weapon_deathtype & HITTYPE_SECONDARY)
			weapon_deathtypestring = "should have used a smaller gun";
		else
			weapon_deathtypestring = "forgot about some firemine";
	} else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		if (weapon_deathtype & HITTYPE_SECONDARY) {
			if (weapon_deathtype & HITTYPE_BOUNCE) {
				if (weapon_deathtype & HITTYPE_SPLASH) { // BFG effect
					weapon_deathtypestring = "could not hide from #'s fireball";
				} else { // laser
					weapon_deathtypestring = "saw the pretty lights of #'s fireball";
				}
			} else if (weapon_deathtype & HITTYPE_SPLASH)
				weapon_deathtypestring = "got too close to #'s fireball";
			else
				weapon_deathtypestring = "tasted #'s fireball";
		} else {
			if (weapon_deathtype & HITTYPE_HEADSHOT)
				weapon_deathtypestring = "tried to catch #'s firemine";
			else
				weapon_deathtypestring = "fatefully ignored #'s firemine";
		}
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		self.fireball_secondarytime = time;
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_fireball_primary_ammo);
		CVAR_CACHE(g_balance_fireball_primary_animtime);
		CVAR_CACHE(g_balance_fireball_primary_damage);
		CVAR_CACHE(g_balance_fireball_primary_damageforcescale);
		CVAR_CACHE(g_balance_fireball_primary_damagetime);
		CVAR_CACHE(g_balance_fireball_primary_laserburntime);
		CVAR_CACHE(g_balance_fireball_primary_laserdamage);
		CVAR_CACHE(g_balance_fireball_primary_laseredgedamage);
		CVAR_CACHE(g_balance_fireball_primary_laserradius);
		CVAR_CACHE(g_balance_fireball_primary_lifetime);
		CVAR_CACHE(g_balance_fireball_primary_recoil);
		CVAR_CACHE(g_balance_fireball_primary_refire);
		CVAR_CACHE(g_balance_fireball_primary_speed);
		CVAR_CACHE(g_balance_fireball_primary_speed_up);
		CVAR_CACHE(g_balance_fireball_secondary_ammo);
		CVAR_CACHE(g_balance_fireball_secondary_animtime);
		CVAR_CACHE(g_balance_fireball_secondary_bfgdamage);
		CVAR_CACHE(g_balance_fireball_secondary_bfgforce);
		CVAR_CACHE(g_balance_fireball_secondary_bfgradius);
		CVAR_CACHE(g_balance_fireball_secondary_damage);
		CVAR_CACHE(g_balance_fireball_secondary_damageforcescale);
		CVAR_CACHE(g_balance_fireball_secondary_edgedamage);
		CVAR_CACHE(g_balance_fireball_secondary_force);
		CVAR_CACHE(g_balance_fireball_secondary_health);
		CVAR_CACHE(g_balance_fireball_secondary_laserburntime);
		CVAR_CACHE(g_balance_fireball_secondary_laserdamage);
		CVAR_CACHE(g_balance_fireball_secondary_laseredgedamage);
		CVAR_CACHE(g_balance_fireball_secondary_laserradius);
		CVAR_CACHE(g_balance_fireball_secondary_lifetime);
		CVAR_CACHE(g_balance_fireball_secondary_radius);
		CVAR_CACHE(g_balance_fireball_secondary_recoil);
		CVAR_CACHE(g_balance_fireball_secondary_refire);
		CVAR_CACHE(g_balance_fireball_secondary_refire2);
		CVAR_CACHE(g_balance_fireball_secondary_speed);
		projectile_init(PROJECTILE_FIREMINE);
		projectile_init(PROJECTILE_FIREBALL);
		if (cvar("g_balance_fireball_swap_buttons")) {
			fireball_buttonatck1 = BUTTON_ATCK2;
			fireball_buttonatck2 = BUTTON_ATCK;
		}
		weapon_ammo_limits(WEAPON_FIREBALL, g_balance_fireball_primary_ammo, g_balance_fireball_secondary_ammo);
	}
	return TRUE;
}
