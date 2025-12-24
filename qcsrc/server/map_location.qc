entity location_request_list;

float(void) map_location_request_customize {
	if not(other == self.owner)
		return FALSE;

	return TRUE;
}

float(entity to, float sf) map_location_request_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_LOCATION_REQUEST);
	net_write_byte(MSG_ENTITY, sf & 255);
	if (sf & 1)
		net_write_string(MSG_ENTITY, self.netname);

	return TRUE;
}

.void(float x, float y) location_request_callback;
void(entity plr) map_location_request_clear {
	entity e;
	for (e = location_request_list; e; e = e.enemy) {
		if (e.owner == plr) {
			remove(e);
			return;
		}
	}
}

var float(string cmd, float argc) map_location_cmd_client_handle_next;
float(string cmd, float argc) map_location_cmd_client_handle {
	if (cmd == "location_select" && argc == 3) {
		entity e;
		for (e = location_request_list; e; e = e.enemy) {
			if (e.owner == self) {
				e.location_request_callback(stof(argv(1)), stof(argv(2)));
				break;
			}
		}
		return TRUE;
	}
	return map_location_cmd_client_handle_next(cmd, argc);
}

float map_location_init_done;
void(void) map_location_init {
	map_location_cmd_client_handle_next = plugin_chain_cmd_client_handle;
	plugin_chain_cmd_client_handle = map_location_cmd_client_handle;
}

entity(entity plr, string title, void(float x, float y)callback) map_location_request {
	if not(map_location_init_done) {
		map_location_init_done = TRUE;
		map_location_init();
	}
	map_location_request_clear(plr);
	entity e = spawn();
	e.netname = title;
	e.owner = plr;
	e.location_request_callback = callback;
	e.customizeentityforclient = map_location_request_customize;
	e.enemy = location_request_list;
	location_request_list = e;
	net_link_entity(e, FALSE, 0, map_location_request_send);
	return e;
}
