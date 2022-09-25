// WEAPON PLUGIN SYSTEM
entity _weapon_info[WEP_LAST_EXTRA];
entity weapon_info_dummy;

float(float dummy) weapon_dummy_func {
	return 0;
}

void(void) weapon_register_done {
	if not(weapon_info_dummy) {
		weapon_info_dummy = spawn();
		weapon_info_dummy.classname = "weapon_info";
		weapon_info_dummy.weapon = 0; // you can recognize dummies by this
		weapon_info_dummy.weapons = 0; // you can recognize dummies by this too
		weapon_info_dummy.netname = "@!#%'n Tuba";
		weapon_info_dummy.items = 0;
		weapon_info_dummy.weapon_func = weapon_dummy_func;
		weapon_info_dummy.mdl = "";
		weapon_info_dummy.model = "";
		#ifdef SVQC
		weapon_info_dummy.spawnflags = 0;
		weapon_info_dummy.bot_pickupbasevalue = 0;
		weapon_info_dummy.model2 = "";
		#endif
		weapon_info_dummy.impulse = -1;
	}
	str_unzone_ifneeded(weaponpriority_hudselector_0);
	str_unzone_ifneeded(weaponpriority_hudselector_1);
	weaponpriority_hudselector_0 = "";
	entity wi;
	WEAPON_INFO_FOR_EACH(wi)
		weaponpriority_hudselector_0 = strcat(weaponpriority_hudselector_0, " ", ftos(wi.weapon));

	float imp;
	weaponpriority_hudselector_1 = "";
	WEAPON_INFO_FOR_EACH(wi)
		if (wi.impulse == 0)
			weaponpriority_hudselector_1 = strcat(weaponpriority_hudselector_1, " ", ftos(wi.weapon));

	for (imp = 9; imp > 0; --imp)
		WEAPON_INFO_FOR_EACH(wi)
			if (wi.impulse == imp)
				weaponpriority_hudselector_1 = strcat(weaponpriority_hudselector_1, " ", ftos(wi.weapon));

	weaponpriority_hudselector_0 = strzone(substring(weaponpriority_hudselector_0, 1, strlen(weaponpriority_hudselector_0) - 1));
	weaponpriority_hudselector_1 = strzone(substring(weaponpriority_hudselector_1, 1, strlen(weaponpriority_hudselector_1) - 1));
}

void(float id,
#ifdef SVQC
		float(float) func,
#endif
#ifndef MENUQC
		float ammotype,
#endif
		float i,
#ifdef SVQC
		float normalweapon, float canclimb, float pickupbasevalue,
#endif
		string modelname, string shortname, string wname) weapon_register_real {
	entity e;
	e = weapon_info(id);
	if (e && e != weapon_info_dummy) {
#ifdef SVQC
		str_unzone_ifneeded(e.model);
		str_unzone_ifneeded(e.mdl);
		str_unzone_ifneeded(e.model2);
#endif
	} else {
		e = spawn();
		e.enemy = weapon_info_chain;
		weapon_info_chain = e;
	}
	e.classname = "weapon_info";
	e.weapon = id;
	e.netname = shortname;
	e.message = wname;
#ifndef MENUQC
	e.items = ammotype;
#endif
	e.impulse = i;
#ifdef SVQC
	e.weapon_func = func;
	string s = cvar_string(strcat("sv_model_", modelname));
	if (s == "")
		s = modelname;

	e.model = strzone(strcat("models/weapons/g_", s, ".md3"));
	e.mdl = strzone(s);
	e.lodmodel1 = strzone(strcat("models/weapons/g_", modelname, ".md3"));
	float animfile;
	string animfilename = strcat("models/weapons/h_", e.mdl, ".dpm.animinfo");
	animfile = fopen(animfilename, FILE_READ);
	// preset some defaults that work great for renamed zym files (which don't need an animinfo)
	e.anim_fire1  = '0 1 0.01';
	e.anim_fire2  = '1 1 0.01';
	e.anim_idle   = '2 1 0.01';
	e.anim_reload = '3 1 0.01';
	if (animfile >= 0) {
		anim_parseerror = FALSE;
		anim_parseline(e, animfile, anim_fire1);
		anim_parseline(e, animfile, anim_fire2);
		anim_parseline(e, animfile, anim_idle);
		anim_parseline(e, animfile, anim_reload);
		fclose(animfile);
		if (anim_parseerror)
			print("Parse error in ", animfilename, ", some animations are broken\n");
	}
	e.model2 = strzone(strcat("wpn-", e.mdl));
	e.spawnflags = 0;
	if (normalweapon > 0)
		e.spawnflags |= WEPSPAWNFLAG_NORMAL;

	if (normalweapon < 0)
		e.spawnflags |= WEPSPAWNFLAG_HIDDEN;

	if (canclimb)
		e.spawnflags |= WEPSPAWNFLAG_CANCLIMB;

	e.bot_pickupbasevalue = pickupbasevalue;
#endif
	_weapon_info[id - 1] = e;
	if (id > WEP_LAST) {
		e.weapons_extra = pow(2, id - 1 - WEP_LAST);
	} else {
		e.weapons = pow(2, id - 1);
	}
	weapon_register_done();
}

entity weapon_info(float id) {
	entity w;
	if (id < WEP_FIRST)
		return weapon_info_dummy;

	if (id > WEP_LAST_EXTRA) {
		return weapon_info_dummy;
	}
	w = _weapon_info[id - 1];
	if (w)
		return w;

	return weapon_info_dummy;
}

#ifndef CLVM
void(void) weapon_register_weapons {
	// %weaponaddpoint
	weapon_register(WEP_LASER, weapon_laser, 0, 1, 1, 1, 0, "laser", "laser", "Laser");
	weapon_register(WEP_SHOTGUN, weapon_shotgun, IT_SHELLS, 2, 1, 0, BOT_PICKUP_RATING_LOW, "shotgun", "shotgun", "Shotgun");
	weapon_register(WEP_UZI, weapon_uzi, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "uzi", "uzi", "Machine Gun");
	weapon_register(WEP_GRENADE_LAUNCHER, weapon_grenadelauncher, IT_ROCKETS, 4, 1, 1, BOT_PICKUP_RATING_MID, "gl", "grenadelauncher", "Mortar");
	weapon_register(WEP_ELECTRO, weapon_electro, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "electro", "electro", "Electro");
	weapon_register(WEP_CRYLINK, weapon_crylink, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "crylink", "crylink", "Crylink");
	weapon_register(WEP_NEX, weapon_nex, IT_CELLS, 7, 1, 0, BOT_PICKUP_RATING_HIGH, "nex", "nex", "Nex");
	weapon_register(WEP_HAGAR, weapon_hagar, IT_ROCKETS, 8, 1, 1, BOT_PICKUP_RATING_MID, "hagar", "hagar", "Hagar");
	weapon_register(WEP_ROCKET_LAUNCHER, weapon_rocketlauncher, IT_ROCKETS, 9, 1, 1, BOT_PICKUP_RATING_HIGH, "rl", "rocketlauncher", "Rocket Launcher");
	weapon_register(WEP_PORTO, weapon_porto, 0, 0, 0, 0, 0, "porto", "porto", "Port-O-Launch");
	weapon_register(WEP_MINSTANEX, weapon_minstanex, IT_CELLS, 7, -1, 1, BOT_PICKUP_RATING_HIGH, "minstanex", "minstanex", "MinstaNex");
	weapon_register(WEP_HOOK, weapon_hook, IT_CELLS, 0, 0, 1, 0, "hookgun", "hook", "Grappling Hook");
	weapon_register(WEP_HLAC, weapon_hlac, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "hlac", "hlac", "Heavy Laser Assault Cannon");
	weapon_register(WEP_TUBA, weapon_tuba, 0, 1, -1, 0, BOT_PICKUP_RATING_MID, "tuba", "tuba", "@!#%'n Tuba");
	weapon_register(WEP_CAMPINGRIFLE, weapon_campingrifle, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "campingrifle", "campingrifle", "Rifle");
	weapon_register(WEP_FIREBALL, weapon_fireball, IT_ROCKETS, 9, 1, 0, BOT_PICKUP_RATING_MID, "fireball", "fireball", "Fireball");
	weapon_register(WEP_SUPERSHOTGUN, weapon_supershotgun, IT_SHELLS, 8, 1, 0, BOT_PICKUP_RATING_MID, "supershotgun", "supershotgun", "SuperShotgun");
	weapon_register(WEP_ZAPPER, weapon_zapper, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "zapper", "zapper", "Zapper");
	weapon_register(WEP_MELEE, weapon_chainsaw, 0, 1, 1, 0, BOT_PICKUP_RATING_MID, "chainsaw", "chainsaw", "Chainsaw");
}
#endif
