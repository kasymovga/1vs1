float g_balance_rocketlauncher_ammo;
float g_balance_rocketlauncher_animtime;
float g_balance_rocketlauncher_damageforcescale;
float g_balance_rocketlauncher_edgedamage;
float g_balance_rocketlauncher_force;
float g_balance_rocketlauncher_guidedelay;
float g_balance_rocketlauncher_guidefadeangle;
float g_balance_rocketlauncher_guidegoal;
float g_balance_rocketlauncher_guidemaxangle;
float g_balance_rocketlauncher_guiderate;
float g_balance_rocketlauncher_guideratedelay;
float g_balance_rocketlauncher_guidestop;
float g_balance_rocketlauncher_health;
float g_balance_rocketlauncher_lifetime;
float g_balance_rocketlauncher_radius;
float g_balance_rocketlauncher_recoil;
float g_balance_rocketlauncher_refire;
float g_balance_rocketlauncher_speed;
float g_balance_rocketlauncher_speedaccel;
float g_balance_rocketlauncher_speedstart;

.float rl_release;
.float rl_detonate_later;
.entity lastrocket;
var .float rl_buttonatck1 = BUTTON_ATCK;
var .float rl_buttonatck2 = BUTTON_ATCK2;

void(void) weapon_rocketlauncher_unregister {
	if (self.owner && self.lastrocket.lastrocket == self) {
		self.lastrocket.lastrocket = world;
		// self.owner.rl_release = 1;
	}
}

void(void) weapon_rocketlauncher_explode {
	weapon_rocketlauncher_unregister();
	if (other.takedamage == DAMAGE_AIM)
		if (other.classname == "player")
			if (team_is_different_teams(self.owner, other))
				if (physics_is_flying(other))
					announce(self.owner, "announcer/male/airshot.wav", "^5Air^1Shot");

	if (self.owner.weapon == WEAPON_ROCKET_LAUNCHER) {
		if not(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)
		if (self.owner.ammo_rockets < g_balance_rocketlauncher_ammo) {
			self.owner.cnt = WEAPON_ROCKET_LAUNCHER;
			WEAPON_ATTACK_FINISHED(self.owner) = time;
			self.owner.switchweapon = weapon_best(self.owner);
		}
	}
	self.realowner = self.owner;
	projectile_explode();
}

void(void) weapon_rocketlauncher_remote_explode {
	if (self.owner.deadflag == DEAD_NO)
	if (self.lastrocket.lastrocket) {
		if ((self.spawnshieldtime >= 0)
				? (time >= self.spawnshieldtime) // timer
				: (vlen(entity_nearest_point_on_box(self.owner, self.origin) - self.origin) > g_balance_rocketlauncher_radius) // safety device
		) {
			other = world;
			self.projectiledeathtype |= HITTYPE_BOUNCE;
			weapon_rocketlauncher_explode ();
		}
	}
}

vector(vector thisdir, vector goaldir, float maxturn_angle) weapon_rocketlauncher_rocket_steerto {
	maxturn_angle *= MATH_DEG2RAD;
	float maxturn_cos = cos(maxturn_angle);
	if (thisdir * goaldir > maxturn_cos)
		return goaldir;

	while (maxturn_angle > 45 * MATH_DEG2RAD) {
		thisdir = weapon_rocketlauncher_rocket_steerto(thisdir, goaldir, 45);
		maxturn_angle -= 45 * MATH_DEG2RAD;
	}
	vector v = goaldir - thisdir;
	vector steerdir = normalize(v + (v * goaldir) * thisdir);
	return normalize(steerdir * tan(maxturn_angle) + thisdir);
}

void(void) weapon_rocketlauncher_think {
	vector desireddir, olddir, newdir, desiredorigin, goal;
	float velspeed, f;
	self.nextthink = time;
	if (time > self.cnt) {
		other = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		weapon_rocketlauncher_explode ();
		return;
	}
	// accelerate
	makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0');
	velspeed = g_balance_rocketlauncher_speed * g_weaponspeedfactor - (self.velocity * v_forward);
	if (velspeed > 0)
		self.velocity = self.velocity + v_forward * min(g_balance_rocketlauncher_speedaccel * g_weaponspeedfactor * frametime, velspeed);

	if (self.owner.weapon == WEAPON_ROCKET_LAUNCHER) {
		if (self == self.lastrocket.lastrocket)
		if (!self.owner.rl_release)
		if (g_balance_rocketlauncher_guiderate)
		if (time > self.pushltime)
		if (self.owner.deadflag == DEAD_NO) {
			f = g_balance_rocketlauncher_guideratedelay;
			if (f)
				f = bound(0, (time - self.pushltime) / f, 1);
			else
				f = 1;

			velspeed = vlen(self.velocity);
			makevectors(self.owner.v_angle);
			vector v = self.realowner.punchangle;
			weapon_setup_shot(self.realowner, 0, "", 0);
			self.realowner.punchangle = v;
			desireddir = warpzone_refsys_transform_velocity(self.owner, self, weapon_shotdir);
			desiredorigin = warpzone_refsys_transform_origin(self.owner, self, weapon_shotorg);
			olddir = normalize(self.velocity);
			// now it gets tricky... we want to move like some curve to approximate the target direction
			// but we are limiting the rate at which we can turn!
			goal = desiredorigin + ((self.origin - desiredorigin) * desireddir + g_balance_rocketlauncher_guidegoal) * desireddir;
			newdir = weapon_rocketlauncher_rocket_steerto(olddir, normalize(goal - self.origin), min(180, g_balance_rocketlauncher_guiderate * f * frametime));
			self.velocity = newdir * velspeed;
			if (!self.count) {
				pointparticles(particleeffectnum("rocket_guide"), self.origin, self.velocity, 1);
				// TODO add a better sound here
				sound (self.owner, CHAN_WEAPON2, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);
				self.count = 1;
			}
		}
		if (self.rl_detonate_later)
			weapon_rocketlauncher_remote_explode();
	}
}

void(void) weapon_rocketlauncher_touch {
	PROJECTILE_TOUCH;
	weapon_rocketlauncher_explode();
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) weapon_rocketlauncher_damage  {
	if (self.health <= 0)
		return;

	self.health = self.health - _damage;
	if (self.health <= 0)
		damage_prepare_explosion(attacker, weapon_rocketlauncher_explode);
}

void(void) weapon_rocketlauncher_attack {
	entity missile;
	entity flash;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - g_balance_rocketlauncher_ammo;

	weapon_setup_shot(self, g_balance_rocketlauncher_recoil, "weapons/rocket_fire.wav", 1);
	pointparticles(particleeffectnum("rocketlauncher_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	missile = projectile(g_balance_rocketlauncher_guiderate == 0 && g_balance_rocketlauncher_speedaccel == 0, PROJECTILE_ROCKET, FALSE, self); // because of fly sound
	projectile_setup(missile, weapon_shotorg - v_forward * 3, EFFECT_IMPACT_ROCKET, WEAPON_ROCKET_LAUNCHER, g_balance_rocketlauncher_damage, // move it back so it hits the wall at the right point
			g_balance_rocketlauncher_edgedamage, g_balance_rocketlauncher_radius, g_balance_rocketlauncher_force, 0, MOVETYPE_FLY);
	warpzone_refsys_copy(missile, missile.owner);
	missile.classname = "rocket"; //for remote exploding
	missile.realowner = self; //we neeed it without akimbo_owner for guiding
	missile.lastrocket = self;
	self.lastrocket = missile;
	if (g_balance_rocketlauncher_detonatedelay >= 0)
		missile.spawnshieldtime = time + g_balance_rocketlauncher_detonatedelay;
	else
		missile.spawnshieldtime = -1;

	missile.pushltime = time + g_balance_rocketlauncher_guidedelay;
	missile.takedamage = DAMAGE_YES;
	missile.damageforcescale = g_balance_rocketlauncher_damageforcescale;
	missile.health = g_balance_rocketlauncher_health;
	missile.event_damage = weapon_rocketlauncher_damage;
	missile.velocity = weapon_shotdir * g_balance_rocketlauncher_speedstart * g_weaponspeedfactor;
	weapon_setup_projectile_velocity(missile);
	missile.touch = weapon_rocketlauncher_touch;
	missile.think = weapon_rocketlauncher_think;
	missile.nextthink = time;
	missile.cnt = time + g_balance_rocketlauncher_lifetime;
	// muzzle flash for 1st person view
	flash = spawn ();
	setmodel (flash, "models/flash.md3"); // precision set below
	entity_fade_setup(flash, time, 0.1);
	flash.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION;
	weapon_attach_to_shotorg(flash, '5 0 0');
}

void(void) spawnfunc_weapon_rocketlauncher; // defined in t_items.qc

float(float req) weapon_rocketlauncher {
	entity rock;
	float rockfound;
	if (req == WEAPON_REQUEST_AIM) {
		// aim and decide to fire if appropriate
		self.rl_buttonatck1 = bot_aim(g_balance_rocketlauncher_speed, 0, g_balance_rocketlauncher_lifetime, FALSE);
		if(skill >= 2) { // skill 0 and 1 bots won't detonate rockets!
			// decide whether to detonate rockets
			entity missile, targetlist, targ;
			float edgedamage, coredamage, edgeradius, recipricoledgeradius, d;
			float selfdamage, teamdamage, enemydamage;
			edgedamage = g_balance_rocketlauncher_edgedamage;
			coredamage = g_balance_rocketlauncher_damage;
			edgeradius = g_balance_rocketlauncher_radius;
			recipricoledgeradius = 1 / edgeradius;
			selfdamage = 0;
			teamdamage = 0;
			enemydamage = 0;
			targetlist = findchainfloat(bot_attack, TRUE);
			missile = find(world, classname, "rocket");
			while (missile) {
				if (missile.owner != self) {
					missile = find(missile, classname, "rocket");
					continue;
				}
				targ = targetlist;
				while (targ) {
					d = vlen(targ.origin + (targ.mins + targ.maxs) * 0.5 - missile.origin);
					d = bound(0, edgedamage + (coredamage - edgedamage) * sqrt(1 - d * recipricoledgeradius), 10000);
					// count potential damage according to type of target
					if (targ == self)
						selfdamage = selfdamage + d;
					else if (targ.team == self.team && team_mode)
						teamdamage = teamdamage + d;
					else if (bot_aim_shouldattack(targ))
						enemydamage = enemydamage + d;

					targ = targ.chain;
				}
				missile = find(missile, classname, "rocket");
			}
			float desirabledamage;
			desirabledamage = enemydamage;
			if (time > self.spawnshieldtime)
				desirabledamage = desirabledamage - selfdamage * g_balance_selfdamagepercent;

			if (self.team)
				desirabledamage = desirabledamage - teamdamage;

			missile = find(world, classname, "rocket");
			while (missile) {
				if (missile.owner != self) {
					missile = find(missile, classname, "rocket");
					continue;
				}
				makevectors(missile.v_angle);
				targ = targetlist;
				if (skill > 9) { // normal players only do this for the target they are tracking
					targ = targetlist;
					while (targ) {
						if ((v_forward * normalize(missile.origin - targ.origin)< 0.1)
								&& desirabledamage > 0.1*coredamage)
							self.rl_buttonatck2 = TRUE;

						targ = targ.chain;
					}
				} else {
					float distance; distance= bound(300,vlen(self.origin-self.enemy.origin),30000);
					//As the distance gets larger, a correct detonation gets near imposible
					//Bots are assumed to use the rocket spawnfunc_light to see if the rocket gets near a player
					if (v_forward * normalize(missile.origin - self.enemy.origin)< 0.1)
						if (self.enemy.classname == "player")
							if (desirabledamage >= 0.1*coredamage)
								if (random()/distance*300 > frametime*bound(0,(10-skill)*0.2,1))
									self.rl_buttonatck2 = TRUE;
				//	dprint(ftos(random()/distance*300),">");dprint(ftos(frametime*bound(0,(10-skill)*0.2,1)),"\n");
				}
				missile = find(missile, classname, "rocket");
			}
			// if we would be doing at X percent of the core damage, detonate it
			// but don't fire a new shot at the same time!
			if (desirabledamage >= 0.75 * coredamage) //this should do group damage in rare fortunate events
				self.rl_buttonatck2 = TRUE;

			if ((skill > 6.5) && (selfdamage > self.health))
				self.rl_buttonatck2 = FALSE;

			if (self.rl_buttonatck2 == TRUE) self.rl_buttonatck1 = FALSE;
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.rl_buttonatck1) {
			if (self.rl_release || g_balance_rocketlauncher_guidestop)
			if (weapon_prepareattack(0, g_balance_rocketlauncher_refire)) {
				weapon_rocketlauncher_attack();
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_rocketlauncher_animtime, weapon_ready);
				self.rl_release = 0;
			}
		} else
			self.rl_release = 1;

		if (self.rl_buttonatck2) {
			rockfound = 0;
			for (rock = world; (rock = find(rock, classname, "rocket")); ) if (rock.lastrocket == self) {
				if (!rock.rl_detonate_later) {
					rock.rl_detonate_later = TRUE;
					rockfound = 1;
				}
			}
			if (rockfound)
				sound (self, CHAN_WEAPON2, "weapons/rocket_det.wav", VOL_BASE, ATTN_NORM);
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		hint_add("With Rocket Launcher you can guide rockets by holding attack button. You can explode rocket midair with secondary attack button.");
		precache_model("models/flash.md3");
		precache_sound("weapons/rocket_det.wav");
		precache_sound("weapons/rocket_fire.wav");
		precache_sound("weapons/rocket_mode.wav");
	} else if (req == WEAPON_REQUEST_SETUP) {
		//weapon_setup(WEAPON_ROCKET_LAUNCHER);
		self.rl_release = 1;
	} else if (req == WEAPON_REQUEST_CHECKAMMO1) {
		// don't switch while guiding a missile
		if ((WEAPON_ATTACK_FINISHED(self) <= time || self.weapon != WEAPON_ROCKET_LAUNCHER)
				&& self.ammo_rockets < g_balance_rocketlauncher_ammo)
			return FALSE;
	} else if (req == WEAPON_REQUEST_CHECKAMMO2)
		return FALSE;
	else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "exploded";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		if(weapon_deathtype & HITTYPE_BOUNCE) // (remote detonation)
			weapon_deathtypestring = "got too close to #'s rocket";
		else if(weapon_deathtype & HITTYPE_SPLASH)
			weapon_deathtypestring = "almost dodged #'s rocket";
		else
			weapon_deathtypestring = "ate #'s rocket";
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		self.rl_release = 0;
		self.lastrocket = world; // stop rocket guiding, no revenge from the grave!
	} else if (req == WEAPON_REQUEST_CLEAR) {
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_rocketlauncher_ammo);
		CVAR_CACHE(g_balance_rocketlauncher_animtime);
		CVAR_CACHE(g_balance_rocketlauncher_damage);
		CVAR_CACHE(g_balance_rocketlauncher_damageforcescale);
		CVAR_CACHE(g_balance_rocketlauncher_detonatedelay);
		CVAR_CACHE(g_balance_rocketlauncher_edgedamage);
		CVAR_CACHE(g_balance_rocketlauncher_force);
		CVAR_CACHE(g_balance_rocketlauncher_guidedelay);
		CVAR_CACHE(g_balance_rocketlauncher_guidefadeangle);
		CVAR_CACHE(g_balance_rocketlauncher_guidegoal);
		CVAR_CACHE(g_balance_rocketlauncher_guidemaxangle);
		CVAR_CACHE(g_balance_rocketlauncher_guiderate);
		CVAR_CACHE(g_balance_rocketlauncher_guideratedelay);
		CVAR_CACHE(g_balance_rocketlauncher_guidestop);
		CVAR_CACHE(g_balance_rocketlauncher_health);
		CVAR_CACHE(g_balance_rocketlauncher_lifetime);
		CVAR_CACHE(g_balance_rocketlauncher_radius);
		CVAR_CACHE(g_balance_rocketlauncher_recoil);
		CVAR_CACHE(g_balance_rocketlauncher_refire);
		CVAR_CACHE(g_balance_rocketlauncher_speed);
		CVAR_CACHE(g_balance_rocketlauncher_speedaccel);
		CVAR_CACHE(g_balance_rocketlauncher_speedstart);
		projectile_init(PROJECTILE_ROCKET);
		if (cvar("g_balance_rocketlauncher_swap_buttons")) {
			rl_buttonatck1 = BUTTON_ATCK2;
			rl_buttonatck2 = BUTTON_ATCK;
		}
	}
	return TRUE;
}

void(void) spawnfunc_weapon_rocketlauncher {
	weapon_defaultspawnfunc(WEAPON_ROCKET_LAUNCHER);
}
