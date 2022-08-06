void() init_dedicated_think {
	if (time < 1)
		self.nextthink = time;
	else {
		self.nextthink = time + 1;
	}
	if not(dlc_ready_all()) {
		if (time > 1)
			print("Some DLC is not ready\n");

		return;
	}
	if (cvar("_sv_init")) {
		print("Dedicated server initialization done.\n");
		map_info_enumerate();
		map_info_filter_game_type(map_info_type_from_game_type(gametype_current()), map_info_required_flags(), map_info_forbidden_flags(), 0);
		if (!map_do_next_override())
			map_goto_next();

		return;
	}
	if (time >= 1)
		print("Waiting for _sv_init being set to 1 by initialization scripts...\n");
}


// handler for _init/_init map (only for dedicated server initialization)
void(void) spawnfunc___init_dedicated_server {
	slowmo_factor = 1;
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
	dlc_init();
}
