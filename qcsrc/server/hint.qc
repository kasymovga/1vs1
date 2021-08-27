float hint_count;
float sv_hints;

void(string hint) hint_add {
	if (hint_count >= 100)
		return;

	float i;
	for (i = 0; i < hint_count; i++) {
		if (cvar_string(strcat("_hint", ftos(i))) == hint)
			return;
	}
	string s = strcat("_hint", ftos(hint_count));
	registercvar(s, hint);
	cvar_set(s, hint);
	hint_count++;
}

void(float n, float p) hint_send {
	msg_entity = self;
	if (hint_count <= 0) {
		net_write_byte(MSG_ONE, SVC_TEMPENTITY);
		net_write_byte(MSG_ONE, NET_TE_CSQC_HINT);
		net_write_byte(MSG_ONE, p);
		net_write_byte(MSG_ONE, 0);
		net_write_string(MSG_ONE, "This game mode not have any hints.");
		return;
	}
	if (n < 0)
		n = hint_count - 1;

	if (n >= hint_count)
		n = 0;

	string s = cvar_string(strcat("_hint", ftos(n)));
	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_HINT);
	net_write_byte(MSG_ONE, p);
	net_write_byte(MSG_ONE, n);
	net_write_string(MSG_ONE, s);
}

var void(void(string item, string cmd) Add_Item) hint_gamemenu_send_next;
void hint_gamemenu_send(void(string item, string cmd) item_add) {
	item_add("Hints", "cmd hint 0;");
	hint_gamemenu_send_next(item_add);
}

var void(void) hint_client_connect_real_next;
void(void) hint_client_connect_real {
	if (hint_count > 0) {
		if (sv_hints > 1)
			hint_send(floor(random() * hint_count), 0);
	}
	hint_client_connect_real_next();
}

var float(string cmd, float tokens) hint_ClientCommandHandle_next;
float(string cmd, float tokens) hint_ClientCommandHandle {
	if (cmd == "hint" && tokens == 2) {
		hint_send(stof(argv(1)), 1);
		return TRUE;
	}
	return hint_ClientCommandHandle_next(cmd, tokens);
}

void(void) hint_init {
	CVAR_CACHE(sv_hints);
	hint_client_connect_real_next = gamehook_chain_client_connect_real;
	gamehook_chain_client_connect_real = hint_client_connect_real;
	hint_gamemenu_send_next = gamehook_chain_gamemenu_send;
	gamehook_chain_gamemenu_send = hint_gamemenu_send;
	hint_ClientCommandHandle_next = gamehook_chain_cmd_client_handle;
	gamehook_chain_cmd_client_handle = hint_ClientCommandHandle;
}
