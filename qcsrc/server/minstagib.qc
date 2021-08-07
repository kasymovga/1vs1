float g_minstagib;
float g_minstagib_ammo_drop;
float g_minstagib_armor_max;
float g_minstagib_health_drop;
float g_minstagib_health_max;
float g_minstagib_invis_alpha;
float g_minstagib_speed_moverate;
float g_minstagib_nolaserdamage;
float g_minstagib_extralives;
float minstagib_ammo;
/* replace items in minstagib
 * IT_STRENGTH	 = invisibility
 * IT_NAILS	 = extra lives
 * IT_INVINCIBLE = speed
 */
void minstagib_items (float itemid)
{
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
				"Health", IT_CELLS, 0, 0, item_generic_pickupevalfunc, 100);
		} else {
			item_start(sv_model_ammocells, "models/items/a_cells.md3",
				"misc/itempickup.wav", 45, 0,
				"Nex Ammo", IT_CELLS, 0, 0, item_generic_pickupevalfunc, 100);
		}
		return;
	}

	// replace with extra lives
	if (itemid == IT_NAILS)
	if (g_minstagib_extralives) {
		self.max_health = 1;
		item_start(sv_model_armorlarge, "models/items/g_a25.md3",
			"misc/megahealth.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
			"Extralife", IT_NAILS, 0, FL_POWERUP, item_generic_pickupevalfunc, BOT_PICKUP_RATING_HIGH);

	}
}

float minst_no_auto_cells;
void minst_remove_item (void) {
	if(minst_no_auto_cells)
		remove(self);
}

.float minstagib_nextthink;
var void() minstagib_PlayerPreThink_NextLink;
void minstagib_PlayerPreThink() {
	minstagib_PlayerPreThink_NextLink();
	if (time < self.minstagib_nextthink || self.deadflag || map_finished)
		return;

	if not(self.items & IT_UNLIMITED_AMMO)
	if (self.ammo_cells <= 0)
	{
		if (self.health <= 5)
		{
			centerprint(self, "you're dead now...\n");
			damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/terminated.wav", "^1Terminated");
		}
		else if (self.health <= 10)
		{
			centerprint(self, "^11^7 second left to find some ammo\n");
			damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/1.wav", "^11");
		}
		else if (self.health <= 20)
		{
			centerprint(self, "^12^7 seconds left to find some ammo\n");
			damage(self, self, self, self.health - 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/2.wav", "^12");
		}
		else if (self.health <= 30)
		{
			centerprint(self, "^13^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/3.wav", "^13");
		}
		else if (self.health <= 40)
		{
			centerprint(self, "^14^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/4.wav", "4");
		}
		else if (self.health <= 50)
		{
			centerprint(self, "^15^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/5.wav", "5");
		}
		else if (self.health <= 60)
		{
			centerprint(self, "^36^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/6.wav", "");
		}
		else if (self.health <= 70)
		{
			centerprint(self, "^37^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/7.wav", "");
		}
		else if (self.health <= 80)
		{
			centerprint(self, "^38^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/8.wav", "");
		}
		else if (self.health <= 90)
		{
			centerprint(self, "^39^7 seconds left to find some ammo\n");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/9.wav", "");
		}
		else if (self.health <= 100)
		{
			centerprint(self, "get some ammo or\nyou'll be dead in ^310^7 seconds...");
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/10.wav", "");
		}
		else {
			damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
		}
	}
	self.minstagib_nextthink = time + 1;
}

var float(entity item, entity player) minstagib_ItemGiveToHandle_NextLink; //Not used actually
float minstagib_ItemGiveToHandle(entity item, entity player) {
	float it;
	if not(item.spawnshieldtime)
		return TRUE;

	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max)
	{
		gamehook_chain_ItemGiveToHandle_PickedUp = TRUE;
		player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
		player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	}
	if((it = (item.items - (item.items & player.items)) & IT_PICKUPMASK))
	{
		gamehook_chain_ItemGiveToHandle_PickedUp = TRUE;
		player.items |= it;
		sprint (player, strcat("You got the ^2", item.netname, "\n"));
	}

	gamehook_chain_ItemGiveToHandle_SwitchWeapon = TRUE;
	if (item.health)
	{
		player.health = min(max(100, player.health + g_minstagib_health_drop), g_minstagib_health_max);
		gamehook_chain_ItemGiveToHandle_PickedUp = TRUE;
	}
	if (item.ammo_cells)
	{
		gamehook_chain_ItemGiveToHandle_PickedUp = TRUE;
		// play some cool sounds ;)
		if (clienttype(player) == CLIENTTYPE_REAL)
		{
			if(player.health <= 5)
				sound_play2(player, "announcer/robotic/lastsecond.wav");
			else if(player.health < 50)
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
	if (item.max_health)
	{
		gamehook_chain_ItemGiveToHandle_PickedUp = TRUE;
		// sound not available
		// play2(player, "announce/robotic/extra.ogg\nplay2 announce/robotic/_lives.wav");
		player.armorvalue = min(player.armorvalue + 100, g_minstagib_armor_max);
		sprint(player, "^3You picked up some extra lives\n");
	}
	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max)
	{
		gamehook_chain_ItemGiveToHandle_PickedUp = TRUE;
		player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
		player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	}
	return gamehook_chain_ItemGiveToHandle_PickedUp;
}

var void() minstagib_player_health_armor_fuel_mods_set_NextLink;
void minstagib_player_health_armor_fuel_mods_set() {
	minstagib_player_health_armor_fuel_mods_set_NextLink();
	gamehook_player_health_armor_rot_regen = FALSE;
}

float minstagib_WeaponSpawnHandle(float wpn) {
	if (wpn == WEP_MINSTANEX ||wpn == WEP_NEX || wpn == WEP_ROCKET_LAUNCHER) {
		minstagib_items(IT_CELLS);
		self.think = minst_remove_item;
		self.nextthink = time;
	} else
		remove(self);

	return TRUE;
}

var float(float doreduce) minstagib_ThrowWeaponAllowed_NextLink;
float minstagib_ThrowWeaponAllowed(float doreduce) {
	if (self.ammo_cells <= 0 || doreduce)
		return FALSE;

	return minstagib_ThrowWeaponAllowed_NextLink(doreduce);
}

void spawnfunc_minstagib_extra_lives() { minstagib_items(IT_NAILS); }

var void() minstagib_entity_spawn_pre_NextLink;
void minstagib_entity_spawn_pre() {
	if (self.classname == "item_health_mega")
		self.classname = "minstagib_extra_lives";
	else if (self.classname == "item_strength")
		self.classname = "item_invisibility";
	else if (self.classname == "item_invincible")
		self.classname = "item_speed";

	minstagib_entity_spawn_pre_NextLink();
}

var float() minstagib_ItemForbidden_NextLink;
float minstagib_ItemForbidden() {
	if (self.classname != "minstagib")
	if (self.classname != "item_speed")
	if (self.classname != "item_invisibility")
		return TRUE;

	return minstagib_ItemForbidden_NextLink();
}

var float(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) minstagib_player_damage_handle_NextLink;
float minstagib_player_damage_handle(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
	if ((deathtype == DEATH_FALL)  ||
		(deathtype == DEATH_DROWN) ||
		(deathtype == DEATH_SLIME) ||
		(deathtype == DEATH_LAVA))
		return TRUE;

	if (self.armorvalue >= 1  && (deathtype != DEATH_HURTTRIGGER) && _damage)
	{
		self.armorvalue -= min(_damage, min(self.armorvalue, 100));
		gamehook_chain_player_damage_mod = 0;
		self.hitsound += 1;
		attacker.hitsound += 1; // TODO change this to a future specific hitsound for armor hit
	}
	return minstagib_player_damage_handle_NextLink(inflictor, attacker, _damage, deathtype, hitloc, force);
}

var void(entity targ, entity attacker, float deathtype) minstagib_DamageForceModsSet_NextLink;
void minstagib_DamageForceModsSet(entity targ, entity attacker, float deathtype) {
	if (targ.classname == "player") {
		if (attacker.classname == "player")
		if (DEATH_ISWEAPON(deathtype, WEP_LASER))
		if (g_minstagib_nolaserdamage || !player_can_fire(attacker, FALSE))
		{
			gamehook_chain_damage_mod = 0;
			if (targ != attacker)
			{
				if (g_minstagib_nolaserdamage)
					centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "Secondary fire inflicts no damage!"));

				gamehook_chain_damage_mod_force = 0;
				gamehook_chain_damage_mod_mirror = 0;
			}
		}
		if (team_mode)
		if (attacker != targ)
		if (deathtype != DEATH_MIRRORDAMAGE)
		if (deathtype != DEATH_NOAMMO)
		if (targ.deadflag == DEAD_NO)
		if (attacker.team == targ.team) {
			if (g_friendlyfire == 0)
				gamehook_chain_damage_mod = 0;
			else
				gamehook_chain_damage_mod = gamehook_chain_damage_mod / g_friendlyfire; //Restore value
		}
	}
	minstagib_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}


float minstagib_MirrorDamageHandle(entity attacker, entity inflictor, float mirrordamage, vector force) {
	if(mirrordamage > 0)
	if(attacker.armorvalue > 0) {// just lose extra LIVES, don't kill the player for mirror damage
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
	self.weapons = WEPBIT_MINSTANEX;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	if not(player_start_items & IT_UNLIMITED_AMMO) {
		self.ammo_cells = cvar("g_minstagib_ammo_start");
	} else
		self.ammo_cells = 0;

	return TRUE;
}

var void() minstagib_ItemRespawnCountDown_NextLink;
void minstagib_ItemRespawnCountDown() {
	if (self.items == IT_NAILS) {
		gamehook_ItemName = "item-extralife";
		gamehook_ItemColor = '1 0 0';
	}
	minstagib_ItemRespawnCountDown_NextLink();
}

float minstagib_ArmorBlockPercentMod() { return 0; }

void minstagib_init() {
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

	weapon_precache(WEP_MINSTANEX);
	g_minstagib_invis_alpha = cvar("g_minstagib_invis_alpha");
	if (g_minstagib_invis_alpha <= 0)
		g_minstagib_invis_alpha = -1;

	precache_sound ("announcer/robotic/lastsecond.wav");
	precache_sound ("announcer/robotic/narrowly.wav");
	minstagib_PlayerPreThink_NextLink = gamehook_chain_player_think;
	gamehook_chain_player_think = minstagib_PlayerPreThink;
	minstagib_ItemGiveToHandle_NextLink = gamehook_chain_ItemGiveToHandle;
	gamehook_chain_ItemGiveToHandle = minstagib_ItemGiveToHandle;
	minstagib_player_health_armor_fuel_mods_set_NextLink = gamehook_chain_player_health_armor_fuel_mods_set;
	gamehook_chain_player_health_armor_fuel_mods_set = minstagib_player_health_armor_fuel_mods_set;
	gamehook_chain_WeaponSpawnHandle = minstagib_WeaponSpawnHandle;
	minstagib_ThrowWeaponAllowed_NextLink = gamehook_chain_ThrowWeaponAllowed;
	gamehook_chain_ThrowWeaponAllowed = minstagib_ThrowWeaponAllowed;
	minstagib_entity_spawn_pre_NextLink = gamehook_chain_entity_spawn_pre;
	gamehook_chain_entity_spawn_pre = minstagib_entity_spawn_pre;
	minstagib_ItemForbidden_NextLink = gamehook_chain_ItemForbidden;
	gamehook_chain_ItemForbidden = minstagib_ItemForbidden;
	minstagib_player_damage_handle_NextLink = gamehook_chain_player_damage_handle;
	gamehook_chain_player_damage_handle = minstagib_player_damage_handle;
	minstagib_DamageForceModsSet_NextLink = gamehook_chain_damage_mods_set;
	gamehook_chain_damage_mods_set = minstagib_DamageForceModsSet;
	gamehook_chain_MirrorDamageHandle = minstagib_MirrorDamageHandle;
	minstagib_player_equip_handle_next = gamehook_chain_player_equip_handle;
	gamehook_chain_player_equip_handle = minstagib_player_equip_handle;
	minstagib_ItemRespawnCountDown_NextLink = gamehook_chain_ItemRespawnCountDown;
	gamehook_chain_ItemRespawnCountDown = minstagib_ItemRespawnCountDown;
	gamehook_chain_ArmorBlockPercentMod = minstagib_ArmorBlockPercentMod;
}

void spawnfunc_item_minst_cells (void) {
	if (g_minstagib)
	{
		minst_no_auto_cells = 1;
		minstagib_items(IT_CELLS);
	}
	else
		remove(self);
}
