#define ABILITY_COUNT_MAX 20
string ability_names[ABILITY_COUNT_MAX];
float ability_count;
var void(entity e, string args, float set) ability_initiators[ABILITY_COUNT_MAX];
float ability_classes_count;
string ability_class_names[MENU_ITEMS_MAXCOUNT];
string ability_class_values[MENU_ITEMS_MAXCOUNT];
string ability_class_model_list_allowed[MENU_ITEMS_MAXCOUNT];
float g_ability_class_default;
float g_ability_kill_on_change;
float ability_class_model_list_allowed_not_empty;

void(entity e, string al, float ac) ability_class_init {
	string an, tail, args;
	tail = al;
	float i, j, eq;
	float oldabilities = 0;
	if (e) {
		oldabilities = e.abilities;
		e.abilities = 0;
		if (e.body && ability_class_model_list_allowed_not_empty)
			if (e.body.playermodel != player_body_model_allowed(e.body.playermodel))
				e.body.playermodel = ""; //force recheck model
	}
	while (tail != "") {
		an = str_car(tail);
		eq = strstrofs(an, "=", 0);
		if (eq > 0) {
			args = an;
			an = substring(an, 0, eq);
			args = substring(args, eq + 1, -1);
		} else {
			args = "";
		}
		if (an == "weapons") {
			if (e) {
				e.weapons = 0;
				e.weapons_extra = 0;
			}
			args = strreplace(",", " ", args);
			entity we;
			string wn;
			while ((wn = str_car(args)) != "") {
				args = str_cdr(args);
				we = weapon_info_by_name(wn);
				if (e) {
					e.weapons |= we.weapons;
					e.weapons_extra |= we.weapons_extra;
				} else
					weapon_precache(we.weapon);
			}
		} else if (an == "armor") {
			if (e) e.armorvalue = stof(args);
		} else if (an == "health") {
			if (e) e.health = stof(args);
		} else if (substring(an, 0, 4) == "ammo_") {
			if (e) {
				if (an == "ammo_nails")
					e.ammo_nails = stof(args);
				else if (an == "ammo_shells")
					e.ammo_shells = stof(args);
				else if (an == "ammo_rockets")
					e.ammo_rockets = stof(args);
				else if (an == "ammo_cells")
					e.ammo_cells = stof(args);
			}
		} else if (an == "viewoffsets") {
			if (e) {
				args = strreplace(",", " ", args);
				float ofs_stand = stof(str_car(args));
				float ofs_crouch = stof(str_cdr(args));
				physics_set_view_offsets(e, ofs_stand * '0 0 1', ofs_crouch * '0 0 1');
			}
		} else if (an == "model") {
			if not(e) {
				args = strreplace(",", " ", args);
				ability_class_model_list_allowed_not_empty = TRUE;
				str_unzone_ifneeded(ability_class_model_list_allowed[ac]);
				ability_class_model_list_allowed[ac] = str_zone_ifneeded(args);
				player_body_precache(args);
			}
		} else {
			for (i = 0, j = 1; i < ability_count; i++, j *= 2) {
				if (ability_names[i] == an) {
					if (e) {
						e.abilities |= j;
					}
					ability_initiators[i](e, strreplace(",", " ", args), TRUE);
					break;
				}
			}
			if (i == ability_count) {
				print("Unknown ability: ", an, "\n");
			}
		}
		tail = str_cdr(tail);
	}
	if (oldabilities)
		for (i = 0, j = 1; i < ability_count; i++, j *= 2)
			if (oldabilities & j)
			if not(e.abilities & j)
				ability_initiators[i](e, "", FALSE);
}

void(float s) ability_class_select {
	if (s >= 0 && s < ability_classes_count) {
		menu_remove_for(self, "ability");
		if (self.ability_class == s + 1)
			return;

		self.ability_class = s + 1;
		if (self.classname != "player" && self.team <= 0) {
			ability_class_init(self, ability_class_values[self.ability_class - 1], self.ability_class); //early call to workaround some issues with delayed ability flags
			spectator_to_player();
		} else if (g_ability_kill_on_change) {
			client_kill_now(self, 0);
		} else
			centerprint(self, cvar_string("g_ability_switch_message"));
	}
}

void(entity e) ability_class_menu {
	menu_remove_for(e, "ability");
	entity m = menu_prepare(e, "ability", cvar_string("g_ability_message"), 0, ability_class_select);
	menu_set_flags(m, MENU_FLAG_ESCAPEABLE | MENU_FLAG_HIDE_AFTER_SELECT);
	string s;
	float ac = e.ability_class - 1;
	for (float i = 0; i < ability_classes_count; i++) {
		s = ability_class_names[i];
		if (ac == i) s = strcat(s, " (*)");
		menu_add_item(m, s);
	}
}

var float(void) ability_spectator_to_player_handle_next;
float(void) ability_spectator_to_player_handle {
	if not(self.ability_class) {
		self.abilities = 0;
		if (g_ability_class_default >= 0)
			self.ability_class = g_ability_class_default + 1;
		else if (clienttype(self) == CLIENTTYPE_REAL) {
			ability_class_menu(self);
			return TRUE;
		}
	}
	return ability_spectator_to_player_handle_next();
}

var void(entity spot) ability_player_spawn_next;
void(entity spot) ability_player_spawn {
	if (!self.ability_class)
		self.ability_class = floor(random() * ability_classes_count) + 1;

	ability_class_init(self, ability_class_values[self.ability_class - 1], self.ability_class);
	ability_player_spawn_next(spot);
}

var void(void(string item, string cmd) Add_Item) ability_gamemenu_send_next;
void(void(string item, string cmd) Add_Item) ability_gamemenu_send {
	Add_Item(cvar_string("g_ability_switch_title"), "cmd pickabilityclass;");
	ability_gamemenu_send_next(Add_Item);
}

var float(string cmd, float tokens) ability_cmd_client_handle_next;
float(string cmd, float tokens) ability_cmd_client_handle {
	if (cmd == "pickabilityclass") {
		ability_class_menu(self);
		return TRUE;
	}
	return ability_cmd_client_handle_next(cmd, tokens);
}

var string(string l) ability_player_body_model_list_allowed_next;
string(string l) ability_player_body_model_list_allowed {
	string s;
	if (self.ability_class > 0) {
		s = ability_class_model_list_allowed[self.ability_class - 1];
		if (s != "")
			return ability_player_body_model_list_allowed_next(s);
	}
	return ability_player_body_model_list_allowed_next(l);
}

void(void) ability_init_delayed {
	float i;
	string an, av;
	for (i = 0; i < MENU_ITEMS_MAXCOUNT; i++) {
		an = cvar_string(strcat("g_ability_class", ftos(i), "_name"));
		av = cvar_string(strcat("g_ability_class", ftos(i), "_value"));
		if (an == "" || av == "") break;
		ability_class_names[i] = strzone(an);
		ability_class_values[i] = strzone(av);
		ability_class_init(NULL, av, i);
	}
	ability_classes_count = i;
	if not(ability_classes_count)
		return;

	ability_spectator_to_player_handle_next = plugin_chain_spectator_to_player_handle;
	plugin_chain_spectator_to_player_handle = ability_spectator_to_player_handle;
	ability_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = ability_player_spawn;
	ability_gamemenu_send_next = plugin_chain_gamemenu_send;
	plugin_chain_gamemenu_send = ability_gamemenu_send;
	ability_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = ability_cmd_client_handle;
	ability_player_body_model_list_allowed_next = plugin_chain_player_body_model_list_allowed_mod;
	plugin_chain_player_body_model_list_allowed_mod = ability_player_body_model_list_allowed;
}

void(void) ability_init {
	entity_initialize(NULL, ability_init_delayed, INITPRIO_GAMETYPE);
	CVAR_CACHE(g_ability_class_default);
	CVAR_CACHE(g_ability_kill_on_change);
}

float(string n) ability_flag {
	float i, j;
	for (i = 0, j = 1; i < ability_count; i++, j *= 2) {
		if (ability_names[i] == n)
			return j;
	}
	return 0;
}

void(entity e, string args, float set) ability_dummy_init {
}

float(string n, void(entity e, string args, float set) init_func) ability_register {
	if (ability_count >= ABILITY_COUNT_MAX)
		error("Too much abilitities");

	float f = ability_flag(n);
	if not(init_func) {
		init_func = ability_dummy_init;
	}
	if (f) return f;
	f = 1 << ability_count;
	ability_names[ability_count] = strzone(n);
	ability_initiators[ability_count] = init_func;
	ability_count++;
	return f;
}
