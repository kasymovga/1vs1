// WEAPON PLUGIN SYSTEM
entity _weapon_info[WEAPON_LAST_EXTRA];
entity weapon_info_dummy;
entity weapon_info_last;

entity(void) weapon_info_dummy_get {
	if not(weapon_info_dummy) {
		weapon_info_dummy = spawn();
		weapon_info_dummy.weapon = 0; // you can recognize dummies by this
	}
	return weapon_info_dummy;
}

entity(float id,
		float i,
		string shortname, string wname) weapon_register_common {
	entity e;
	if not(id >= WEAPON_FIRST && id <= WEAPON_LAST_EXTRA)
		return weapon_info_dummy_get();

	e = weapon_info(id);
	if not(e && e != weapon_info_dummy) {
		e = spawn();
		if (weapon_info_last) {
			weapon_info_last.enemy = e;
			weapon_info_last = e;
		} else {
			weapon_info_chain = e;
			weapon_info_last = e;
		}
	}
	e.classname = "weapon_info";
	e.weapon = id;
	e.netname = shortname;
	e.message = wname;
	e.impulse = i;
	_weapon_info[id - 1] = e;
	if (id > WEAPON_LAST) {
		e.weapons_extra = pow(2, id - 1 - WEAPON_LAST);
	} else {
		e.weapons = pow(2, id - 1);
	}
	return e;
}

entity(float id) weapon_info {
	entity w;
	if (id < WEAPON_FIRST)
		return weapon_info_dummy_get();

	if (id > WEAPON_LAST_EXTRA) {
		return weapon_info_dummy_get();
	}
	w = _weapon_info[id - 1];
	if (w)
		return w;

	return weapon_info_dummy_get();
}
