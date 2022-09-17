float(float a, float b) target_items_func_set {
	if (b == 0)
		return a;
	else if (b < 0)
		return 0;
	else
		return b;
}

float(float a, float b) target_items_func_min {
	if (b == 0)
		return a;
	else if (b < 0)
		return 0;
	else
		return min(a, b);
}

float(float a, float b) target_items_func_max {
	return max(a, b);
}

float(float a, float b) target_items_func_bitset {
	return b;
}

float(float a, float b) target_items_func_and {
	return a & b;
}

float(float a, float b) target_items_func_itembitset {
	return (a - (a & (IT_PICKUPMASK | IT_STRENGTH | IT_INVINCIBLE | IT_SPEED | IT_INVISIBILITY))) | b;
}

float(float a, float b) target_items_func_itemand {
	return (a - (a & (IT_PICKUPMASK | IT_STRENGTH | IT_INVINCIBLE | IT_SPEED | IT_INVISIBILITY))) | (a & b);
}

float(float a, float b) target_items_func_or {
	return a | b;
}

float(float a, float b) target_items_func_andnot {
	return a - (a & b);
}

float target_items_changed;
void(float binary, .float field, float(float a, float b) func, string sound_increase, string sound_decrease) target_items_change {
	float n, d;
	n = func(activator.field, self.field);
	if (binary) {
		d = n & activator.field;
		if (d != n) // bits added?
			d = +1;
		else if (d != activator.field) // bits removed?
			d = -1;
		else
			d = 0;
	} else
		d = n - activator.field;

	if (d < 0) {
		if (sound_decrease != "")
			sound (activator, CHAN_AUTO, sound_decrease, VOL_BASE, ATTN_NORM);

		target_items_changed = 1;
	} else if (d > 0) {
		if (sound_increase != "")
			sound (activator, CHAN_AUTO, sound_increase, VOL_BASE, ATTN_NORM);

		target_items_changed = 1;
	}
	activator.field = n;
}

void(void) target_items_use {
	float h0, a0, f0;
	if (substring(activator.classname, 7, 0) == "dropped") {
		TRIGGER_EXACT_TOUCH;
		remove(activator);
		return;
	}
	if (activator.classname != "player")
		return;

	if (activator.deadflag != DEAD_NO)
		return;

	TRIGGER_EXACT_TOUCH;
	entity e;
	for (e = world; (e = findentity(e, enemy, activator)); )
		if (substring(e.classname, 0, 7) == "dropped")
			remove(e);

	float _switchweapon;
	_switchweapon = FALSE;
	if (activator.autoswitch)
		if (activator.switchweapon == weapon_best(activator))
			_switchweapon = TRUE;

	a0 = activator.armorvalue;
	h0 = activator.health;
	f0 = activator.ammo_fuel;
	target_items_changed = 0;
	if (self.spawnflags == 0) { //SET
		target_items_change(0, ammo_shells, target_items_func_set, "misc/itempickup.wav", "");
		target_items_change(0, ammo_nails, target_items_func_set, "misc/itempickup.wav", "");
		target_items_change(0, ammo_rockets, target_items_func_set, "misc/itempickup.wav", "");
		target_items_change(0, ammo_cells, target_items_func_set, "misc/itempickup.wav", "");
		target_items_change(0, ammo_fuel, target_items_func_set, "misc/itempickup.wav", "");
		target_items_change(0, health, target_items_func_set, "misc/megahealth.wav", "");
		target_items_change(0, armorvalue, target_items_func_set, "misc/armor25.wav", "");
		target_items_change(1, items, target_items_func_itembitset, "misc/powerup.wav", "misc/poweroff.wav");
		target_items_change(1, weapons, target_items_func_bitset, "weapons/weaponpickup.wav", "");
		if ((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = time + self.strength_finished;

		if ((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = time + self.invincible_finished;

		if ((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = time + self.speed_finished;

		if ((self.items & activator.items) & IT_INVISIBILITY)

			activator.invisibility_finished = time + self.invisibility_finished;
	} else if (self.spawnflags == 1) { // AND/MIN
		target_items_change(0, ammo_shells, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_nails, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_rockets, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_cells, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_fuel, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, health, target_items_func_min, "misc/megahealth.wav", "");
		target_items_change(0, armorvalue, target_items_func_min, "misc/armor25.wav", "");
		target_items_change(1, items, target_items_func_itemand, "misc/powerup.wav", "misc/poweroff.wav");
		target_items_change(1, weapons, target_items_func_and, "weapons/weaponpickup.wav", "");
		if ((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = min(activator.strength_finished, time + self.strength_finished);

		if ((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = min(activator.invincible_finished, time + self.invincible_finished);

		if ((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = min(activator.speed_finished, time + self.speed_finished);

		if ((self.items & activator.items) & IT_INVISIBILITY)
			activator.invisibility_finished = min(activator.invisibility_finished, time + self.invisibility_finished);
	} else if (self.spawnflags == 2) { // OR/MAX
		target_items_change(0, ammo_shells, target_items_func_max, "misc/itempickup.wav", "");
		target_items_change(0, ammo_nails, target_items_func_max, "misc/itempickup.wav", "");
		target_items_change(0, ammo_rockets, target_items_func_max, "misc/itempickup.wav", "");
		target_items_change(0, ammo_cells, target_items_func_max, "misc/itempickup.wav", "");
		target_items_change(0, ammo_fuel, target_items_func_max, "misc/itempickup.wav", "");
		target_items_change(0, health, target_items_func_max, "misc/megahealth.wav", "");
		target_items_change(0, armorvalue, target_items_func_max, "misc/armor25.wav", "");
		target_items_change(1, items, target_items_func_or, "misc/powerup.wav", "misc/poweroff.wav");
		target_items_change(1, weapons, target_items_func_or, "weapons/weaponpickup.wav", "");
		if ((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = max(activator.strength_finished, time + self.strength_finished);

		if ((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = max(activator.invincible_finished, time + self.invincible_finished);

		if ((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = max(activator.speed_finished, time + self.speed_finished);

		if ((self.items & activator.items) & IT_INVISIBILITY)
			activator.invisibility_finished = max(activator.invisibility_finished, time + self.invisibility_finished);
	} else if (self.spawnflags == 4) { // ANDNOT/MIN
		target_items_change(0, ammo_shells, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_nails, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_rockets, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_cells, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, ammo_fuel, target_items_func_min, "misc/itempickup.wav", "");
		target_items_change(0, health, target_items_func_min, "misc/megahealth.wav", "");
		target_items_change(0, armorvalue, target_items_func_min, "misc/armor25.wav", "");
		target_items_change(1, items, target_items_func_andnot, "misc/powerup.wav", "misc/poweroff.wav");
		target_items_change(1, weapons, target_items_func_andnot, "weapons/weaponpickup.wav", "");
		if ((self.items & activator.items) & IT_STRENGTH)
			activator.strength_finished = min(activator.strength_finished, time + self.strength_finished);

		if ((self.items & activator.items) & IT_INVINCIBLE)
			activator.invincible_finished = min(activator.invincible_finished, time + self.invincible_finished);

		if ((self.items & activator.items) & IT_SPEED)
			activator.speed_finished = min(activator.speed_finished, time + self.speed_finished);

		if ((self.items & activator.items) & IT_INVISIBILITY)
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

	if (activator.health > h0)
		activator.pauserothealth_finished = max(activator.pauserothealth_finished, time + g_balance_pause_health_rot);
	else if (activator.health < h0)
		activator.pauseregen_finished = max(activator.pauseregen_finished, time + g_balance_pause_health_regen);

	if (activator.ammo_fuel > f0)
		activator.pauserotfuel_finished = max(activator.pauserotfuel_finished, time + g_balance_pause_fuel_rot);

	if (activator.armorvalue > a0)
		activator.pauserotarmor_finished = max(activator.pauserothealth_finished, time + g_balance_pause_health_rot);

	e = weapon_info(activator.switchweapon);
	if not((activator.weapons & e.weapons) || (activator.weapons_extra & e.weapons_extra))
		_switchweapon = TRUE;

	if (_switchweapon)
		weapon_switch_force(activator, weapon_best(activator));

	if (target_items_changed)
		centerprint(activator, self.message);
}

void(void) spawnfunc_target_items {
	float n, i, j;
	entity e;

	self.use = target_items_use;
	if (!self.strength_finished)
		self.strength_finished = cvar("g_balance_powerup_strength_time");

	if (!self.invincible_finished)
		self.invincible_finished = cvar("g_balance_powerup_invincible_time");

	if (!self.invisibility_finished)
		self.invisibility_finished = cvar("g_balance_powerup_invisibility_time");

	if (!self.speed_finished)
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
	for (i = 0; i < n; ++i) {
		if     (argv(i) == "unlimited_ammo")         self.items |= IT_UNLIMITED_AMMO;
		else if (argv(i) == "unlimited_weapon_ammo")  self.items |= IT_UNLIMITED_WEAPON_AMMO;
		else if (argv(i) == "unlimited_superweapons") self.items |= IT_UNLIMITED_SUPERWEAPONS;
		else if (argv(i) == "strength")               { self.items |= IT_STRENGTH; powerup_strength_init(); }
		else if (argv(i) == "invincible")             { self.items |= IT_INVINCIBLE; powerup_invincible_init(); }
		else if (argv(i) == "speed")                  { self.items |= IT_SPEED; powerup_speed_init(); }
		else if (argv(i) == "invisibility")           { self.items |= IT_INVISIBILITY; powerup_invisibility_init(); }
		else if (argv(i) == "jetpack")                self.items |= IT_JETPACK;
		else {
			for (j = WEP_FIRST; j <= WEP_LAST; ++j) {
				e = weapon_info(j);
				if (argv(i) == e.netname) {
					self.weapons |= e.weapons;
					if (self.spawnflags == 0 || self.spawnflags == 2)
						weapon_precache(e.weapon);

					break;
				}
			}
			if (j > WEP_LAST)
				print("target_items: invalid item ", argv(i), "\n");
		}
	}
}
