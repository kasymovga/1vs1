float g_warmup_limit;
float g_warmup_allguns;
float g_warmup_allow_timeout;
float warmup_start_health;
float warmup_start_armorvalue;
float warmup_start_ammo_shells;
float warmup_start_ammo_nails;
float warmup_start_ammo_rockets;
float warmup_start_ammo_cells;
float warmup_start_ammo_fuel;

void(void) warmup_note_message {
	if (!other.ready && (other.classname == "player" || other.team > 0))
		self.message = "^2Currently in ^1warmup^2 stage!\n^2Press ^3{ready}^2 to finish warmup!";
	else
		self.message = "^2Currently in ^1warmup^2 stage!\n^2Waiting for others to ready up...";
}

void(void) warmup_note_update {
	if (warmup_note)
		warmup_note.SendFlags = 1;
}

var void(entity ignore) warmup_spawn_next;
void(entity ignore) warmup_spawn {
	warmup_note_update();
	warmup_spawn_next(ignore);
}

var void(void) warmup_observer_spawn_next;
void(void) warmup_observer_spawn {
	warmup_note_update();
	warmup_observer_spawn_next();
}

var float(void) warmup_player_equip_handle_next;
float(void) warmup_player_equip_handle {
	if (warmup_player_equip_handle_next())
		return TRUE;

	if not(warmup_active)
		return FALSE;

	self.ammo_shells = warmup_start_ammo_shells;
	self.ammo_nails = warmup_start_ammo_nails;
	self.ammo_rockets = warmup_start_ammo_rockets;
	self.ammo_cells = warmup_start_ammo_cells;
	self.ammo_fuel = warmup_start_ammo_fuel;
	self.health = warmup_start_health;
	self.armorvalue = warmup_start_armorvalue;
	if (g_warmup_allguns)
		self.weapons = start_weapons | weapon_spawned_list;

	return TRUE;
}

var void(void) warmup_server_frame_next;
void(void) warmup_server_frame {
	warmup_server_frame_next();
	if not(warmup_active)
		return;

	// if in warmup stage and limit for warmup is hit start match
	if (warmup_active)
	if ((g_warmup_limit > 0 && time >= g_warmup_limit)
			|| (g_warmup_limit == 0 && cvar("timelimit") > 0 && time >= cvar("timelimit") * 60)) {

		ready_restart();
		return;
	}
}

void(void) warmup_init {
	float i;
	entity e;
	CACHE_CVAR(g_warmup_limit);
	CACHE_CVAR(g_warmup_allguns);
	CACHE_CVAR(g_warmup_allow_timeout);
	warmup_active = cvar("g_warmup");
	if (!GameHook_WarmupAllowed() || g_campaign)
		warmup_active = 0; // these modes cannot work together, sorry

	if not(warmup_active)
		return;

	warmup_spawn_next = gamehook_chain_spawn;
	gamehook_chain_spawn = warmup_spawn;
	warmup_observer_spawn_next = gamehook_chain_observer_spawn;
	gamehook_chain_observer_spawn = warmup_observer_spawn;
	warmup_server_frame_next = gamehook_chain_world_frame_start;
	gamehook_chain_world_frame_start = warmup_server_frame;
	warmup_note = NoteLine_New(warmup_note_message);
	warmup_note_update();
	warmup_player_equip_handle_next = gamehook_chain_player_equip_handle;
	gamehook_chain_player_equip_handle = warmup_player_equip_handle;
	warmup_start_ammo_shells = start_ammo_shells;
	warmup_start_ammo_nails = start_ammo_nails;
	warmup_start_ammo_rockets = start_ammo_rockets;
	warmup_start_ammo_cells = start_ammo_cells;
	warmup_start_ammo_fuel = start_ammo_fuel;
	warmup_start_health = start_health;
	warmup_start_armorvalue = start_armorvalue;
	if not(start_items & IT_UNLIMITED_WEAPON_AMMO) {
		warmup_start_ammo_shells = max(0, cvar("g_warmup_start_ammo_shells"));
		warmup_start_ammo_cells = max(0, cvar("g_warmup_start_ammo_cells"));
		warmup_start_ammo_nails = max(0, cvar("g_warmup_start_ammo_nails"));
		warmup_start_ammo_rockets = max(0, cvar("g_warmup_start_ammo_rockets"));
	}
	warmup_start_health = cvar("g_warmup_start_health");
	warmup_start_armorvalue = cvar("g_warmup_start_armor");
}

void(void) warmup_finish {
	if (warmup_active) {
		warmup_active = 0; //once the game is restarted the game is in match stage
		remove(warmup_note);
		sound_play2all("announcer/robotic/prepareforbattle.wav");
	}
}
