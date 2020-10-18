float player_deadflag;
entity player_slots[255]; // 255 is engine limit on maxclients
entity player_list;

void (entity player) player_register {
	entity pl;
	for(pl = player_list.sort_next; pl; pl = pl.sort_next)
		if(pl == player) {
			print("Player already registered!\n");
			return;
		}
	player.sort_next = player_list.sort_next;
	player.sort_prev = player_list;
	if(player_list.sort_next)
		player_list.sort_next.sort_prev = player;
	player_list.sort_next = player;
}

void (entity player) player_remove {
	entity pl, parent;
	parent = player_list;
	for (pl = player_list.sort_next; pl && pl != player; pl = pl.sort_next)
		parent = pl;

	if (!pl) {
		print("Trying to remove a player which is not in the playerlist!\n");
		return;
	}
	parent.sort_next = player.sort_next;
	if (player.sort_next)
		player.sort_next.sort_prev = parent;

	player.sort_prev = world;
}

float(float i) player_color_force {
	if (team_mode)
		return (stof(getplayerkey(i, "colors")) & 15) + 1;
	else
		return 0;
}

float(float i) player_color {
	entity pl = player_slots[i];
	if not(pl.gotscores) // unconnected
		return TEAM_COLOR_SPECTATOR;
	else if (pl.team == TEAM_COLOR_SPECTATOR)
		return TEAM_COLOR_SPECTATOR;
	else if (team_mode)
		return pl.team;
	else
		return player_color_force(i);
}

string(float i) player_name {
	return getplayerkey(i, "name");
}
