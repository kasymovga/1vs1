float single_level_finished;
float _single_transit_weapons;
float _single_transit_weapons_extra;
float single_secrets_found;
float single_secrets_total;
float single_monsters_killed;
float single_monsters_total;
float single_skill_save;
float single_slowmo;
entity single_secrets_controller;

var void() single_shutdown_next;
void() single_shutdown {
	registercvar("_single_transit_weapons", "0");
	builtin_cvar_set("_single_transit_weapons", ftos(_single_transit_weapons | weapon_spawned_list | player_start_weapons)); //builting function for avoid campaign wrapper
	registercvar("_single_transit_weapons_extra", "0");
	builtin_cvar_set("_single_transit_weapons_extra", ftos(_single_transit_weapons_extra | weapon_spawned_extra_list | player_start_weapons_extra)); //builting function for avoid campaign wrapper
	single_shutdown_next();
}

void(void) single_endlevel {
	// //This broke trigger_once
	//if (PLAYER_DEAD(activator))
	//	return;
	//
	if (single_level_finished)
		return;

	single_level_finished = TRUE;
	entity e;
	PLAYER_FOR_EACH(e)
		e.winning = 1;

	campaign_won = TRUE;
	single_monsters_total = single_monsters_killed;
	for (e = world; (e = nextent(e));) {
		if (e.classname == "monster") {
			single_monsters_total++;
			continue;
		}
		if (substring(e.classname, 0, 8) == "monster_") //Untriggered spawn
		if (substring(e.classname, strlen(e.classname) - 6, 6) == "_spawn")
		if (e.dmg == max(e.cnt, 1)) {
			single_monsters_total += e.dmg;
		}
	}
	if (self.netname != "") {
		cvar_set("nextmap", self.netname);
		campaign_map_transition = TRUE;
	}
	registercvar("_autosave_skip", "0");
	builtin_cvar_set("_autosave_skip", "0");
}

float(float ignore, float ignore2) single_winning_condition {
	return single_level_finished;
}

string (string s) single_map_finish_message_mod {
	if (campaign_won) {
		game_status_set("^2Level finished\nSecrets: {1}\nMonsters: {2}", 30, strcat(ftos(single_secrets_found), "/", ftos(single_secrets_total)), strcat(ftos(single_monsters_killed), "/", ftos(single_monsters_total)), "");
		return "";
	} else
		return "^1Game over";
}

float(entity ignore, entity ignore2, float ignore3) single_player_death_handle {
	single_level_finished = TRUE;
	campaign_won = FALSE;
	campaign_map_transition = TRUE;
	registercvar("_autosave_skip", "0");
	builtin_cvar_set("_autosave_skip", "1");
	return FALSE;
}

void single_init_delayed(void) {
	entity e;
	string s;
	entity map_target;
	cvar_set("skill", ftos(single_skill_save));
	for (e = nextent(world); e; e = nextent(e)) {
		if (e.target != "")
		if (substring(e.target, 0, 9) == "endlevel:") {
			s = substring(e.target, 9, -1);
			map_target = spawn();
			map_target.netname = strzone(s);
			print("endlevel with nextmap: ", s, "\n");
			map_target.targetname = e.target;
			map_target.use = single_endlevel;
		}
	}
	_single_transit_weapons = builtin_cvar("_single_transit_weapons"); //builtin to avoid campaign intercepting
	_single_transit_weapons_extra = builtin_cvar("_single_transit_weapons_extra"); //builtin to avoid campaign intercepting
	WEAPON_INFO_FOR_EACH(e) {
		if (_single_transit_weapons & e.weapons)
			weapon_precache(e.weapon);

		if (_single_transit_weapons_extra & e.weapons_extra)
			weapon_precache(e.weapon);
	}
}

void() single_client_parms_new {
	parm5 = player_start_health;
	parm6 = player_start_armorvalue;
	parm7 = player_start_ammo_shells;
	parm8 = player_start_ammo_nails;
	parm9 = player_start_ammo_rockets;
	parm10 = player_start_ammo_cells;
	parm11 = player_start_weapons;
	parm12 = FALSE;
	parm13 = player_start_weapons_extra;
}

void() single_client_parms_change {
	if (self.classname == "player" && (self.deadflag == DEAD_NO || campaign_won)) {
		parm5 = self.health;
		parm6 = self.armorvalue;
		parm7 = self.ammo_shells;
		parm8 = self.ammo_nails;
		parm9 = self.ammo_rockets;
		parm10 = self.ammo_cells;
		parm11 = self.weapons;
		parm12 = TRUE;
		parm13 = self.weapons_extra;
	} else {
		single_client_parms_new();
	}
}

.float default_equip;
void() single_client_parms_decode {
	if (parm12) {
		self.health = parm5;
		self.armorvalue = parm6;
		self.ammo_shells = parm7;
		self.ammo_nails = parm8;
		self.ammo_rockets = parm9;
		self.ammo_cells = parm10;
		self.weapons = parm11;
		self.default_equip = FALSE;
		self.weapons_extra = parm13;
	} else {
		self.default_equip = TRUE; //Hack for force default equip
	}
}

float(void) single_forbid_spectators {
	if not(self.default_equip) //For just connected players who carried equip from previous level
		return TRUE;

	return FALSE;
}

void(void) single_autosave {
	float slot_auto_secondary = builtin_cvar("_slot_auto_secondary"); //last time saved on secondary slot
	string slotnum = (slot_auto_secondary ? "11" : "13");
	print_to(self, PRINT_CENTER, "Autosaving...", "", "", "");
	localcmd(strcat("\nseta _slot_description", slotnum, " \"", mapname, " - ", strftime(TRUE, "%Y %b %e %H:%M:%S")));
	localcmd(" \"\n");
	localcmd(strcat("seta _slot_auto_secondary ", ftos(!slot_auto_secondary), ";"));
	localcmd(strcat("save slot", slotnum, ".sav\nsaveconfig\n"));
}

var float(void) single_player_equip_handle_next;
float(void) single_player_equip_handle {
	if (self.default_equip)
		return single_player_equip_handle_next();

	registercvar("_autosave_skip", "0");
	if (game_type == GAME_TYPE_SINGLE)
	if (self.netaddress == "local")
	if not(builtin_cvar("_autosave_skip")) {
		defer(0.5, single_autosave);
	}
	builtin_cvar_set("_autosave_skip", "0");
	return TRUE;
}

float(void) single_map_restart {
	if (game_type == GAME_TYPE_COOP) {
		if (single_level_finished)
			return !campaign_won;
		else
			return FALSE; //Endmatch
	}
	return !campaign_won;
}

float() single_monster_team_switchable {
	return FALSE;
}

var void() single_player_think_next;
void() single_player_think {
	self.items &= ~(IT_KEY1 | IT_KEY2);
	self.items |= self.keys;
	single_player_think_next();
}

var void(entity) single_player_spawn_next;
void(entity e) single_player_spawn {
	self.default_equip = TRUE;
	single_player_spawn_next(e);
}

void(entity attacker) single_monster_killed {
	single_monsters_killed++;
	if (attacker.classname == "player")
		score_player_add(attacker, SP_SCORE, self.frags);
}

var float(string cmd, float tokens) single_cmd_client_handle_next;
float(string cmd, float tokens) single_cmd_client_handle {
	float slot_quick_secondary = builtin_cvar("_slot_quick_secondary"); //last time saved on secondary slot
	string slotnum = (slot_quick_secondary ? "12" : "14");
	if (cmd == "quicksave") {
		print_to(self, PRINT_CENTER, "Quicksaving...", "", "", "");
		localcmd(strcat("\nseta _slot_description", slotnum, " \"", mapname, " - ", strftime(TRUE, "%Y %b %e %H:%M:%S")));
		localcmd(" \"\n");
		localcmd("seta _slot_quick_secondary ", ftos(!slot_quick_secondary), "\n");
		localcmd(strcat("save slot", slotnum, ".sav\nsaveconfig\n"));
		return TRUE;
	}
	if (cmd == "slowmostart") {
		single_slowmo = 0.05;
		return TRUE;
	}
	if (cmd == "slowmoend") {
		single_slowmo = 1;
		return TRUE;
	}
	return single_cmd_client_handle_next(cmd, tokens);
}

var float(float f) single_slowmo_update_mod_next;
float(float f) single_slowmo_update_mod {
	f *= single_slowmo;
	return single_slowmo_update_mod_next(f);
}

void(void) single_init {
	hint_add("You can save/load game at any moment.");
	single_skill_save = builtin_cvar("skill");
	builtin_cvar_set("skill", "2");
	builtin_cvar_set("deathmatch", "0");
	if (game_type == GAME_TYPE_COOP)
		builtin_cvar_set("coop", "1");
	else
		builtin_cvar_set("coop", "0");

	plugin_map_restart = single_map_restart;
	plugin_forbid_specatators = single_forbid_spectators;
	single_player_equip_handle_next = plugin_chain_player_equip_handle;
	plugin_chain_player_equip_handle = single_player_equip_handle;
	plugin_winning_condition = single_winning_condition;
	plugin_map_finish_message_mod = single_map_finish_message_mod;
	plugin_player_death_handle = single_player_death_handle;
	plugin_client_parms_new = single_client_parms_new;
	plugin_client_parms_change = single_client_parms_change;
	plugin_client_parms_decode = single_client_parms_decode;
	plugin_monster_team_switchable = single_monster_team_switchable;
	single_player_think_next = plugin_chain_player_think;
	plugin_chain_player_think = single_player_think;
	single_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = single_player_spawn;
	single_shutdown_next = plugin_chain_shutdown;
	plugin_chain_shutdown = single_shutdown;
	plugin_monster_killed = single_monster_killed;
	if (game_type == GAME_TYPE_SINGLE) {
		single_slowmo = 1;
		single_cmd_client_handle_next = plugin_chain_cmd_client_handle;
		plugin_chain_cmd_client_handle = single_cmd_client_handle;
		single_slowmo_update_mod_next = plugin_chain_slowmo_update_mod;
		plugin_chain_slowmo_update_mod = single_slowmo_update_mod;
	}
	entity e = spawn();
	e.targetname = "endlevel";
	e.use = single_endlevel;
	entity_initialize(world, single_init_delayed, INITPRIO_GAMETYPE);
}

void(void) single_secret_controller_use {
	single_secrets_found++;
	game_status_set("^2Secrets found: ^3{1}^2/^3{2}", 2, ftos(single_secrets_found), ftos(single_secrets_total), "");
}

void(void) single_secret_controller_reset {
	single_secrets_found = 0;
	single_monsters_killed = 0;
}

void(void) spawnfunc_single_secret {
	single_secrets_total++;
	self.noise = "misc/strength_respawn.wav";
	if (self.message == "") {
		self.message = "You found a secret area!";
	}
	self.spawnflags = self.spawnflags | TRIGGER_SPAWNFLAG_PLAYERONLY;
	if not(single_secrets_controller) {
		single_secrets_controller = spawn();
		single_secrets_controller.targetname = "single_secrets_controller";
		single_secrets_controller.use = single_secret_controller_use;
		single_secrets_controller.reset = single_secret_controller_reset;
	}
	self.target = "single_secrets_controller";
	spawnfunc_trigger_once();
}
