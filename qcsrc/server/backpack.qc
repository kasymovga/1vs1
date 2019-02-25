float g_pickup_drop_backpack;
string sv_model_backpack;
string model_backpack;

var float() backpack_ThrowWeaponOnDeathHandle_NextLink;
float() backpack_ThrowWeaponOnDeathHandle {
	if not(g_pickup_drop_backpack)
		return backpack_ThrowWeaponOnDeathHandle_NextLink();

	entity ammopack, oldself;
	ammopack = spawn();
	ammopack.ammo_cells = self.ammo_cells;
	ammopack.ammo_rockets = self.ammo_rockets;
	ammopack.ammo_shells = self.ammo_shells;
	ammopack.ammo_nails = self.ammo_nails;
	ammopack.ammo_fuel = self.ammo_fuel;
	ammopack.classname = "droppedbackpack";
	ammopack.colormap = self.colormap;
	setorigin(ammopack, self.origin);
	oldself = self;
	self = ammopack;
	StartItem(model_backpack, "misc/itempickup.wav", 0, 0, "ammopack", IT_AMMO, W_WeaponBit(oldself.weapon), FL_WEAPON | FL_NO_WEAPON_STAY, commodity_pickupevalfunc, 3000);
	self = oldself;
	return TRUE;
}

float backpack_init_done;
void() backpack_init {
	CACHE_CVAR(g_pickup_drop_backpack);
	if not(g_pickup_drop_backpack)
		return;

	CACHE_CVAR_STR(sv_model_backpack);
	model_backpack = ((sv_model_backpack == "") ? "models/items/g_jetpack.md3" : sv_model_backpack);
	precache_model(model_backpack);
	if (backpack_init_done)
		return;

	backpack_init_done = TRUE;
	backpack_ThrowWeaponOnDeathHandle_NextLink = GameHookChain_ThrowWeaponOnDeathHandle;
	GameHookChain_ThrowWeaponOnDeathHandle = backpack_ThrowWeaponOnDeathHandle;
}
