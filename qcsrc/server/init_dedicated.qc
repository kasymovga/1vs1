void() init_dedicated_think {
	float n;
	localcmd("\nset _sv_init2 1\n");
	if(cvar("_sv_init") && cvar("_sv_init2")) {
		map_list_init();
		if(cvar("g_maplist_shuffle"))
			map_list_shuffle();

		n = tokenizebyseparator(cvar_string("_g_maplist"), " ");
		cvar_set("_g_maplist_index", ftos(n - 1)); // jump to map 0 in map_goto_next
		MapInfo_Enumerate();
		MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		if(!map_do_next_override())
			map_goto_next();

		return;
	}
	if(time < 5)
		self.nextthink = time;
	else {
		self.nextthink = time + 1;
		print("Waiting for _sv_init being set to 1 by initialization scripts...\n");
	}
}


// handler for _init/_init map (only for dedicated server initialization)
void(void) spawnfunc___init_dedicated_server {
	cvar_preinit();
	weapon_register_weapons();
	world_initialized = -1; // don't complain
	entity e;
	e = spawn();
	e.think = init_dedicated_think;
	e.nextthink = time;
	e = spawn();
	e.classname = "info_player_deathmatch"; // safeguard against player joining
	self.classname = "worldspawn"; // safeguard against various stuff ;)
	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_GameTypeToMapInfoType(MapInfo_CurrentGametype()), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	dlc_init();
}
