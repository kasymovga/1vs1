// WEAPON PLUGIN SYSTEM
entity _weapon_info[24];
entity weapon_info_dummy;

void(float id, float(float) func,
#ifndef MENUQC
		float ammotype,
#endif
		float i,
#ifdef SVQC
		float normalweapon, float canclimb, float pickupbasevalue,
#endif
		string modelname, string shortname, string wname, vector wcolor) weapon_register_real {
	entity e;
#ifdef SVQC
	e = _weapon_info[id - 1];
	if (e) {
		strunzone(e.model);
		strunzone(e.mdl);
		remove(e);
	}
#endif
	_weapon_info[id - 1] = e = spawn();
	e.classname = "weapon_info";
	e.weapon = id;
	e.weapons = pow(2, id - 1);
	e.netname = shortname;
	e.message = wname;
#ifndef MENUQC
	e.items = ammotype;
	e.colormod = wcolor;
#endif
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
#endif
	e.model2 = strzone(strcat("wpn-", e.mdl));
	e.impulse = i;
#ifdef SVQC
	e.spawnflags = 0;
	if (normalweapon > 0)
		e.spawnflags |= WEPSPAWNFLAG_NORMAL;

	if (normalweapon < 0)
		e.spawnflags |= WEPSPAWNFLAG_HIDDEN;

	if (canclimb)
		e.spawnflags |= WEPSPAWNFLAG_CANCLIMB;

	e.bot_pickupbasevalue = pickupbasevalue;
#endif
}

float(float dummy) weapon_dummy_func {
	return 0;
}

void(void) weapon_register_done {
	entity wi;
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
#endif
	weapon_info_dummy.impulse = -1;
	weapon_info_dummy.model2 = "";
	float i;
	weaponpriority_hudselector_0 = "";
	for (i = 24; i >= 1; --i)
		if (_weapon_info[i-1])
			weaponpriority_hudselector_0 = strcat(weaponpriority_hudselector_0, " ", ftos(i));

	float imp;
	weaponpriority_hudselector_1 = "";
	for (i = 1; i <= 24; ++i) {
		wi = _weapon_info[i-1];
		if (wi && wi.impulse == 0)
			weaponpriority_hudselector_1 = strcat(weaponpriority_hudselector_1, " ", ftos(i));
	}
	for (imp = 9; imp > 0; --imp)
		for (i = 1; i <= 24; ++i) {
			wi = _weapon_info[i-1];
			if (wi && wi.impulse == imp)
				weaponpriority_hudselector_1 = strcat(weaponpriority_hudselector_1, " ", ftos(i));
		}
	weaponpriority_hudselector_0 = strzone(substring(weaponpriority_hudselector_0, 1, strlen(weaponpriority_hudselector_0) - 1));
	weaponpriority_hudselector_1 = strzone(substring(weaponpriority_hudselector_1, 1, strlen(weaponpriority_hudselector_1) - 1));
}

entity weapon_info(float id) {
	entity w;
	if (id < WEP_FIRST || id > WEP_LAST)
		return weapon_info_dummy;

	w = _weapon_info[id - 1];
	if (w)
		return w;

	return weapon_info_dummy;
}

#ifdef SVQC
#define weapon_register(id,func,ammotype,i,normalweapon,canclimb,pickupbasevalue,modelname,shortname,wname,wclr) \
	weapon_register_real(id,func,ammotype,i,normalweapon,canclimb,pickupbasevalue,modelname,shortname,wname,wclr)
#else
#ifdef MENUQC
#define weapon_register(id,func,ammotype,i,normalweapon,canclimb,pickupbasevalue,modelname,shortname,wname,wclr) \
	weapon_register_real(id,weapon_dummy_func,i,modelname,shortname,wname,wclr)
#else
// no weapon funcs here!
#define weapon_register(id,func,ammotype,i,normalweapon,canclimb,pickupbasevalue,modelname,shortname,wname,wclr) \
	weapon_register_real(id,weapon_dummy_func,ammotype,i,modelname,shortname,wname,wclr)
#endif
#endif

void(void) weapon_register_weapons {
	// %weaponaddpoint
	weapon_register(WEP_LASER, weapon_laser, 0, 1, 1, 1, 0, "laser", "laser", "Laser", '1 0.75 0.5');
	weapon_register(WEP_SHOTGUN, weapon_shotgun, IT_SHELLS, 2, 1, 0, BOT_PICKUP_RATING_LOW, "shotgun", "shotgun", "Shotgun", '0.5 0.5 0');
	weapon_register(WEP_UZI, weapon_uzi, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "uzi", "uzi", "Machine Gun", '1 1 0.0');
	weapon_register(WEP_GRENADE_LAUNCHER, weapon_grenadelauncher, IT_ROCKETS, 4, 1, 1, BOT_PICKUP_RATING_MID, "gl", "grenadelauncher", "Mortar", '1 0.5 0.5');
	weapon_register(WEP_ELECTRO, weapon_electro, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "electro", "electro", "Electro", '0.5 0.5 1');
	weapon_register(WEP_CRYLINK, weapon_crylink, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "crylink", "crylink", "Crylink", '1 0.5 1');
	weapon_register(WEP_NEX, weapon_nex, IT_CELLS, 7, 1, 0, BOT_PICKUP_RATING_HIGH, "nex", "nex", "Nex", '0.5 1 1');
	weapon_register(WEP_HAGAR, weapon_hagar, IT_ROCKETS, 8, 1, 1, BOT_PICKUP_RATING_MID, "hagar", "hagar", "Hagar", '0.5 1 0');
	weapon_register(WEP_ROCKET_LAUNCHER, weapon_rocketlauncher, IT_ROCKETS, 9, 1, 1, BOT_PICKUP_RATING_HIGH, "rl", "rocketlauncher", "Rocket Launcher", '1 1 0.5');
	weapon_register(WEP_PORTO, weapon_porto, 0, 0, 0, 0, 0, "porto", "porto", "Port-O-Launch", '0.25 0.25 0.25');
	weapon_register(WEP_MINSTANEX, weapon_minstanex, IT_CELLS, 7, -1, 1, BOT_PICKUP_RATING_HIGH, "minstanex", "minstanex", "MinstaNex", '0.5 1 1');
	weapon_register(WEP_HOOK, weapon_hook, IT_CELLS, 0, 0, 1, 0, "hookgun", "hook", "Grappling Hook", '0.25 0.5 0.25');
	weapon_register(WEP_HLAC, weapon_hlac, IT_CELLS, 6, 1, 0, BOT_PICKUP_RATING_MID, "hlac", "hlac", "Heavy Laser Assault Cannon", '0.5 1 0.5');
	weapon_register(WEP_TUBA, weapon_tuba, 0, 1, -1, 0, BOT_PICKUP_RATING_MID, "tuba", "tuba", "@!#%'n Tuba", '1 1 1');
	weapon_register(WEP_CAMPINGRIFLE, weapon_campingrifle, IT_NAILS, 3, 1, 0, BOT_PICKUP_RATING_MID, "campingrifle", "campingrifle", "Rifle", '0.75 1 0');
	weapon_register(WEP_FIREBALL, weapon_fireball, IT_ROCKETS, 9, 1, 0, BOT_PICKUP_RATING_MID, "fireball", "fireball", "Fireball", '1 0.5 0');
	weapon_register(WEP_SUPERSHOTGUN, weapon_supershotgun, IT_SHELLS, 8, 1, 0, BOT_PICKUP_RATING_MID, "supershotgun", "supershotgun", "SuperShotgun", '0.75 0.25 0');
	weapon_register(WEP_ZAPPER, weapon_zapper, IT_CELLS, 5, 1, 0, BOT_PICKUP_RATING_MID, "zapper", "zapper", "Zapper", '0.5 0.5 1');
	weapon_register(WEP_MELEE, weapon_chainsaw, 0, 1, 1, 0, BOT_PICKUP_RATING_MID, "chainsaw", "chainsaw", "Chainsaw", '1 0.75 0.5');
	if not(weapon_info_dummy)
		weapon_register_done();
}
