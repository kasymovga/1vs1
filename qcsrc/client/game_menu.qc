void(void) game_menu_read {
	float i;
	string s;
	for (i = 0; i < GAME_MENU_ITEMS_COUNT_MAX; i++) {
		str_unzone_ifneeded(game_menu_items[i]);
		str_unzone_ifneeded(game_menu_commands[i]);
	}
	for (i = 0; i < GAME_MENU_ITEMS_COUNT_MAX; i++) {
		s = net_read_string();
		if (s == "")
			break;

		game_menu_items[i] = str_zone_ifneeded(translate(s));
		game_menu_commands[i] = str_zone_ifneeded(net_read_string());
	}
	game_menu_commands_count = i;
}
