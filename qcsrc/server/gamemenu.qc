void(string item, string cmd) gamemenu_send_item {
	WriteString(MSG_ENTITY, item);
	WriteString(MSG_ENTITY, cmd);
}

void(void) gamemenu_send {
	gamehook_chain_gamemenu_send(gamemenu_send_item);
	WriteString(MSG_ENTITY, "");
}
