float single_level_finished;
float _single_transit_weapons;
float single_secrets_found;
float single_secrets_total;
float single_monsters_killed;
float single_monsters_total;
entity single_secrets_controller;

var void() single_shutdown_next;
void() single_shutdown {
	registercvar("_single_transit_weapons", "0");
	builtin_cvar_set("_single_transit_weapons", ftos(_single_transit_weapons | weapon_spawned_list | player_start_weapons)); //builting function for avoid campaign wrapper
	single_shutdown_next();
}

void(void) single_endlevel {
	// //This broke trigger_once
	//if (PLAYER_DEAD(activator))
	//	return;
	//
	single_level_finished = TRUE;
	entity e;
	FOR_EACH_PLAYER(e)
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
		string msg = strcat("^2Level finished\nSecrets: ", ftos(single_secrets_found), "/", ftos(single_secrets_total));
		msg = strcat(msg, "\nMonsters: ", ftos(single_monsters_killed), "/", ftos(single_monsters_total));
		return msg;
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
	float i, j;
	for(i = WEP_FIRST, j = 1; i < WEP_LAST; ++i, j *= 2) {
		if (_single_transit_weapons & j)
			weapon_precache(i);
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
	centerprint(self, "Autosaving...");
	localcmd(strcat("\nseta _slot_description11 \"", mapname, " - ", strftime(TRUE, "%Y %b %e %H:%M:%S")));
	localcmd(" \"\n");
	localcmd("save slot11.sav\nsaveconfig\n");
}

var float(void) single_player_equip_handle_next;
float(void) single_player_equip_handle {
	if (self.default_equip)
		return single_player_equip_handle_next();

	registercvar("_autosave_skip", "0");
	if (gametype == GAMETYPE_SINGLE)
	if (self.netaddress == "local")
	if not(builtin_cvar("_autosave_skip")) {
		defer(0.5, single_autosave);
	}
	builtin_cvar_set("_autosave_skip", "0");
	return TRUE;
}

float(void) single_map_restart {
	if (gametype == GAMETYPE_COOP) {
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

var void(entity) single_spawn_next;
void(entity e) single_spawn {
	self.default_equip = TRUE;
	single_spawn_next(e);
}

void(entity attacker) single_monster_killed {
	single_monsters_killed++;
	if (attacker.classname == "player")
		score_player_add(attacker, SP_SCORE, self.frags);
}

var float(string cmd, float tokens) single_cmd_client_handle_next;
float(string cmd, float tokens) single_cmd_client_handle {
	if (cmd == "quicksave") {
		centerprint(self, "Quicksaving...");
		localcmd(strcat("\nseta _slot_description12 \"", mapname, " - ", strftime(TRUE, "%Y %b %e %H:%M:%S")));
		localcmd(" \"\n");
		localcmd("save slot12.sav\nsaveconfig\n");
		return TRUE;
	}
	return single_cmd_client_handle_next(cmd, tokens);
}

void(void) single_init {
	hint_add("You can save/load game at any moment.");
	gamehook_map_restart = single_map_restart;
	gamehook_forbid_specatators = single_forbid_spectators;
	single_player_equip_handle_next = gamehook_chain_player_equip_handle;
	gamehook_chain_player_equip_handle = single_player_equip_handle;
	gamehook_winning_condition = single_winning_condition;
	gamehook_map_finish_message_mod = single_map_finish_message_mod;
	gamehook_player_death_handle = single_player_death_handle;
	gamehook_client_parms_new = single_client_parms_new;
	gamehook_client_parms_change = single_client_parms_change;
	gamehook_client_parms_decode = single_client_parms_decode;
	gamehook_monster_team_switchable = single_monster_team_switchable;
	single_player_think_next = gamehook_chain_player_think;
	gamehook_chain_player_think = single_player_think;
	single_spawn_next = gamehook_chain_spawn;
	gamehook_chain_spawn = single_spawn;
	single_shutdown_next = gamehook_chain_shutdown;
	gamehook_chain_shutdown = single_shutdown;
	gamehook_monster_killed = single_monster_killed;
	if (gametype == GAMETYPE_SINGLE) {
		single_cmd_client_handle_next = gamehook_chain_cmd_client_handle;
		gamehook_chain_cmd_client_handle = single_cmd_client_handle;
	}
	entity e = spawn();
	e.targetname = "endlevel";
	e.use = single_endlevel;
	entity_initialize(world, single_init_delayed, INITPRIO_GAMETYPE);
}

void(void) single_secret_controller_use {
	single_secrets_found++;
	gamestatus_set(strcat("^2Secrets found: ^3", ftos(single_secrets_found), "^2/^3", ftos(single_secrets_total)), 2);
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
