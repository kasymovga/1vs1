float g_pickup_drop_backpack;
string sv_model_backpack;
string model_backpack;

var float() backpack_player_death_weapon_throw_handle_NextLink;
float() backpack_player_death_weapon_throw_handle {
	if not(g_pickup_drop_backpack)
		return backpack_player_death_weapon_throw_handle_NextLink();

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
	string s;
	entity e;
	e = (oldself.weapon ? weapon_info(oldself.weapon) : world);
	if (e)
		s = e.message;
	else
		s = "Ammo Pack";

	item_start(model_backpack, "misc/itempickup.wav", 0, 0, s, IT_AMMO, weapon_bit(oldself.weapon), FL_WEAPON | FL_NO_WEAPON_STAY, commodity_pickupevalfunc, 3000);
	self = oldself;
	return TRUE;
}

float backpack_init_done;
void() backpack_init {
	CVAR_CACHE(g_pickup_drop_backpack);
	if not(g_pickup_drop_backpack)
		return;

	CVAR_CACHE_STR(sv_model_backpack);
	model_backpack = ((sv_model_backpack == "") ? "models/items/g_jetpack.md3" : sv_model_backpack);
	precache_model(model_backpack);
	if (backpack_init_done)
		return;

	backpack_init_done = TRUE;
	backpack_player_death_weapon_throw_handle_NextLink = gamehook_chain_player_death_weapon_throw_handle;
	gamehook_chain_player_death_weapon_throw_handle = backpack_player_death_weapon_throw_handle;
}
