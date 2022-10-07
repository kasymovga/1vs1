string(string order, float from, float to, float subtract, float complete) weapon_fix_priority_list {
	string neworder = "";
	float i, n, w;
	n = tokenize_console(order);
	for (i = 0; i < n; ++i) {
		w = stof(argv(i));
		if(w == floor(w)) {
			if(w >= from && w <= to)
				neworder = strcat(neworder, ftos(w), " ");
			else {
				w -= subtract;
				if(w >= from && w <= to)
					neworder = strcat(neworder, ftos(w), " ");
			}
		}
	}
	if (complete) {
		n = tokenize_console(neworder);
		for (w = to; w >= from; --w) {
			for(i = 0; i < n; ++i)
				if(stof(argv(i)) == w)
					break;
			if(i == n) // not found
				neworder = strcat(neworder, ftos(w), " ");
		}
	}
	return substring(neworder, 0, strlen(neworder) - 1);
}

string(string order, float complete) weapon_fix_order {
	return weapon_fix_priority_list(order, WEAPON_FIRST, WEAPON_LAST_EXTRA, 230 - WEAPON_FIRST, complete);
}

void(void) weapon_register_weapons {
	// %weaponaddpoint
	#ifdef SVQC
	#define WEAPON_REGISTER(id, func, ammotype, i, normalweapon, canclimb, pickupbasevalue,modelname, shortname, wname) weapon_register(id, func, ammotype, i, normalweapon, canclimb, pickupbasevalue,modelname, shortname, wname)
	#else
	#define WEAPON_REGISTER(id, func, ammotype, i, normalweapon, canclimb, pickupbasevalue,modelname, shortname, wname) weapon_register_common(id, i, shortname, wname)
	#endif
	WEAPON_REGISTER(0, weapon_dummy_func, 0, -1, 0, 0, 0, "dummy", "dummy", "Dummy");
	WEAPON_REGISTER(WEAPON_LASER, weapon_laser, 0, 1, 1, 1, 0, "laser", "laser", "Laser");
	WEAPON_REGISTER(WEAPON_SHOTGUN, weapon_shotgun, IT_SHELLS, 2, 1, 0, BOT_PICKUP_RATING_LOW, "shotgun", "shotgun", "Shotgun");
	WEAPON_REGISTER(WEAPON_UZI, weapon_uzi, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "uzi", "uzi", "Machine Gun");
	WEAPON_REGISTER(WEAPON_GRENADE_LAUNCHER, weapon_grenadelauncher, IT_ROCKETS, 4, 1, 1, BOT_PICKUP_RATING_MID, "gl", "grenadelauncher", "Mortar");
	WEAPON_REGISTER(WEAPON_ELECTRO, weapon_electro, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "electro", "electro", "Electro");
	WEAPON_REGISTER(WEAPON_CRYLINK, weapon_crylink, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "crylink", "crylink", "Crylink");
	WEAPON_REGISTER(WEAPON_NEX, weapon_nex, IT_CELLS, 7, 1, 0, BOT_PICKUP_RATING_HIGH, "nex", "nex", "Nex");
	WEAPON_REGISTER(WEAPON_HAGAR, weapon_hagar, IT_ROCKETS, 8, 1, 1, BOT_PICKUP_RATING_MID, "hagar", "hagar", "Hagar");
	WEAPON_REGISTER(WEAPON_ROCKET_LAUNCHER, weapon_rocketlauncher, IT_ROCKETS, 9, 1, 1, BOT_PICKUP_RATING_HIGH, "rl", "rocketlauncher", "Rocket Launcher");
	WEAPON_REGISTER(WEAPON_PORTO, weapon_porto, 0, 0, 0, 0, 0, "porto", "porto", "Port-O-Launch");
	WEAPON_REGISTER(WEAPON_MINSTANEX, weapon_minstanex, IT_CELLS, 7, -1, 1, BOT_PICKUP_RATING_HIGH, "minstanex", "minstanex", "MinstaNex");
	WEAPON_REGISTER(WEAPON_HOOK, weapon_hook, IT_CELLS, 0, 0, 1, 0, "hookgun", "hook", "Grappling Hook");
	WEAPON_REGISTER(WEAPON_HLAC, weapon_hlac, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "hlac", "hlac", "Heavy Laser Assault Cannon");
	WEAPON_REGISTER(WEAPON_TUBA, weapon_tuba, 0, 1, -1, 0, BOT_PICKUP_RATING_MID, "tuba", "tuba", "@!#%'n Tuba");
	WEAPON_REGISTER(WEAPON_CAMPINGRIFLE, weapon_campingrifle, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "campingrifle", "campingrifle", "Rifle");
	WEAPON_REGISTER(WEAPON_FIREBALL, weapon_fireball, IT_ROCKETS, 9, 1, 0, BOT_PICKUP_RATING_MID, "fireball", "fireball", "Fireball");
	WEAPON_REGISTER(WEAPON_SUPERSHOTGUN, weapon_supershotgun, IT_SHELLS, 8, 1, 0, BOT_PICKUP_RATING_MID, "supershotgun", "supershotgun", "SuperShotgun");
	WEAPON_REGISTER(WEAPON_ZAPPER, weapon_zapper, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "zapper", "zapper", "Zapper");
	WEAPON_REGISTER(WEAPON_MELEE, weapon_chainsaw, 0, 1, 1, 0, BOT_PICKUP_RATING_MID, "chainsaw", "chainsaw", "Chainsaw");
}
