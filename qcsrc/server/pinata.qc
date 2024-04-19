float g_pinata;
float g_pinata_drop_all;
float g_pinata_ammo;

var float() pinata_player_death_weapon_throw_handle_NextLink;
float() pinata_player_death_weapon_throw_handle {
	if not(g_pinata)
		return pinata_player_death_weapon_throw_handle_NextLink();

	entity wi;
	vector o = ENTITY_CENTER(self);
	WEAPON_INFO_FOR_EACH(wi) {
		if ((self.weapons & wi.weapons) || (self.weapons_extra & wi.weapons_extra))
			if (weapon_throwable(wi.weapon) || g_pinata_drop_all)
				weapon_throw_new(self, wi.weapon, g_pinata_ammo, o, randomvec() * 175 + '0 0 325');
	}
	if (g_pinata_ammo) {
		entity oldself = self;
		if (oldself.ammo_nails) {
			self = spawn();
			setorigin(self, o);
			self.classname = "droppeditem";
			item_spawnfunc_for("bullets")();
			if not(item_start_failed) {
				self.ammo_nails = oldself.ammo_nails;
				self.velocity = '0 0 100' + randomvec() * 100;
			}
		}
		if (oldself.ammo_rockets) {
			self = spawn();
			setorigin(self, o);
			self.classname = "droppeditem";
			item_spawnfunc_for("rockets")();
			if not(item_start_failed) {
				self.ammo_rockets = oldself.ammo_rockets;
				self.velocity = '0 0 100' + randomvec() * 100;
			}
		}
		if (oldself.ammo_shells) {
			self = spawn();
			setorigin(self, o);
			self.classname = "droppeditem";
			item_spawnfunc_for("shells")();
			if not(item_start_failed) {
				self.ammo_shells = oldself.ammo_shells;
				self.velocity = '0 0 100' + randomvec() * 100;
			}
		}
		if (oldself.ammo_cells) {
			self = spawn();
			setorigin(self, o);
			self.classname = "droppeditem";
			item_spawnfunc_for("cells")();
			if not(item_start_failed) {
				self.ammo_cells = oldself.ammo_cells;
				self.velocity = '0 0 100' + randomvec() * 100;
			}
		}
		self = oldself;
	}
	return TRUE;
}

float pinata_init_done;
void() pinata_init {
	CVAR_CACHE(g_pinata);
	CVAR_CACHE(g_pinata_drop_all);
	CVAR_CACHE(g_pinata_ammo);
	if (pinata_init_done)
		return;

	pinata_init_done = TRUE;
	pinata_player_death_weapon_throw_handle_NextLink = plugin_chain_player_death_weapon_throw_handle;
	plugin_chain_player_death_weapon_throw_handle = pinata_player_death_weapon_throw_handle;
}
