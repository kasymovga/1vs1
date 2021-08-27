void(string item, string cmd) gamemenu_send_item {
	net_write_string(MSG_ENTITY, item);
	net_write_string(MSG_ENTITY, cmd);
}

void(void) gamemenu_send {
	gamehook_chain_gamemenu_send(gamemenu_send_item);
	net_write_string(MSG_ENTITY, "");
}
