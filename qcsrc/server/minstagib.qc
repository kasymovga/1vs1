float g_minstagib;
float g_minstagib_ammo_drop;
float g_minstagib_extralives;
float g_minstagib_invis_alpha;
float g_minstagib_speed_jumpheight;
float g_minstagib_speed_moverate;
float g_minstagib_nolaserdamage;
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
	if (itemid == IT_CELLS)
	{
		if not(minstagib_ammo) {
			remove(self);
			return;
		}
		self.ammo_cells = 1;
		StartItem ("models/items/a_cells.md3",
			"misc/itempickup.wav", 45, 0,
			"Nex Ammo", IT_CELLS, 0, 0, generic_pickupevalfunc, 100);
		return;
	}

	// replace with extra lives
	if (itemid == IT_NAILS)
	{
		self.max_health = 1;
		StartItem (sv_model_healthmega,
			"misc/megahealth.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
			"Extralife", IT_NAILS, 0, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_HIGH);

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

	if not(self.items & IT_UNLIMITED_AMMO)
	if (self.ammo_cells <= 0)
	{
		if (self.health <= 5)
		{
			centerprint(self, "you're dead now...\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/terminated.wav");
		}
		else if (self.health <= 10)
		{
			centerprint(self, "^11^7 second left to find some ammo\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/1.wav");
		}
		else if (self.health <= 20)
		{
			centerprint(self, "^12^7 seconds left to find some ammo\n");
			Damage(self, self, self, self.health - 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/2.wav");
		}
		else if (self.health <= 30)
		{
			centerprint(self, "^13^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/3.wav");
		}
		else if (self.health <= 40)
		{
			centerprint(self, "^14^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/4.wav");
		}
		else if (self.health <= 50)
		{
			centerprint(self, "^15^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/5.wav");
		}
		else if (self.health <= 60)
		{
			centerprint(self, "^36^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/6.wav");
		}
		else if (self.health <= 70)
		{
			centerprint(self, "^37^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/7.wav");
		}
		else if (self.health <= 80)
		{
			centerprint(self, "^38^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/8.wav");
		}
		else if (self.health <= 90)
		{
			centerprint(self, "^39^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/9.wav");
		}
		else if (self.health <= 100)
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

		if not(player.items & IT_UNLIMITED_AMMO)
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
	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max)
	{
		GameHookChain_ItemGiveToHandle_PickedUp = TRUE;
		player.ammo_fuel = min(player.ammo_fuel + item.ammo_fuel, g_pickup_fuel_max);
		player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + g_balance_pause_fuel_rot);
	}
	return GameHookChain_ItemGiveToHandle_PickedUp;
}

var void() minstagib_HealthArmorFuelModsSet_NextLink;
void minstagib_HealthArmorFuelModsSet() {
	minstagib_HealthArmorFuelModsSet_NextLink();
	GameHook_HealthArmorRotRegen = FALSE;
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

var void() minstagib_EntityPreSpawn_NextLink;
void minstagib_EntityPreSpawn() {
	if (self.classname == "item_health_mega")
		self.classname = "minstagib_extra_lives";
	else if (self.classname == "item_strength")
		self.classname = "item_invisibility";
	else if (self.classname == "item_invincible")
		self.classname = "item_speed";

	minstagib_EntityPreSpawn_NextLink();
}

var float() minstagib_ItemForbidden_NextLink;
float minstagib_ItemForbidden() {
	if (self.classname != "minstagib")
	if (self.classname != "item_speed")
	if (self.classname != "item_invisibility")
		return TRUE;

	return minstagib_ItemForbidden_NextLink();
}

var string(string s) minstagib_WelcomeMessageMod_NextLink;
string minstagib_WelcomeMessageMod(string s) {
	return strcat(minstagib_WelcomeMessageMod_NextLink(s), ", MinstaGib");
}

var float() minstagib_PlayerEffectsHandle_NextLink;
float minstagib_PlayerEffectsHandle() {
	minstagib_PlayerEffectsHandle_NextLink();
	self.effects |= EF_FULLBRIGHT;
	return TRUE;
}

var float(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) minstagib_PlayerDamageHandle_NextLink;
float minstagib_PlayerDamageHandle(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if ((deathtype == DEATH_FALL)  ||
		(deathtype == DEATH_DROWN) ||
		(deathtype == DEATH_SLIME) ||
		(deathtype == DEATH_LAVA))
		return TRUE;

	if (self.armorvalue && (deathtype == WEP_MINSTANEX) && damage)
	{
		self.armorvalue -= 1;
		centerprint(self, strcat(DAMAGE_CENTERPRINT_SPACER, "^3Remaining extra lives: ",ftos(self.armorvalue)));
		GameHookChain_PlayerDamageMod = 0;
		self.hitsound += 1;
		attacker.hitsound += 1; // TODO change this to a future specific hitsound for armor hit
	}
	return minstagib_PlayerDamageHandle_NextLink(inflictor, attacker, damage, deathtype, hitloc, force);
}

var void(entity targ, entity attacker, float deathtype) minstagib_DamageForceModsSet_NextLink;
void minstagib_DamageForceModsSet(entity targ, entity attacker, float deathtype) {
	if (targ.classname == "player") {
		if (attacker.classname == "player")
		if (DEATH_ISWEAPON(deathtype, WEP_LASER))
		if (g_minstagib_nolaserdamage || !PlayerCanFire(attacker, FALSE))
		{
			GameHook_DamageMod = 0;
			if (targ != attacker)
			{
				if (g_minstagib_nolaserdamage)
					centerprint(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "Secondary fire inflicts no damage!"));

				GameHook_ForceMod = 0;
				GameHook_MirrorDamageMod = 0;
			}
		}
		if (teamplay)
		if (attacker != targ)
		if (deathtype != DEATH_MIRRORDAMAGE)
		if (deathtype != DEATH_NOAMMO)
		if (deathtype != DEATH_TELEFRAG)
		if (targ.deadflag == DEAD_NO)
		if (attacker.team == targ.team) {
			if (g_friendlyfire == 0)
				GameHook_DamageMod = 0;
			else
				GameHook_DamageMod = GameHook_DamageMod / g_friendlyfire; //Restore value
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
	Damage(attacker, inflictor, attacker, 0, DEATH_MIRRORDAMAGE, attacker.origin, force);
	return TRUE;
}

float minstagib_StartAmmoHandle(float use_ammunition) {
	start_health = 100;
	start_armorvalue = 0;
	start_weapons = WEPBIT_MINSTANEX;
	weapon_precache(WEP_MINSTANEX);
	if (use_ammunition) {
		start_ammo_cells = cvar("g_minstagib_ammo_start");
		minstagib_ammo = TRUE;
	} else 
		start_items |= IT_UNLIMITED_AMMO;

	return TRUE;
}

float minstagib_WarmupStartAmmoHandle(float use_ammunition) { return TRUE; }

var void() minstagib_ItemRespawnCountDown_NextLink;
void minstagib_ItemRespawnCountDown() {
	if (self.items == IT_NAILS) {
		GameHook_ItemName = "item-extralife";
		GameHook_ItemColor = '1 0 0';
	}
	minstagib_ItemRespawnCountDown_NextLink();
}

float minstagib_ArmorBlockPercentMod() { return 0; }

void minstagib_init() {
	CACHE_CVAR(g_minstagib);
	if not(g_minstagib)
		return;

	CACHE_CVAR(g_minstagib_ammo_drop);
	CACHE_CVAR(g_minstagib_extralives);
	CACHE_CVAR(g_minstagib_speed_jumpheight);
	CACHE_CVAR(g_minstagib_speed_moverate);
	CACHE_CVAR(g_minstagib_nolaserdamage);

	g_minstagib_invis_alpha = cvar("g_minstagib_invis_alpha");
	if (g_minstagib_invis_alpha <= 0)
		g_minstagib_invis_alpha = -1;

	precache_sound ("announcer/robotic/lastsecond.wav");
	precache_sound ("announcer/robotic/narrowly.wav");
	minstagib_PlayerPreThink_NextLink = GameHookChain_PlayerPreThink;
	GameHookChain_PlayerPreThink = minstagib_PlayerPreThink;
	minstagib_ItemGiveToHandle_NextLink = GameHookChain_ItemGiveToHandle;
	GameHookChain_ItemGiveToHandle = minstagib_ItemGiveToHandle;
	minstagib_HealthArmorFuelModsSet_NextLink = GameHookChain_HealthArmorFuelModsSet;
	GameHookChain_HealthArmorFuelModsSet = minstagib_HealthArmorFuelModsSet;
	GameHookChain_WeaponSpawnHandle = minstagib_WeaponSpawnHandle;
	minstagib_ThrowWeaponAllowed_NextLink = GameHookChain_ThrowWeaponAllowed;
	GameHookChain_ThrowWeaponAllowed = minstagib_ThrowWeaponAllowed;
	minstagib_EntityPreSpawn_NextLink = GameHookChain_EntityPreSpawn;
	GameHookChain_EntityPreSpawn = minstagib_EntityPreSpawn;
	minstagib_ItemForbidden_NextLink = GameHookChain_ItemForbidden;
	GameHookChain_ItemForbidden = minstagib_ItemForbidden;
	minstagib_WelcomeMessageMod_NextLink = GameHookChain_WelcomeMessageMod;
	GameHookChain_WelcomeMessageMod = minstagib_WelcomeMessageMod;
	minstagib_PlayerEffectsHandle_NextLink = GameHookChain_PlayerEffectsHandle;
	GameHookChain_PlayerEffectsHandle = minstagib_PlayerEffectsHandle;
	minstagib_PlayerDamageHandle_NextLink = GameHookChain_PlayerDamageHandle;
	GameHookChain_PlayerDamageHandle = minstagib_PlayerDamageHandle;
	minstagib_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = minstagib_DamageForceModsSet;
	GameHookChain_MirrorDamageHandle = minstagib_MirrorDamageHandle;
	GameHookChain_StartAmmoHandle = minstagib_StartAmmoHandle;
	GameHookChain_WarmupStartAmmoHandle = minstagib_WarmupStartAmmoHandle;
	minstagib_ItemRespawnCountDown_NextLink = GameHookChain_ItemRespawnCountDown;
	GameHookChain_ItemRespawnCountDown = minstagib_ItemRespawnCountDown;
	GameHookChain_ArmorBlockPercentMod = minstagib_ArmorBlockPercentMod;
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
