.entity dmg_indicator;

float g_friendlyfire;
float g_friendlyfire_force;
float g_mirrordamage;
float g_mirrorforce;
float g_teamdamage_threshold;
float g_throughfloor_damage;
float g_throughfloor_force;

float damage_goodhits;
float damage_gooddamage;
float damage_headshotbonus; // bonus multiplier for head shots, set to 0 after use

.float dmg_team;
.float teamkill_complain;
.float teamkill_soundtime;
.entity teamkill_soundsource;
.entity pusher;
.float taunt_soundtime;
.float lastfrag;

void(entity targ, entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) damage {
	float mirrordamage;
	float mirrorforce;
	mirrordamage = 0;
	mirrorforce = 0;
	RM({
		_damage = rm_buffs_medic_damage(targ, attacker, inflictor, _damage, deathtype, hitloc, force);
		if (_damage < 0) return;
	})
	if (targ.flags & FL_GODMODE) {
		if (g_campaign) {
			cheat_assign(targ, flags, FL_GODMODE, "GOD");
		} else {
			if (deathtype != DEATH_HURTTRIGGER)
			if (deathtype != DEATH_TEAMCHANGE)
				_damage = 0;
		}
	}
	if (map_finished || targ.killcount == -666)
		return;

	if (targ.existsonlyfor) {
		if (inflictor.existsonlyfor && targ.existsonlyfor != inflictor.existsonlyfor) return;
		if (attacker && attacker != targ.existsonlyfor);
	}
	entity oldself;
	oldself = self;
	self = targ;
	// special rule: gravity bomb does not hit team mates (other than for disconnecting the hook)
	if (deathtype & HITTYPE_NOTEAMDAMAGE) {
		if (targ.classname == "player")
			if not(team_is_different_teams(targ, attacker)) {
				self = oldself;
				return;
			}
	}
	if (deathtype == DEATH_KILL || deathtype == DEATH_TEAMCHANGE || deathtype == DEATH_AUTOTEAMCHANGE) {
		// These are ALWAYS lethal
		// No damage modification here
		// Instead, prepare the victim for his death...
		targ.armorvalue = 0;
		targ.spawnshieldtime = 0;
		targ.health = 0.9; // this is < 1
		targ.flags -= targ.flags & FL_GODMODE;
		_damage = 100000;
	} else if (deathtype == DEATH_MIRRORDAMAGE || deathtype == DEATH_ROT) {
		// no processing
	} else {
		if (targ.classname == "player") {
			if (attacker.classname == "player" && targ != attacker && (PLAYER_IS_INDEPENDENT(attacker) || PLAYER_IS_INDEPENDENT(targ))) {
				_damage = 0;
				force = '0 0 0';
			} else if (attacker.team == targ.team && !targ.saboteur && !plugin_team_ignored_for(targ)) {
				if (attacker != targ) {
					if (team_mode) {
						if (targ.deadflag == DEAD_NO) {
							float teamdamage0 = max(attacker.dmg_team, g_teamdamage_threshold);
							attacker.dmg_team = attacker.dmg_team + _damage;
							if (attacker.dmg_team > teamdamage0)
								mirrordamage = g_mirrordamage * (attacker.dmg_team - teamdamage0);

							mirrorforce = g_mirrorforce * vlen(force);
							_damage = g_friendlyfire * _damage;
							force = g_friendlyfire_force * force;
							// mirrordamage will be used LATER
						}
					}
				}
			}
		}
		if (targ == attacker)
			_damage = _damage * g_balance_selfdamagepercent;	// Partial damage if the attacker hits himself

		plugin_chain_damage_mod = plugin_chain_damage_mod_force = plugin_chain_damage_mod_mirror = plugin_chain_damage_mod_force_mirror = 1;
		plugin_chain_damage_mods_set(targ, attacker, deathtype);
		_damage = _damage * plugin_chain_damage_mod;
		force = force * plugin_chain_damage_mod_force;
		mirrordamage = mirrordamage * plugin_chain_damage_mod_mirror;
		mirrorforce = mirrorforce * plugin_chain_damage_mod_force_mirror;
		// count the damage
		if (attacker)
		if (!targ.deadflag)
		if (targ.takedamage == DAMAGE_AIM)
		if (targ != attacker) {
			if (targ.classname == "player") {
				// HEAD SHOT:
				// find height of hit on player axis
				// if above view_ofs and below maxs, and also in the middle half of the bbox, it is head shot
				vector headmins, headmaxs, org;
				org = targ.origin;
				headmins = org + '0.6 0 0' * targ.mins_x + '0 0.6 0' * targ.mins_y + '0 0 1' * (1.3 * targ.view_ofs_z - 0.3 * targ.maxs_z);
				headmaxs = org + '0.6 0 0' * targ.maxs_x + '0 0.6 0' * targ.maxs_y + '0 0 1' * targ.maxs_z;
				if (trace_hits_box(bullet_from, bullet_to, headmins, headmaxs)) {
					deathtype |= HITTYPE_HEADSHOT;
				}
			}
			if (deathtype & HITTYPE_HEADSHOT)
				_damage *= 1 + damage_headshotbonus;

			if (targ.classname == "player") {
				if (team_is_different_teams(targ, attacker) || targ.saboteur || plugin_team_ignored_for(targ)) {
					if (_damage > 0) {
						if (targ.BUTTON_CHAT)
							attacker.typehitsound += 1;
						else
							attacker.hitsound += 1;

						damage_goodhits += 1;
						damage_gooddamage += _damage;
						if not(DEATH_ISSPECIAL(deathtype)) {
							if (physics_is_flying(targ))
								damage_yoda = max(1, damage_yoda);

							if (targ.items & IT_INVISIBILITY)
								damage_yoda = 2;

							if (deathtype & HITTYPE_HEADSHOT)
								damage_headshot = 1;
						}
					}
				} else {
					if (deathtype != DEATH_FIRE)
						attacker.typehitsound += 1;

					if (mirrordamage > 0)
						if (time > attacker.teamkill_complain) {
							attacker.teamkill_complain = time + 5;
							attacker.teamkill_soundtime = time + 0.4;
							attacker.teamkill_soundsource = targ;
						}
				}
			}
		}
	}
	// apply push
	if (self.damageforcescale)
	if (vlen(force)) {
		self.velocity = self.velocity + self.damageforcescale * force;
		if (self.flags & FL_PROJECTILE) {
			self.flags &= ~FL_ONGROUND;
			projectile_update(self);
		}
	}
	// apply damage
	RM({
		if (targ.classname != "player") {
			rm_damage_indicator(attacker, hitloc, _damage, 0, RM_DAMAGE_NOTPLAYER);
		}
		if (_damage > 0 && deathtype != DEATH_RM_ENDURANCE)
			if (!team_mode || self.team != attacker.team) {
				self.buff_stealth_time = time;
				if (self.hg_stealth && self.hg_stealthalpha > 0.2) {
					self.hg_stealth = 0;
					self.hg_stealth_saved = 0;
					self.hg_stealthtime = 0; // no action delay if forcefully decloaked
				}
			}
	})
	if (_damage != 0 || (self.damageforcescale && vlen(force)))
	if (self.event_damage) {
		self.event_damage (inflictor, attacker, _damage, deathtype, hitloc, force);
		self.lastdamage = time;
	}
	self = oldself;
	plugin_chain_damage_force_done(targ, attacker, _damage, force);
	// apply mirror damage if any
	if (mirrordamage > 0 || mirrorforce > 0) {
		force = normalize(attacker.origin + attacker.view_ofs - hitloc) * mirrorforce;
		if not(plugin_chain_MirrorDamageHandle(attacker, inflictor, mirrordamage, force)) {
			damage(attacker, inflictor, attacker, mirrordamage, DEATH_MIRRORDAMAGE, attacker.origin, force);
		}
	}
}

float damage_radius_running;
void(entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity ignore, float forceintensity, float impacttype, float deathtype, entity directhitentity) damage_radius {
	entity targ;
	float finaldmg;
	float power;
	vector blastorigin;
	vector force;
	vector diff;
	vector center;
	vector nearest;
	float a;
	float c;
	float hits;
	float total;
	float hitratio;
	vector hitloc;
	if (damage_radius_running) {
		backtrace("damage_radius called recursively!\n");
		return;
	}
	damage_radius_running = 1;
	blastorigin = (inflictor.origin + (inflictor.mins + inflictor.maxs) * 0.5);
	if not(deathtype & HITTYPE_NOINFO) {
		force = inflictor.velocity;
		if (vlen(force) == 0)
			force = '0 0 -1';
		else
			force = normalize(force);

		if (forceintensity >= 0)
			effect_impact(blastorigin, coredamage, edgedamage, rad, forceintensity * force, impacttype, attacker);
		else
			effect_impact(blastorigin, coredamage, edgedamage, -rad, (-forceintensity) * force, impacttype, attacker);
	}
	float record_damage = attacker.flags & FL_CLIENT;
	targ = warpzone_find_radius(blastorigin, rad, FALSE);
	float restoremaxs;
	vector restoremaxsvalue = '0 0 0';
	while (targ) {
		if (targ != inflictor)
		if (ignore != targ)
		if (directhitentity != targ)
		if (targ.takedamage) {
			// LordHavoc: measure distance to nearest point on target (not origin)
			// (this guarentees 100% damage on a touch impact)
			nearest = targ.warpzone_findradius_nearest;
			diff = targ.warpzone_findradius_dist;
			// round up a little on the damage to ensure full damage on impacts
			// and turn the distance into a fraction of the radius
			power = 1 - ((vlen (diff) - 2) / rad);
			if (power > 0) {
				if (power > 1)
					power = 1;

				finaldmg = coredamage * power + edgedamage * (1 - power);
				if (finaldmg > 0 || forceintensity > 0) {
					restoremaxs = 0;
					// if it's a player, use the view origin as reference
					if (targ.classname == "player" && attacker == targ) {
						if (targ.view_ofs_z > targ.maxs_z) {
							restoremaxsvalue = targ.maxs;
							restoremaxs = TRUE;
							targ.maxs_z = targ.view_ofs_z;
							setsize(targ, targ.mins, targ.maxs);
						}
						center = targ.origin + targ.view_ofs;
					} else
						center = targ.origin + (targ.mins + targ.maxs) * 0.5;

					force = normalize(center - warpzone_transform_origin(targ, blastorigin));
					force = force * (coredamage ? (finaldmg / coredamage) : 1) * forceintensity;
					// test line of sight to multiple positions on box,
					// and do damage if any of them hit
					hits = 0;
					if (targ.classname == "player")
						total = ceil(bound(1, finaldmg, 10));
					else
						total = ceil(bound(1, finaldmg/10, 5));

					hitloc = nearest;
					c = 0;
					while (c < total) {
						warpzone_trace_line(blastorigin, warpzone_untransform_origin(targ, nearest), TRACE_MOVE_NOMONSTERS, inflictor); //targ have .warpzone_transform from warpzone_find_radius
						if (trace_fraction == 1 || trace_ent == targ) {
							hits = hits + 1;
							if (hits > 1)
								hitloc = hitloc + nearest;
							else
								hitloc = nearest;
						}
						nearest_x = targ.origin_x + targ.mins_x + random() * targ.size_x;
						nearest_y = targ.origin_y + targ.mins_y + random() * targ.size_y;
						nearest_z = targ.origin_z + targ.mins_z + random() * targ.size_z;
						c = c + 1;
					}
					if (restoremaxs)
						setsize(targ, targ.mins, restoremaxsvalue);

					nearest = hitloc * (1 / max(1, hits));
					hitratio = (hits / total);
					a = bound(0, g_throughfloor_damage + (1-g_throughfloor_damage) * hitratio, 1);
					finaldmg = finaldmg * a;
					a = bound(0, g_throughfloor_force + (1-g_throughfloor_force) * hitratio, 1);
					force = force * a;
					if (hits || g_throughfloor_damage || g_throughfloor_force) {
						if (record_damage)
							weapon_score_hits(attacker, targ, deathtype, 1, finaldmg);

						if (DEATH_ISSPECIAL(deathtype))
							damage(targ, inflictor, attacker, finaldmg, deathtype, nearest, force);
						else
							damage(targ, inflictor, attacker, finaldmg, deathtype | HITTYPE_SPLASH, nearest, force);
					}
				}
			}
		}
		targ = targ.chain;
	}
	if (directhitentity)
	if (directhitentity.takedamage) {
		damage(directhitentity, inflictor, attacker, coredamage, deathtype, entity_nearest_point_on_box(directhitentity, blastorigin), forceintensity * normalize(directhitentity.origin - blastorigin + (directhitentity.mins + directhitentity.maxs) * 0.5));
		weapon_score_hits(attacker, directhitentity, deathtype, 1, coredamage);
	}
	damage_radius_running = 0;
}

void(entity attacker, void() explode) damage_prepare_explosion {
	self.takedamage = DAMAGE_NO;
	self.event_damage = NULL;
	self.realowner = self.owner = attacker;
	// do not explode NOW but in the NEXT FRAME!
	// because recursive calls to damage_radius are not allowed
	self.nextthink = time;
	self.think = explode;
}

void(void) damage_init {
	CVAR_CACHE(g_friendlyfire);
	CVAR_CACHE(g_friendlyfire_force);
	CVAR_CACHE(g_mirrordamage);
	CVAR_CACHE(g_mirrorforce);
	CVAR_CACHE(g_teamdamage_threshold);
	CVAR_CACHE(g_throughfloor_damage);
	CVAR_CACHE(g_throughfloor_force);
	CVAR_CACHE(g_balance_selfdamagepercent);
}
