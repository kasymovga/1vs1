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
	weapon_register(WEAPON_LASER, weapon_laser, 0, 1, 1, 1, 0, "laser", "laser", "Laser");
	weapon_register(WEAPON_SHOTGUN, weapon_shotgun, IT_SHELLS, 2, 1, 0, BOT_PICKUP_RATING_LOW, "shotgun", "shotgun", "Shotgun");
	weapon_register(WEAPON_UZI, weapon_uzi, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "uzi", "uzi", "Machine Gun");
	weapon_register(WEAPON_GRENADE_LAUNCHER, weapon_grenadelauncher, IT_ROCKETS, 4, 1, 1, BOT_PICKUP_RATING_MID, "gl", "grenadelauncher", "Mortar");
	weapon_register(WEAPON_ELECTRO, weapon_electro, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "electro", "electro", "Electro");
	weapon_register(WEAPON_CRYLINK, weapon_crylink, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "crylink", "crylink", "Crylink");
	weapon_register(WEAPON_NEX, weapon_nex, IT_CELLS, 7, 1, 0, BOT_PICKUP_RATING_HIGH, "nex", "nex", "Nex");
	weapon_register(WEAPON_HAGAR, weapon_hagar, IT_ROCKETS, 8, 1, 1, BOT_PICKUP_RATING_MID, "hagar", "hagar", "Hagar");
	weapon_register(WEAPON_ROCKET_LAUNCHER, weapon_rocketlauncher, IT_ROCKETS, 9, 1, 1, BOT_PICKUP_RATING_HIGH, "rl", "rocketlauncher", "Rocket Launcher");
	weapon_register(WEAPON_PORTO, weapon_porto, 0, 0, 0, 0, 0, "porto", "porto", "Port-O-Launch");
	weapon_register(WEAPON_MINSTANEX, weapon_minstanex, IT_CELLS, 7, -1, 1, BOT_PICKUP_RATING_HIGH, "minstanex", "minstanex", "MinstaNex");
	weapon_register(WEAPON_HOOK, weapon_hook, IT_CELLS, 0, 0, 1, 0, "hookgun", "hook", "Grappling Hook");
	weapon_register(WEAPON_HLAC, weapon_hlac, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "hlac", "hlac", "Heavy Laser Assault Cannon");
	weapon_register(WEAPON_TUBA, weapon_tuba, 0, 1, -1, 0, BOT_PICKUP_RATING_MID, "tuba", "tuba", "@!#%'n Tuba");
	weapon_register(WEAPON_CAMPINGRIFLE, weapon_campingrifle, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "campingrifle", "campingrifle", "Rifle");
	weapon_register(WEAPON_FIREBALL, weapon_fireball, IT_ROCKETS, 9, 1, 0, BOT_PICKUP_RATING_MID, "fireball", "fireball", "Fireball");
	weapon_register(WEAPON_SUPERSHOTGUN, weapon_supershotgun, IT_SHELLS, 8, 1, 0, BOT_PICKUP_RATING_MID, "supershotgun", "supershotgun", "SuperShotgun");
	weapon_register(WEAPON_ZAPPER, weapon_zapper, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "zapper", "zapper", "Zapper");
	weapon_register(WEAPON_MELEE, weapon_chainsaw, 0, 1, 1, 0, BOT_PICKUP_RATING_MID, "chainsaw", "chainsaw", "Chainsaw");
}
