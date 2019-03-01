float g_spawn_furthest;
#define SPAWNPOINT_SCORE frags

void() spawnfunc_info_player_deathmatch; // needed for the other spawnpoints
void() spawnpoint_use;

float spawn_relocate_claim_once;
void() spawn_relocate {
    // nudge off the floor
    setorigin(self, self.origin + '0 0 1');
    tracebox(self.origin, PL_MIN, PL_MAX, self.origin, TRUE, self);
    if (trace_startsolid) {
        vector o;
        o = self.origin;
        self.mins = PL_MIN;
        self.maxs = PL_MAX;
        if (!move_out_of_solid(self))
            objerror("could not get out of solid at all!");
        print("^1NOTE: this map needs FIXING. Spawnpoint at ", vtos(o - '0 0 1'));
        print(" needs to be moved out of solid, e.g. by '", ftos(self.origin_x - o_x));
        print(" ", ftos(self.origin_y - o_y));
        print(" ", ftos(self.origin_z - o_z), "'\n");
        if (cvar("g_spawnpoints_auto_move_out_of_solid")) {
            if (!spawn_relocate_claim_once) {
                print("\{1}^1NOTE: this map needs FIXING (it contains spawnpoints in solid, see server log)\n");
				spawn_relocate_claim_once = 1;
			}
        } else {
            setorigin(self, o);
            self.mins = self.maxs = '0 0 0';
            objerror("player spawn point in solid, mapper sucks!\n");
            return;
        }
    }
    if (cvar("g_spawnpoints_autodrop"))
    {
        setsize(self, PL_MIN, PL_MAX);
        droptofloor();
    }
    self.use = spawnpoint_use;
    self.team_saved = self.team;
    if (!self.cnt)
        self.cnt = 1;

    if (teamplay)
        if (self.team)
            have_team_spawns = 1;

    if (cvar("r_showbboxes")) {
        // show where spawnpoints point at too
        makevectors(self.angles);
        entity e;
        e = spawn();
        e.classname = "info_player_foo";
        setorigin(e, self.origin + v_forward * 24);
        setsize(e, '-8 -8 -8', '8 8 8');
        e.solid = SOLID_TRIGGER;
    }
}


void(void) spawnfunc_info_player_survivor {
	spawnfunc_info_player_deathmatch();
}

void(void) spawnfunc_info_player_start {
	spawnfunc_info_player_deathmatch();
}

void(void) spawnfunc_info_player_deathmatch {
	self.classname = "info_player_deathmatch";
	waypoint_spawnforitem(self);
	spawn_relocate();
}

void() spawnpoint_use {
	if(teamplay)
	if(have_team_spawns)
	{
		self.team = activator.team;
		some_spawn_has_been_used = 1;
	}
}

// Returns:
//   -1 if a spawn can't be used
//   otherwise, a weight of the spawnpoint
float(entity spot, entity playerlist, float teamcheck) spawn_score {
	float shortest, thisdist;
	entity player;

	// filter out spots for the wrong team
	if(teamcheck)
	if(spot.team != teamcheck)
		return -1;

	if(clienttype(self) == CLIENTTYPE_REAL)
	{
		if(spot.restriction == 1)
			return -1;
	}
	else
	{
		if(spot.restriction == 2)
			return -1;
	}
	if (!GameHook_SpawnPointGood(spot))
		return -1;

	player = playerlist;
	shortest = vlen(world.maxs - world.mins);
	for(player = playerlist; player; player = player.chain)
		if (player != self)
		{
			thisdist = vlen(player.origin - spot.origin);
			if (thisdist < shortest)
				shortest = thisdist;
		}
	return shortest;
}

float spawn_allbad;
float spawn_allgood;
entity(entity firstspot, entity playerlist, float mindist, float teamcheck) spawn_filter_out_of_bad_spots {
	local entity spot, spotlist, spotlistend;
	spawn_allgood = TRUE;
	spawn_allbad = TRUE;

	spotlist = world;
	spotlistend = world;

	for(spot = firstspot; spot; spot = spot.chain)
	{
		spot.SPAWNPOINT_SCORE = spawn_score(spot, playerlist, teamcheck);

		if(spawn_debugview)
		{
			setmodel(spot, "models/runematch/rune.mdl");
			if(spot.SPAWNPOINT_SCORE < mindist)
			{
				spot.colormod = '1 0 0';
				spot.scale = 1;
			}
			else
			{
				spot.colormod = '0 1 0';
				spot.scale = spot.SPAWNPOINT_SCORE / mindist;
			}
		}

		if(spot.SPAWNPOINT_SCORE >= 0) // spawning allowed here
		{
			if(spot.SPAWNPOINT_SCORE < mindist)
			{
				// too short distance
				spawn_allgood = FALSE;
			}
			else
			{
				// perfect
				spawn_allbad = FALSE;

				if(spotlistend)
					spotlistend.chain = spot;
				spotlistend = spot;
				if(!spotlist)
					spotlist = spot;

				/*
				if(teamcheck)
				if(spot.team != teamcheck)
					error("invalid spawn added");

				print("added ", etos(spot), "\n");
				*/
			}
		}
	}
	if(spotlistend)
		spotlistend.chain = world;

	/*
		entity e;
		if(teamcheck)
			for(e = spotlist; e; e = e.chain)
			{
				print("seen ", etos(e), "\n");
				if(e.team != teamcheck)
					error("invalid spawn found");
			}
	*/

	return spotlist;
}

entity(entity firstspot, float lower, float upper, float exponent) spawn_weighted_point {
	// weight of a point: bound(lower, mindisttoplayer, upper)^exponent
	// multiplied by spot.cnt (useful if you distribute many spawnpoints in a small area)
	entity spot;
	random_selection_init();
	for(spot = firstspot; spot; spot = spot.chain)
		random_selection_add(spot, 0, string_null, pow(bound(lower, spot.SPAWNPOINT_SCORE, upper), exponent) * spot.cnt, spot.SPAWNPOINT_SCORE >= lower);

	return random_selection_chosen_ent;
}

entity (float anypoint) spawn_select {
	float teamcheck;
	entity firstspot_new;
	entity spot, firstspot, playerlist;
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

	teamcheck = 0;
	if(!anypoint && have_team_spawns)
		teamcheck = self.team;

	// get the list of players
	playerlist = findchain(classname, "player");
	// get the entire list of spots
	firstspot = findchain(classname, "info_player_deathmatch");
	// filter out the bad ones
	// (note this returns the original list if none survived)
	if(anypoint) {
		spot = spawn_weighted_point(firstspot, 1, 1, 1);
	} else {
		firstspot_new = spawn_filter_out_of_bad_spots(firstspot, playerlist, 100, teamcheck);
		if(!firstspot_new)
			firstspot_new = spawn_filter_out_of_bad_spots(firstspot, playerlist, -1, teamcheck);

		firstspot = firstspot_new;
		// there is 50/50 chance of choosing a random spot or the furthest spot
		// (this means that roughly every other spawn will be furthest, so you
		// usually won't get fragged at spawn twice in a row)
		if (random() > g_spawn_furthest)
			spot = spawn_weighted_point(firstspot, 1, 1, 1);
		else
			spot = spawn_weighted_point(firstspot, 1, 5000, 5); // chooses a far far away spawnpoint
	}
	if(spawn_debugview)
	{
		print("spot mindistance: ", ftos(spot.SPAWNPOINT_SCORE), "\n");

		entity e;
		if(teamcheck)
			for(e = firstspot; e; e = e.chain)
				if(e.team != teamcheck)
					error("invalid spawn found");
	}
	if (!spot)
	{
		if(spawn_debug)
			map_goto_next();
		else
			return world; // team can't spawn any more, because of actions of other team
	}

	return spot;
}

void() spawn_init {
	CACHE_CVAR(g_spawn_furthest);
}
