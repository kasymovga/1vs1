float MINSTAGIB_WEAPON;
float minstagib_ammo;

float g_minstagib;
float g_minstagib_ammo_drop;
float g_minstagib_armor_max;
float g_minstagib_health_drop;
float g_minstagib_health_max;
float g_minstagib_invis_alpha;
float g_minstagib_speed_moverate;
float g_minstagib_nolaserdamage;
float g_minstagib_extralives;
float g_balance_minstanex_damage;
float g_balance_minstanex_animtime;
float g_balance_minstanex_refire;
float g_balance_minstanex_explode;
float g_balance_minstanex_explode_damage;
float g_balance_minstanex_explode_edgedamage;
float g_balance_minstanex_explode_force;
float g_balance_minstanex_explode_radius;
float g_balance_minstanex_laser;
float g_balance_minstanex_laser_count;
float g_balance_minstanex_laser_damage;
float g_balance_minstanex_laser_edgedamage;
float g_balance_minstanex_laser_force;
float g_balance_minstanex_laser_lifetime;
float g_balance_minstanex_laser_spread;
float g_balance_minstanex_laser_speed;
float g_balance_minstanex_laser_radius;
float g_balance_minstanex_laser_refire;
float g_balance_minstanex_laser_rapid;
float g_balance_minstanex_laser_rapid_delay;
float g_balance_minstanex_laser_rapid_refire;

.float minstanex_lasthit;
.float laser_hold;
.float jump_interval;

float minstagib_weapon_draw_beam_particles_effect;
void(vector start, vector end, vector to) minstagib_weapon_draw_beam_particles {
	weapon_nex_whoosh(start, end);
	trailparticles(world, minstagib_weapon_draw_beam_particles_effect, start, end);
}

void(void) minstagib_weapon_attack {
	float flying;
	flying = physics_is_flying(self); // do this BEFORE to make the trace values from bullet_railgun last
	antilag_begin(akimbo_owner(self));
	weapon_setup_shot (self, 0, "weapons/minstanexfire.wav", 1);
	damage_yoda = 0;
	damage_goodhits = 0;
	damage_headshot = 0;
	bullet_railgun (weapon_shotorg, weapon_shotorg + weapon_shotdir * WORLD_MAX_SHOT_DISTANCE, g_balance_minstanex_damage, 800, 0, 0, 0, 0, MINSTAGIB_WEAPON);
	antilag_end();
	if (damage_yoda > 1)
		announce(self, "announcer/male/yoda.wav", "^5Awesome");

	if (damage_headshot)
		announce(self, "announcer/male/headshot.wav", "^1Head^3Shot");

	self.minstanex_lasthit = damage_goodhits;
	pointparticles(particleeffectnum("nex_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	// teamcolor / hit beam effect
	if (team_mode) {
		switch(self.team) {
		case COLOR_TEAM1:   // Red
			if(damage_goodhits)
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3RED_HIT");
			else
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3RED");
			break;
		case COLOR_TEAM2:   // Blue
			if(damage_goodhits)
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3BLUE_HIT");
			else
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3BLUE");
			break;
		case COLOR_TEAM3:   // Yellow
			if(damage_goodhits)
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3YELLOW_HIT");
			else
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3YELLOW");
			break;
		case COLOR_TEAM4:   // Pink
			if(damage_goodhits)
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3PINK_HIT");
			else
				minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3PINK");
			break;
		}
	} else
		minstagib_weapon_draw_beam_particles_effect = particleeffectnum("TE_TEI_G3");

	warpzone_draw_effect_triangle(weapon_shotorg, weapon_shotorg_visual,  warpzone_untransform_origin(warpzone_trace_transform, trace_endpos), minstagib_weapon_draw_beam_particles);
	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)) {
		if (g_balance_minstanex_explode) {
			entity e = spawn();
			setorigin(e, trace_endpos);
			entity o = akimbo_owner(self);
			damage_radius (e, o, g_balance_minstanex_explode_damage, g_balance_minstanex_explode_edgedamage, g_balance_minstanex_explode_radius, world, g_balance_minstanex_explode_force, EFFECT_IMPACT_ROCKET, 0, world);
			remove(e);
		}
		effect_impact(trace_endpos, 10000, 0, 0, 800 * warpzone_transform_velocity(warpzone_trace_transform, weapon_shotdir), EFFECT_IMPACT_NEX, self);
	}
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - 1;
}

void(void) minstagib_weapon_laser_attack_setup {
	float w_safe = self.weapon;
	self.weapon = WEAPON_LASER;
	weapon_setup_shotdir(self, v_forward, 3, "weapons/lasergun_fire.wav", 1);
	self.weapon = w_safe;
}

float(void) minstagib_weapon_player_can_fire {
	float w_safe = self.weapon;
	self.weapon = WEAPON_LASER;
	float r = player_can_fire(self, TRUE);
	self.weapon = w_safe;
	return r;
}

void(void) minstagib_weapon_laser_attack {
	minstagib_weapon_laser_attack_setup();
	pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	float f1, f2;
	if (g_balance_minstanex_laser_count > 1) {
		f1 = g_balance_minstanex_laser_spread / (g_balance_minstanex_laser_count - 1);
		f2 = -0.5 * g_balance_minstanex_laser_spread;
	} else
		f1 = f2 = 0;

	float i;
	vector v;
	float ff = 1 / g_balance_minstanex_laser_count;
	for (i = 0; i < g_balance_minstanex_laser_count; i++) {
		v = weapon_shotdir + v_right * f2;
		f2 += f1;
		laser_projectile(v, g_balance_minstanex_laser_speed,
				g_balance_minstanex_laser_damage * ff, g_balance_minstanex_laser_edgedamage * ff,
				g_balance_minstanex_laser_radius, g_balance_minstanex_laser_force * ff,
				g_balance_minstanex_explode, TRUE, g_balance_minstanex_laser_lifetime);
	}
}

void(void) minstagib_weapon_laser_attack_rapid {
	minstagib_weapon_laser_attack_setup();
	pointparticles(particleeffectnum("laser_muzzleflash"), weapon_shotorg_visual, weapon_shotdir * 1000, 1);
	laser_projectile(weapon_shotdir, g_balance_minstanex_laser_speed,
			g_balance_minstanex_laser_damage, g_balance_minstanex_laser_edgedamage,
			g_balance_minstanex_laser_radius, g_balance_minstanex_laser_force,
			g_balance_minstanex_explode, TRUE, g_balance_minstanex_laser_lifetime);
}

#define minstagib_weapon weapon_minstanex
float(float req) minstagib_weapon {
	if (req == WEAPON_REQUEST_AIM) {
		if (self.ammo_cells > 0 || self.items & IT_UNLIMITED_AMMO)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(g_balance_laser_primary_speed, 0, g_balance_laser_primary_lifetime, FALSE);
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.BUTTON_ATCK) {
			if (weapon_prepareattack(0, g_balance_minstanex_refire)) {
				minstagib_weapon_attack();
				weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_minstanex_animtime, weapon_ready);
			}
		}
		if (g_balance_minstanex_laser) {
			if (self.BUTTON_ATCK2) {
				if not(self.laser_hold) {
					if (self.jump_interval <= time)
					if (minstagib_weapon_player_can_fire()) {
						self.jump_interval = time + g_balance_minstanex_laser_refire * weapon_rate_factor();
						minstagib_weapon_laser_attack();
						if (g_balance_minstanex_laser_rapid)
							self.laser_hold = time + g_balance_minstanex_laser_rapid_delay;
					}
				} else {
					if (self.laser_hold <= time)
					if (self.jump_interval <= time)
					if (minstagib_weapon_player_can_fire()) {
						self.jump_interval = time + g_balance_minstanex_laser_rapid_refire * weapon_rate_factor();
						minstagib_weapon_laser_attack_rapid();
					}
				}
			} else {
				self.laser_hold = 0;
			}
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		precache_model("models/nexflash.md3");
		precache_sound("weapons/minstanexfire.wav");
		precache_sound("weapons/nexwhoosh1.wav");
		precache_sound("weapons/nexwhoosh2.wav");
		precache_sound("weapons/nexwhoosh3.wav");
		weapon_laser(WEAPON_REQUEST_PRECACHE);
	} else if (req == WEAPON_REQUEST_SETUP) {
		self.minstanex_lasthit = 0;
		self.laser_hold = 0;
		self.jump_interval = time;
	} else if (req == WEAPON_REQUEST_CHECKAMMO1) {
		return self.ammo_cells >= 1;
	} else if (req == WEAPON_REQUEST_CHECKAMMO2)
		return TRUE;
	else if (req == WEAPON_REQUEST_SUICIDEMESSAGE)
		weapon_deathtypestring = "did the impossible";
	else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_fragprefix = "^5INSTA";
		weapon_deathtypestring = "has been vaporized by";
	} else if (req == WEAPON_REQUEST_RESETPLAYER) {
		self.minstanex_lasthit = 0;
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_minstanex_damage);
		CVAR_CACHE(g_balance_minstanex_animtime);
		CVAR_CACHE(g_balance_minstanex_refire);
		CVAR_CACHE(g_balance_minstanex_explode);
		CVAR_CACHE(g_balance_minstanex_explode_damage);
		CVAR_CACHE(g_balance_minstanex_explode_edgedamage);
		CVAR_CACHE(g_balance_minstanex_explode_force);
		CVAR_CACHE(g_balance_minstanex_explode_radius);
		CVAR_CACHE(g_balance_minstanex_laser);
		g_balance_minstanex_laser_count = max(1, cvar("g_balance_minstanex_laser_count"));
		CVAR_CACHE(g_balance_minstanex_laser_damage);
		CVAR_CACHE(g_balance_minstanex_laser_edgedamage);
		CVAR_CACHE(g_balance_minstanex_laser_force);
		CVAR_CACHE(g_balance_minstanex_laser_lifetime);
		CVAR_CACHE(g_balance_minstanex_laser_speed);
		CVAR_CACHE(g_balance_minstanex_laser_spread);
		CVAR_CACHE(g_balance_minstanex_laser_radius);
		CVAR_CACHE(g_balance_minstanex_laser_refire);
		CVAR_CACHE(g_balance_minstanex_laser_rapid);
		CVAR_CACHE(g_balance_minstanex_laser_rapid_delay);
		CVAR_CACHE(g_balance_minstanex_laser_rapid_refire);
		if (g_balance_minstanex_explode) {
			dlc_require("rm_effects_v2");
			projectile_init(PROJECTILE_RM_LASER);
		} else
			projectile_init(PROJECTILE_LASER);
	}
	return TRUE;
}
void(float itemid) minstagib_items {
	if not(self.classname == "droppedweapon")
		self.classname = "minstagib";

	// replace rocket launchers and nex guns with ammo cells
	if (itemid == IT_CELLS) {
		if not(minstagib_ammo || g_minstagib_health_drop) {
			remove(self);
			return;
		}
		if (minstagib_ammo)
			self.ammo_cells = 1;

		if (g_minstagib_health_drop) {
			self.health = 1;
			item_start(sv_model_healthlarge, "models/items/g_h50.md3",
				"misc/mediumhealth.wav", 45, 0,
				"Health", IT_CELLS, 0, item_generic_pickupevalfunc, 100);
		} else {
			item_start(sv_model_ammocells, "models/items/a_cells.md3",
				"misc/itempickup.wav", 45, 0,
				"Nex Ammo", IT_CELLS, 0, item_generic_pickupevalfunc, 100);
		}
		return;
	}
	// replace with extra lives
	if (itemid == IT_NAILS)
	if (g_minstagib_extralives) {
		self.max_health = 1;
		item_start(sv_model_armorlarge, "models/items/g_a25.md3",
			"misc/megahealth.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
			"Extralife", IT_NAILS, FL_POWERUP, item_generic_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
		return;
	}
	remove(self);
}

float minst_no_auto_cells;
void(void) minst_remove_item {
	if (minst_no_auto_cells)
		remove(self);
}

.float minstagib_nextthink;
var void() minstagib_player_think_next;
void() minstagib_player_think {
	minstagib_player_think_next();
	if (time < self.minstagib_nextthink || self.deadflag || map_finished)
		return;

	if not(self.items & IT_UNLIMITED_AMMO)
	if (self.ammo_cells <= 0) {
		if (self.health <= 5) {
			centerprint(self, "you're dead now...\n");
			damage(self, self, self, 5, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/terminated.wav", "^1Terminated");
		} else if (self.health <= 10) {
			centerprint(self, "^11^7 second left to find some ammo\n");
			damage(self, self, self, 5, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/1.wav", "^11");
		} else if (self.health <= 20) {
			centerprint(self, "^12^7 seconds left to find some ammo\n");
			damage(self, self, self, self.health - 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/2.wav", "^12");
		} else if (self.health <= 30) {
			centerprint(self, "^13^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/3.wav", "^13");
		} else if (self.health <= 40) {
			centerprint(self, "^14^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/4.wav", "4");
		} else if (self.health <= 50) {
			centerprint(self, "^15^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/5.wav", "5");
		} else if (self.health <= 60) {
			centerprint(self, "^36^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/6.wav", "");
		} else if (self.health <= 70) {
			centerprint(self, "^37^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/7.wav", "");
		} else if (self.health <= 80) {
			centerprint(self, "^38^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/8.wav", "");
		} else if (self.health <= 90) {
			centerprint(self, "^39^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/9.wav", "");
		} else if (self.health <= 100) {
			centerprint(self, "get some ammo or\nyou'll be dead in ^310^7 seconds...");
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
			announce(self, "announcer/robotic/10.wav", "");
		} else {
			damage(self, self, self, 10, DEATH_ROT, self.origin, '0 0 0');
		}
	}
	self.minstagib_nextthink = time + 1;
}

var float(entity item, entity player) minstagib_ItemGiveToHandle_next; //Not used actually
float minstagib_ItemGiveToHandle(entity item, entity player) {
	float it;
	if not(item.spawnshieldtime)
		return TRUE;

	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max) {
		plugin_chain_ItemGiveToHandle_PickedUp = TRUE;
		player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
		player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	}
	if ((it = (item.items - (item.items & player.items)) & IT_PICKUPMASK)) {
		plugin_chain_ItemGiveToHandle_PickedUp = TRUE;
		player.items |= it;
		sprint (player, strcat("You got the ^2", item.netname, "\n"));
	}
	plugin_chain_ItemGiveToHandle_SwitchWeapon = TRUE;
	if (item.health) {
		player.health = min(max(100, player.health + g_minstagib_health_drop), g_minstagib_health_max);
		plugin_chain_ItemGiveToHandle_PickedUp = TRUE;
	}
	if (item.ammo_cells) {
		plugin_chain_ItemGiveToHandle_PickedUp = TRUE;
		// play some cool sounds ;)
		if (clienttype(player) == CLIENTTYPE_REAL) {
			if (player.health <= 5)
				sound_play2(player, "announcer/robotic/lastsecond.wav");
			else if (player.health < 50)
				sound_play2(player, "announcer/robotic/narrowly.wav");
		}
		// sound not available
		// else if(item.items == IT_CELLS)
		//	play2(player, "announce/robotic/ammo.wav");

		if not(player.items & IT_UNLIMITED_AMMO)
			player.ammo_cells = min (player.ammo_cells + g_minstagib_ammo_drop, 999);
		player.health = max(100, player.health);
	}
	// extralife powerup
	if (item.max_health) {
		plugin_chain_ItemGiveToHandle_PickedUp = TRUE;
		// sound not available
		// play2(player, "announce/robotic/extra.ogg\nplay2 announce/robotic/_lives.wav");
		player.armorvalue = min(player.armorvalue + 100, g_minstagib_armor_max);
		sprint(player, "^3You picked up some extra lives\n");
	}
	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max) {
		plugin_chain_ItemGiveToHandle_PickedUp = TRUE;
		player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
		player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	}
	return plugin_chain_ItemGiveToHandle_PickedUp;
}

var void() minstagib_player_health_armor_mods_set_next;
void minstagib_player_health_armor_mods_set() {
	minstagib_player_health_armor_mods_set_next();
	plugin_player_health_armor_rot_regen = FALSE;
}

/* replace items in minstagib
 * IT_STRENGTH	 = invisibility
 * IT_NAILS	 = extra lives
 * IT_INVINCIBLE = speed
 */
float(float wpn) minstagib_WeaponSpawnHandle {
	if (wpn == MINSTAGIB_WEAPON ||wpn == WEAPON_NEX || wpn == WEAPON_ROCKET_LAUNCHER) {
		minstagib_items(IT_CELLS);
		self.think = minst_remove_item;
		self.nextthink = time;
	} else
		remove(self);

	return TRUE;
}

var float(float doreduce) minstagib_weapon_throw_allowed_next;
float(float doreduce) minstagib_weapon_throw_allowed {
	if (self.ammo_cells <= 0 || doreduce)
		return FALSE;

	return minstagib_weapon_throw_allowed_next(doreduce);
}

void spawnfunc_minstagib_extra_lives() { minstagib_items(IT_NAILS); }

var void() minstagib_entity_spawn_pre_next;
void() minstagib_entity_spawn_pre {
	if (self.classname == "item_health_mega")
		self.classname = "minstagib_extra_lives";
	else if (self.classname == "item_strength" || self.classname == "item_akimbo")
		self.classname = "item_invisibility";
	else if (self.classname == "item_invincible")
		self.classname = "item_speed";

	minstagib_entity_spawn_pre_next();
}

var float(string s) minstagib_ItemForbidden_next;
float(string s) minstagib_ItemForbidden {
	if (s != "minstagib")
	if (s != "item_speed")
	if (s != "item_invisibility")
		return TRUE;

	return minstagib_ItemForbidden_next(s);
}

var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) minstagib_player_damage_handle_next;
float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) minstagib_player_damage_handle {
	if ((deathtype == DEATH_FALL)  ||
		(deathtype == DEATH_DROWN) ||
		(deathtype == DEATH_SLIME) ||
		(deathtype == DEATH_LAVA))
		return TRUE;

	if (self.armorvalue >= 1  && (deathtype != DEATH_HURTTRIGGER) && _damage) {
		self.armorvalue -= min(_damage, min(self.armorvalue, 100));
		plugin_chain_player_damage_mod = 0;
		self.hitsound += 1;
		attacker.hitsound += 1; // TODO change this to a future specific hitsound for armor hit
	}
	return minstagib_player_damage_handle_next(inflictor, attacker, _damage, deathtype, hitloc, force);
}

var void(entity targ, entity attacker, float deathtype) minstagib_damage_mods_set_next;
void(entity targ, entity attacker, float deathtype) minstagib_damage_mods_set {
	if (targ.classname == "player") {
		if (attacker.classname == "player")
		if (DEATH_ISWEAPON(deathtype, WEAPON_LASER))
		if (g_minstagib_nolaserdamage || !player_can_fire(attacker, FALSE)) {
			plugin_chain_damage_mod = 0;
			if (targ != attacker) {
				if (g_minstagib_nolaserdamage)
					centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "Secondary fire inflicts no damage!"));

				plugin_chain_damage_mod_force = 0;
				plugin_chain_damage_mod_mirror = 0;
			}
		}
		if (team_mode)
		if (attacker != targ)
		if (deathtype != DEATH_MIRRORDAMAGE)
		if (deathtype != DEATH_ROT)
		if (targ.deadflag == DEAD_NO)
		if (attacker.team == targ.team) {
			if (g_friendlyfire == 0)
				plugin_chain_damage_mod = 0;
			else
				plugin_chain_damage_mod = plugin_chain_damage_mod / g_friendlyfire; //Restore value
		}
	}
	minstagib_damage_mods_set_next(targ, attacker, deathtype);
}


float(entity attacker, entity inflictor, float mirrordamage, vector force) minstagib_MirrorDamageHandle {
	if (mirrordamage > 0)
	if (attacker.armorvalue > 0) {// just lose extra LIVES, don't kill the player for mirror damage
		attacker.armorvalue = attacker.armorvalue - 1;
		centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^3Remaining extra lives: ",ftos(attacker.armorvalue)));
		attacker.hitsound += 1;
	}
	damage(attacker, inflictor, attacker, 0, DEATH_MIRRORDAMAGE, attacker.origin, force);
	return TRUE;
}

var float(void) minstagib_player_equip_handle_next;
float(void) minstagib_player_equip_handle {
	self.health = 100;
	self.armorvalue = 0;
	entity wi = weapon_info(MINSTAGIB_WEAPON);
	self.weapons = wi.weapons;
	self.weapons_extra = wi.weapons_extra;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	if not(player_start_items & IT_UNLIMITED_AMMO) {
		self.ammo_cells = cvar("g_minstagib_ammo_start");
	} else
		self.ammo_cells = 0;

	return TRUE;
}

var void() minstagib_ItemRespawnCountDown_next;
void() minstagib_ItemRespawnCountDown {
	if (self.items == IT_NAILS) {
		plugin_ItemName = "item-extralife";
		plugin_ItemColor = '1 0 0';
	}
	minstagib_ItemRespawnCountDown_next();
}

float minstagib_ArmorBlockPercentMod() { return 1; }

void(void) minstagib_init {
	CVAR_CACHE(g_minstagib);
	if not(g_minstagib)
		return;

	CVAR_CACHE(g_minstagib_ammo_drop);
	CVAR_CACHE(g_minstagib_armor_max);
	CVAR_CACHE(g_minstagib_speed_moverate);
	CVAR_CACHE(g_minstagib_nolaserdamage);
	CVAR_CACHE(g_minstagib_health_drop);
	CVAR_CACHE(g_minstagib_health_max);
	CVAR_CACHE(g_minstagib_extralives);
	if (g_minstagib_ammo_drop)
		minstagib_ammo = TRUE;

	item_precache(sv_model_healthlarge, "models/items/g_h50.md3", "misc/mediumhealth.wav");
	item_precache(sv_model_ammocells, "models/items/a_cells.md3", "misc/itempickup.wav");
	g_minstagib_invis_alpha = cvar("g_minstagib_invis_alpha");
	if (g_minstagib_invis_alpha <= 0)
		g_minstagib_invis_alpha = -1;

	precache_sound ("announcer/robotic/lastsecond.wav");
	precache_sound ("announcer/robotic/narrowly.wav");
	minstagib_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = minstagib_player_think;
	minstagib_ItemGiveToHandle_next = plugin_chain_ItemGiveToHandle;
	plugin_chain_ItemGiveToHandle = minstagib_ItemGiveToHandle;
	minstagib_player_health_armor_mods_set_next = plugin_chain_player_health_armor_mods_set;
	plugin_chain_player_health_armor_mods_set = minstagib_player_health_armor_mods_set;
	plugin_chain_WeaponSpawnHandle = minstagib_WeaponSpawnHandle;
	minstagib_weapon_throw_allowed_next = plugin_chain_weapon_throw_allowed;
	plugin_chain_weapon_throw_allowed = minstagib_weapon_throw_allowed;
	minstagib_entity_spawn_pre_next = plugin_chain_entity_spawn_pre;
	plugin_chain_entity_spawn_pre = minstagib_entity_spawn_pre;
	minstagib_ItemForbidden_next = plugin_chain_ItemForbidden;
	plugin_chain_ItemForbidden = minstagib_ItemForbidden;
	minstagib_player_damage_handle_next = plugin_chain_player_damage_handle;
	plugin_chain_player_damage_handle = minstagib_player_damage_handle;
	minstagib_damage_mods_set_next = plugin_chain_damage_mods_set;
	plugin_chain_damage_mods_set = minstagib_damage_mods_set;
	plugin_chain_MirrorDamageHandle = minstagib_MirrorDamageHandle;
	minstagib_player_equip_handle_next = plugin_chain_player_equip_handle;
	plugin_chain_player_equip_handle = minstagib_player_equip_handle;
	minstagib_ItemRespawnCountDown_next = plugin_chain_ItemRespawnCountDown;
	plugin_chain_ItemRespawnCountDown = minstagib_ItemRespawnCountDown;
	plugin_chain_ArmorBlockPercentMod = minstagib_ArmorBlockPercentMod;
	MINSTAGIB_WEAPON = WEAPON_LAST + 1;
	weapon_register(MINSTAGIB_WEAPON, minstagib_weapon, IT_CELLS, 7, 1, 0, 1, "minstanex", "minstanex", "MinstaNex");
	weapon_precache(MINSTAGIB_WEAPON);
}

void(void) spawnfunc_item_minst_cells {
	if (g_minstagib) {
		minst_no_auto_cells = 1;
		minstagib_items(IT_CELLS);
	} else
		remove(self);
}
