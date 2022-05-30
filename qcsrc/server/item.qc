.float speed_finished;
.float invincible_finished;
.float invisibility_finished;
float g_balance_pause_armor_rot;
float g_balance_pause_fuel_rot;
float g_balance_pause_health_regen;
float g_balance_pause_health_rot;
float g_fullbrightitems;
float g_pickup_shells_max;
float g_pickup_nails_max;
float g_pickup_rockets_max;
float g_pickup_cells_max;
float g_pickup_fuel_max;
float g_pickup_shells;
float g_pickup_nails;
float g_pickup_rockets;
float g_pickup_cells;
float g_pickup_fuel;
float g_ghost_items;
float g_pickup_items;
float g_pickup_nodrop;
float g_pickup_weapons_max;
float g_pickup_weapons;
float g_pickup_respawntime_weapon;
float g_pickup_respawntime_ammo;
float g_pickup_respawntime_healthsmall;
float g_pickup_respawntime_healthmedium;
float g_pickup_respawntime_healthlarge;
float g_pickup_respawntime_healthmega;
float g_pickup_respawntime_armorsmall;
float g_pickup_respawntime_armormedium;
float g_pickup_respawntime_armorbig;
float g_pickup_respawntime_armorlarge;
float g_pickup_respawntime_powerup;
float g_pickup_respawntime_mushroom;
float g_pickup_respawntimejitter_weapon;
float g_pickup_respawntimejitter_ammo;
float g_pickup_respawntimejitter_healthsmall;
float g_pickup_respawntimejitter_healthmedium;
float g_pickup_respawntimejitter_healthlarge;
float g_pickup_respawntimejitter_healthmega;
float g_pickup_respawntimejitter_armorsmall;
float g_pickup_respawntimejitter_armormedium;
float g_pickup_respawntimejitter_armorbig;
float g_pickup_respawntimejitter_armorlarge;
float g_pickup_respawntimejitter_powerup;
float g_pickup_respawntimejitter_mushroom;
float g_use_ammunition;
float g_pickup_armorsmall;
float g_pickup_armorsmall_max;
float g_pickup_armormedium;
float g_pickup_armormedium_max;
float g_pickup_armorbig;
float g_pickup_armorbig_max;
float g_pickup_armorlarge;
float g_pickup_armorlarge_max;
float g_pickup_healthsmall;
float g_pickup_healthsmall_max;
float g_pickup_healthmedium;
float g_pickup_healthmedium_max;
float g_pickup_healthlarge;
float g_pickup_healthlarge_max;
float g_pickup_healthmega;
float g_pickup_healthmega_max;
float g_pickup_fuel_jetpack;
float g_powerup_strength;
float g_powerup_speed;
float g_powerup_invisibility;
float g_powerup_shield;
float g_powerup_addition;
float g_balance_powerup_strength_time;
float g_balance_powerup_invisibility_time;
float g_balance_powerup_invincible_time;
float g_balance_powerup_speed_time;
string sv_model_powerupstrength;
string sv_model_powerupinvincible;
string sv_model_powerupinvisibility;
string sv_model_powerupspeed;
string sv_model_ammobullets;
string sv_model_ammoshells;
string sv_model_ammocells;
string sv_model_ammorockets;
string sv_model_healthsmall;
string sv_model_healthmedium;
string sv_model_healthlarge;
string sv_model_healthmega;
string sv_model_armorsmall;
string sv_model_armormedium;
string sv_model_armorbig;
string sv_model_armorlarge;
string sv_model_mushroom;
string sv_sound_mushroom;
float sv_item_tracecull;

void(string itemmodel, string defitemmodel, string pickupsound, float defaultrespawntime, float defaultrespawntimejitter, string itemname, float itemid, float weaponid, float itemflags, float(entity player, entity item) pickupevalfunc, float pickupbasevalue) item_start;

float(entity player, entity item) item_generic_pickupevalfunc {
	return item.bot_pickupbasevalue;
}

#define ITEM_RESPAWN_TICKS 10

#define ITEM_RESPAWNTIME(i)         ((i).respawntime + random_2() * (i).respawntimejitter)
	// range: respawntime - respawntimejitter .. respawntime + respawntimejitter
	// range: 10 .. respawntime + respawntimejitter

floatfield(float it) item_counter_field {
	switch (it) {
	case IT_SHELLS:      return ammo_shells;
	case IT_NAILS:       return ammo_nails;
	case IT_ROCKETS:     return ammo_rockets;
	case IT_CELLS:       return ammo_cells;
	case IT_HEALTH:      return health;
	case IT_ARMOR:       return armorvalue;
	// add more things here (health, armor)
	default:             error("requested item has no counter field");
	}
	return NULL;
}

string(float it) item_counter_field_name {
	switch (it) {
	case IT_SHELLS:      return "shells";
	case IT_NAILS:       return "nails";
	case IT_ROCKETS:     return "rockets";
	case IT_CELLS:       return "cells";
	// add more things here (health, armor)
	default:             error("requested item has no counter field name");
	}
	return NULL;
}

.float max_armorvalue;

void (entity e, float mode) item_show {
	e.effects &= ~(EFFECT_ADDITIVE | EFFECT_STARDUST | EFFECT_FULLBRIGHT);
	if (mode > 0) {
		// make the item look normal, and be touchable
		e.model = e.mdl;
		e.solid = SOLID_TRIGGER;
		//e.colormod = '0 0 0';
		e.alpha = 0;
		e.spawnshieldtime = 1;
	} else if (mode < 0) {
		// hide the item completely
		e.model = NULL;
		e.solid = SOLID_NOT;
		//e.colormod = '0 0 0';
		e.alpha = -1;
		e.spawnshieldtime = 1;
	} else if (g_ghost_items) {
		// make the item translucent green and not touchable
		e.model = e.mdl;
		e.solid = SOLID_NOT;
		//e.colormod = '0.2 1 0.2';
		e.alpha = g_ghost_items;
		e.spawnshieldtime = 1;
	} else {
		// hide the item completely
		e.model = NULL;
		e.solid = SOLID_NOT;
		//e.colormod = '0 0 0';
		e.alpha = 0;
		e.spawnshieldtime = 1;
	}
	if (e.strength_finished || e.invincible_finished)
		e.effects |= EFFECT_ADDITIVE | EFFECT_FULLBRIGHT;

	if (g_fullbrightitems)
		e.effects |= EFFECT_FULLBRIGHT;

	// relink entity (because solid may have changed)
	setorigin(e, e.origin);
}

void(void) item_respawn {
	item_show(self, 1);
	if (self.items == IT_STRENGTH)
		sound (self, CHAN_TRIGGER, "misc/strength_respawn.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	else if (self.items == IT_INVINCIBLE)
		sound (self, CHAN_TRIGGER, "misc/shield_respawn.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	else
		sound (self, CHAN_TRIGGER, "misc/itemrespawn.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);

	//pointparticles(particleeffectnum("item_respawn"), self.origin + self.mins_z * '0 0 1' + '0 0 48', '0 0 0', 1);
	pointparticles(particleeffectnum("item_respawn"), self.origin + 0.5 * (self.mins + self.maxs), '0 0 0', 1);
}

void(void) item_respawn_countdown {
	if (self.count >= ITEM_RESPAWN_TICKS) {
		if (self.waypointsprite_attached)
			WaypointSprite_Kill(self.waypointsprite_attached);

		item_respawn();
	} else {
		self.nextthink = time + 1;
		self.count += 1;
		if (self.count == 1) {
			gamehook_ItemName = NULL;
			gamehook_chain_ItemRespawnCountDown();
			switch (self.items) {
			case IT_STRENGTH:     gamehook_ItemName = "item-strength"; gamehook_ItemColor = '0 0 1'; break;
			case IT_INVINCIBLE:   gamehook_ItemName = "item-shield"; gamehook_ItemColor = '1 0 1'; break;
			case IT_SPEED:        gamehook_ItemName = "item-speed"; gamehook_ItemColor = '1 0 1'; break;
			case IT_INVISIBILITY: gamehook_ItemName = "item-invis"; gamehook_ItemColor = '0 0 1'; break;
			case IT_JETPACK:      gamehook_ItemName = "item-jetpack"; gamehook_ItemColor = '0.5 0.5 0.5'; break;
			}
			if (gamehook_ItemName) {
				WaypointSprite_Spawn(gamehook_ItemName, 0, 0, self, '0 0 64', world, 0, self, waypointsprite_attached, TRUE);
				if (self.waypointsprite_attached) {
					WaypointSprite_UpdateTeamRadar(self.waypointsprite_attached, RADARICON_POWERUP, gamehook_ItemColor);
					//WaypointSprite_UpdateMaxHealth(self.waypointsprite_attached, ITEM_RESPAWN_TICKS + 1);
					WaypointSprite_UpdateBuildFinished(self.waypointsprite_attached, time + ITEM_RESPAWN_TICKS);
				}
			}
		}
		sound (self, CHAN_TRIGGER, "misc/itemrespawncountdown.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
		if (self.waypointsprite_attached) {
			WaypointSprite_Ping(self.waypointsprite_attached);
			//WaypointSprite_UpdateHealth(self.waypointsprite_attached, self.count);
		}
	}
}

void(entity e, float t) item_schedule_respawn_in {
	if ((e.flags & FL_POWERUP) && t >= ITEM_RESPAWN_TICKS) {
		e.think = item_respawn_countdown;
		e.nextthink = time + max(0, t - ITEM_RESPAWN_TICKS);
		e.count = 0;
	} else {
		e.think = item_respawn;
		e.nextthink = time + t;
	}
}

void(entity e) item_schedule_respawn {
	if (e.respawntime < 0) {
		item_show(e, -1);
		return;
	} else if (!e.respawntime) {
		item_show(e, 1);
		return;
	}
	item_show(e, 0);
	item_schedule_respawn_in(e, ITEM_RESPAWNTIME(e));
}

void(entity e) item_schedule_initial_respawn {
	item_show(e, 0);
	item_schedule_respawn_in(e, max(0, map_starttime - time) + ITEM_RESPAWNTIME(e));
}

float(entity item, entity player, .float field_finished) item_powerup_give_to {
	if (item.field_finished) {
		if (g_powerup_addition) {
			player.field_finished = max(player.field_finished, time) + item.field_finished;
			return TRUE;
		} else if (player.field_finished + 0.5 < time + item.field_finished || !player.field_finished) {
			player.field_finished = time + item.field_finished;
			return TRUE;
		}
	}
	return FALSE;
}

float(entity item, entity player) item_give_to {
	float _switchweapon;
	float pickedup;
	float it;
	float i;
	entity e;
	// if nothing happens to player, just return without taking the item
	pickedup = FALSE;
	_switchweapon = FALSE;
	if (time < map_starttime)
		return FALSE;

	if (gamehook_chain_ItemGiveToHandle(item, player)) {
		pickedup = gamehook_chain_ItemGiveToHandle_PickedUp;
		gamehook_chain_ItemGiveToHandle_PickedUp = FALSE;
		_switchweapon = gamehook_chain_ItemGiveToHandle_SwitchWeapon;
		gamehook_chain_ItemGiveToHandle_SwitchWeapon = FALSE;
	} else {
		if (g_weapon_stay)
		if not(item.flags & FL_NO_WEAPON_STAY)
		if (item.flags & FL_WEAPON) {
			for (i = WEP_FIRST; i <= WEP_LAST; ++i)
				if (weapon_bit(i) & item.weapons & player.weapons)
					if (akimbo_weapon_give(player, i, item.netname)) {
						pickedup = TRUE;
						sound (player, CHAN_AUTO, item.noise, VOL_BASE, ATTN_NORM);
					}
			if not(pickedup) {
				if (player.weapons & item.weapons) {
					if (g_weapon_stay == 2 && g_use_ammunition && substring(item.classname, 0, 7) != "dropped")
					if (player.ammo_shells < item.ammo_shells
							|| player.ammo_nails < item.ammo_nails
							|| player.ammo_rockets < item.ammo_rockets
							|| player.ammo_cells < item.ammo_cells) {
						player.ammo_shells = max(player.ammo_shells, item.ammo_shells);
						player.ammo_nails = max(player.ammo_nails, item.ammo_nails);
						player.ammo_rockets = max(player.ammo_rockets, item.ammo_rockets);
						player.ammo_cells = max(player.ammo_cells, item.ammo_cells);
						pickedup = TRUE;
						goto skip;
					}
					if (g_weapon_stay != 1 || substring(item.classname, 0, 7) != "dropped") {
						goto skip;
					}
				}
			}
		}

		// in case the player has autoswitch enabled do the following:
		// if the player is using their best weapon before items are given, they
		// probably want to switch to an even better weapon after items are given
		if (player.autoswitch)
		if (player.switchweapon == weapon_best(player))
			_switchweapon = TRUE;

		if not(player.weapons & weapon_bit(player.switchweapon))
			_switchweapon = TRUE;

		if (g_pickup_weapons_max) {
			if (item.flags & FL_WEAPON) {
				float weapons_count = 0;
				for (i = WEP_FIRST, it = 1; i <= WEP_LAST; i++, it *= 2) {
					if (player.weapons & it) {
						weapons_count++;
						if (weapons_count >= g_pickup_weapons_max) {
							centerprint(player, strcat("You can carry only ", ftos(g_pickup_weapons_max), " weapons.\nDrop extra weapons to take this one."));
							goto skip;
						}
					}
				}
			}
		}
		if (item.spawnshieldtime)
		if (g_use_ammunition) {
			if (item.ammo_shells)
			if (player.ammo_shells < g_pickup_shells_max) {
				pickedup = TRUE;
				player.ammo_shells = min (player.ammo_shells + item.ammo_shells, g_pickup_shells_max);
			}
			if (item.ammo_nails)
			if (player.ammo_nails < g_pickup_nails_max) {
				pickedup = TRUE;
				player.ammo_nails = min (player.ammo_nails + item.ammo_nails, g_pickup_nails_max);
			}
			if (item.ammo_rockets)
			if (player.ammo_rockets < g_pickup_rockets_max) {
				pickedup = TRUE;
				player.ammo_rockets = min (player.ammo_rockets + item.ammo_rockets, g_pickup_rockets_max);
			}
			if (item.ammo_cells)
			if (player.ammo_cells < g_pickup_cells_max) {
				pickedup = TRUE;
				player.ammo_cells = min (player.ammo_cells + item.ammo_cells, g_pickup_cells_max);
			}
			if (item.ammo_fuel)
			if (player.ammo_fuel < g_pickup_fuel_max) {
				pickedup = TRUE;
				player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
				player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
			}
		}
		if (item.flags & FL_WEAPON) {
			for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
				e = weapon_info(i);
				if not(item.weapons & e.weapons)
					continue;

				if not(player.weapons & e.weapons) {
					pickedup = TRUE;
					weapon_give(player, e.weapon, item.netname);
				} else if (akimbo_weapon_give(player, e.weapon, item.netname))
					pickedup = TRUE;
			}
		}
		if ((it = (item.items - (item.items & player.items)) & IT_PICKUPMASK)) {
			pickedup = TRUE;
			player.items |= it;
			sprint (player, strcat("You got the ^2", item.netname, "\n"));
		}
		if (item.spawnshieldtime) {
			if (item_powerup_give_to(item, player, strength_finished))
				pickedup = TRUE;

			if (item_powerup_give_to(item, player, invincible_finished))
				pickedup = TRUE;

			if (item_powerup_give_to(item, player, speed_finished))
				pickedup = TRUE;

			if (item_powerup_give_to(item, player, invisibility_finished))
				pickedup = TRUE;

			if (item.health)
			if (player.health < item.max_health) {
				pickedup = TRUE;
				player.health = min(player.health + item.health, item.max_health);
				player.pauserothealth_finished = max(player.pauserothealth_finished, time + g_balance_pause_health_rot);
			}
			if (item.armorvalue)
			if (player.armorvalue < item.max_armorvalue) {
				pickedup = TRUE;
				player.armorvalue = min(player.armorvalue + item.armorvalue, item.max_armorvalue);
				player.pauserotarmor_finished = max(player.pauserotarmor_finished, time + g_balance_pause_armor_rot);
			}
		}
	}
	if (item.spawnshieldtime)
	if ((it = item.items & (IT_KEY1 | IT_KEY2 | IT_KEY3))) {
		if ((player.keys & it) == it)
			goto skip;

		pickedup = TRUE;
		player.keys |= it;
	}

:skip
	// always eat teamed entities
	if (item.team)
		pickedup = TRUE;

	if (!pickedup)
		return 0;

	sound (player, CHAN_AUTO, item.noise, VOL_BASE, ATTN_NORM);
	if (_switchweapon)
		if (player.switchweapon != weapon_best(player))
			weapon_switch_force(player, weapon_best(player));

	return 1;
}

float item_touch_picked;
void(void) item_touch  {
	entity e, head;
	item_touch_picked = FALSE;
	// remove the item if it's currnetly in a NODROP brush or hits a NOIMPACT surface (such as sky)
	if (((trace_dpstartcontents | trace_dphitcontents) & DPCONTENTS_NODROP) || (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)) {
		if (self.targetname == "") {
			remove(self);
			return;
		} else {
			self.solid = SOLID_NOT;
			self.touch = NULL;
		}
	}
	if (other.classname != "player")
		return;

	if (other.deadflag)
		return;

	if (self.solid != SOLID_TRIGGER)
		return;

	if (self.owner == other)
		return;

	if (!item_give_to(self, other))
		return;

	item_touch_picked = TRUE;
	activator = other;
	trigger_use_targets();
	pointparticles(particleeffectnum("item_pickup"), self.origin, '0 0 0', 1);
	if (substring(self.classname, 0, 7) == "dropped")
		remove (self);
	else if not(self.spawnshieldtime)
		return;
	else if ((self.flags & FL_WEAPON) && !(self.flags & FL_NO_WEAPON_STAY) && g_weapon_stay)
		return;
	else {
		if (self.team) {
			random_selection_init();
			for (head = world; (head = findfloat(head, team, self.team)); ) {
				if (head.flags & FL_ITEM) {
					item_show(head, -1);
					random_selection_add(head, 0, NULL, head.cnt, 0);
				}
			}
			e = random_selection_chosen_ent;
		} else
			e = self;

		item_schedule_respawn(e);
	}
}

void(void) item_find_team {
	entity head, e;
	if (self.effects & EFFECT_NODRAW) {
		// marker for item team search
		random_selection_init();
		for (head = world; (head = findfloat(head, team, self.team)); ) if (head.flags & FL_ITEM)
			random_selection_add(head, 0, NULL, head.cnt, 0);

		e = random_selection_chosen_ent;
		e.state = 0;
		item_show(e, 1);

		for (head = world; (head = findfloat(head, team, self.team)); ) if (head.flags & FL_ITEM) {
			if (head != e) {
				// make it a non-spawned item
				item_show(head, -1);
				head.state = 1; // state 1 = initially hidden item
			}
			head.effects &= ~EFFECT_NODRAW;
		}
		if (e.flags & FL_POWERUP) // do not spawn powerups initially!
			item_schedule_initial_respawn(e);
	}
}

void(void) item_reset {
	if (self.waypointsprite_attached)
		WaypointSprite_Kill(self.waypointsprite_attached);

	item_show(self, !self.state);
	setorigin (self, self.origin);
	self.think = stdproc_nothing;
	self.nextthink = 0;
	if (self.flags & FL_POWERUP) // do not spawn powerups initially!
		item_schedule_initial_respawn(self);
}

float(entity player, entity item) weapon_pickupevalfunc {
	float c, i, j, position;
	// See if I have it already
	if (player.weapons & item.weapons == item.weapons) {
		// If I can pick it up
		if (g_weapon_stay || !item.spawnshieldtime)
			c = 0;

		else if (player.ammo_cells || player.ammo_shells || player.ammo_nails || player.ammo_rockets) {
			// Skilled bots will grab more
			c = bound(0, skill / 10, 1) * 0.5;
		} else
			c = 0;
	} else
		c = 1;

	// If custom weapon priorities for bots is enabled rate most wanted weapons higher
	if (bot_custom_weapon && c) {
		for (i = WEP_FIRST; i < WEP_LAST ; ++i) {
			// Find weapon
			if ((weapon_info(i)).weapons & item.weapons  != item.weapons)
				continue;

			// Find the highest position on any range
			position = -1;
			for (j = 0; j < WEP_LAST ; ++j){
				if (
						bot_weapons_far[j] == i ||
						bot_weapons_mid[j] == i ||
						bot_weapons_close[j] == i)
				{
					position = j;
					break;
				}
			}
			// Rate it
			if (position >= 0 ) {
				position = WEP_LAST - position;
				// item.bot_pickupbasevalue is overwritten here
				return (BOT_PICKUP_RATING_LOW + ( (BOT_PICKUP_RATING_HIGH - BOT_PICKUP_RATING_LOW) * (position / WEP_LAST ))) * c;
			}
		}
	}
	return item.bot_pickupbasevalue * c;
}

float(entity player, entity item) commodity_pickupevalfunc {
	float c, i, need_shells = FALSE, need_nails = FALSE, need_rockets = FALSE, need_cells = FALSE;
	entity wi;
	c = 0;
	// Detect needed ammo
	for (i = WEP_FIRST; i < WEP_LAST ; ++i) {
		wi = weapon_info(i);
		if not(wi.weapons & player.weapons)
			continue;

		if (wi.items & IT_SHELLS)
			need_shells = TRUE;
		else if (wi.items & IT_NAILS)
			need_nails = TRUE;
		else if (wi.items & IT_ROCKETS)
			need_rockets = TRUE;
		else if (wi.items & IT_CELLS)
			need_cells = TRUE;
	}
	// TODO: figure out if the player even has the weapon this ammo is for?
	// may not affect strategy much though...
	// find out how much more ammo/armor/health the player can hold
	if (need_shells)
	if (item.ammo_shells)
	if (player.ammo_shells < g_pickup_shells_max)
		c = c + max(0, 1 - player.ammo_shells / g_pickup_shells_max);

	if (need_nails)
	if (item.ammo_nails)
	if (player.ammo_nails < g_pickup_nails_max)
		c = c + max(0, 1 - player.ammo_nails / g_pickup_nails_max);

	if (need_rockets)
	if (item.ammo_rockets)
	if (player.ammo_rockets < g_pickup_rockets_max)
		c = c + max(0, 1 - player.ammo_rockets / g_pickup_rockets_max);

	if (need_cells)
	if (item.ammo_cells)
	if (player.ammo_cells < g_pickup_cells_max)
		c = c + max(0, 1 - player.ammo_cells / g_pickup_cells_max);

	if (item.armorvalue)
	if (player.armorvalue < item.max_armorvalue)
		c = c + max(0, 1 - player.armorvalue / item.max_armorvalue);

	if (item.health)
	if (player.health < item.max_health)
		c = c + max(0, 1 - player.health / item.max_health);

	return item.bot_pickupbasevalue * c;
}

float(void) item_customize {
	if (other.cvar_cl_simpleitems) {
		self.modelindex = self.modelindex_lod1;
	} else {
		self.modelindex = self.modelindex_lod0;
	}
	return TRUE;
}

void (string itemmodel, string defitemmodel, string pickupsound, float defaultrespawntime, float defaultrespawntimejitter, string itemname, float itemid, float weaponid, float itemflags, float(entity player, entity item) pickupevalfunc, float pickupbasevalue) item_start {
	item_start_failed = FALSE;
	if (itemmodel == "")
		itemmodel = defitemmodel;

	// is it a dropped weapon?
	if (substring(self.classname, 0, 7) == "dropped") {
		if (g_pickup_nodrop)
			goto item_start_fail;

		self.reset = stdproc_remove;
		// it's a dropped weapon
		self.movetype = MOVETYPE_TOSS;
		entity_fade_setup(self, time + 60, 1);
		trace_line(self.origin, self.origin, TRACE_MOVE_NORMAL, self);
		if (trace_dpstartcontents & DPCONTENTS_NODROP)
			goto item_start_fail;
	} else {
		// it's a level item
		if (!g_pickup_items || gamehook_chain_ItemForbidden(self.classname))
			goto item_start_fail;

		if (team_mode) {
			if (self.notteam) {
				print("removed non-teamplay ", self.classname, "\n");
				goto item_start_fail;
			}
		} else {
			if (self.notfree) {
				print("removed non-FFA ", self.classname, "\n");
				goto item_start_fail;
			}
		}
		if (self.spawnflags & 1)
			self.noalign = 1;
		if (self.noalign)
			self.movetype = MOVETYPE_NONE;
		else
			self.movetype = MOVETYPE_TOSS;

		// do item filtering according to game mode and other things
		if (!self.noalign) {
			// first nudge it off the floor a little bit to avoid math errors
			setorigin(self, self.origin + '0 0 1');
			// set item size before we spawn a spawnfunc_waypoint
			if ((itemflags & FL_POWERUP) || self.health || self.armorvalue)
				setsize (self, '-16 -16 0', '16 16 48');
			else
				setsize (self, '-16 -16 0', '16 16 32');

			// note entity_droptofloor returns FALSE if stuck/or would fall too far
			entity_droptofloor();
			waypoint_spawnforitem(self);
		}
		self.reset = item_reset;
		weapon_spawned_list |= weaponid;
		item_precache(itemmodel, defitemmodel, pickupsound);
		precache_sound("misc/itemrespawn.wav");
		precache_sound("misc/itemrespawncountdown.wav");
		if (itemid == IT_STRENGTH)
			precache_sound("misc/strength_respawn.wav");

		if (itemid == IT_INVINCIBLE)
			precache_sound("misc/shield_respawn.wav");

		if ((itemid & (IT_STRENGTH | IT_INVINCIBLE | IT_SPEED | IT_INVISIBILITY | IT_HEALTH | IT_ARMOR | IT_KEY1 | IT_KEY2)) || (weaponid & WEPBIT_ALL))
			self.message2 = "###item###"; // for finding the nearest item using find()
	}
	self.bot_pickup = TRUE;
	self.bot_pickupevalfunc = pickupevalfunc;
	self.bot_pickupbasevalue = pickupbasevalue;
	if not(sv_item_tracecull)
		self.culltracemode = CULLTRACEMODE_NONE;

	self.mdl = itemmodel;
	self.noise = pickupsound;
	// let mappers override respawntime
	if (!self.respawntime) { // both set
		self.respawntime = defaultrespawntime;
		self.respawntimejitter = defaultrespawntimejitter;
	}
	self.netname = itemname;
	self.items = itemid;
	self.weapons = weaponid;
	self.flags = FL_ITEM | itemflags;
	if (self.targetname != "")
		self.mdl = ""; //invisible
	else
		self.touch = item_touch;

	setmodel(self, defitemmodel); // precision set below
	self.modelindex_lod1 = self.modelindex;
	setmodel(self, itemmodel); // precision set below
	self.modelindex_lod0 = self.modelindex;
	if (self.modelindex_lod0 != self.modelindex_lod1)
		self.customizeentityforclient = item_customize;

	setmodel(self, self.mdl); // precision set below
	self.effects |= EFFECT_LOWPRECISION;
	if ((itemflags & FL_POWERUP) || self.health || self.armorvalue)
		setsize (self, '-16 -16 0', '16 16 48');
	else
		setsize (self, '-16 -16 0', '16 16 32');

	if (itemflags & FL_WEAPON)
		self.modelflags |= MF_ROTATE;

	if (substring(self.classname, 0, 7) != "dropped") // if dropped, colormap is already set up nicely
	if (itemflags & FL_WEAPON) {
		// neutral team color for pickup weapons
		self.colormap = 1024; // color shirt=0 pants=0 grey
	}
	item_show(self, 1);
	self.state = 0;
	if (self.team) {
		if (!self.cnt)
			self.cnt = 1; // item probability weight

		self.effects = self.effects | EFFECT_NODRAW; // marker for item team search
		entity_initialize(self, item_find_team, INITPRIO_FINDTARGET);
	} else if ((self.flags & FL_POWERUP) && self.respawntime > 0 && substring(self.classname, 0, 7) != "dropped") // do not spawn powerups initially!
		item_schedule_initial_respawn(self);

	return;
:item_start_fail
	item_start_failed = TRUE;
	remove(self);
	return;
}

void(void) spawnfunc_item_rockets {
	if (!g_use_ammunition || g_pickup_rockets <= 0) {
		remove(self);
		return;
	}
	self.ammo_rockets = g_pickup_rockets;
	item_start(sv_model_ammorockets, "models/items/a_rockets.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "rockets", IT_ROCKETS, 0, 0, commodity_pickupevalfunc, 3000);
}

void(void) spawnfunc_item_bullets {
	if (!g_use_ammunition || g_pickup_nails <= 0) {
		remove(self);
		return;
	}
	self.ammo_nails = g_pickup_nails;
	item_start(sv_model_ammobullets, "models/items/a_bullets.mdl", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "bullets", IT_NAILS, 0, 0, commodity_pickupevalfunc, 2000);
}

void(void) spawnfunc_item_cells {
	if (!g_use_ammunition || g_pickup_cells <= 0) {
		remove(self);
		return;
	}
	self.ammo_cells = g_pickup_cells;
	item_start(sv_model_ammocells, "models/items/a_cells.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "cells", IT_CELLS, 0, 0, commodity_pickupevalfunc, 2000);
}

void(void) spawnfunc_item_shells {
	if (!g_use_ammunition || g_pickup_shells <= 0) {
		remove(self);
		return;
	}
	self.ammo_shells = g_pickup_shells;
	item_start(sv_model_ammoshells, "models/items/a_shells.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "shells", IT_SHELLS, 0, 0, commodity_pickupevalfunc, 500);
}

void(void) spawnfunc_item_armor_small {
	if (g_pickup_armorsmall <= 0) {
		remove(self);
		return;
	}
	self.armorvalue = g_pickup_armorsmall;
	self.max_armorvalue = g_pickup_armorsmall_max;
	item_start(sv_model_armorsmall, "models/items/g_a1.md3", "misc/armor1.wav", g_pickup_respawntime_armorsmall, g_pickup_respawntimejitter_armorsmall, "5 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
}

void(void) spawnfunc_item_armor_medium {
	if (g_pickup_armormedium <= 0) {
		remove(self);
		return;
	}
	if (g_pickup_armormedium <= g_pickup_armorsmall) {
		spawnfunc_item_armor_small();
		return;
	}
	hint_add("Collect armor to stay alive longer.");
	self.armorvalue = g_pickup_armormedium;
	self.max_armorvalue = g_pickup_armormedium_max;
	item_start(sv_model_armormedium, "models/items/g_armormedium.md3", "misc/armor10.wav", g_pickup_respawntime_armormedium, g_pickup_respawntimejitter_armormedium, "25 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_MID);
}

void(void) spawnfunc_item_armor_big {
	if (g_pickup_armorbig <= 0) {
		remove(self);
		return;
	}
	if (g_pickup_armorbig <= g_pickup_armormedium) {
		spawnfunc_item_armor_medium();
		return;
	}
	hint_add("Collect armor to stay alive longer.");
	self.armorvalue = g_pickup_armorbig;
	self.max_armorvalue = g_pickup_armorbig_max;
	item_start(sv_model_armorbig, "models/items/g_a50.md3","misc/armor17_5.wav", g_pickup_respawntime_armorbig, g_pickup_respawntimejitter_armorbig, "50 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, 20000);
}

void(void) spawnfunc_item_armor_large {
	if (g_pickup_armorlarge <= 0) {
		remove(self);
		return;
	}
	if (g_pickup_armorlarge <= g_pickup_armorbig) {
		spawnfunc_item_armor_big();
		return;
	}
	hint_add("Collect armor to stay alive longer.");
	self.armorvalue = g_pickup_armorlarge;
	self.max_armorvalue = g_pickup_armorlarge_max;
	item_start(sv_model_armorlarge, "models/items/g_a25.md3", "misc/armor25.wav", g_pickup_respawntime_armorlarge, g_pickup_respawntimejitter_armorlarge, "100 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
}

void(void) spawnfunc_item_health_small {
	if (g_pickup_healthsmall <= 0) {
		remove(self);
		return;
	}
	self.health = g_pickup_healthsmall;
	self.max_health = g_pickup_healthsmall_max;
	item_start(sv_model_healthsmall, "models/items/g_h1.md3", "misc/minihealth.wav", g_pickup_respawntime_healthsmall, g_pickup_respawntimejitter_healthsmall, "5 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
}

void(void) spawnfunc_item_health_medium {
	if (g_pickup_healthmedium <= 0) {
		remove(self);
		return;
	}
	if (g_pickup_healthlarge <= g_pickup_healthsmall) {
		spawnfunc_item_health_small();
		return;
	}
	self.max_health = g_pickup_healthmedium_max;
	self.health = g_pickup_healthmedium;
	item_start(sv_model_healthmedium, "models/items/g_h25.md3", "misc/mediumhealth.wav", g_pickup_respawntime_healthmedium, g_pickup_respawntimejitter_healthmedium, "25 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_MID);
}

void(void) spawnfunc_item_health_large {
	if (g_pickup_healthlarge <= 0) {
		remove(self);
		return;
	}
	if (g_pickup_healthlarge <= g_pickup_healthmedium) {
		spawnfunc_item_health_medium();
		return;
	}
	self.max_health = g_pickup_healthlarge_max;
	self.health = g_pickup_healthlarge;
	item_start(sv_model_healthlarge, "models/items/g_h50.md3", "misc/mediumhealth.wav", g_pickup_respawntime_healthlarge, g_pickup_respawntimejitter_healthlarge, "50 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_MID);
}

void(void) spawnfunc_item_health_mega {
	if (g_pickup_healthmega <= 0) {
		remove(self);
		return;
	}
	if (g_pickup_healthmega <= g_pickup_healthlarge) {
		spawnfunc_item_health_large();
		return;
	}
	hint_add("Collect extra health to stay alive longer.");
	self.max_health = g_pickup_healthmega_max;
	self.health = g_pickup_healthmega;
	item_start(sv_model_healthmega, "models/items/g_h100.md3", "misc/megahealth.wav", g_pickup_respawntime_healthmega, g_pickup_respawntimejitter_healthmega, "100 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
}

void(void) spawnfunc_item_strength {
	if (!g_powerup_strength) {
		remove(self);
		return;
	}
	precache_sound("weapons/strength_fire.wav");
	self.strength_finished = g_balance_powerup_strength_time;
	item_start(sv_model_powerupstrength, "models/items/g_strength.md3", "misc/powerup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Strength Powerup", IT_STRENGTH, 0, FL_POWERUP, item_generic_pickupevalfunc, 100000);
	powerup_strength_init();
}

void(void) spawnfunc_item_invincible {
	if (!g_powerup_shield) {
		remove(self);
		return;
	}
	self.invincible_finished = g_balance_powerup_invincible_time;
	item_start(sv_model_powerupinvincible, "models/items/g_invincible.md3", "misc/powerup_shield.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Shield", IT_INVINCIBLE, 0, FL_POWERUP, item_generic_pickupevalfunc, 100000);
	powerup_invincible_init();
}

float(void) item_glow_customize {
	if (other.scorekeeper.clientversion < CLIENT_NEXUIZ)
		self.glowmod = '0 0 0';
	else
		self.glowmod = self.colormod;

	if (self.modelindex_lod0 != self.modelindex_lod1)
		item_customize();

	return TRUE;
}

void(void) spawnfunc_item_invisibility {
	if (!g_powerup_invisibility) {
		remove(self);
		return;
	}
	self.invisibility_finished = g_balance_powerup_invisibility_time;
	item_start(sv_model_powerupinvisibility, "models/items/g_strength.md3", "misc/powerup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Invisibility", IT_INVISIBILITY, 0, FL_POWERUP, item_generic_pickupevalfunc, 100000);
	self.colormod = '1 1.5 0.1';
	self.glowmod = '1 1.5 0.1';
	self.customizeentityforclient = item_glow_customize;
	powerup_invisibility_init();
}

void(void) spawnfunc_item_speed {
	if (!g_powerup_speed) {
		remove(self);
		return;
	}
	self.speed_finished = g_balance_powerup_speed_time;
	item_start(sv_model_powerupspeed, "models/items/g_invincible.md3", "misc/powerup_shield.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Speed", IT_SPEED, 0, FL_POWERUP, item_generic_pickupevalfunc, 100000);
	self.colormod = '1 1 0.1';
	self.glowmod = '1 1 0.1';
	self.customizeentityforclient = item_glow_customize;
	powerup_speed_init();
}

void(float key, string name, vector _colormod) item_key_spawn {
	setorigin(self, self.origin + '0 0 1' * 48);
	string tn = self.targetname;
	self.targetname = "";
	item_start("", "models/keyhunt/key.md3", "kh/collect.wav", cvar("g_pickup_respawntime_key"), cvar("g_pickup_respawntimejitter_key"), name, key, 0, 0, item_generic_pickupevalfunc, 100000);
	self.targetname = tn;
	self.colormod = _colormod;
	self.effects = EFFECT_FULLBRIGHT | EFFECT_STARDUST;
	setsize(self, self.mins - '0 0 1' * 48, self.maxs);
}

void(void) spawnfunc_item_key_gold {
	item_key_spawn(IT_KEY2, "Gold Key", '1 1 0');
}

void(void) spawnfunc_item_key_silver {
	item_key_spawn(IT_KEY1, "Silver Key", '0 0 0');
}

void(void) spawnfunc_item_key_blood {
	item_key_spawn(IT_KEY3, "Blood Key", '1 0 0');
}

void(void) spawnfunc_item_jetpack {
	if (player_start_items & IT_JETPACK) {
		remove(self);
		return;
	}
	self.ammo_fuel = g_pickup_fuel_jetpack;
	item_start("", "models/items/g_jetpack.md3", "misc/itempickup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Jet pack", IT_JETPACK, 0, FL_POWERUP, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
	jetpack_enable();
}

//Q1 compat
void spawnfunc_item_health (void) {if (self.spawnflags & 2) spawnfunc_item_health_mega();else spawnfunc_item_health_medium();}

//1st april joke
void(void) item_mushroom_touch {
	item_touch();
	if (item_touch_picked)
	if (clienttype(other) == CLIENTTYPE_REAL) {
		msg_entity = other;
		net_write_byte(MSG_ONE, SVC_TEMPENTITY);
		net_write_byte(MSG_ONE, NET_TE_CSQC_TRIP);
		net_write_byte(MSG_ONE, self.cnt);
		if (sv_sound_mushroom != "")
			announce(other, sv_sound_mushroom, "");
	}
}

void(void) spawnfunc_item_mushroom {
	self.max_health = cvar("g_pickup_healthmushroom_max");
	self.health = cvar("g_pickup_healthmushroom");
	self.cnt = cvar("g_pickup_healthmushroom_time");
	item_start(sv_model_mushroom, "models/items/g_h100.md3", "misc/megahealth.wav", g_pickup_respawntime_mushroom, g_pickup_respawntimejitter_mushroom, "Mushroom", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
	self.touch = item_mushroom_touch;
}

voidfunc(string s) item_spawnfunc_for {
	if (gamehook_chain_ItemForbidden(strcat("item_", s)))
		return NULL;

#define RETURN_SPAWNFUNC_FOR(x) if (s == #x) return spawnfunc_item_##x;
	RETURN_SPAWNFUNC_FOR(health_small)
	RETURN_SPAWNFUNC_FOR(health_medium)
	RETURN_SPAWNFUNC_FOR(health_large)
	RETURN_SPAWNFUNC_FOR(health_mega)
	RETURN_SPAWNFUNC_FOR(armor_small)
	RETURN_SPAWNFUNC_FOR(armor_medium)
	RETURN_SPAWNFUNC_FOR(armor_big)
	RETURN_SPAWNFUNC_FOR(armor_large)
	RETURN_SPAWNFUNC_FOR(bullets)
	RETURN_SPAWNFUNC_FOR(cells)
	RETURN_SPAWNFUNC_FOR(rockets)
	RETURN_SPAWNFUNC_FOR(shells)
	RETURN_SPAWNFUNC_FOR(strength)
	RETURN_SPAWNFUNC_FOR(invincible)
	RETURN_SPAWNFUNC_FOR(invisibility)
	RETURN_SPAWNFUNC_FOR(speed)
#undef RETURN_SPAWNFUNC_FOR
	return NULL;
}

void(string _model, string defmodel, string snd) item_precache {
	if (_model != "")
		precache_model(_model);

	if (defmodel != _model)
		precache_model(defmodel);

	if (snd != "")
		precache_sound(snd);
}

void(void) item_init {
	CVAR_CACHE(g_balance_pause_armor_rot);
	CVAR_CACHE(g_balance_pause_fuel_rot);
	CVAR_CACHE(g_balance_pause_health_regen);
	CVAR_CACHE(g_balance_pause_health_rot);
	CVAR_CACHE(g_fullbrightitems);
	CVAR_CACHE(g_pickup_respawntime_weapon);
	CVAR_CACHE(g_pickup_respawntime_ammo);
	CVAR_CACHE(g_pickup_respawntime_healthsmall);
	CVAR_CACHE(g_pickup_respawntime_healthmedium);
	CVAR_CACHE(g_pickup_respawntime_healthlarge);
	CVAR_CACHE(g_pickup_respawntime_healthmega);
	CVAR_CACHE(g_pickup_respawntime_armorsmall);
	CVAR_CACHE(g_pickup_respawntime_armormedium);
	CVAR_CACHE(g_pickup_respawntime_armorbig);
	CVAR_CACHE(g_pickup_respawntime_armorlarge);
	CVAR_CACHE(g_pickup_respawntime_powerup);
	CVAR_CACHE(g_pickup_respawntimejitter_weapon);
	CVAR_CACHE(g_pickup_respawntimejitter_ammo);
	CVAR_CACHE(g_pickup_respawntimejitter_healthsmall);
	CVAR_CACHE(g_pickup_respawntimejitter_healthmedium);
	CVAR_CACHE(g_pickup_respawntimejitter_healthlarge);
	CVAR_CACHE(g_pickup_respawntimejitter_healthmega);
	CVAR_CACHE(g_pickup_respawntimejitter_armorsmall);
	CVAR_CACHE(g_pickup_respawntimejitter_armormedium);
	CVAR_CACHE(g_pickup_respawntimejitter_armorbig);
	CVAR_CACHE(g_pickup_respawntimejitter_armorlarge);
	CVAR_CACHE(g_pickup_respawntimejitter_powerup);
	CVAR_CACHE(g_pickup_respawntime_mushroom);
	CVAR_CACHE(g_pickup_respawntimejitter_mushroom);
	CVAR_CACHE(g_pickup_shells_max);
	CVAR_CACHE(g_pickup_nails_max);
	CVAR_CACHE(g_pickup_rockets_max);
	CVAR_CACHE(g_pickup_cells_max);
	CVAR_CACHE(g_pickup_fuel_max);
	CVAR_CACHE(g_use_ammunition);
	CVAR_CACHE(g_pickup_items);
	CVAR_CACHE(g_pickup_nodrop);
	CVAR_CACHE(g_pickup_weapons);
	CVAR_CACHE(g_pickup_weapons_max);
	CVAR_CACHE(g_pickup_shells);
	CVAR_CACHE(g_pickup_nails);
	CVAR_CACHE(g_pickup_rockets);
	CVAR_CACHE(g_pickup_cells);
	CVAR_CACHE(g_pickup_fuel);
	CVAR_CACHE(g_pickup_armorsmall);
	CVAR_CACHE(g_pickup_armorsmall_max);
	CVAR_CACHE(g_pickup_armormedium);
	CVAR_CACHE(g_pickup_armormedium_max);
	CVAR_CACHE(g_pickup_armorbig);
	CVAR_CACHE(g_pickup_armorbig_max);
	CVAR_CACHE(g_pickup_armorlarge);
	CVAR_CACHE(g_pickup_armorlarge_max);
	CVAR_CACHE(g_pickup_healthsmall);
	CVAR_CACHE(g_pickup_healthsmall_max);
	CVAR_CACHE(g_pickup_healthmedium);
	CVAR_CACHE(g_pickup_healthmedium_max);
	CVAR_CACHE(g_pickup_healthlarge);
	CVAR_CACHE(g_pickup_healthlarge_max);
	CVAR_CACHE(g_pickup_healthmega);
	CVAR_CACHE(g_pickup_healthmega_max);
	CVAR_CACHE(g_pickup_fuel_jetpack);
	CVAR_CACHE(g_powerup_strength);
	CVAR_CACHE(g_powerup_speed);
	CVAR_CACHE(g_powerup_invisibility);
	CVAR_CACHE(g_powerup_shield);
	CVAR_CACHE(g_powerup_addition);
	CVAR_CACHE(g_balance_powerup_strength_time);
	CVAR_CACHE(g_balance_powerup_invisibility_time);
	CVAR_CACHE(g_balance_powerup_invincible_time);
	CVAR_CACHE(g_balance_powerup_speed_time);
	CVAR_CACHE(sv_item_tracecull);
	CVAR_CACHE_STR(sv_model_powerupstrength);
	CVAR_CACHE_STR(sv_model_powerupinvincible);
	CVAR_CACHE_STR(sv_model_powerupinvisibility);
	CVAR_CACHE_STR(sv_model_powerupspeed);
	CVAR_CACHE_STR(sv_model_ammobullets);
	CVAR_CACHE_STR(sv_model_ammocells);
	CVAR_CACHE_STR(sv_model_ammorockets);
	CVAR_CACHE_STR(sv_model_ammoshells);
	CVAR_CACHE_STR(sv_model_healthsmall);
	CVAR_CACHE_STR(sv_model_healthmedium);
	CVAR_CACHE_STR(sv_model_healthlarge);
	CVAR_CACHE_STR(sv_model_healthmega);
	CVAR_CACHE_STR(sv_model_mushroom);
	sv_sound_mushroom = cvar_string_zone_ifneeded("sv_sound_mushroom");
	if (sv_sound_mushroom != "")
		precache_sound(sv_sound_mushroom);

	CVAR_CACHE_STR(sv_model_armorsmall);
	CVAR_CACHE_STR(sv_model_armormedium);
	CVAR_CACHE_STR(sv_model_armorbig);
	CVAR_CACHE_STR(sv_model_armorlarge);
	CVAR_CACHE(g_weapon_stay);
	CVAR_CACHE(g_ghost_items);
	if (g_ghost_items >= 1)
		g_ghost_items = 0.13; // default alpha value

	entity e;
	float i, t;

	// initialize starting values for players
	player_start_weapons = 0;
	player_start_items = 0;
	player_start_health = cvar("g_balance_health_start");
	player_start_armorvalue = cvar("g_balance_armor_start");
	if (g_use_ammunition) {
		player_start_ammo_shells = max(0, cvar("g_start_ammo_shells"));
		player_start_ammo_nails = max(0, cvar("g_start_ammo_nails"));
		player_start_ammo_rockets = max(0, cvar("g_start_ammo_rockets"));
		player_start_ammo_cells = max(0, cvar("g_start_ammo_cells"));
	} else {
		player_start_ammo_shells = 0;
		player_start_ammo_nails = 0;
		player_start_ammo_rockets = 0;
		player_start_ammo_cells = 0;
		player_start_items |= IT_UNLIMITED_AMMO;
	}
	for (i = WEP_FIRST; i <= WEP_LAST; ++i) {
		e = weapon_info(i);
		if (!(e.weapon))
			continue;

		t = cvar(strcat("g_start_weapon_", e.netname));
		if (t > 0) {
			player_start_weapons |= e.weapons;
			weapon_precache(e.weapon);
		}
	}
}
