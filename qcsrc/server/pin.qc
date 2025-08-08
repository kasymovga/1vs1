string sv_pin_code;
float sv_pin_timeout;

entity pin_checkers;

void(entity e) pin_checker_remove {
	entity pin, pin2;
	if (pin_checkers.owner == e) {
		pin = pin_checkers;
		pin_checkers = pin_checkers.enemy;
		remove(pin);
		return;
	}
	for (pin = pin_checkers; pin.enemy; pin = pin.enemy) {
		if (pin.enemy.owner == e) {
			pin2 = pin.enemy.enemy;
			remove(pin.enemy);
			pin.enemy = pin2;
			return;
		}
	}
}

float(entity e) pin_checker_presents {
	entity pin;
	for (pin = pin_checkers; pin; pin = pin.enemy) {
		if (pin.owner == e) {
			return TRUE;
		}
	}
	return FALSE;
}

void(void) pin_checker_think2 {
	entity o = self.owner;
	pin_checker_remove(o);
	print_to(self.owner, PRINT_CHAT, "^1No correct PIN code in {1} seconds, disconnecting...", ftos(sv_pin_timeout), "", "");
	dropclient(o);
}

void(void) pin_checker_think {
	print_to(self.owner, PRINT_CHAT, "^1* This server required PIN-code to play", "", "", "");
	self.nextthink = max(self.cnt, time);
	self.think = pin_checker_think2;
}

var float(string cmd, float tokens) pin_cmd_client_handle_next;
float(string cmd, float tokens) pin_cmd_client_handle {
	if (cmd == "pin_code" && tokens == 2) {
		if (argv(1) == sv_pin_code) {
			pin_checker_remove(self);
			stuffcmd(self, strcat("set _cl_pin_code ", sv_pin_code, "\n"));
		}
		return TRUE;
	}
	return pin_cmd_client_handle_next(cmd, tokens);
}

float(entity to, float sf) pin_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_PIN_CODE_REQUEST);
	net_write_coord(MSG_ENTITY, self.cnt - time);
	return TRUE;
}

var void() pin_client_connect_real_next;
void() pin_client_connect_real {
	pin_checker_remove(self);
	if (self.netaddress != "local") {
		entity e = spawn();
		e.classname = "pin_checker";
		e.enemy = pin_checkers;
		e.owner = self;
		e.think = pin_checker_think;
		e.nextthink = time + 1;
		e.cnt = time + sv_pin_timeout;
		e.viewmodelforclient = e.owner;
		net_link_entity(e, FALSE, 0, pin_send);
		pin_checkers = e;
	}
	pin_client_connect_real_next();
}

var void() pin_client_disconnect_real_next;
var void() pin_client_disconnect_real {
	pin_checker_remove(self);
	pin_client_disconnect_real_next();
}

var float() pin_spectator_to_player_handle_next;
float() pin_spectator_to_player_handle {
	if (clienttype(self) == CLIENTTYPE_REAL) {
		if (pin_checker_presents(self))
			return TRUE;
	}
	return pin_spectator_to_player_handle_next();
}

void(void) pin_init {
	CVAR_CACHE_STR(sv_pin_code);
	if (sv_pin_code == "") return;
	CVAR_CACHE(sv_pin_timeout);
	float i, n = strlen(sv_pin_code);
	for (i = 0; i < n; i++)
		if (strstrofs("0123456789", substring(sv_pin_code, i, 1), 0) < 0) {
			print("Incorrect character in PIN code! Must be digits only\n");
			return;
		}
	pin_client_connect_real_next = plugin_chain_client_connect_real;
	plugin_chain_client_connect_real = pin_client_connect_real;
	pin_client_disconnect_real_next = plugin_chain_client_disconnect_real;
	plugin_chain_client_disconnect_real = pin_client_disconnect_real;
	pin_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = pin_cmd_client_handle;
	pin_spectator_to_player_handle_next = plugin_chain_spectator_to_player_handle;
	plugin_chain_spectator_to_player_handle = pin_spectator_to_player_handle;
}
