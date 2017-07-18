float g_minstagib_speed_jumpheight;
float g_minstagib_speed_moverate;
/* replace items in minstagib
 * IT_STRENGTH	 = invisibility
 * IT_NAILS	 = extra lives
 * IT_INVINCIBLE = speed
 */
void minstagib_items (float itemid)
{
	// we don't want to replace dropped weapons ;)
	if (self.classname == "droppedweapon")
	{
		self.ammo_cells = 25;
		StartItem ("models/weapons/g_nex.md3",
			"weapons/weaponpickup.wav", 15, 0,
			"MinstaNex", 0, WEPBIT_MINSTANEX, FL_WEAPON, generic_pickupevalfunc, 1000);
		return;
	}

	local float rnd;
	self.classname = "minstagib";

	// replace rocket launchers and nex guns with ammo cells
	if (itemid == IT_CELLS)
	{
		self.ammo_cells = 1;
		StartItem ("models/items/a_cells.md3",
			"misc/itempickup.wav", 45, 0,
			"Nex Ammo", IT_CELLS, 0, 0, generic_pickupevalfunc, 100);
		return;
	}

	// randomize
	rnd = random() * 3;
	if (rnd <= 1)
		itemid = IT_STRENGTH;
	else if (rnd <= 2)
		itemid = IT_NAILS;
	else
		itemid = IT_INVINCIBLE;

	// replace with invis
	if (itemid == IT_STRENGTH)
	{
		self.strength_finished = cvar("g_balance_powerup_strength_time");
		StartItem ("models/items/g_strength.md3",
			"misc/powerup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
			"Invisibility", IT_STRENGTH, 0, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_MID);
	}
	// replace with extra lives
	if (itemid == IT_NAILS)
	{
		self.max_health = 1;
		StartItem (sv_model_healthmega,
			"misc/megahealth.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
			"Extralife", IT_NAILS, 0, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_HIGH);

	}
	// replace with speed
	if (itemid == IT_INVINCIBLE)
	{
		self.invincible_finished = cvar("g_balance_powerup_invincible_time");
		StartItem ("models/items/g_invincible.md3",
			"misc/powerup_shield.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
			"Speed", IT_INVINCIBLE, 0, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_MID);
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
	if (time < self.minstagib_nextthink || self.deadflag || gameover)
		return;

	if (self.ammo_cells <= 0)
	{
		if (self.health == 5)
		{
			centerprint(self, "you're dead now...\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/terminated.wav");
		}
		else if (self.health == 10)
		{
			centerprint(self, "^11^7 second left to find some ammo\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/1.wav");
		}
		else if (self.health == 20)
		{
			centerprint(self, "^12^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/2.wav");
		}
		else if (self.health == 30)
		{
			centerprint(self, "^13^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/3.wav");
		}
		else if (self.health == 40)
		{
			centerprint(self, "^14^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/4.wav");
		}
		else if (self.health == 50)
		{
			centerprint(self, "^15^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/5.wav");
		}
		else if (self.health == 60)
		{
			centerprint(self, "^36^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/6.wav");
		}
		else if (self.health == 70)
		{
			centerprint(self, "^37^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/7.wav");
		}
		else if (self.health == 80)
		{
			centerprint(self, "^38^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/8.wav");
		}
		else if (self.health == 90)
		{
			centerprint(self, "^39^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/9.wav");
		}
		else if (self.health == 100)
		{
			centerprint(self, "get some ammo or\nyou'll be dead in ^310^7 seconds...");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/10.wav");
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
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
		player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	}
	if((it = (item.items - (item.items & player.items)) & IT_PICKUPMASK))
	{
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		player.items |= it;
		sprint (player, strcat("You got the ^2", item.netname, "\n"));
	}

	GameHookChain_ItemGiveToHandle_SwitchWeapon = TRUE;
	if (item.ammo_cells)
	{
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		// play some cool sounds ;)
		centerprint(player, "\n");
		if (clienttype(player) == CLIENTTYPE_REAL)
		{
			if(player.health <= 5)
				play2(player, "announcer/robotic/lastsecond.wav");
			else if(player.health < 50)
				play2(player, "announcer/robotic/narrowly.wav");
		}
		// sound not available
		// else if(item.items == IT_CELLS)
		//	play2(player, "announce/robotic/ammo.wav");

		if (item.weapons & WEPBIT_MINSTANEX)
			W_GiveWeapon (player, WEP_MINSTANEX, "Nex");
		if (item.ammo_cells)
			player.ammo_cells = min (player.ammo_cells + g_minstagib_ammo_drop, 999);
		player.health = 100;
	}

	// extralife powerup
	if (item.max_health)
	{
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		// sound not available
		// play2(player, "announce/robotic/extra.ogg\nplay2 announce/robotic/_lives.wav");
		player.armorvalue = player.armorvalue + g_minstagib_extralives;
		sprint(player, "^3You picked up some extra lives\n");
	}

	// invis powerup
	if (item.strength_finished)
	{
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		// sound not available
		// play2(player, "announce/robotic/invisible.wav");
		player.strength_finished = max(player.strength_finished, time) + item.strength_finished;
	}

	// speed powerup
	if (item.invincible_finished)
	{
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		// sound not available
		// play2(player, "announce/robotic/speed.wav");
		player.invincible_finished = max(player.invincible_finished, time) + item.invincible_finished;
	}

	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max)
	{
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
		player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	}
	return TRUE;
}

var void() minstagib_HealthArmorFuelModsSet_NextLink;
void minstagib_HealthArmorFuelModsSet() {
	minstagib_HealthArmorFuelModsSet_NextLink();
	GameHook_HealthArmorRotRegen = FALSE;
}

var float(float wpn) minstagib_WeaponSpawnHandle_NextLink;
float minstagib_WeaponSpawnHandle(float wpn) {
	if (wpn == WEP_MINSTANEX ||wpn == WEP_NEX || wpn == WEP_ROCKET_LAUNCHER) {
		minstagib_items(IT_CELLS);
		self.think = minst_remove_item;
		self.nextthink = time;
	} else
		remove(self);

	return TRUE;
}

var float() minstagib_JumpVelocityMod_NextLink;
float minstagib_JumpVelocityMod() {
	return ((self.items & IT_INVINCIBLE) ? g_minstagib_speed_jumpheight : 1) * minstagib_JumpVelocityMod_NextLink();
}

var float() minstagib_SpeedMod_NextLink;
float minstagib_SpeedMod() {
	return ((self.items & IT_INVINCIBLE) ? g_minstagib_speed_moverate : 1) * minstagib_SpeedMod_NextLink();
}

var float(float doreduce) minstagib_ThrowWeaponAllowed_NextLink;
float minstagib_ThrowWeaponAllowed(float doreduce) {
	if (self.ammo_cells <= 0 || doreduce)
		return FALSE;

	return minstagib_ThrowWeaponAllowed_NextLink(doreduce);
}

void minstagib_init() {
	CACHE_CVAR(g_minstagib);
	if not(g_minstagib)
		return;

	CACHE_CVAR(g_minstagib_speed_jumpheight);
	CACHE_CVAR(g_minstagib_speed_moverate);
	precache_sound ("announcer/robotic/lastsecond.wav");
	precache_sound ("announcer/robotic/narrowly.wav");
	minstagib_PlayerPreThink_NextLink = GameHookChain_PlayerPreThink;
	GameHookChain_PlayerPreThink = minstagib_PlayerPreThink;
	minstagib_ItemGiveToHandle_NextLink = GameHookChain_ItemGiveToHandle;
	GameHookChain_ItemGiveToHandle = minstagib_ItemGiveToHandle;
	minstagib_HealthArmorFuelModsSet_NextLink = GameHookChain_HealthArmorFuelModsSet;
	GameHookChain_HealthArmorFuelModsSet = minstagib_HealthArmorFuelModsSet;
	minstagib_WeaponSpawnHandle_NextLink = GameHookChain_WeaponSpawnHandle;
	GameHookChain_WeaponSpawnHandle = minstagib_WeaponSpawnHandle;
	minstagib_JumpVelocityMod_NextLink = GameHookChain_JumpVelocityMod;
	GameHookChain_JumpVelocityMod = minstagib_JumpVelocityMod;
	minstagib_SpeedMod_NextLink = GameHookChain_SpeedMod;
	GameHookChain_SpeedMod = minstagib_SpeedMod;
	minstagib_ThrowWeaponAllowed_NextLink = GameHookChain_ThrowWeaponAllowed;
	GameHookChain_ThrowWeaponAllowed = minstagib_ThrowWeaponAllowed;
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
