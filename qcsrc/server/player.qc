float sv_autotaunt;
float sv_taunt;
.float cvar_cl_autotaunt;
.float cvar_cl_voice_directional;
.float cvar_cl_voice_directional_taunt_attenuation;
.float usecolormod;
float g_respawn_delay;
float g_respawn_mapsettings;
float g_respawn_mapsettings_delay;
float g_respawn_mapsettings_waves;
float g_respawn_waves;
float g_fullbrightplayers;
string g_player_debris;
float g_player_death_sound;
float g_balance_armor_blockpercent;
float g_balance_armor_regen;
float g_balance_armor_regenlinear;
float g_balance_armor_regenstable;
float g_balance_armor_rot;
float g_balance_armor_rotlinear;
float g_balance_armor_rotstable;
float g_balance_health_regen;
float g_balance_health_regenlinear;
float g_balance_health_regenstable;
float g_balance_health_rot;
float g_balance_health_rotlinear;
float g_balance_health_rotstable;
float g_balance_pause_armor_rot_spawn;
float g_balance_pause_fuel_rot_spawn;
float g_balance_pause_health_regen_spawn;
float g_balance_pause_health_rot_spawn;
float g_forced_respawn;
float g_teamdamage_resetspeed;
float g_reset_on_join;
float g_spawnshieldtime;
float g_spawnfrags;
float g_spawnsound;
float g_player_pushfactor;
float g_player_body_pitch_maxangle;
float g_player_team_collisions;
float g_endmatch_on_leave;
string sv_announcer_extra_pushfrag;
string sv_announcer_extra_doublekill;
float sv_announcer_extra_doublekill_interval;
string sv_announcer_extra_firstblood;
string sv_sound_frag;
float bot_taunt;
float bot_talk;
float sv_loddistance1;
float sv_loddistance2;
.string playermodel_save;
.vector anim_stand;

.entity pusher;

void(void) player_dmg_inflictor_fix {
	entity e;
	for (e = find(NULL, classname, "dmg_inflictor"); (e = find(e, classname, "dmg_inflictor")); ) {
		if (e.owner.dmg_inflictor != e) {
			print("wrong dmg_inflictor removed\n");
			remove(e);
		}
	}
	FOR_EACH_PLAYER(e)
		if (e.dmg_inflictor && (e.dmg_inflictor.classname != "dmg_inflictor" || e.dmg_inflictor.owner != e || wasfreed(e.dmg_inflictor))) {
			e.dmg_inflictor = spawn();
			e.dmg_inflictor.classname = "dmg_inflictor";
			e.dmg_inflictor.owner = e;
		}
}

void(void) player_corpse_think {
	if (self.frame != self.dead_frame) {
		anim_update(self);
		if (self.weaponentity) anim_update(self.weaponentity);
		if (time >= self.animstate_endtime) {
			if (self.modelindex) {
				entity o = self.owner;
				vector _stand_maxs = o.stand_maxs;
				vector _crouch_maxs = o.crouch_maxs;
				_stand_maxs_z = 5;
				_crouch_maxs_z = 5;
				physics_set_sizes(o, o.stand_mins, _stand_maxs, o.crouch_mins, _crouch_maxs);
			}
			self.frame = self.dead_frame;
			if (self.weaponentity)
				self.weaponentity.frame = self.dead_frame;
		}
	} else if (time >= self.fade_time) {
		if (self.owner == self) {
			pointparticles(particleeffectnum("morphed_damage_dissolve"), self.origin + (self.mins + self.maxs) * 0.5, '0 0 0', 1);
			if (self.weaponentity) remove(self.weaponentity);
			if (self.exteriorweaponentity) remove(self.exteriorweaponentity);
			remove(self);
		} else {
			pointparticles(particleeffectnum("morphed_damage_dissolve"), self.owner.origin + (self.owner.mins + self.maxs) * 0.5, '0 0 0', 1);
			self = self.owner;
			player_body_remove();
			self = world;
		}
		return;
	}
	self.nextthink = time;
}

void(void) player_respawn {
	player_body_detach(1, MOVETYPE_TOSS);
	client_put();
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) player_corpse_damage {
	violence_gib_splash_at(hitloc, force, 2, bound(0, _damage, 200) / 16, self, attacker);

	// damage resistance (ignore most of the damage from a bullet or similar)
	_damage = max(_damage - 5, 1);
	entity b = self.body;
	entity o = b.owner;

	if (_damage > 30)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact2.wav", VOL_BASE, ATTN_NORM);
	else if (_damage > 10)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM);

	if (_damage > 50)
		violence_gib_splash_at(hitloc, force * -0.1, 3, 1, self, attacker);
	if (_damage > 100)
		violence_gib_splash_at(hitloc, force * -0.2, 3, 1, self, attacker);

	o.health = o.health - _damage;
	if (o.health <= -75 && b.modelindex != 0) {
		violence_gib_splash(self, 1, 1, attacker);
		if (self == b) { //detached body
			if (self.weaponentity) remove(self.weaponentity);
			if (self.exteriorweaponentity) remove(self.exteriorweaponentity);
			self.nextthink = time;
			self.think = stdproc_remove;
		} else { //player
			b.effects |= EFFECT_NODRAW;
			// view just above the floor
			physics_set_view_offsets(o, '0 0 4', '0 0 4');
		}
		self.takedamage = FALSE;
		self.event_damage = NULL;
		self.solid = SOLID_NOT; // restore later
	}
}

void(float killed) player_clear {
	float j;
	if (killed)
		portal_clear_all_later(self);
	else
		portal_clear_all(self);

	// reset fields the weapons may use just in case
	WEAPON_INFO_FOR_EACH_ID(j) {
		weapon_action(j, WEAPON_REQUEST_RESETPLAYER);
		weapon_action(j, WEAPON_REQUEST_CLEAR);
		WEAPON_ATTACK_FINISHED_FOR(self, j) = 0;
	}
	plugin_chain_player_clear(killed);
	//Clear waypoints
	WaypointSprite_PlayerDead();
	if (self.classname == "disconnecting") {
		str_unzone_ifneeded(self.body.playermodel);
		player_body_remove();
	}
}

float player_obituary_firstblood;
void(entity attacker, entity inflictor, entity targ, float deathtype) player_obituary {
	string s, a;
	float p, w;
	s = targ.netname;
	a = attacker.netname;
	float attacker_is_player = (attacker.classname == "player" || (team_mode && attacker.classname == "spectator" && attacker.team > 0));
	if (targ == attacker) {
		if (clienttype(attacker) == CLIENTTYPE_BOT)
			bot_say(attacker, FALSE, world, cvar_string("bot_messages_suicide"), "");

		if (deathtype == DEATH_TEAMCHANGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You are now on: ", team_colored_name(targ.team)));
		} else if (deathtype == DEATH_AUTOTEAMCHANGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You have been moved into a different team to improve team balance\nYou are now on: ", team_colored_name(targ.team)));
			return;
		} else if (deathtype == DEATH_NOAMMO) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were killed for running out of ammo..."));
		} else if (deathtype == DEATH_ROT) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You grew too old without taking your medicine"));
		} else if (deathtype == DEATH_MIRRORDAMAGE) {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't shoot your team mates!"));
		} else {
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You killed your own dumb self!"));
		}
		w = DEATH_WEAPONOF(deathtype);
		if (WEAPON_VALID(w)) {
			weapon_deathtypestring = "couldn't resist the urge to self-destruct";
			weapon_deathtype = deathtype;
			weapon_action(w, WEAPON_REQUEST_SUICIDEMESSAGE);
			bprint("^1", s, "^1 ", weapon_deathtypestring, "\n");
		} else if (deathtype == DEATH_KILL)
			bprint ("^1",s, "^1 couldn't take it anymore\n");
		else if (deathtype == DEATH_ROT)
			bprint ("^1",s, "^1 died\n");
		else if (deathtype == DEATH_NOAMMO)
			bprint ("^7",s, "^7 committed suicide. What's the point of living without ammo?\n");
		else if (deathtype == DEATH_MIRRORDAMAGE)
			bprint ("^1",s, "^1 didn't become friends with the Lord of Teamplay\n");
		else if (deathtype == DEATH_FIRE)
			bprint ("^1",s, "^1 burned to death\n");
		else if (deathtype != DEATH_TEAMCHANGE)
			bprint ("^1",s, "^1 couldn't resist the urge to self-destruct\n");

		if (deathtype != DEATH_TEAMCHANGE) {
			score_give_frag(attacker, targ, -1);
		}
		if (targ.killcount > 2)
			bprint ("^1",s,"^1 ended it all after a ",ftos(targ.killcount)," kill spree\n");
	} else if (attacker_is_player || attacker.netname != "") {
		if (clienttype(attacker) == CLIENTTYPE_BOT) {
			if (bot_talk)
			if (random() < bot_talk) {
				if (team_mode && attacker.team == targ.team)
					bot_say(attacker, FALSE, world, cvar_string("bot_messages_teamkill"), strcat(targ.netname, "^7: "));
				else
					bot_say(attacker, FALSE, world, cvar_string("bot_messages_frag"), strcat(targ.netname, "^7: "));
			}
			if (bot_taunt)
			if (random() <= bot_taunt) {
				entity oldself;
				oldself = self;
				self = attacker;
				player_sound_voice_message("taunt", "");
				self = oldself;
			}
		}
		if (clienttype(targ) == CLIENTTYPE_BOT)
		if (bot_talk)
		if (attacker_is_player)
		if (random() <= bot_talk) {
			if (team_mode && attacker.team == targ.team) {
				bot_say(targ, FALSE, world, cvar_string("bot_messages_teamkilled"), strcat(attacker.netname, "^7: "));
			} else {
				if (random() < 0.5)
					bot_say(targ, FALSE, world, cvar_string("bot_messages_fragged"), "");
				else
					bot_say(targ, FALSE, world, cvar_string("bot_messages_fragged_priv"), strcat(attacker.netname, "^7: "));
			}
		}
		if (team_mode && attacker.team == targ.team && !targ.saboteur && attacker_is_player) {
			centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You fragged ", s, ", a team mate!"));
			bprint ("^1", a, "^1 mows down a team mate\n");
			if (targ.killcount > 2) {
				bprint ("^1",s,"'s ^1",ftos(targ.killcount)," kill spree was ended by a team mate!\n");
			}
			if (attacker.killcount > 2) {
				bprint ("^1",a,"^1 ended a ",ftos(attacker.killcount)," kill spree by killing a team mate\n");
			}
			attacker.killcount = 0;
		} else {
			string blood_message = "", victim_message = "";
			weapon_fragprefix = "";
			if (!player_obituary_firstblood) {
				player_obituary_firstblood = TRUE;
				bprint("^1",a, "^1 drew first blood", "\n");
				blood_message = "^1First blood\n";
				victim_message = "^1First victim\n";  // or First casualty
				if (sv_announcer_extra_firstblood != "")
					announce(attacker, sv_announcer_extra_firstblood, "^5First ^1Blood");
			}
			w = DEATH_WEAPONOF(deathtype);
			if (WEAPON_VALID(w)) {
				weapon_deathtypestring = "was blasted by";
				weapon_deathtype = deathtype;
				weapon_fragannounce = "";
				weapon_action(w, WEAPON_REQUEST_KILLMESSAGE);
				p = strstrofs(weapon_deathtypestring, "#", 0);
				if (p < 0)
					bprint("^1", s, "^1 ", weapon_deathtypestring, " ", a, "\n");
				else
					bprint("^1", s, "^1 ", substring(weapon_deathtypestring, 0, p), a, "^1", substring(weapon_deathtypestring, p+1, strlen(weapon_deathtypestring) - (p+1)), "\n");
			} else if (deathtype == DEATH_DROWN)
				bprint ("^1",s, "^1 was drowned by ", a, "\n");
			else if (deathtype == DEATH_SLIME)
				bprint ("^1",s, "^1 was slimed by ", a, "\n");
			else if (deathtype == DEATH_LAVA)
				bprint ("^1",s, "^1 was cooked by ", a, "\n");
			else if (deathtype == DEATH_FALL) {
				bprint ("^1",s, "^1 was grounded by ", a, "\n");
				if (sv_announcer_extra_pushfrag != "") {
					announce(targ, sv_announcer_extra_pushfrag, "");
					announce(attacker, sv_announcer_extra_pushfrag, "");
				}
			} else if (deathtype == DEATH_SWAMP)
				bprint ("^1",s, "^1 was conserved by ", a, "\n");
			else if (deathtype == DEATH_HURTTRIGGER) {
				if (sv_announcer_extra_pushfrag != "") {
					announce(targ, sv_announcer_extra_pushfrag, "");
					announce(attacker, sv_announcer_extra_pushfrag, "");
				}
				if (inflictor.message2 != "") {
					p = strstrofs(inflictor.message2, "#", 0);
					if (p < 0)
						bprint("^1", s, "^1 ", inflictor.message2, " ", a, "\n");
					else
						bprint("^1", s, "^1 ", substring(inflictor.message2, 0, p), a, "^1", substring(inflictor.message2, p+1, strlen(inflictor.message2) - (p+1)), "\n");
				}
			} else if (deathtype == DEATH_TURRET)
				bprint ("^1",s, "^1 was pushed into the line of fire by ^1", a, "\n");
			else if (deathtype == DEATH_FIRE)
				bprint ("^1",s, "^1 was burnt to death by ^1", a, "\n");
			else if not(plugin_chain_player_obituary_frag(deathtype, targ, inflictor, attacker))
				bprint ("^1",s, "^1 was ", weapon_fragprefix, "^1fragged by ", a, "\n");

			if (attacker_is_player) {
				if (g_spawnfrags && (targ.spawnshieldtime > time || attacker.spawnshieldtime > time)) {
					weapon_fragprefix = strcat("^3SPAWN", weapon_fragprefix);
				} else {
					score_give_frag(attacker, targ, 1);
				}
				if (targ.killcount > 2) {
					bprint ("^1",s,"'s ^1", ftos(targ.killcount), " kill spree was ended by ", a, "\n");
				}
				attacker.killcount = attacker.killcount + 1;
				if (attacker.killcount > 2) {
					bprint ("^1",a,"^1 has ",ftos(attacker.killcount)," frags in a row\n");
				}
				float fragtime = time;
				string announce_sound;
				if ((announce_sound = cvar_string(strcat("sv_player_killcount_", ftos(attacker.killcount), "_announce_sound"))) != "") {
					announce(attacker, announce_sound, cvar_string(strcat("sv_player_killcount_", ftos(attacker.killcount), "_announce_message")));
				} else if (time - attacker.lastfrag < sv_announcer_extra_doublekill_interval && attacker.lastfrag && sv_announcer_extra_doublekill != "") {
					announce(attacker, sv_announcer_extra_doublekill, "^3Excellent");
					fragtime = 0;
				}
				attacker.taunt_soundtime = time + 1;
				attacker.lastfrag = fragtime;
				if (weapon_fragannounce != "") {
						announce(targ, weapon_fragannounce, "");
						announce(attacker, weapon_fragannounce, "");
						weapon_fragannounce = "";
				}
				centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ", weapon_fragprefix, "^4fragged ^7", s));
			}
			centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ", weapon_fragprefix, "^1fragged by ^7", a));
			weapon_fragprefix = "";
		}
	} else {
		if (clienttype(targ) == CLIENTTYPE_BOT)
		if (bot_talk)
		if (random() <= bot_talk)
			bot_say(targ, FALSE, world, cvar_string("bot_messages_suicide"), "");

		centerprint(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Watch your step!"));
		if (deathtype == DEATH_HURTTRIGGER && inflictor.message != "")
			bprint ("^1",s, "^1 ", inflictor.message, "\n");
		else if (deathtype == DEATH_DROWN)
			bprint ("^1",s, "^1 drowned\n");
		else if (deathtype == DEATH_SLIME)
			bprint ("^1",s, "^1 was slimed\n");
		else if (deathtype == DEATH_LAVA)
			bprint ("^1",s, "^1 turned into hot slag\n");
		else if (deathtype == DEATH_FALL)
			bprint ("^1",s, "^1 hit the ground with a crunch\n");
		else if (deathtype == DEATH_SWAMP)
			bprint ("^1",s, "^1 is now conserved for centuries to come\n");
		else if (deathtype == DEATH_TURRET)
			bprint ("^1",s, "^1 was mowed down by a turret \n");
		else if (deathtype == DEATH_FIRE)
			bprint ("^1",s, "^1 burnt to death\n");
		else
			bprint ("^1",s, "^1 died\n");

		if (targ.classname == "player") {
			score_give_frag(targ, targ, -1);
			if (score_player_add(targ, SP_SCORE, 0) == -5) {
				announce(targ, "announcer/male/botlike.wav", "");
			}
		}
		if (targ.killcount > 2)
			bprint ("^1",s,"^1 died with a ",ftos(targ.killcount)," kill spree\n");
	}
	targ.death_origin = targ.origin;
	// FIXME: this should go in client_put
	if (targ.killcount)
		targ.killcount = 0;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) player_damage {
	float take, save, waves, sdelay, dh, da;
	plugin_chain_player_damage_mod = 1;
	if (plugin_chain_player_damage_handle(inflictor, attacker, _damage, deathtype, hitloc, force))
		return;

	dh = max(self.health, 0);
	da = max(self.armorvalue, 0);
	_damage = _damage * plugin_chain_player_damage_mod;
	violence_gib_splash_at(hitloc, force, 2, bound(0, _damage, 200) / 16, self, attacker);
	save = bound(0, _damage * plugin_chain_ArmorBlockPercentMod() * g_balance_armor_blockpercent, self.armorvalue);
	take = bound(0, _damage - save, _damage);
	if (save > 10)
		sound (self, CHAN_PROJECTILE, "misc/armorimpact.wav", VOL_BASE, ATTN_NORM);
	else if (take > 30)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact2.wav", VOL_BASE, ATTN_NORM);
	else if (take > 10)
		sound (self, CHAN_PROJECTILE, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM); // FIXME possibly remove them?

	if (take > 50)
		violence_gib_splash_at(hitloc, force * -0.1, 3, 1, self, attacker);

	if (take > 100)
		violence_gib_splash_at(hitloc, force * -0.2, 3, 1, self, attacker);

	if (time >= self.spawnshieldtime || g_spawnfrags) {
		self.armorvalue = self.armorvalue - save;
		self.health = self.health - take;
		// pause regeneration for 5 seconds
		self.pauseregen_finished = max(self.pauseregen_finished, time + g_balance_pause_health_regen);
		if (time > self.pain_finished) { //Don't switch pain sequences like crazy
			self.pain_finished = time + 0.5;	//Supajoe
			if (self.classname != "body") { // pain anim is BORKED on our ZYMs, FIXME remove this once we have good models
				if (random() > 0.5)
					player_body_animation_set(self, anim_pain1, FALSE, TRUE, TRUE, 2);
				else
					player_body_animation_set(self, anim_pain2, FALSE, TRUE, TRUE, 2);
			}
			// exclude pain sounds for laserjumps as long as you aren't REALLY low on health and would die of the next two
			if (!DEATH_ISWEAPON(deathtype, WEAPON_LASER) || attacker != self || self.health < 2 * g_balance_laser_primary_damage * g_balance_selfdamagepercent + 1) {
				if (self.health > 75) // TODO make a "gentle" version?
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain100), VOL_BASE, ATTN_NORM);
				else if (self.health > 50)
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain75), VOL_BASE, ATTN_NORM);
				else if (self.health > 25)
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain50), VOL_BASE, ATTN_NORM);
				else if (self.health > 1)
					player_sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_pain25), VOL_BASE, ATTN_NORM);
			}
			// throw off bot aim temporarily
			float shake;
			shake = _damage * 5 / (bound(0,skill,100) + 1);
			self.v_angle_x = self.v_angle_x + (random() * 2 - 1) * shake;
			self.v_angle_y = self.v_angle_y + (random() * 2 - 1) * shake;
		}
	}
	if (self.dmg_inflictor) {
		self.dmg_save = self.dmg_save + save;
		self.dmg_take = self.dmg_take + _damage;
		if (self.dmg_inflictor.classname == "dmg_inflictor") {
			setorigin(self.dmg_inflictor, 0.5 * (inflictor.absmin + inflictor.absmax));
		} else {
			print("player_damage:", self.netname," have wrong dmg_inflictor\n");
			player_dmg_inflictor_fix();
		}
	}
	if (attacker == self) {
		// don't reset pushltime for self damage as it may be an attempt to
		// escape a lava pit or similar
		//self.pushltime = 0;
	} else if (attacker.classname == "player") {
		self.pusher = attacker;
		self.pushltime = time + g_maxpushtime;
	} else if (time < self.pushltime) {
		attacker = self.pusher;
		self.pushltime = max(self.pushltime, time + 0.6);
	} else
		self.pushltime = 0;

	if (self.health < 1)
	if not(plugin_player_death_handle(attacker, inflictor, deathtype)) {
		float defer_client_kill_now_team_change;
		defer_client_kill_now_team_change = FALSE;
		float switchweapon_save = self.weapon;
		debris_throw(force);
		if (g_player_death_sound) {
			if (deathtype == DEATH_DROWN)
				sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_drown), VOL_BASE, ATTN_NORM);
			else
				sound(self, CHAN_PAIN, sound_random_by_str(self.playersound_death), VOL_BASE, ATTN_NORM);
		}
		// get rid of kill indicator
		if (self.killindicator) {
			if (self.killindicator.team)
				defer_client_kill_now_team_change = TRUE;

			if (self.classname == "body")
			if (deathtype == DEATH_KILL) {
				// for the lemmings fans, a small harmless explosion
				pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
			}
		}
        entity_drop_entities(self);
		// clear selected player display
		if not(plugin_chain_player_death_weapon_throw_handle())
			weapon_throw(randomvec() * 125 + '0 0 200', (self.mins + self.maxs) * 0.5, FALSE);

		self.switchweapon = switchweapon_save;
		// print an obituary message
		player_obituary(attacker, inflictor, self, deathtype);
		if (sv_sound_frag != "")
		if (clienttype(attacker) == CLIENTTYPE_REAL)
		if (attacker != self)
		if (team_is_different_teams(attacker, self))
			sound_play2(attacker, sv_sound_frag);

		player_clear(TRUE);
		// make the corpse upright (not tilted)
		self.angles_x = 0;
		self.angles_z = 0;
		// don't spin
		self.avelocity = '0 0 0';
		// view from the floor
		physics_set_view_offsets(self, '0 0 -8', '0 0 -8');
		// shootable corpse
		self.solid = SOLID_CORPSE;
		// don't stick to the floor
		self.flags &= ~FL_ONGROUND;
		// dying animation
		self.deadflag = DEAD_DYING;
		// when to allow respawn
		sdelay = 0;
		waves = 0;
		if (g_respawn_mapsettings) {
			sdelay = g_respawn_mapsettings_delay;
			waves = g_respawn_mapsettings_waves;
		}
		if (!sdelay)
			sdelay = g_respawn_delay;

		if (!waves)
			waves = g_respawn_waves;

		if (waves)
			self.death_time = ceil((time + sdelay) / waves) * waves;
		else
			self.death_time = time + sdelay;

		if ((sdelay + waves >= 5.0) && (self.death_time - time > 1.75))
			self.respawn_countdown = 10; // first number to count down from is 10
		else
			self.respawn_countdown = -1; // do not count down

		if (random() < 0.5) {
			player_body_animation_set(self, anim_die1, FALSE, TRUE, TRUE, 3);
			self.body.dead_frame = self.anim_dead1_x;
		} else {
			player_body_animation_set(self, anim_die2, FALSE, TRUE, TRUE, 3);
			self.body.dead_frame = self.anim_dead2_x;
		}
		// set damage function to corpse damage
		self.event_damage = player_corpse_damage;
		// call the corpse damage function just in case it wants to gib
		self.event_damage(inflictor, attacker, 0, deathtype, hitloc, force);
		if (self.body) {
			self.body.think = player_corpse_think;
			self.body.fade_time = time + 15;
			self.body.nextthink = time;
		}
		if (defer_client_kill_now_team_change)
			client_kill_now_team_change(self, self.killindicator.team);
	}
}

float(entity plr, entity viewer) player_alpha {
	plr = akimbo_owner(plr);
	float dalpha = 1;
	if (plr.classname == "observer") {
		if (plr == viewer) {
			return dalpha;
		}
		return -1;
	} else if (plr.classname == "spectator") {
		return -1;
	}
	if (plr.deadflag) {
		return dalpha;
	}
	if (viewer.classname == "spectator") {
		viewer = viewer.enemy;
	}
	float sa = plugin_chain_player_alpha_mod(plr, viewer, dalpha);
	if ((plr == viewer || plugin_player_is_carrier(plr)) && sa < 0.01) {
		sa = 0.01;
	} else if (sa <= 0) {
		sa = -1;
	}
	return sa;
}

void() player_effects {
	entity b = self.body;
	if (!b) return;
	b.body.effects = self.effects & EFFECT_TELEPORT_BIT; //for teleportation
	if (!b.modelindex || PLAYER_REALLY_DEAD(self)) // don't apply the flags if the player is gibbed
		return;

	fire_apply_effect(self);
	plugin_chain_player_effects();
	if (g_fullbrightplayers)
		self.effects = self.effects | EFFECT_FULLBRIGHT;

	if not(g_spawnfrags)
	if (time >= map_starttime)
	if (time < self.spawnshieldtime)
		self.effects = self.effects | (EFFECT_ADDITIVE | EFFECT_FULLBRIGHT);

	b.effects = self.effects;
	if (b.weaponentity) {
		b.weaponentity.angles_x = bound(-g_player_body_pitch_maxangle, (-g_player_body_pitch_maxangle / 90) * self.v_angle_x, g_player_body_pitch_maxangle);
		b.weaponentity.effects = self.effects;
		if (b.exteriorweaponentity)
			b.exteriorweaponentity.effects = self.effects;
	}
	else
		b.angles_x = bound(-g_player_body_pitch_maxangle, (-g_player_body_pitch_maxangle / 90) * self.v_angle_x, g_player_body_pitch_maxangle);

	b.body.modelflags = self.modelflags; //for MF_ROCKET effect
	self.effects = 0;
}

void(entity player) player_to_spec {
	if (player.classname == "player" || (player.classname == "spectator" && player.team >= 0))
	if not(g_campaign)
	if not(plugin_forbid_specatators()) {
		entity oldself = self;
		self = player;
		player_clear(FALSE);
		player_body_remove();
		player.classname = "observer";
		if (spectator_block)
			sprint(player, strcat("^7You have to become a player within the next ", ftos(g_maxplayers_spectator_blocktime), " seconds, otherwise you will be kicked, because spectators aren't allowed at this time!\n"));

		client_put();
		voip_setup(self);
		self = oldself;
		spectator_note_update();
		if (team_mode)
			team_balance_audit(FALSE);

		player_leave();
	}
}

float(float current, float stable, float regenfactor, float regenframetime) player_calc_regen {
	if (current > stable)
		return current;

	if (current > stable - 0.25) // when close enough, "snap"
		return stable;

	return min(stable, current + (stable - current) * regenfactor * regenframetime);
}

float(float current, float stable, float rotfactor, float rotframetime) player_calc_rot {
	if (current < stable)
		return current;

	if (current < stable + 0.25) // when close enough, "snap"
		return stable;

	return max(stable, current + (stable - current) * rotfactor * rotframetime);
}

float(float current, float regenstable, float regenfactor, float regenlinear, float regenframetime, float rotstable, float rotfactor, float rotlinear, float rotframetime, float limit) player_calc_rot_regen {
	if (current > rotstable) {
		if (rotframetime > 0) {
			current = player_calc_rot(current, rotstable, rotfactor, rotframetime);
			current = max(rotstable, current - rotlinear * rotframetime);
		}
	} else if (current < regenstable) {
		if (regenframetime > 0) {
			current = player_calc_regen(current, regenstable, regenfactor, regenframetime);
			current = min(regenstable, current + regenlinear * regenframetime);
		}
	}
	if (current > limit)
		current = limit;

	return current;
}

void() player_respawn_countdown {
	float number;
	if (self.deadflag == DEAD_NO) // just respawned?
		return;

	number = ceil(self.death_time - time);
	if (number <= 0)
		return;

	if (number <= self.respawn_countdown) {
		self.respawn_countdown = number - 1;
		if (ceil(self.death_time - (time + 0.5)) == number) // only say it if it is the same number even in 0.5s; to prevent overlapping sounds
			announce(self, strcat("announcer/robotic/", ftos(number), ".wav"), "");
	}
}


void() player_regen {
	float minh, maxh, limith, limita;
	plugin_player_health_armor_rot_regen = plugin_player_health_max_mod = plugin_player_armor_health_limit_mod = plugin_player_regen_mod = plugin_player_rot_mod = 1;
	plugin_chain_player_health_armor_mods_set();
	if (plugin_player_health_armor_rot_regen) {
		limith = g_balance_health_limit * plugin_player_armor_health_limit_mod;
		maxh = g_balance_health_rotstable * plugin_player_health_max_mod;
		minh = g_balance_health_regenstable * plugin_player_health_max_mod;
		self.health = player_calc_rot_regen(self.health, minh, g_balance_health_regen, g_balance_health_regenlinear, plugin_player_regen_mod * frametime * (time > self.pauseregen_finished), maxh, g_balance_health_rot, g_balance_health_rotlinear, plugin_player_rot_mod * frametime * (time > self.pauserothealth_finished), limith);
		// if player rotted to death...  die!
		if (self.health < 1)
			self.event_damage(self, self, 1, DEATH_ROT, self.origin, '0 0 0');

		limita = g_balance_armor_limit * plugin_player_armor_health_limit_mod;
		self.armorvalue = player_calc_rot_regen(self.armorvalue, g_balance_armor_regenstable, g_balance_armor_regen, g_balance_armor_regenlinear, plugin_player_regen_mod * frametime * (time > self.pauseregen_finished), g_balance_armor_rotstable, g_balance_armor_rot, g_balance_armor_rotlinear, plugin_player_rot_mod * frametime * (time > self.pauserotarmor_finished), limita);
	}
}

void() player_think {
	if (self.deadflag == DEAD_NO)
	if not(map_finished)
	if not(warmup_active)
		self.play_time = self.play_time + frametime;

	if (self.teleport_time)
	if (time > self.teleport_time) {
		self.teleport_time = 0;
	}
	//don't allow the player to turn around while game is paused!
	if (timeout_status == 2) {
		self.v_angle = self.lastV_angle;
		self.angles = self.lastV_angle;
		self.fixangle = TRUE;
	}
	plugin_chain_player_think();
	if (frametime) {
		fire_apply_damage(self);
		player_effects();
	}
	if (PLAYER_REALLY_DEAD(self)) {
		float button_pressed;
		if (frametime)
			player_body_animation();

		button_pressed = (self.BUTTON_ATCK || self.BUTTON_JUMP || self.BUTTON_ATCK2 || self.BUTTON_HOOK || self.BUTTON_USE);
		if (self.deadflag == DEAD_DYING) {
			if (g_forced_respawn)
				self.deadflag = DEAD_RESPAWNING;
			else if (!button_pressed)
				self.deadflag = DEAD_DEAD;
		} else if (self.deadflag == DEAD_DEAD) {
			if (button_pressed)
				self.deadflag = DEAD_RESPAWNABLE;
		} else if (self.deadflag == DEAD_RESPAWNABLE) {
			if (!button_pressed)
				self.deadflag = DEAD_RESPAWNING;
		} else if (self.deadflag == DEAD_RESPAWNING) {
			if (time > self.death_time) {
				self.death_time = time + 1; // only retry once a second
				player_respawn();
			}
		}
		player_respawn_countdown();
		return;
	}
	player_body_model_setup();
	weapon_frame();
	akimbo_weapon_frame();
	if (frametime) {
		player_regen();
		player_body_animation();
	}
	self.dmg_team = max(0, self.dmg_team - g_teamdamage_resetspeed * frametime);
	if (self.teamkill_soundtime)
	if (time > self.teamkill_soundtime) {
		self.teamkill_soundtime = 0;
		entity oldpusher, oldself;
		oldself = self; self = self.teamkill_soundsource;
		oldpusher = self.pusher; self.pusher = oldself;
		if (self.pusher)
		if (self.pusher.team == self.team) {
			msg_entity = self.pusher;
			if (clienttype(msg_entity) == CLIENTTYPE_REAL) {
				if (msg_entity.cvar_cl_voice_directional == 1)
					sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_teamshoot), VOL_BASEVOICE, ATTN_MIN);
				else if (msg_entity.cvar_cl_voice_directional >= 0)
					sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_teamshoot), VOL_BASEVOICE, ATTN_NONE);
			}
		}
		self.pusher = oldpusher;
		self = oldself;
	}
	if (self.taunt_soundtime)
	if (time > self.taunt_soundtime) {
		self.taunt_soundtime = 0;
		if (sv_taunt)
		if (sv_autotaunt) {
			float tauntrand = random();
			FOR_EACH_REALCLIENT(msg_entity)
				if (tauntrand < msg_entity.cvar_cl_autotaunt) {
					if (msg_entity.cvar_cl_voice_directional >= 1)
						sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_taunt), VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
					else if (msg_entity.cvar_cl_voice_directional >= 0)
						sound_to(MSG_ONE, self, CHAN_VOICE, sound_random_by_str(self.playersound_taunt), VOL_BASEVOICE, ATTN_NONE);
				}
		}
	}
}

/*
 * Impulse map:
 *
 * 0 reserved (no input)
 * 1 to 9, 14: weapon shortcuts
 * 10: next weapon according to linear list
 * 11: most recently used weapon
 * 12: previous weapon according to linear list
 * 13: best weapon according to priority list
 * 15: next weapon according to priority list
 * 16: previous weapon according to priority list
 * 17: throw weapon
 * 18: next weapon according to sbar_hudselector 1 list
 * 19: previous weapon according to sbar_hudselector 1 list
 * 20: reload if needed
 *
 * 30 to 39: create waypoints
 * 47: clear personal waypoints
 * 48: clear team waypoints
 *
 * TODO:
 * 200 to 209: prev weapon shortcuts
 * 210 to 219: best weapon shortcuts
 * 220 to 229: next weapon shortcuts
 * 230 to 253: individual weapons (up to 24)
 */
void(void) player_impulse {
	float imp;
	float i;
	float m;
	imp = self.impulse;
	if (!imp || map_finished)
		return;

	self.impulse = 0;
	if (timeout_status == 2) //don't allow any impulses while the game is paused
		return;

	if (imp >= 1 && imp <= 9) {
		// weapon switching impulses
		if (self.deadflag == DEAD_NO)
			weapon_next_on_impulse(imp);
		else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 10 && imp <= 20) {
		if (self.deadflag == DEAD_NO) {
			switch (imp) {
			case 10:
				weapon_next(0);
				break;
			case 11:
				weapon_switch(self.cnt); // previously used
				break;
			case 12:
				weapon_previous(0);
				break;
			case 13:
				weapon_switch(weapon_best(self));
				break;
			case 14:
				weapon_next_on_impulse(0);
				break;
			case 15:
				weapon_next(2);
				break;
			case 16:
				weapon_previous(2);
				break;
			case 17:
				if (plugin_chain_weapon_throw_handle())
					return;

				weapon_throw(weapon_calculate_projectile_velocity(self.velocity, v_forward * 750), '0 0 0', TRUE);
				break;
			case 18:
				weapon_next(1);
				break;
			case 19:
				weapon_previous(1);
				break;
			case 20:
				weapon_reload();
				break;
			}
		} else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 200 && imp <= 229) {
		if (self.deadflag == DEAD_NO) {
			// custom order weapon cycling
			i = math_mod(imp, 10);
			m = (imp - (210 + i)); // <0 for prev, =0 for best, >0 for next
			weapon_cycle(self.(cvar_cl_weaponpriorities[i]), m);
		} else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 230 && imp <= 253) {
		if (self.deadflag == DEAD_NO) {
			weapon_switch(imp - 230 + WEAPON_FIRST);
		} else
			self.impulse = imp; // retry in next frame
	} else if (imp >= 30 && imp <= 49) { // deploy waypoints
		waypointsprite_impulse(imp);
	} else if (imp >= 103 && imp <= 107) {
		waypoint_impulse(imp);
	}
}


void() player_post_think {
	entity bb = self.body.body;
	if (bb) {
		setorigin(bb, self.origin);
		bb.angles = self.angles;
		bb.effects = self.effects;
		bb.health = self.health; //for entcs
		bb.armorvalue = self.armorvalue; //for entcs
		setsize(bb, self.mins, self.maxs);
	}
	if (map_intermission_running)
		return; // intermission or finale

	self.pressedkeys = 0;
	if (self.movement_x > 0)
		self.pressedkeys |= KEY_FORWARD;
	else if (self.movement_x < 0)
		self.pressedkeys |= KEY_BACKWARD;

	if (self.movement_y > 0)
		self.pressedkeys |= KEY_RIGHT;
	else if (self.movement_y < 0)
		self.pressedkeys |= KEY_LEFT;

	self.pressedkeys = self.pressedkeys + ((self.BUTTON_JUMP ? KEY_JUMP : 0) + (self.BUTTON_CROUCH ? KEY_CROUCH : 0));
}

float(void) player_real_customize {
	if (other.enemy == self)
	if (other.classname == "spectator")
		return TRUE;

	if (other == self)
		return TRUE;

	return FALSE;
}

void(entity pl) player_physics_setup {
	pl.movetype = MOVETYPE_QCWALK;
	pl.solid = SOLID_SLIDEBOX;
	pl.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | (g_playerclip_collisions ? DPCONTENTS_PLAYERCLIP : 0);
	if (player_independent)
		PLAYER_MAKE_INDEPENDENT(pl);

	if (team_mode)
	if (g_sideview || !g_player_team_collisions)
		pl.clipgroup = pl.team;
}

float player_real_count;
void(entity spot) player_spawn {
	entity oldself, oldother;
	player_clear(FALSE);
	if ((self.debris = g_player_debris) != "")
		debris_setup();

	self.iscreature = TRUE;
	self.delay = FALSE;
	player_physics_setup(self);
	self.flags = FL_CLIENT;
	self.takedamage = DAMAGE_AIM;
	self.effects &= EFFECT_TELEPORT_BIT;
	self.air_finished = time + 12;
	self.keys = 0;
	self.touch = push_touch;
	self.pushfactor = g_player_pushfactor;
	if not(self.body)
		player_body_spawn(world);
	else
		self.body.effects &= ~EFFECT_NODRAW;

	self.body.nextthink = 0;
	self.body.dead_frame = -1;
	setmodel(self, "null");
	if not(plugin_chain_player_equip_handle()) {
		self.ammo_shells = player_start_ammo_shells;
		self.ammo_nails = player_start_ammo_nails;
		self.ammo_rockets = player_start_ammo_rockets;
		self.ammo_cells = player_start_ammo_cells;
		self.ammo_fuel = player_start_ammo_fuel;
		self.health = player_start_health;
		self.armorvalue = player_start_armorvalue;
		self.weapons = player_start_weapons;
		self.weapons_extra = player_start_weapons_extra;
	}
	self.items = player_start_items;
	self.spawnshieldtime = time + g_spawnshieldtime;
	self.pauserotarmor_finished = time + g_balance_pause_armor_rot_spawn;
	self.pauserothealth_finished = time + g_balance_pause_health_rot_spawn;
	self.pauserotfuel_finished = time + g_balance_pause_fuel_rot_spawn;
	self.pauseregen_finished = time + g_balance_pause_health_regen_spawn;
	//extend the pause of rotting if client was reset at the beginning of the countdown
	if (!map_restart_active && time < map_starttime) {
		self.spawnshieldtime += map_starttime - time;
		self.pauserotarmor_finished += map_starttime - time;
		self.pauserothealth_finished += map_starttime - time;
		self.pauseregen_finished += map_starttime - time;
	}
	self.damageforcescale = 2;
	self.death_time = 0;
	self.alpha = 0;
	self.fade_time = 0;
	self.pain_frame = 0;
	self.pain_finished = 0;
	self.pushltime = 0;
	self.think = NULL;
	self.nextthink = 0;
	self.dmg_team = 0;
	client_put_to_spot(spot);
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	self.punchangle = '0 0 0';
	self.punchvector = '0 0 0';
	self.oldvelocity = self.velocity;
	self.waterlevel = 0; //prevent wrong waterlevel handing in server frame for bots
	self.fire_endtime = -1;
	self.teleport_time = 0;
	msg_entity = self;
	self.customizeentityforclient = player_real_customize;
	physics_set_view_offsets(self, PL_VIEW_OFS, PL_CROUCH_VIEW_OFS);
	physics_set_sizes(self, PL_MIN, PL_MAX, PL_CROUCH_MIN, PL_CROUCH_MAX);
	if (self.playermodel == "" && self.playermodel_save != "") {
		self.playermodel = strcat1(self.playermodel_save); //temp string here, will be cleand by player_body_model_setup()
	}
	player_body_model_setup();
	self.playermodel = ""; //just in case
	player_body_animation_set(self, anim_idle, TRUE, FALSE, TRUE, 2);
	self.spawnorigin = spot.origin;
	self.event_damage = player_damage;
	self.bot_attack = TRUE;
	self.BUTTON_ATCK = self.BUTTON_JUMP = self.BUTTON_ATCK2 = 0;
	if (self.killcount == -666)
		self.killcount = 0;

	weapon_model_spawn();
	self.alpha = 1;
	oldself = self;
	oldother = other;
	player_effects();
	plugin_chain_player_spawn(spot);
	if (self.classname == "player") { //spawn can be aborted by game hook
		if (g_spawnsound)
			sound (self, CHAN_TRIGGER, "misc/spawn.wav", VOL_BASE, ATTN_NORM);

		self.wasplayer = TRUE;
		if (!self.switchweapon || !weapon_carried(self, self.switchweapon, TRUE, FALSE))
			self.switchweapon = weapon_best(self);

		if (!self.cnt || self.cnt == self.switchweapon || !weapon_carried(self, self.cnt, TRUE, FALSE)) {
			self.cnt = weaypon_cycle_get(self, self.cvar_cl_weaponpriority, -1, -1, 0);
		}
		self.weapon = 0;
	}
	entity e;
	float n = 0;
	FOR_EACH_REALPLAYER(e) n++;
	if not(warmup_active)
	if not(map_finished)
	if (n > player_real_count)
	if (g_reset_on_join)
	if (n == g_reset_on_join) {
		ready_restart();
	}
	player_real_count = n;
	self = spot;
	other = spot;
	activator = oldself;
	trigger_use_targets();
	activator = world;
	self = oldself;
	other = oldother;
}

void(void) player_leave {
	float n = 0;
	entity e;
	FOR_EACH_REALPLAYER(e) n++;
	if not(warmup_active)
	if not(map_finished)
	if (n < player_real_count)
	if (g_endmatch_on_leave)
	if (n <= g_endmatch_on_leave) {
		cvar_set("timelimit", "-1");
	}
	player_real_count = n;
	if (self.scorekeeper)
		score_clear(self);

	self.winning = FALSE;
}

float(entity plr, float wep) player_can_fire {
	if (PLAYER_DEAD(plr))
		return FALSE;

	if (time < map_starttime)
	if (!map_restart_active)
		return FALSE;

	if (timeout_status == 2) //don't allow the player to shoot while game is paused
		return FALSE;

	return plugin_chain_player_can_fire(plr, wep);
}

// decolorizes and team colors the player name when needed
string(entity p) player_name {
    string t;
    if (team_mode && !map_intermission_running && p.classname == "player") {
        t = team_color_code(p.team);
        return strcat(t, strdecolorize(p.netname));
    } else
        return p.netname;
}

void(entity pl, float _color) player_set_colors {
	float pants, shirt;
	pants = _color & 0x0F;
	shirt = _color & 0xF0;
	float t = pl.team;
	if (team_mode)
		setcolor(pl, 16*pants + pants);
	else
		setcolor(pl, shirt + pants);

	pl.team = t;
}

void(entity pl, float t, float s, float noprint) player_set_team {
	float _team = team_from_index(t - 1);
	if (!_team)
		return;

	pl.team = _team;
	if (!noprint && t != s) {
		//bprint(pl.netname, " has changed to ", team_name_by_no(t), "\n");
		bprint(pl.netname, "^7 has changed from ", team_name_by_no(s), " to ", team_name_by_no(t), "\n");
	}
	score_touch(pl);
	if (pl.body) {
		str_unzone_ifneeded(pl.body.playermodel);
		pl.body.playermodel = "";
	}
}

entity(entity pl) player_entity {
	if (pl.classname == "player")
		return plugin_chain_player_entity(pl);

	return pl;
}

void(entity e, float chan) player_sound_stop {
	FOR_EACH_REALCLIENT(msg_entity) {
		if (msg_entity == e)
			sound_stop_to(MSG_ONE, e, chan);
		else
			sound_stop_to(MSG_ONE, e.body.body, chan);
	}
}

void(entity e, float chan, string s, float vol, float attn) player_sound {
	FOR_EACH_REALCLIENT(msg_entity) {
		if (msg_entity == e)
			sound_to_at(MSG_ONE, e, e.origin, chan, s, vol, attn);
		else
			sound_to_at(MSG_ONE, e.body.body, e.origin, chan, s, vol, attn);
	}
}

float player_init_done;
void() player_init {
	player_sound_init();
	player_body_init();
	CVAR_CACHE(g_respawn_delay);
	CVAR_CACHE(g_respawn_mapsettings);
	CVAR_CACHE(g_respawn_mapsettings_delay);
	CVAR_CACHE(g_respawn_mapsettings_waves);
	CVAR_CACHE(g_respawn_waves);
	CVAR_CACHE(g_fullbrightplayers);
	if not(player_init_done) {
		CVAR_CACHE_STR(g_player_debris);
		entity oldself = self;
		self = spawn();
		self.debris = g_player_debris;
		debris_init();
		remove(self);
		self = oldself;
	}
	CVAR_CACHE(g_player_death_sound);
	CVAR_CACHE(g_balance_armor_blockpercent);
	CVAR_CACHE(g_balance_armor_regen);
	CVAR_CACHE(g_balance_armor_regenlinear);
	CVAR_CACHE(g_balance_armor_regenstable);
	CVAR_CACHE(g_balance_armor_rot);
	CVAR_CACHE(g_balance_armor_rotlinear);
	CVAR_CACHE(g_balance_armor_rotstable);
	CVAR_CACHE(g_balance_armor_limit);
	CVAR_CACHE(g_balance_health_limit);
	CVAR_CACHE(g_balance_health_regen);
	CVAR_CACHE(g_balance_health_regenlinear);
	CVAR_CACHE(g_balance_health_regenstable);
	CVAR_CACHE(g_balance_health_rot);
	CVAR_CACHE(g_balance_health_rotlinear);
	CVAR_CACHE(g_balance_health_rotstable);
	CVAR_CACHE(g_balance_pause_armor_rot_spawn);
	CVAR_CACHE(g_balance_pause_fuel_rot_spawn);
	CVAR_CACHE(g_balance_pause_health_regen_spawn);
	CVAR_CACHE(g_balance_pause_health_rot_spawn);
	CVAR_CACHE(g_forced_respawn);
	CVAR_CACHE(g_teamdamage_resetspeed);
	CVAR_CACHE(g_reset_on_join);
	CVAR_CACHE(g_player_pushfactor);
	CVAR_CACHE(g_player_body_pitch_maxangle);
	CVAR_CACHE(g_player_team_collisions);
	CVAR_CACHE(g_spawnshieldtime);
	CVAR_CACHE(g_spawnfrags);
	CVAR_CACHE(g_spawnsound);
	CVAR_CACHE(g_reset_on_join);
	CVAR_CACHE(g_endmatch_on_leave);
	CVAR_CACHE(sv_autotaunt);
	CVAR_CACHE(sv_taunt);
	CVAR_CACHE(sv_loddistance1);
	CVAR_CACHE(sv_loddistance2);
	PL_VIEW_OFS = '0 0 1' * cvar("g_player_view_ofs");
	PL_MIN = '-1 -1 0' * cvar("g_player_maxsxy") + '0 0 -24';
	PL_MAX = '1 1 0' * cvar("g_player_maxsxy") + '0 0 1' * cvar("g_player_maxsz");
	PL_CROUCH_VIEW_OFS = '0 0 1' * cvar("g_player_crouch_view_ofs");
	PL_CROUCH_MIN = '-1 -1 0' * cvar("g_player_maxsxy") + '0 0 -24';
	PL_CROUCH_MAX = '1 1 0' * cvar("g_player_maxsxy") + '0 0 1' * cvar("g_player_crouch_maxsz");
	if (sv_loddistance2 <= sv_loddistance1)
		sv_loddistance2 = 1073741824; // enough to turn off LOD 2 reliably

#define EXTRA_ANNOUNCER(x) do { str_unzone_ifneeded(sv_announcer_extra_##x); sv_announcer_extra_##x = cvar_string_zone_ifneeded("sv_announcer_extra_"#x); if (sv_announcer_extra_##x != "") { precache_sound(sv_announcer_extra_##x); print("Extra announcer sound "#x" ", sv_announcer_extra_##x, "\n");} } while (0)
	//Extra sounds
	EXTRA_ANNOUNCER(pushfrag);
	CVAR_CACHE(sv_announcer_extra_doublekill_interval);
	if (sv_announcer_extra_doublekill_interval) {
		EXTRA_ANNOUNCER(doublekill);
	}
	EXTRA_ANNOUNCER(firstblood);
#undef EXTRA_ANNOUNCER
	CVAR_CACHE_STR(sv_sound_frag);
	if (sv_sound_frag != "")
		precache_sound(sv_sound_frag);

	CVAR_CACHE(bot_taunt);
	CVAR_CACHE(bot_talk);
	CVAR_CACHE(g_maxpushtime);
	CVAR_CACHE(g_playerclip_collisions);
	player_init_done = TRUE;
}
