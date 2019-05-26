void(void) spawnfunc_info_notnull {};

void(void) spawnfunc_info_null {
	remove(self);
	// if anything breaks, tell the mapper to fix his map! info_null is meant to remove itself immediately.
}


void(void) spawnfunc_info_player_deathmatch {
	self.classname = "info_player_deathmatch";
	waypoint_spawnforitem(self);
	spawn_relocate();
}

/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player
in team one (Red).

Keys:
"angle"
 viewing angle when spawning
*/
void(void) spawnfunc_info_player_team1 {
	self.team = COLOR_TEAM1; // red
	spawnfunc_info_player_deathmatch();
};
//self.team = 4;self.classname = "info_player_start";spawnfunc_info_player_start();};

/*QUAKED spawnfunc_info_player_team2 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in
team two (Blue).

Keys:
"angle"
 viewing angle when spawning
*/
void(void) spawnfunc_info_player_team2 {
	self.team = COLOR_TEAM2; // blue
	spawnfunc_info_player_deathmatch();
}

/*QUAKED spawnfunc_info_player_team3 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in
team three (Yellow).

Keys:
"angle"
 viewing angle when spawning
*/
void(void) spawnfunc_info_player_team3 {
	self.team = COLOR_TEAM3; // yellow
	spawnfunc_info_player_deathmatch();
}

/*QUAKED spawnfunc_info_player_team4 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in
team four (Magenta).

Keys:
"angle"
 viewing angle when spawning
*/
void(void) spawnfunc_info_player_team4 {
	self.team = COLOR_TEAM4; // purple
	spawnfunc_info_player_deathmatch();
}

void(void) spawnfunc_info_location {
    self.classname = "target_location";
    self.message = self.netname;
}

void(void) spawnfunc_info_teleport_destination {
	self.classname = "info_teleport_destination";
	self.mangle = self.angles;
	self.angles = '0 0 0';
	//setorigin (self, self.origin + '0 0 27');	// To fix a mappers' habit as old as Quake
	setorigin (self, self.origin);
	IFTARGETED {
	} else
		entity_abort("^3Teleport destination without a targetname");
}
