#define ABILITY_COUNT_MAX 20
string ability_names[ABILITY_COUNT_MAX];
float ability_count;
var void(entity e, string args) ability_initiators[ABILITY_COUNT_MAX];
float ability_classes_count;
string ability_class_names[MENU_ITEMS_MAXCOUNT];
string ability_class_values[MENU_ITEMS_MAXCOUNT];
.float ability_class;

void(entity e, string al) ability_class_init {
	string an, tail, args;
	tail = al;
	float i, j, eq;
	float oldabilities = 0;
	if (e) {
		oldabilities = e.abilities;
		e.abilities = 0;
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
			if (e)
				e.weapons = 0;

			args = strreplace(",", " ", args);
			entity we;
			string wn;
			while ((wn = str_car(args)) != "") {
				args = str_cdr(args);
				we = weapon_info_by_name(wn);
				if (e)
					e.weapons |= we.weapons;
				else
					weapon_precache(we.weapon);
			}
		} else if (an == "armor") {
			e.armorvalue = stof(args);
		} else if (an == "health") {
			e.health = stof(args);
		} else if (substring(an, 0, 4) == "ammo") {
			if (an == "ammo_nails")
				e.ammo_nails = stof(args);
			else if (an == "ammo_shells")
				e.ammo_shells = stof(args);
			else if (an == "ammo_rockets")
				e.ammo_rockets = stof(args);
			else if (an == "ammo_cells")
				e.ammo_cells = stof(args);
		} else {
			for (i = 0, j = 1; i < ability_count; i++, j *= 2) {
				if (ability_names[i] == an) {
					if (e) {
						e.abilities |= j;
					}
					ability_initiators[i](e, args);
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
				ability_initiators[i](e, "");
}

void(float s) ability_class_select {
	if (s >= 0 && s < ability_classes_count) {
		self.ability_class = s + 1;
		menu_remove_for(self, "ability");
		if (self.classname != "player" && self.team <= 0) {
			ability_class_init(self, ability_class_values[self.ability_class - 1]); //early call to workaround some issues with delayed ability flags
			spectator_to_player();
		} else
			centerprint(self, "^7Your ability class will be changed at next spawn\n");
	}
}

void(entity e) ability_class_menu {
	menu_remove_for(e, "ability");
	entity m = menu_prepare(e, "ability", "Please select your ability class:", 0, ability_class_select);
	for (float i = 0; i < ability_classes_count; i++) {
		menu_add_item(m, ability_class_names[i]);
	}
}

var float(void) ability_spectator_to_player_handle_next;
float(void) ability_spectator_to_player_handle {
	if not(self.ability_class) {
		self.abilities = 0;
		if (clienttype(self) == CLIENTTYPE_REAL) {
			ability_class_menu(self);
			return TRUE;
		} else {
			self.ability_class = 1;
		}
	}
	return ability_spectator_to_player_handle_next();
}

var void(entity spot) ability_player_spawn_next;
void(entity spot) ability_player_spawn {
	ability_class_init(self, ability_class_values[self.ability_class - 1]);
	ability_player_spawn_next(spot);
}

var void(void(string item, string cmd) Add_Item) ability_gamemenu_send_next;
void(void(string item, string cmd) Add_Item) ability_gamemenu_send {
	Add_Item("Switch Ability Class", "cmd pickabilityclass;");
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

void(void) ability_init_delayed {
	float i;
	string an, av;
	for (i = 0; i < MENU_ITEMS_MAXCOUNT; i++) {
		an = cvar_string(strcat("g_ability_class", ftos(i), "_name"));
		av = cvar_string(strcat("g_ability_class", ftos(i), "_value"));
		if (an == "" || av == "") break;
		ability_class_names[i] = strzone(an);
		ability_class_values[i] = strzone(av);
		ability_class_init(NULL, av);
	}
	ability_classes_count = i;
	if not(ability_classes_count)
		return;

	ability_spectator_to_player_handle_next = gamehook_chain_spectator_to_player_handle;
	gamehook_chain_spectator_to_player_handle = ability_spectator_to_player_handle;
	ability_player_spawn_next = gamehook_chain_player_spawn;
	gamehook_chain_player_spawn = ability_player_spawn;
	ability_gamemenu_send_next = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = ability_gamemenu_send;
	ability_cmd_client_handle_next = gamehook_chain_cmd_client_handle;
	gamehook_chain_cmd_client_handle = ability_cmd_client_handle;
}

void(void) ability_init {
	entity_initialize(NULL, ability_init_delayed, INITPRIO_GAMETYPE);
}

float(string n) ability_flag {
	float i, j;
	for (i = 0, j = 1; i < ability_count; i++, j *= 2) {
		if (ability_names[i] == n)
			return j;
	}
	return 0;
}

float(string n, void(entity e, string args) init_func) ability_register {
	if (ability_count >= ABILITY_COUNT_MAX)
		error("Too much abilitities");

	float f = ability_flag(n);
	if (f) return f;
	f = 1 << ability_count;
	ability_names[ability_count] = strzone(n);
	ability_initiators[ability_count] = init_func;
	ability_count++;
	return f;
}
