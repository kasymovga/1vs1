void(void) gamemenu_read {
	float i;
	string s;
	for (i = 0; i < GAMEMENU_ITEMS_COUNT_MAX; i++) {
		if (gamemenu_items[i] != "") {
			strunzone(gamemenu_items[i]);
			strunzone(gamemenu_commands[i]);
		}
	}
	for (i = 0; i < GAMEMENU_ITEMS_COUNT_MAX; i++) {
		s = net_read_string();
		if (s == "")
			break;

		gamemenu_items[i] = strzone(s);
		gamemenu_commands[i] = strzone(net_read_string());
	}
	gamemenu_commands_count = i;
}
