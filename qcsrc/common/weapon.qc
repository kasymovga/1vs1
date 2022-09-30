// WEAPON PLUGIN SYSTEM
entity _weapon_info[WEP_LAST_EXTRA];
entity weapon_info_dummy;

#ifdef SVQC
float(float dummy) weapon_dummy_func {
	return 0;
}
#endif

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
	if not(weapon_info_dummy) {
		weapon_info_dummy = spawn();
		weapon_info_dummy.classname = "weapon_info";
		weapon_info_dummy.weapon = 0; // you can recognize dummies by this
		weapon_info_dummy.weapons = 0; // you can recognize dummies by this too
		weapon_info_dummy.netname = "Dummy weapon";
		weapon_info_dummy.items = 0;
		weapon_info_dummy.mdl = "";
		weapon_info_dummy.model = "";
		#ifdef SVQC
		weapon_info_dummy.weapon_func = weapon_dummy_func;
		weapon_info_dummy.spawnflags = 0;
		weapon_info_dummy.bot_pickupbasevalue = 0;
		weapon_info_dummy.model2 = "";
		#endif
		weapon_info_dummy.impulse = -1;
	}
}

entity(float id) weapon_info {
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
