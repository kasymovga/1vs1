.float speed_finished;
.float invincible_finished;
.float invisibility_finished;
float g_balance_pause_armor_rot;
float g_balance_pause_fuel_regen;
float g_balance_pause_fuel_rot;
float g_balance_pause_health_regen;
float g_balance_pause_health_rot;
float g_fullbrightitems;
float g_pickup_shells_max;
float g_pickup_nails_max;
float g_pickup_rockets_max;
float g_pickup_cells_max;
float g_pickup_fuel_max;
float g_ghost_items;
float g_pickup_items;
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
float g_balance_powerup_invincible_takedamage;
float g_balance_powerup_strength_damage;
float g_balance_powerup_strength_force;
float g_balance_powerup_strength_selfdamage;
float g_balance_powerup_strength_selfforce;
float g_powerup_strength_droppable;
float g_powerup_invisibility_droppable;
float g_powerup_shield_droppable;
float g_powerup_speed_droppable;
float g_use_ammunition;
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

void StartItem (string itemmodel, string pickupsound, float defaultrespawntime, float defaultrespawntimejitter, string itemname, float itemid, float weaponid, float itemflags, float(entity player, entity item) pickupevalfunc, float pickupbasevalue);

float generic_pickupevalfunc(entity player, entity item) {return item.bot_pickupbasevalue;};

void(.float powerupfield, string _model, string _sound, string _name, float it) powerup_drop {
	entity oldself;
	if (self.powerupfield > 0) {
		entity e = spawn();
		e.classname = "droppedpowerup";
		e.powerupfield = self.powerupfield - time;
		setorigin(e, self.origin);
		oldself = self;
		self = e;
		StartItem(_model, _sound, 0, 0, _name, it, 0, FL_POWERUP, generic_pickupevalfunc, 100000);
		self = oldself;
	}
}

var void(float killed) powerups_PlayerClear_NextLink;
void powerups_PlayerClear(float killed) {
	if (g_powerup_strength_droppable)
		powerup_drop(strength_finished, "models/items/g_strength.md3", "misc/powerup.wav", "Strength Powerup", IT_STRENGTH);

	if (g_powerup_shield_droppable)
		powerup_drop(invincible_finished, "models/items/g_invincible.md3", "misc/powerup_shield.wav", "Shield", IT_INVINCIBLE);

	if (g_powerup_invisibility_droppable)
		powerup_drop(invisibility_finished, "models/items/g_strength.md3", "misc/powerup.wav", "Invisibility", IT_INVISIBILITY);

	if (g_powerup_speed_droppable)
		powerup_drop(speed_finished, "models/items/g_invincible.md3", "misc/powerup_shield.wav", "Shield", IT_SPEED);

	self.invincible_finished = 0;
	self.invisibility_finished = 0;
	self.strength_finished = 0;
	self.speed_finished = 0;
	powerups_PlayerClear_NextLink(killed);
}

var void(entity e) powerups_SpectateCopy_NextLink;
void powerups_SpectateCopy(entity e) {
	self.strength_finished = e.strength_finished;
	self.invincible_finished = e.invincible_finished;
	self.speed_finished = e.speed_finished;
	self.invisibility_finished = e.invisibility_finished;
	powerups_SpectateCopy_NextLink(e);
}

float powerups_init_done;
void powerups_init() {
	if (powerups_init_done)
		return;

	powerups_init_done = 1;
	CACHE_CVAR(g_powerup_strength_akimbo);
	CACHE_CVAR(g_powerup_strength_droppable);
	CACHE_CVAR(g_powerup_invisibility_droppable);
	CACHE_CVAR(g_powerup_shield_droppable);
	CACHE_CVAR(g_powerup_speed_droppable);
	powerups_PlayerClear_NextLink = GameHookChain_PlayerClear;
	GameHookChain_PlayerClear = powerups_PlayerClear;
	powerups_SpectateCopy_NextLink = GameHookChain_SpectateCopy;
	GameHookChain_SpectateCopy = powerups_SpectateCopy;
}

var void(entity targ, entity attacker, float deathtype) powerup_invincible_DamageForceModsSet_NextLink;
void powerup_invincible_DamageForceModsSet(entity targ, entity attacker, float deathtype) {
	if (targ.items & IT_INVINCIBLE) {
		GameHook_DamageMod = GameHook_DamageMod * g_balance_powerup_invincible_takedamage;
		if (deathtype == DEATH_SLIME || deathtype == DEATH_LAVA)
			GameHook_DamageMod = 0;
	}
	powerup_invincible_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

var float() powerup_invincible_PlayerEffectsHandle_NextLink;
float powerup_invincible_PlayerEffectsHandle() {
	if (self.items & IT_INVINCIBLE) {
		play_countdown(self.invincible_finished, "misc/poweroff.wav");
		self.effects = self.effects | (EF_RED | EF_ADDITIVE | EF_FULLBRIGHT);
		if (time > self.invincible_finished) {
			self.items = self.items - (self.items & IT_INVINCIBLE);
			sprint(self, "^3Shield has worn off\n");
		}
	} else if (self.invincible_finished) {
		if (time < self.invincible_finished) {
			self.items = self.items | IT_INVINCIBLE;
			sprint(self, "^3Shield surrounds you\n");
		} else if (time > self.invincible_finished + 1)
			self.invincible_finished = 0;
	}
	return powerup_invincible_PlayerEffectsHandle_NextLink();
}

float powerup_invincible_init_done;
void powerup_invincible_init() {
	if (powerup_invincible_init_done)
		return;

	powerup_invincible_init_done = 1;
	powerups_init();
	addstat(STAT_INVINCIBLE_FINISHED, AS_FLOAT, invincible_finished);
	powerup_invincible_PlayerEffectsHandle_NextLink = GameHookChain_PlayerEffectsHandle;
	GameHookChain_PlayerEffectsHandle = powerup_invincible_PlayerEffectsHandle;
	powerup_invincible_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = powerup_invincible_DamageForceModsSet;
}

var void(entity targ, entity attacker, float deathtype) powerup_strength_DamageForceModsSet_NextLink;
void powerup_strength_DamageForceModsSet(entity targ, entity attacker, float deathtype) {
	// apply strength multiplier
	if ((attacker.items & IT_STRENGTH)) {
		if(targ == attacker) {
			GameHook_DamageMod = GameHook_DamageMod * g_balance_powerup_strength_selfdamage;
			GameHook_ForceMod = GameHook_ForceMod * g_balance_powerup_strength_selfforce;
		} else {
			GameHook_DamageMod = GameHook_DamageMod * g_balance_powerup_strength_damage;
			GameHook_ForceMod = GameHook_ForceMod * g_balance_powerup_strength_force;
		}
	}
	powerup_strength_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

var float() powerup_strength_PlayerEffectsHandle_NextLink;
float powerup_strength_PlayerEffectsHandle() {
	if (self.items & IT_STRENGTH) {
		play_countdown(self.strength_finished, "misc/poweroff.wav");
		self.effects = self.effects | (EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT);

		if (time > self.strength_finished) {
			self.items = self.items - (self.items & IT_STRENGTH);
			sprint(self, "^3Strength has worn off\n");
		}
	} else if (self.strength_finished) {
		if (time < self.strength_finished) {
			self.items = self.items | IT_STRENGTH;
			sprint(self, "^3Strength infuses your weapons with devastating power\n");
		} else if (time > self.strength_finished + 1)
			self.strength_finished = 0;
	}
	return powerup_strength_PlayerEffectsHandle_NextLink();
}

float powerup_strength_init_done;
void powerup_strength_init() {
	if (powerup_strength_init_done)
		return;

	powerup_strength_init_done = 1;
	powerups_init();
	addstat(STAT_STRENGTH_FINISHED, AS_FLOAT, strength_finished);
	if (g_powerup_strength_akimbo)
		return;

	powerup_strength_PlayerEffectsHandle_NextLink = GameHookChain_PlayerEffectsHandle;
	GameHookChain_PlayerEffectsHandle = powerup_strength_PlayerEffectsHandle;
	powerup_strength_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = powerup_strength_DamageForceModsSet;
}

var float() powerup_speed_WeaponRateFactor_NextLink;
float powerup_speed_WeaponRateFactor() {
	if (time < self.speed_finished)
		return powerup_speed_WeaponRateFactor_NextLink() * 0.666;

	return powerup_speed_WeaponRateFactor_NextLink();
}

var float() powerup_speed_PlayerEffectsHandle_NextLink;
float powerup_speed_PlayerEffectsHandle() {
	if (self.items & IT_SPEED) {
		play_countdown(self.speed_finished, "misc/poweroff.wav");
		if (time > self.speed_finished) {
			self.items = self.items - (self.items & IT_SPEED);
			sprint(self, "^3Speed has worn off\n");
		}
	} else if (self.speed_finished) {
		if (time < self.speed_finished) {
			self.items = self.items | IT_SPEED;
			sprint(self, "^3You are on speed\n");
		} else if (time > self.speed_finished + 1)
			self.speed_finished = 0;
	}

	return powerup_speed_PlayerEffectsHandle_NextLink();
}

var float() powerup_speed_SpeedMod_NextLink;
float powerup_speed_SpeedMod() {
	if (time < self.speed_finished)
		return powerup_speed_SpeedMod_NextLink() * 1.5;

	return powerup_speed_SpeedMod_NextLink();
}

float powerup_speed_init_done;
void powerup_speed_init() {
	if (powerup_speed_init_done)
		return;

	powerup_speed_init_done = 1;
	powerups_init();
	powerup_speed_SpeedMod_NextLink = GameHookChain_SpeedMod;
	GameHookChain_SpeedMod = powerup_speed_SpeedMod;
	powerup_speed_PlayerEffectsHandle_NextLink = GameHookChain_PlayerEffectsHandle;
	GameHookChain_PlayerEffectsHandle = powerup_speed_PlayerEffectsHandle;
	powerup_speed_WeaponRateFactor_NextLink = GameHookChain_WeaponRateFactor;
	GameHookChain_WeaponRateFactor = powerup_speed_WeaponRateFactor;
	addstat(STAT_SPEED_FINISHED, AS_FLOAT, speed_finished);
	PhysicEnableCSQC();
}

var float() powerup_invisibility_PlayerEffectsHandle_NextLink;
float powerup_invisibility_PlayerEffectsHandle() {
	if (self.items & IT_INVISIBILITY) {
		play_countdown(self.invisibility_finished, "misc/poweroff.wav");
		if (time > self.invisibility_finished) {
			self.items &~= IT_INVISIBILITY;
			sprint(self, "^3Invisibility has worn off\n");
		}
	} else if (self.invisibility_finished) {
		if (time < self.invisibility_finished) {
			self.items |= IT_INVISIBILITY;
			sprint(self, "^3You are invisible\n");
		} else if (time > self.invisibility_finished + 1)
			self.invisibility_finished = 0;
	}
	return powerup_invisibility_PlayerEffectsHandle_NextLink();
}

var float(entity plr, entity viewer, float dalpha) powerup_invisibility_PlayerAlphaMod_NextLink;
float powerup_invisibility_PlayerAlphaMod(entity plr, entity viewer, float dalpha) {
	if (time < plr.invisibility_finished)
		dalpha *= 0.05;

	return powerup_invisibility_PlayerAlphaMod_NextLink(plr, viewer, dalpha);
}

float powerup_invisibility_init_done;
void powerup_invisibility_init() {
	if (powerup_invisibility_init_done)
		return;

	powerup_invisibility_init_done = 1;
	powerups_init();
	powerup_invisibility_PlayerAlphaMod_NextLink = GameHookChain_PlayerAlphaMod;
	GameHookChain_PlayerAlphaMod = powerup_invisibility_PlayerAlphaMod;
	powerup_invisibility_PlayerEffectsHandle_NextLink = GameHookChain_PlayerEffectsHandle;
	GameHookChain_PlayerEffectsHandle = powerup_invisibility_PlayerEffectsHandle;
	addstat(STAT_INVISIBILITY_FINISHED, AS_FLOAT, invisibility_finished);
}

#define ITEM_RESPAWN_TICKS 10

#define ITEM_RESPAWNTIME(i)         ((i).respawntime + random_2() * (i).respawntimejitter)
	// range: respawntime - respawntimejitter .. respawntime + respawntimejitter
#define ITEM_RESPAWNTIME_INITIAL(i) (ITEM_RESPAWN_TICKS + random() * ((i).respawntime + (i).respawntimejitter - ITEM_RESPAWN_TICKS))
	// range: 10 .. respawntime + respawntimejitter

floatfield Item_CounterField(float it)
{
	switch(it)
	{
		case IT_SHELLS:      return ammo_shells;
		case IT_NAILS:       return ammo_nails;
		case IT_ROCKETS:     return ammo_rockets;
		case IT_CELLS:       return ammo_cells;
		case IT_HEALTH:      return health;
		case IT_ARMOR:       return armorvalue;
		// add more things here (health, armor)
		default:             error("requested item has no counter field");
	}
}

string Item_CounterFieldName(float it)
{
	switch(it)
	{
		case IT_SHELLS:      return "shells";
		case IT_NAILS:       return "nails";
		case IT_ROCKETS:     return "rockets";
		case IT_CELLS:       return "cells";

		// add more things here (health, armor)
		default:             error("requested item has no counter field name");
	}
}

.float max_armorvalue;

void Item_Show (entity e, float mode)
{
	e.effects &~= EF_ADDITIVE | EF_STARDUST | EF_FULLBRIGHT;
	if (mode > 0)
	{
		// make the item look normal, and be touchable
		e.model = e.mdl;
		e.solid = SOLID_TRIGGER;
		//e.colormod = '0 0 0';
		e.alpha = 0;
		e.customizeentityforclient = func_null;

		e.spawnshieldtime = 1;
	}
	else if (mode < 0)
	{
		// hide the item completely
		e.model = string_null;
		e.solid = SOLID_NOT;
		//e.colormod = '0 0 0';
		e.alpha = -1;
		e.customizeentityforclient = func_null;

		e.spawnshieldtime = 1;
	}
	else if(g_ghost_items)
	{
		// make the item translucent green and not touchable
		e.model = e.mdl;
		e.solid = SOLID_NOT;
		//e.colormod = '0.2 1 0.2';
		e.alpha = g_ghost_items;
		e.customizeentityforclient = func_null;

		e.spawnshieldtime = 1;
	}
	else
	{
		// hide the item completely
		e.model = string_null;
		e.solid = SOLID_NOT;
		//e.colormod = '0 0 0';
		e.alpha = 0;
		e.customizeentityforclient = func_null;

		e.spawnshieldtime = 1;
	}

	if (e.strength_finished || e.invincible_finished)
		e.effects |= EF_ADDITIVE | EF_FULLBRIGHT;
	if (g_fullbrightitems)
		e.effects |= EF_FULLBRIGHT;

	// relink entity (because solid may have changed)
	setorigin(e, e.origin);
}

void Item_Respawn (void)
{
	Item_Show(self, 1);
	if(self.items == IT_STRENGTH)
		sound (self, CHAN_TRIGGER, "misc/strength_respawn.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	else if(self.items == IT_INVINCIBLE)
		sound (self, CHAN_TRIGGER, "misc/shield_respawn.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	else
		sound (self, CHAN_TRIGGER, "misc/itemrespawn.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);

	//pointparticles(particleeffectnum("item_respawn"), self.origin + self.mins_z * '0 0 1' + '0 0 48', '0 0 0', 1);
	pointparticles(particleeffectnum("item_respawn"), self.origin + 0.5 * (self.mins + self.maxs), '0 0 0', 1);
}

void Item_RespawnCountdown (void)
{
	if(self.count >= ITEM_RESPAWN_TICKS)
	{
		if(self.waypointsprite_attached)
			WaypointSprite_Kill(self.waypointsprite_attached);
		Item_Respawn();
	}
	else
	{
		self.nextthink = time + 1;
		self.count += 1;
		if(self.count == 1)
		{
			GameHook_ItemName = string_null;
			GameHookChain_ItemRespawnCountDown();
			switch(self.items)
			{
				case IT_STRENGTH:       GameHook_ItemName = "item-strength"; GameHook_ItemColor = '0 0 1'; break;
				case IT_INVINCIBLE:     GameHook_ItemName = "item-shield"; GameHook_ItemColor = '1 0 1'; break;
				case IT_SPEED:          GameHook_ItemName = "item-speed"; GameHook_ItemColor = '1 0 1'; break;
				case IT_INVISIBILITY:   GameHook_ItemName = "item-invis"; GameHook_ItemColor = '0 0 1'; break;
				case IT_JETPACK:        GameHook_ItemName = "item-jetpack"; GameHook_ItemColor = '0.5 0.5 0.5'; break;
			}
			if(GameHook_ItemName)
			{
				WaypointSprite_Spawn(GameHook_ItemName, 0, 0, self, '0 0 64', world, 0, self, waypointsprite_attached, TRUE);
				if(self.waypointsprite_attached)
				{
					WaypointSprite_UpdateTeamRadar(self.waypointsprite_attached, RADARICON_POWERUP, GameHook_ItemColor);
					//WaypointSprite_UpdateMaxHealth(self.waypointsprite_attached, ITEM_RESPAWN_TICKS + 1);
					WaypointSprite_UpdateBuildFinished(self.waypointsprite_attached, time + ITEM_RESPAWN_TICKS);
				}
			}
		}
		sound (self, CHAN_TRIGGER, "misc/itemrespawncountdown.wav", VOL_BASE, ATTN_NORM);	// play respawn sound
		if(self.waypointsprite_attached)
		{
			WaypointSprite_Ping(self.waypointsprite_attached);
			//WaypointSprite_UpdateHealth(self.waypointsprite_attached, self.count);
		}
	}
}

void Item_ScheduleRespawnIn(entity e, float t)
{
	if(e.flags & FL_POWERUP)
	{
		e.think = Item_RespawnCountdown;
		e.nextthink = time + max(0, t - ITEM_RESPAWN_TICKS);
		e.count = 0;
	}
	else
	{
		e.think = Item_Respawn;
		e.nextthink = time + t;
	}
}

void Item_ScheduleRespawn(entity e)
{
	if (e.respawntime < 0) {
		Item_Show(e, -1);
		return;
	}
	Item_Show(e, 0);
	Item_ScheduleRespawnIn(e, ITEM_RESPAWNTIME(e));
}

void Item_ScheduleInitialRespawn(entity e)
{
	Item_Show(e, 0);
	Item_ScheduleRespawnIn(e, max(0, game_starttime - time) + ITEM_RESPAWNTIME_INITIAL(e));
}

float Item_GiveTo(entity item, entity player)
{
	float _switchweapon;
	float pickedup;
	float it;
	float i;
	entity e;

	// if nothing happens to player, just return without taking the item
	pickedup = FALSE;
	_switchweapon = FALSE;

	if (time < game_starttime)
		return FALSE;

	if (GameHookChain_ItemGiveToHandle(item, player)) {
		pickedup = GameHookChain_ItemGiveToHandle_PickedUp;
		GameHookChain_ItemGiveToHandle_PickedUp = FALSE;
		_switchweapon = GameHookChain_ItemGiveToHandle_SwitchWeapon;
		GameHookChain_ItemGiveToHandle_SwitchWeapon = FALSE;
	} else {
		if (g_weapon_stay)
		if not(item.flags & FL_NO_WEAPON_STAY)
		if (item.flags & FL_WEAPON)
		{
			for(i = WEP_FIRST; i <= WEP_LAST; ++i)
				if (W_WeaponBit(i) & item.weapons & player.weapons)
					if (Akimbo_GiveWeapon (player, i, item.netname))
					{
						pickedup = TRUE;
						sound (player, CHAN_AUTO, item.noise, VOL_BASE, ATTN_NORM);
					}

			if not(pickedup)
			{
				if (player.weapons & item.weapons)	// don't let players stack ammo by tossing weapons
					goto skip;
			}
		}

		// in case the player has autoswitch enabled do the following:
		// if the player is using their best weapon before items are given, they
		// probably want to switch to an even better weapon after items are given
		if (player.autoswitch)
		if (player.switchweapon == w_getbestweapon(player))
			_switchweapon = TRUE;

		if not(player.weapons & W_WeaponBit(player.switchweapon))
			_switchweapon = TRUE;

		if(item.spawnshieldtime)
		if(g_use_ammunition)
		{
			if (item.ammo_shells)
			if (player.ammo_shells < g_pickup_shells_max)
			{
				pickedup = TRUE;
				player.ammo_shells = min (player.ammo_shells + item.ammo_shells, g_pickup_shells_max);
			}
			if (item.ammo_nails)
			if (player.ammo_nails < g_pickup_nails_max)
			{
				pickedup = TRUE;
				player.ammo_nails = min (player.ammo_nails + item.ammo_nails, g_pickup_nails_max);
			}
			if (item.ammo_rockets)
			if (player.ammo_rockets < g_pickup_rockets_max)
			{
				pickedup = TRUE;
				player.ammo_rockets = min (player.ammo_rockets + item.ammo_rockets, g_pickup_rockets_max);
			}
			if (item.ammo_cells)
			if (player.ammo_cells < g_pickup_cells_max)
			{
				pickedup = TRUE;
				player.ammo_cells = min (player.ammo_cells + item.ammo_cells, g_pickup_cells_max);
			}
			if (item.ammo_fuel)
			if (player.ammo_fuel < g_pickup_fuel_max)
			{
				pickedup = TRUE;
				player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
				player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
			}
		}

		if (item.flags & FL_WEAPON)
		{
			for(i = WEP_FIRST; i <= WEP_LAST; ++i)
			{
				e = get_weaponinfo(i);
				if not(item.weapons & e.weapons)
					continue;
				if not(player.weapons & e.weapons)
				{
					pickedup = TRUE;
					W_GiveWeapon (player, e.weapon, item.netname);
				}
				else if (Akimbo_GiveWeapon (player, e.weapon, item.netname))
					pickedup = TRUE;
			}
		}

		if((it = (item.items - (item.items & player.items)) & IT_PICKUPMASK))
		{
			pickedup = TRUE;
			player.items |= it;
			sprint (player, strcat("You got the ^2", item.netname, "\n"));
		}

		if(item.spawnshieldtime)
		{
			if (item.strength_finished)
			{
				pickedup = TRUE;
				player.strength_finished = max(player.strength_finished, time) + item.strength_finished;
			}
			if (item.invincible_finished)
			{
				pickedup = TRUE;
				player.invincible_finished = max(player.invincible_finished, time) + item.invincible_finished;
			}
			if (item.speed_finished)
			{
				pickedup = TRUE;
				player.speed_finished = max(player.speed_finished, time) + item.speed_finished;
			}
			if (item.invisibility_finished)
			{
				pickedup = TRUE;
				player.invisibility_finished = max(player.invisibility_finished, time) + item.invisibility_finished;
			}

			if (item.health)
			if (player.health < item.max_health)
			{
				pickedup = TRUE;
				player.health = min(player.health + item.health, item.max_health);
				player.pauserothealth_finished = max(player.pauserothealth_finished, time + g_balance_pause_health_rot);
			}
			if (item.armorvalue)
			if (player.armorvalue < item.max_armorvalue)
			{
				pickedup = TRUE;
				player.armorvalue = min(player.armorvalue + item.armorvalue, item.max_armorvalue);
				player.pauserotarmor_finished = max(player.pauserotarmor_finished, time + g_balance_pause_armor_rot);
			}
		}
	}
	if(item.spawnshieldtime)
	if((it = item.items & (IT_KEY1 | IT_KEY2)))
	{
		if ((player.keys & it) == it)
			goto skip;

		pickedup = TRUE;
		player.keys |= it;
	}

:skip
	// always eat teamed entities
	if(item.team)
		pickedup = TRUE;

	if (!pickedup)
		return 0;

	sound (player, CHAN_AUTO, item.noise, VOL_BASE, ATTN_NORM);
	if (_switchweapon)
		if (player.switchweapon != w_getbestweapon(player))
			W_SwitchWeapon_Force(player, w_getbestweapon(player));

	return 1;
}

float item_touch_picked;
void Item_Touch (void)
{
	entity e, head;

	item_touch_picked = FALSE;
	// remove the item if it's currnetly in a NODROP brush or hits a NOIMPACT surface (such as sky)
	if (((trace_dpstartcontents | trace_dphitcontents) & DPCONTENTS_NODROP) || (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
	{
		remove(self);
		return;
	}
	if (other.classname != "player")
		return;
	if (other.deadflag)
		return;
	if (self.solid != SOLID_TRIGGER)
		return;
	if (self.owner == other)
		return;

	if(!Item_GiveTo(self, other))
		return;

	item_touch_picked = TRUE;
	activator = other;
	SUB_UseTargets();
	pointparticles(particleeffectnum("item_pickup"), self.origin, '0 0 0', 1);

	if (substring(self.classname, 0, 7) == "dropped")
		remove (self);
	else if not(self.spawnshieldtime)
		return;
	else if((self.flags & FL_WEAPON) && !(self.flags & FL_NO_WEAPON_STAY) && g_weapon_stay)
		return;
	else
	{
		if(self.team)
		{
			random_selection_init();
			for(head = world; (head = findfloat(head, team, self.team)); )
			{
				if(head.flags & FL_ITEM)
				{
					Item_Show(head, -1);
					random_selection_add(head, 0, string_null, head.cnt, 0);
				}
			}
			e = random_selection_chosen_ent;
		}
		else
			e = self;
		Item_ScheduleRespawn(e);
	}
}

void Item_FindTeam()
{
	entity head, e;

	if(self.effects & EF_NODRAW)
	{
		// marker for item team search
		dprint("Initializing item team ", ftos(self.team), "\n");
		random_selection_init();
		for(head = world; (head = findfloat(head, team, self.team)); ) if(head.flags & FL_ITEM)
			random_selection_add(head, 0, string_null, head.cnt, 0);
		e = random_selection_chosen_ent;
		e.state = 0;
		Item_Show(e, 1);

		for(head = world; (head = findfloat(head, team, self.team)); ) if(head.flags & FL_ITEM)
		{
			if(head != e)
			{
				// make it a non-spawned item
				Item_Show(head, -1);
				head.state = 1; // state 1 = initially hidden item
			}
			head.effects &~= EF_NODRAW;
		}

		if(e.flags & FL_POWERUP) // do not spawn powerups initially!
			Item_ScheduleInitialRespawn(e);
	}
}

void Item_Reset()
{
	if(self.waypointsprite_attached)
		WaypointSprite_Kill(self.waypointsprite_attached);

	Item_Show(self, !self.state);
	setorigin (self, self.origin);
	self.think = SUB_Null;
	self.nextthink = 0;
	if(self.flags & FL_POWERUP) // do not spawn powerups initially!
		Item_ScheduleInitialRespawn(self);
}

float weapon_pickupevalfunc(entity player, entity item)
{
	float c, i, j, position;

	// See if I have it already
	if(player.weapons & item.weapons == item.weapons)
	{
		// If I can pick it up
		if(g_weapon_stay || !item.spawnshieldtime)
			c = 0;
		else if(player.ammo_cells || player.ammo_shells || player.ammo_nails || player.ammo_rockets)
		{
			// Skilled bots will grab more
			c = bound(0, skill / 10, 1) * 0.5;
		}
		else
			c = 0;
	}
	else
		c = 1;

	// If custom weapon priorities for bots is enabled rate most wanted weapons higher
	if( bot_custom_weapon && c )
	{
		for(i = WEP_FIRST; i < WEP_LAST ; ++i)
		{
			// Find weapon
			if( (get_weaponinfo(i)).weapons & item.weapons  != item.weapons )
				continue;

			// Find the highest position on any range
			position = -1;
			for(j = 0; j < WEP_LAST ; ++j){
				if(
						bot_weapons_far[j] == i ||
						bot_weapons_mid[j] == i ||
						bot_weapons_close[j] == i
				  )
				{
					position = j;
					break;
				}
			}

			// Rate it
			if (position >= 0 )
			{
				position = WEP_LAST - position;
				// item.bot_pickupbasevalue is overwritten here
				return (BOT_PICKUP_RATING_LOW + ( (BOT_PICKUP_RATING_HIGH - BOT_PICKUP_RATING_LOW) * (position / WEP_LAST ))) * c;
			}
		}
	}

	return item.bot_pickupbasevalue * c;
};

float commodity_pickupevalfunc(entity player, entity item)
{
	float c, i, need_shells, need_nails, need_rockets, need_cells;
	entity wi;
	c = 0;

	// Detect needed ammo
	for(i = WEP_FIRST; i < WEP_LAST ; ++i)
	{
		wi = get_weaponinfo(i);

		if not(wi.weapons & player.weapons)
			continue;

		if(wi.items & IT_SHELLS)
			need_shells = TRUE;
		else if(wi.items & IT_NAILS)
			need_nails = TRUE;
		else if(wi.items & IT_ROCKETS)
			need_rockets = TRUE;
		else if(wi.items & IT_CELLS)
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
};


.float is_item;
void StartItem (string itemmodel, string pickupsound, float defaultrespawntime, float defaultrespawntimejitter, string itemname, float itemid, float weaponid, float itemflags, float(entity player, entity item) pickupevalfunc, float pickupbasevalue)
{
	startitem_failed = FALSE;

	// is it a dropped weapon?
	if (substring(self.classname, 0, 7) == "dropped")
	{
		self.reset = SUB_Remove;
		// it's a dropped weapon
		self.movetype = MOVETYPE_TOSS;
		SUB_SetFade(self, time + 60, 1);
		traceline(self.origin, self.origin, MOVE_NORMAL, self);
		if (trace_dpstartcontents & DPCONTENTS_NODROP)
		{
			startitem_failed = TRUE;
			remove(self);
			return;
		}
	}
	else
	{
		// it's a level item
		if(self.notq3a)
		{
			// We aren't TA or something like that, so we keep the Q3A entities
			print("removed non-Q3A ", self.classname, "\n");
			startitem_failed = TRUE;
			remove (self);
			return;
		}
		if (!g_pickup_items || GameHookChain_ItemForbidden())
		{
			startitem_failed = TRUE;
			remove (self);
			return;
		}
		if(teamplay)
		{
			if(self.notteam)
			{
				print("removed non-teamplay ", self.classname, "\n");
				startitem_failed = TRUE;
				remove (self);
				return;
			}
		}
		else
		{
			if(self.notfree)
			{
				print("removed non-FFA ", self.classname, "\n");
				startitem_failed = TRUE;
				remove (self);
				return;
			}
		}
		if (self.scale)
			self.scale = self.scale * sv_world_scale;
		else
			self.scale = sv_world_scale;

		if(self.spawnflags & 1)
			self.noalign = 1;
		if (self.noalign)
			self.movetype = MOVETYPE_NONE;
		else
			self.movetype = MOVETYPE_TOSS;
		// do item filtering according to game mode and other things
		if (!self.noalign)
		{
			// first nudge it off the floor a little bit to avoid math errors
			setorigin(self, self.origin + '0 0 1');
			// set item size before we spawn a spawnfunc_waypoint
			if((itemflags & FL_POWERUP) || self.health || self.armorvalue)
				setsize (self, '-16 -16 0' * sv_world_scale, '16 16 48' * sv_world_scale);
			else
				setsize (self, '-16 -16 0' * sv_world_scale, '16 16 32' * sv_world_scale);
			// note droptofloor returns FALSE if stuck/or would fall too far
			droptofloor();
			waypoint_spawnforitem(self);
		}
		self.reset = Item_Reset;
		/*
		 * can't do it that way, as it would break maps
		 * TODO make a target_give like entity another way, that perhaps has
		 * the weapon name in a key
		if(self.targetname)
		{
			// target_give not yet supported; maybe later
			print("removed targeted ", self.classname, "\n");
			startitem_failed = TRUE;
			remove (self);
			return;
		}
		*/

		if(spawn_debug >= 2)
		{
			entity otheritem;
			for(otheritem = findradius(self.origin, 3); otheritem; otheritem = otheritem.chain)
			{
				if(otheritem.is_item)
				{
					dprint("XXX Found duplicated item: ", itemname, vtos(self.origin));
					dprint(" vs ", otheritem.netname, vtos(otheritem.origin), "\n");
					error("Mapper sucks.");
				}
			}
			self.is_item = TRUE;
		}
		weaponsInMap |= weaponid;
		precache_model (itemmodel);
		precache_sound (pickupsound);
		precache_sound ("misc/itemrespawn.wav");
		precache_sound ("misc/itemrespawncountdown.wav");

		if(itemid == IT_STRENGTH)
			precache_sound ("misc/strength_respawn.wav");
		if(itemid == IT_INVINCIBLE)
			precache_sound ("misc/shield_respawn.wav");

		if((itemid & (IT_STRENGTH | IT_INVINCIBLE | IT_SPEED | IT_INVISIBILITY | IT_HEALTH | IT_ARMOR | IT_KEY1 | IT_KEY2)) || (weaponid & WEPBIT_ALL))
			self.targetname = "###item###"; // for finding the nearest item using find()
	}

	self.bot_pickup = TRUE;
	self.bot_pickupevalfunc = pickupevalfunc;
	self.bot_pickupbasevalue = pickupbasevalue;
	self.mdl = itemmodel;
	self.noise = pickupsound;
	// let mappers override respawntime
	if(!self.respawntime) // both set
	{
		self.respawntime = defaultrespawntime;
		self.respawntimejitter = defaultrespawntimejitter;
	}
	self.netname = itemname;
	self.items = itemid;
	self.weapons = weaponid;
	self.flags = FL_ITEM | itemflags;
	self.touch = Item_Touch;
	setmodel (self, self.mdl); // precision set below
	self.effects |= EF_LOWPRECISION;
	if((itemflags & FL_POWERUP) || self.health || self.armorvalue)
		setsize (self, '-16 -16 0', '16 16 48');
	else
		setsize (self, '-16 -16 0', '16 16 32');
	if(itemflags & FL_WEAPON)
		self.modelflags |= MF_ROTATE;

	if (substring(self.classname, 0, 7) != "dropped") // if dropped, colormap is already set up nicely
	if (itemflags & FL_WEAPON)
	{
		// neutral team color for pickup weapons
		self.colormap = 1024; // color shirt=0 pants=0 grey
	}

	Item_Show(self, 1);
	self.state = 0;
	if(self.team)
	{
		if(!self.cnt)
			self.cnt = 1; // item probability weight
		self.effects = self.effects | EF_NODRAW; // marker for item team search
		InitializeEntity(self, Item_FindTeam, INITPRIO_FINDTARGET);
	}
	else if(self.flags & FL_POWERUP && self.respawntime > 0) // do not spawn powerups initially!
		Item_ScheduleInitialRespawn(self);
}

float internalteam;

void weapon_defaultspawnfunc(float wpn)
{
	entity e;
	float t;
	var .float ammofield;
	string s;
	entity oldself;
	float i, j;
	if not(g_pickup_weapons) {
		remove(self);
		return;
	}
	if (GameHookChain_WeaponSpawnHandle(float wpn))
		return;

	// set the respawntime in advance (so replaced weapons can copy it)

	if(!self.respawntime)
	{
		e = get_weaponinfo(wpn);
		if(e.items == IT_SUPERWEAPON)
		{
			self.respawntime = g_pickup_respawntime_powerup;
			self.respawntimejitter = g_pickup_respawntimejitter_powerup;
		}
		else
		{
			self.respawntime = g_pickup_respawntime_weapon;
			self.respawntimejitter = g_pickup_respawntimejitter_weapon;
		}
	}

	if(self.classname != "droppedweapon" && self.classname != "replacedweapon")
	{
		e = get_weaponinfo(wpn);
		s = cvar_string(strcat("g_weaponreplace_", e.netname));
		if(s == "0")
		{
			remove(self);
			startitem_failed = TRUE;
			return;
		}
		t = tokenize_console(s);
		if(t >= 2)
		{
			self.team = --internalteam;
			oldself = self;
			for(i = 1; i < t; ++i)
			{
				s = argv(i);
				for(j = WEP_FIRST; j <= WEP_LAST; ++j)
				{
					e = get_weaponinfo(j);
					if(e.netname == s)
					{
						self = spawn();
						copyentity(oldself, self);
						self.classname = "replacedweapon";
						weapon_defaultspawnfunc(j);
						break;
					}
				}
				if(j > WEP_LAST)
				{
					print("The weapon replace list for ", oldself.classname, " contains an unknown weapon ", s, ". Skipped.\n");
				}
			}
			self = oldself;
		}
		if(t >= 1)
		{
			s = argv(0);
			wpn = 0;
			for(j = WEP_FIRST; j <= WEP_LAST; ++j)
			{
				e = get_weaponinfo(j);
				if(e.netname == s)
				{
					wpn = j;
					break;
				}
			}
			if(j > WEP_LAST)
			{
				print("The weapon replace list for ", self.classname, " contains an unknown weapon ", s, ". Skipped.\n");
			}
		}
		if(wpn == 0)
		{
			remove(self);
			startitem_failed = TRUE;
			return;
		}
	}

	e = get_weaponinfo(wpn);

	if(e.items && e.items != IT_SUPERWEAPON)
	{
		for(i = 0, j = 1; i < 24; ++i, j *= 2)
		{
			if(e.items & j)
			{
				ammofield = Item_CounterField(j);
				if(!self.ammofield)
					self.ammofield = cvar(strcat("g_pickup_", Item_CounterFieldName(j)));
			}
		}
	}
	else
	{
		self.flags |= FL_NO_WEAPON_STAY;
	}

	// weapon stay isn't supported for teamed weapons
	if(self.team)
		self.flags |= FL_NO_WEAPON_STAY;

	StartItem(e.model, "weapons/weaponpickup.wav", self.respawntime, self.respawntimejitter, e.message, 0, e.weapons, FL_WEAPON, weapon_pickupevalfunc, e.bot_pickupbasevalue);
	if (self.modelindex) // don't precache if self was removed
		weapon_precache(e.weapon);
}

void spawnfunc_weapon_uzi (void) {
	weapon_defaultspawnfunc(WEP_UZI);
}

void spawnfunc_weapon_shotgun (void) {
	weapon_defaultspawnfunc(WEP_SHOTGUN);
}

void spawnfunc_weapon_supershotgun (void) {
	weapon_defaultspawnfunc(WEP_SUPERSHOTGUN);
}

void spawnfunc_weapon_nex (void)
{
	weapon_defaultspawnfunc(WEP_NEX);
}

void spawnfunc_weapon_rocketlauncher (void)
{
	weapon_defaultspawnfunc(WEP_ROCKET_LAUNCHER);
}

void spawnfunc_item_rockets (void) {
	if not(g_use_ammunition) {
		remove(self);
		return;
	}
	if(!self.ammo_rockets)
		self.ammo_rockets = cvar("g_pickup_rockets");
	StartItem ("models/items/a_rockets.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "rockets", IT_ROCKETS, 0, 0, commodity_pickupevalfunc, 3000);
}

void spawnfunc_item_bullets (void) {
	if not(g_use_ammunition) {
		remove(self);
		return;
	}
	if(!self.ammo_nails)
		self.ammo_nails = cvar("g_pickup_nails");
	StartItem ("models/items/a_bullets.mdl", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "bullets", IT_NAILS, 0, 0, commodity_pickupevalfunc, 2000);
}

void spawnfunc_item_cells (void) {
	if not(g_use_ammunition) {
		remove(self);
		return;
	}
	if(!self.ammo_cells)
		self.ammo_cells = cvar("g_pickup_cells");
	StartItem ("models/items/a_cells.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "cells", IT_CELLS, 0, 0, commodity_pickupevalfunc, 2000);
}

void spawnfunc_item_shells (void) {
	if not(g_use_ammunition) {
		remove(self);
		return;
	}
	if(!self.ammo_shells)
		self.ammo_shells = cvar("g_pickup_shells");
	StartItem ("models/items/a_shells.md3", "misc/itempickup.wav", g_pickup_respawntime_ammo, g_pickup_respawntimejitter_ammo, "shells", IT_SHELLS, 0, 0, commodity_pickupevalfunc, 500);
}

void spawnfunc_item_armor_small (void) {
	if(!self.armorvalue)
		self.armorvalue = cvar("g_pickup_armorsmall");
	if(!self.max_armorvalue)
		self.max_armorvalue = cvar("g_pickup_armorsmall_max");
	StartItem (sv_model_armorsmall, "misc/armor1.wav", g_pickup_respawntime_armorsmall, g_pickup_respawntimejitter_armorsmall, "5 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
}

void spawnfunc_item_armor_medium (void) {
	if(!self.armorvalue)
		self.armorvalue = cvar("g_pickup_armormedium");
	if(!self.max_armorvalue)
		self.max_armorvalue = cvar("g_pickup_armormedium_max");
	StartItem (sv_model_armormedium, "misc/armor10.wav", g_pickup_respawntime_armormedium, g_pickup_respawntimejitter_armormedium, "25 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_MID);
}

void spawnfunc_item_armor_big (void) {
	if(!self.armorvalue)
		self.armorvalue = cvar("g_pickup_armorbig");
	if(!self.max_armorvalue)
		self.max_armorvalue = cvar("g_pickup_armorbig_max");
	StartItem (sv_model_armorbig, "misc/armor17_5.wav", g_pickup_respawntime_armorbig, g_pickup_respawntimejitter_armorbig, "50 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, 20000);
}

void spawnfunc_item_armor_large (void) {
	if(!self.armorvalue)
		self.armorvalue = cvar("g_pickup_armorlarge");
	if(!self.max_armorvalue)
		self.max_armorvalue = cvar("g_pickup_armorlarge_max");
	StartItem (sv_model_armorlarge, "misc/armor25.wav", g_pickup_respawntime_armorlarge, g_pickup_respawntimejitter_armorlarge, "100 Armor", IT_ARMOR, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
}

void spawnfunc_item_health_small (void) {
	if(!self.max_health)
		self.max_health = cvar("g_pickup_healthsmall_max");
	if(!self.health)
		self.health = cvar("g_pickup_healthsmall");
	StartItem (sv_model_healthsmall, "misc/minihealth.wav", g_pickup_respawntime_healthsmall, g_pickup_respawntimejitter_healthsmall, "5 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
}

void spawnfunc_item_health_medium (void) {
	if(!self.max_health)
		self.max_health = cvar("g_pickup_healthmedium_max");
	if(!self.health)
		self.health = cvar("g_pickup_healthmedium");
	StartItem (sv_model_healthmedium, "misc/mediumhealth.wav", g_pickup_respawntime_healthmedium, g_pickup_respawntimejitter_healthmedium, "25 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_MID);
}

void spawnfunc_item_health_large (void) {
	if(!self.max_health)
		self.max_health = cvar("g_pickup_healthlarge_max");
	if(!self.health)
		self.health = cvar("g_pickup_healthlarge");
	StartItem (sv_model_healthlarge, "misc/mediumhealth.wav", g_pickup_respawntime_healthlarge, g_pickup_respawntimejitter_healthlarge, "50 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_MID);
}

void spawnfunc_item_health_mega (void) {
	if(!cvar("g_powerup_superhealth")) {
		remove(self);
		return;
	}
	if(!self.max_health)
		self.max_health = cvar("g_pickup_healthmega_max");
	if(!self.health)
		self.health = cvar("g_pickup_healthmega");
	StartItem (sv_model_healthmega, "misc/megahealth.wav", g_pickup_respawntime_healthmega, g_pickup_respawntimejitter_healthmega, "100 Health", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
}

// support old misnamed entities
void spawnfunc_item_strength (void) {
	if(!cvar("g_powerup_strength")) {
		remove(self);
		return;
	}
	precache_sound("weapons/strength_fire.wav");
	self.strength_finished = cvar("g_balance_powerup_strength_time");
	StartItem ("models/items/g_strength.md3", "misc/powerup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Strength Powerup", IT_STRENGTH, 0, FL_POWERUP, generic_pickupevalfunc, 100000);
	powerup_strength_init();
}

void spawnfunc_item_invincible (void) {
	if(!cvar("g_powerup_shield")) {
		remove(self);
		return;
	}
	self.invincible_finished = cvar("g_balance_powerup_invincible_time");
	StartItem ("models/items/g_invincible.md3", "misc/powerup_shield.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Shield", IT_INVINCIBLE, 0, FL_POWERUP, generic_pickupevalfunc, 100000);
	powerup_invincible_init();
}

void spawnfunc_item_invisibility (void) {
	if(!cvar("g_powerup_invisibility")) {
		remove(self);
		return;
	}
	self.invisibility_finished = cvar("g_balance_powerup_invisibility_time");
	StartItem ("models/items/g_strength.md3", "misc/powerup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Invisibility", IT_INVISIBILITY, 0, FL_POWERUP, generic_pickupevalfunc, 100000);
	powerup_invisibility_init();
}

void spawnfunc_item_speed (void) {
	if(!cvar("g_powerup_speed")) {
		remove(self);
		return;
	}
	self.speed_finished = cvar("g_balance_powerup_speed_time");
	StartItem ("models/items/g_invincible.md3", "misc/powerup_shield.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Speed", IT_SPEED, 0, FL_POWERUP, generic_pickupevalfunc, 100000);
	powerup_speed_init();
}

void spawnfunc_item_key_gold (void) {
	self.origin_z = self.origin_z + 40;
	StartItem ("models/keyhunt/key.md3", "kh/collect.wav", cvar("g_pickup_respawntime_key"), cvar("g_pickup_respawntimejitter_key"), "Gold Key", IT_KEY2, 0, 0, generic_pickupevalfunc, 100000);
	self.colormod = '1 1 0';
	self.effects = EF_FULLBRIGHT | EF_STARDUST;
	self.mins_z = self.mins_z - 48;
}

void spawnfunc_item_key_silver (void) {
	self.origin_z = self.origin_z + 40;
	StartItem ("models/keyhunt/key.md3", "kh/collect.wav", cvar("g_pickup_respawntime_key"), cvar("g_pickup_respawntimejitter_key"), "Silver Key", IT_KEY1, 0, 0, generic_pickupevalfunc, 100000);
	self.effects = EF_FULLBRIGHT | EF_STARDUST;
	self.mins_z = self.mins_z - 48;
}

float target_item_func_set(float a, float b)
{
	if(b == 0)
		return a;
	else if(b < 0)
		return 0;
	else
		return b;
}

float target_item_func_min(float a, float b)
{
	if(b == 0)
		return a;
	else if(b < 0)
		return 0;
	else
		return min(a, b);
}

float target_item_func_max(float a, float b)
{
	return max(a, b);
}

float target_item_func_bitset(float a, float b)
{
	return b;
}

float target_item_func_and(float a, float b)
{
	return a & b;
}

float target_item_func_itembitset(float a, float b)
{
	return (a - (a & (IT_PICKUPMASK | IT_STRENGTH | IT_INVINCIBLE | IT_SPEED | IT_INVISIBILITY))) | b;
}

float target_item_func_itemand(float a, float b)
{
	return (a - (a & (IT_PICKUPMASK | IT_STRENGTH | IT_INVINCIBLE | IT_SPEED | IT_INVISIBILITY))) | (a & b);
}

float target_item_func_or(float a, float b)
{
	return a | b;
}

float target_item_func_andnot(float a, float b)
{
	return a - (a & b);
}

float target_item_changed;
void target_item_change(float binary, .float field, float(float a, float b) func, string sound_increase, string sound_decrease)
{
	float n, d;
	n = func(activator.field, self.field);

	if(binary)
	{
		d = n & activator.field;
		if(d != n) // bits added?
			d = +1;
		else if(d != activator.field) // bits removed?
			d = -1;
		else
			d = 0;
	}
	else
		d = n - activator.field;

	if(d < 0)
	{
		if(sound_decrease != "")
			sound (activator, CHAN_AUTO, sound_decrease, VOL_BASE, ATTN_NORM);
		target_item_changed = 1;
	}
	else if(d > 0)
	{
		if(sound_increase != "")
			sound (activator, CHAN_AUTO, sound_increase, VOL_BASE, ATTN_NORM);
		target_item_changed = 1;
	}
	activator.field = n;
}

void target_items_use (void)
{
	float h0, a0, f0;

	if(substring(activator.classname, 7, 0) == "dropped")
	{
		EXACTTRIGGER_TOUCH;
		remove(activator);
		return;
	}

	if(activator.classname != "player")
		return;
	if(activator.deadflag != DEAD_NO)
		return;
	EXACTTRIGGER_TOUCH;

	entity e;
	for(e = world; (e = findentity(e, enemy, activator)); )
		if(substring(e.classname, 0, 7) == "dropped")
			remove(e);

	float _switchweapon;
	_switchweapon = FALSE;
	if (activator.autoswitch)
		if (activator.switchweapon == w_getbestweapon(activator))
			_switchweapon = TRUE;

	a0 = activator.armorvalue;
	h0 = activator.health;
	f0 = activator.ammo_fuel;
	target_item_changed = 0;

	if(self.spawnflags == 0) // SET
	{
		target_item_change(0, ammo_shells, target_item_func_set, "misc/itempickup.wav", "");
		target_item_change(0, ammo_nails, target_item_func_set, "misc/itempickup.wav", "");
		target_item_change(0, ammo_rockets, target_item_func_set, "misc/itempickup.wav", "");
		target_item_change(0, ammo_cells, target_item_func_set, "misc/itempickup.wav", "");
		target_item_change(0, ammo_fuel, target_item_func_set, "misc/itempickup.wav", "");
		target_item_change(0, health, target_item_func_set, "misc/megahealth.wav", "");
		target_item_change(0, armorvalue, target_item_func_set, "misc/armor25.wav", "");
		target_item_change(1, items, target_item_func_itembitset, "misc/powerup.wav", "misc/poweroff.wav");
		target_item_change(1, weapons, target_item_func_bitset, "weapons/weaponpickup.wav", "");

		if((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = time + self.strength_finished;
		if((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = time + self.invincible_finished;
		if((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = time + self.speed_finished;
		if((self.items & activator.items) & IT_INVISIBILITY)
			activator.invisibility_finished = time + self.invisibility_finished;
	}
	else if(self.spawnflags == 1) // AND/MIN
	{
		target_item_change(0, ammo_shells, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_nails, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_rockets, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_cells, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_fuel, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, health, target_item_func_min, "misc/megahealth.wav", "");
		target_item_change(0, armorvalue, target_item_func_min, "misc/armor25.wav", "");
		target_item_change(1, items, target_item_func_itemand, "misc/powerup.wav", "misc/poweroff.wav");
		target_item_change(1, weapons, target_item_func_and, "weapons/weaponpickup.wav", "");

		if((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = min(activator.strength_finished, time + self.strength_finished);
		if((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = min(activator.invincible_finished, time + self.invincible_finished);
		if((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = min(activator.speed_finished, time + self.speed_finished);
		if((self.items & activator.items) & IT_INVISIBILITY)
			activator.invisibility_finished = min(activator.invisibility_finished, time + self.invisibility_finished);
	}
	else if(self.spawnflags == 2) // OR/MAX
	{
		target_item_change(0, ammo_shells, target_item_func_max, "misc/itempickup.wav", "");
		target_item_change(0, ammo_nails, target_item_func_max, "misc/itempickup.wav", "");
		target_item_change(0, ammo_rockets, target_item_func_max, "misc/itempickup.wav", "");
		target_item_change(0, ammo_cells, target_item_func_max, "misc/itempickup.wav", "");
		target_item_change(0, ammo_fuel, target_item_func_max, "misc/itempickup.wav", "");
		target_item_change(0, health, target_item_func_max, "misc/megahealth.wav", "");
		target_item_change(0, armorvalue, target_item_func_max, "misc/armor25.wav", "");
		target_item_change(1, items, target_item_func_or, "misc/powerup.wav", "misc/poweroff.wav");
		target_item_change(1, weapons, target_item_func_or, "weapons/weaponpickup.wav", "");

		if((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = max(activator.strength_finished, time + self.strength_finished);
		if((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = max(activator.invincible_finished, time + self.invincible_finished);
		if((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = max(activator.speed_finished, time + self.speed_finished);
		if((self.items & activator.items) & IT_INVISIBILITY)
			activator.invisibility_finished = max(activator.invisibility_finished, time + self.invisibility_finished);
	}
	else if(self.spawnflags == 4) // ANDNOT/MIN
	{
		target_item_change(0, ammo_shells, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_nails, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_rockets, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_cells, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, ammo_fuel, target_item_func_min, "misc/itempickup.wav", "");
		target_item_change(0, health, target_item_func_min, "misc/megahealth.wav", "");
		target_item_change(0, armorvalue, target_item_func_min, "misc/armor25.wav", "");
		target_item_change(1, items, target_item_func_andnot, "misc/powerup.wav", "misc/poweroff.wav");
		target_item_change(1, weapons, target_item_func_andnot, "weapons/weaponpickup.wav", "");

		if((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = min(activator.strength_finished, time + self.strength_finished);
		if((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = min(activator.invincible_finished, time + self.invincible_finished);
		if((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = min(activator.speed_finished, time + self.speed_finished);
		if((self.items & activator.items) & IT_INVISIBILITY)
			activator.invisibility_finished = min(activator.invisibility_finished, time + self.invisibility_finished);
	}

	if not(activator.items & IT_STRENGTH)
		activator.strength_finished = 0;
	if not(activator.items & IT_INVINCIBLE)
		activator.invincible_finished = 0;
	if not(activator.items & IT_SPEED)
		activator.speed_finished = 0;
	if not(activator.items & IT_INVISIBILITY)
		activator.invisibility_finished = 0;

	if(activator.health > h0)
		activator.pauserothealth_finished = max(activator.pauserothealth_finished, time + g_balance_pause_health_rot);
	else if(activator.health < h0)
		activator.pauseregen_finished = max(activator.pauseregen_finished, time + g_balance_pause_health_regen);

	if(activator.ammo_fuel > f0)
		activator.pauserotfuel_finished = max(activator.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	else if(activator.ammo_fuel < f0)
		activator.pauseregen_finished = max(activator.pauseregen_finished, time + g_balance_pause_fuel_regen);

	if(activator.armorvalue > a0)
		activator.pauserotarmor_finished = max(activator.pauserothealth_finished, time + g_balance_pause_health_rot);

	if not(activator.weapons & W_WeaponBit(activator.switchweapon))
		_switchweapon = TRUE;
	if(_switchweapon)
		W_SwitchWeapon_Force(activator, w_getbestweapon(activator));

	if(target_item_changed)
		centerprint(activator, self.message);
}

void spawnfunc_target_items (void)
{
	float n, i, j;
	entity e;

	self.use = target_items_use;
	if(!self.strength_finished)
		self.strength_finished = cvar("g_balance_powerup_strength_time");
	if(!self.invincible_finished)
		self.invincible_finished = cvar("g_balance_powerup_invincible_time");
	if(!self.invisibility_finished)
		self.invisibility_finished = cvar("g_balance_powerup_invisibility_time");
	if(!self.speed_finished)
		self.speed_finished = cvar("g_balance_powerup_speed_time");

	precache_sound("misc/itempickup.wav");
	precache_sound("misc/itempickup.wav");
	precache_sound("misc/itempickup.wav");
	precache_sound("misc/itempickup.wav");
	precache_sound("misc/megahealth.wav");
	precache_sound("misc/armor25.wav");
	precache_sound("misc/powerup.wav");
	precache_sound("misc/poweroff.wav");
	precache_sound("weapons/weaponpickup.wav");

	n = tokenize_console(self.netname);
	for(i = 0; i < n; ++i)
	{
		if     (argv(i) == "unlimited_ammo")         self.items |= IT_UNLIMITED_AMMO;
		else if(argv(i) == "unlimited_weapon_ammo")  self.items |= IT_UNLIMITED_WEAPON_AMMO;
		else if(argv(i) == "unlimited_superweapons") self.items |= IT_UNLIMITED_SUPERWEAPONS;
		else if(argv(i) == "strength")               { self.items |= IT_STRENGTH; powerup_strength_init(); }
		else if(argv(i) == "invincible")             { self.items |= IT_INVINCIBLE; powerup_invisibility_init(); }
		else if(argv(i) == "speed")                  { self.items |= IT_SPEED; powerup_speed_init(); }
		else if(argv(i) == "invisibility")           { self.items |= IT_INVISIBILITY; powerup_invisibility_init(); }
		else if(argv(i) == "jetpack")                self.items |= IT_JETPACK;
		else
		{
			for(j = WEP_FIRST; j <= WEP_LAST; ++j)
			{
				e = get_weaponinfo(j);
				if(argv(i) == e.netname)
				{
					self.weapons |= e.weapons;
					if(self.spawnflags == 0 || self.spawnflags == 2)
						weapon_precache(e.weapon);
					break;
				}
			}
			if(j > WEP_LAST)
				print("target_items: invalid item ", argv(i), "\n");
		}
	}
}

void spawnfunc_item_jetpack(void)
{
	if(g_grappling_hook || start_items & IT_JETPACK) {
		remove(self);
		return;
	}
	if(!self.ammo_fuel)
		self.ammo_fuel = cvar("g_pickup_fuel_jetpack");

	StartItem ("models/items/g_jetpack.md3", "misc/itempickup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup, "Jet pack", IT_JETPACK, 0, FL_POWERUP, commodity_pickupevalfunc, BOT_PICKUP_RATING_LOW);
}

//Q1 compat
void spawnfunc_item_health (void) {if (self.spawnflags & 2) spawnfunc_item_health_mega();else spawnfunc_item_health_medium();}

//1st april joke
void() mushroom_touch {
	Item_Touch();
	if (item_touch_picked)
	if (clienttype(other) == CLIENTTYPE_REAL) {
		msg_entity = other;
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_TRIP);
		WriteByte(MSG_ONE, 15);
		if (sv_sound_mushroom != "")
			announce(other, sv_sound_mushroom);
	}
}

void() spawnfunc_item_mushroom {
	self.max_health = cvar("g_pickup_healthmushroom_max");
	self.health = cvar("g_pickup_healthmushroom");
	StartItem (sv_model_mushroom, "misc/megahealth.wav", g_pickup_respawntime_mushroom, g_pickup_respawntimejitter_mushroom, "Mushroom", IT_HEALTH, 0, 0, commodity_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
	self.touch = mushroom_touch;
}

void Items_Init()
{
	CACHE_CVAR(g_balance_pause_armor_rot);
	CACHE_CVAR(g_balance_pause_fuel_regen);
	CACHE_CVAR(g_balance_pause_fuel_rot);
	CACHE_CVAR(g_balance_pause_health_regen);
	CACHE_CVAR(g_balance_pause_health_rot);
	CACHE_CVAR(g_fullbrightitems);
	CACHE_CVAR(g_pickup_respawntime_weapon);
	CACHE_CVAR(g_pickup_respawntime_ammo);
	CACHE_CVAR(g_pickup_respawntime_healthsmall);
	CACHE_CVAR(g_pickup_respawntime_healthmedium);
	CACHE_CVAR(g_pickup_respawntime_healthlarge);
	CACHE_CVAR(g_pickup_respawntime_healthmega);
	CACHE_CVAR(g_pickup_respawntime_armorsmall);
	CACHE_CVAR(g_pickup_respawntime_armormedium);
	CACHE_CVAR(g_pickup_respawntime_armorbig);
	CACHE_CVAR(g_pickup_respawntime_armorlarge);
	CACHE_CVAR(g_pickup_respawntime_powerup);
	CACHE_CVAR(g_pickup_respawntimejitter_weapon);
	CACHE_CVAR(g_pickup_respawntimejitter_ammo);
	CACHE_CVAR(g_pickup_respawntimejitter_healthsmall);
	CACHE_CVAR(g_pickup_respawntimejitter_healthmedium);
	CACHE_CVAR(g_pickup_respawntimejitter_healthlarge);
	CACHE_CVAR(g_pickup_respawntimejitter_healthmega);
	CACHE_CVAR(g_pickup_respawntimejitter_armorsmall);
	CACHE_CVAR(g_pickup_respawntimejitter_armormedium);
	CACHE_CVAR(g_pickup_respawntimejitter_armorbig);
	CACHE_CVAR(g_pickup_respawntimejitter_armorlarge);
	CACHE_CVAR(g_pickup_respawntimejitter_powerup);
	CACHE_CVAR(g_pickup_respawntime_mushroom);
	CACHE_CVAR(g_pickup_respawntimejitter_mushroom);
	CACHE_CVAR(g_pickup_shells_max);
	CACHE_CVAR(g_pickup_nails_max);
	CACHE_CVAR(g_pickup_rockets_max);
	CACHE_CVAR(g_pickup_cells_max);
	CACHE_CVAR(g_pickup_fuel_max);
	CACHE_CVAR(g_use_ammunition);
	CACHE_CVAR(g_pickup_items);
	CACHE_CVAR(g_pickup_weapons);
	CACHE_CVAR(g_balance_powerup_invincible_takedamage);
	CACHE_CVAR(g_balance_powerup_strength_damage);
	CACHE_CVAR(g_balance_powerup_strength_force);
	CACHE_CVAR(g_balance_powerup_strength_selfdamage);
	CACHE_CVAR(g_balance_powerup_strength_selfforce);
	sv_model_healthsmall = cvar_string_zone_ifneeded("sv_model_healthsmall");
	if (sv_model_healthsmall == "")
		sv_model_healthsmall = "models/items/g_h1.md3";

	sv_model_healthmedium = cvar_string_zone_ifneeded("sv_model_healthmedium");
	if (sv_model_healthmedium == "")
		sv_model_healthmedium = "models/items/g_h25.md3";

	sv_model_healthlarge = cvar_string_zone_ifneeded("sv_model_healthlarge");
	if (sv_model_healthlarge == "")
		sv_model_healthlarge = "models/items/g_h50.md3";

	sv_model_healthmega = cvar_string_zone_ifneeded("sv_model_healthmega");
	if (sv_model_healthmega == "")
		sv_model_healthmega = "models/items/g_h100.md3";

	sv_model_mushroom = cvar_string_zone_ifneeded("sv_model_mushroom");
	if (sv_model_mushroom == "")
		sv_model_mushroom = "models/items/g_h100.md3";

	sv_sound_mushroom = cvar_string_zone_ifneeded("sv_sound_mushroom");
	if (sv_sound_mushroom != "")
		precache_sound(sv_sound_mushroom);

	sv_model_armorsmall = cvar_string_zone_ifneeded("sv_model_armorsmall");
	if (sv_model_armorsmall == "")
		sv_model_armorsmall = "models/items/g_a1.md3";

	sv_model_armormedium = cvar_string_zone_ifneeded("sv_model_armormedium");
	if (sv_model_armormedium == "")
		sv_model_armormedium = "models/items/g_armormedium.md3";

	sv_model_armorbig = cvar_string_zone_ifneeded("sv_model_armorbig");
	if (sv_model_armorbig == "")
		sv_model_armorbig = "models/items/g_a50.md3";

	sv_model_armorlarge = cvar_string_zone_ifneeded("sv_model_armorlarge");
	if (sv_model_armorlarge == "")
		sv_model_armorlarge = "models/items/g_a25.md3";

	CACHE_CVAR(g_weapon_stay);
	CACHE_CVAR(g_ghost_items);
	if(g_ghost_items >= 1)
		g_ghost_items = 0.13; // default alpha value

	entity e;
	float i, t;

	// initialize starting values for players
	start_weapons = 0;
	start_items = 0;
	start_ammo_shells = 0;
	start_ammo_nails = 0;
	start_ammo_rockets = 0;
	start_ammo_cells = 0;
	start_health = cvar("g_balance_health_start");
	start_armorvalue = cvar("g_balance_armor_start");

	if not(GameHookChain_StartAmmoHandle(g_use_ammunition))
	{
		if (g_use_ammunition)
		{
			start_ammo_shells = cvar("g_start_ammo_shells");
			start_ammo_nails = cvar("g_start_ammo_nails");
			start_ammo_rockets = cvar("g_start_ammo_rockets");
			start_ammo_cells = cvar("g_start_ammo_cells");
		}
		else
		{
			start_ammo_shells = 0;
			start_ammo_nails = 0;
			start_ammo_rockets = 0;
			start_ammo_cells = 0;
			start_ammo_fuel = 0;
			start_items |= IT_UNLIMITED_AMMO;
		}

		for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		{
			e = get_weaponinfo(i);
			if (!(e.weapon))
				continue;

			t = cvar(strcat("g_start_weapon_", e.netname));

			if (t < 0) // "default" weapon selection
			{
				t = (i == WEP_LASER || i == WEP_SHOTGUN);
			}

			if (t)
			{
				start_weapons |= e.weapons;
				weapon_precache(e.weapon);
			}
		}
	}

	if (inWarmupStage)
	{
		warmup_start_ammo_shells = start_ammo_shells;
		warmup_start_ammo_nails = start_ammo_nails;
		warmup_start_ammo_rockets = start_ammo_rockets;
		warmup_start_ammo_cells = start_ammo_cells;
		warmup_start_ammo_fuel = start_ammo_fuel;
		warmup_start_health = start_health;
		warmup_start_armorvalue = start_armorvalue;
		warmup_start_weapons = start_weapons;

		if not(GameHookChain_WarmupStartAmmoHandle(g_use_ammunition))
		{
			if (g_use_ammunition)
			{
				warmup_start_ammo_shells = cvar("g_warmup_start_ammo_shells");
				warmup_start_ammo_cells = cvar("g_warmup_start_ammo_cells");
				warmup_start_ammo_nails = cvar("g_warmup_start_ammo_nails");
				warmup_start_ammo_rockets = cvar("g_warmup_start_ammo_rockets");
			}
			warmup_start_health = cvar("g_warmup_start_health");
			warmup_start_armorvalue = cvar("g_warmup_start_armor");
			if (cvar("g_warmup_allguns"))
			{
				for (i = WEP_FIRST; i < WEP_FIREBALL; ++i)
				{
					e = get_weaponinfo(i);
					if (!(e.weapon))
						continue;
					if (e.spawnflags & WEPSPAWNFLAG_NORMAL)
					{
						warmup_start_weapons |= e.weapons;
						weapon_precache(e.weapon);
					}
				}
			}
		}
	}

	if (g_jetpack) {
		start_items |= IT_JETPACK;
		if (g_use_ammunition) {
			g_grappling_hook = 0; // these two can't coexist, as they use the same button
			start_items |= IT_FUEL_REGEN;
			start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
			warmup_start_ammo_fuel = max(warmup_start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
		}
	}
	start_ammo_shells = max(0, start_ammo_shells);
	start_ammo_nails = max(0, start_ammo_nails);
	start_ammo_cells = max(0, start_ammo_cells);
	start_ammo_rockets = max(0, start_ammo_rockets);
	start_ammo_fuel = max(0, start_ammo_fuel);

	warmup_start_ammo_shells = max(0, warmup_start_ammo_shells);
	warmup_start_ammo_nails = max(0, warmup_start_ammo_nails);
	warmup_start_ammo_cells = max(0, warmup_start_ammo_cells);
	warmup_start_ammo_rockets = max(0, warmup_start_ammo_rockets);
	warmup_start_ammo_fuel = max(0, warmup_start_ammo_fuel);
}
