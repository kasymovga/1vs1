void(string item, string cmd) game_menu_send_item {
	net_write_string(MSG_ENTITY, item);
	net_write_string(MSG_ENTITY, cmd);
}

void(void) game_menu_send {
	gamehook_chain_gamemenu_send(game_menu_send_item);
	net_write_string(MSG_ENTITY, "");
}
