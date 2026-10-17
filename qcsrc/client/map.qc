void(void) map_list_read {
	float i, n;
	for (i = 0; i < CMD_LSMAPS_REPLY_STRINGS_COUNT; i++) {
		str_unzone_ifneeded(gui_available_maps[i]);
		gui_available_maps_count[i] = 0;
	}
	for (i = 0; i < CMD_LSMAPS_REPLY_STRINGS_COUNT; i++) {
		gui_available_maps[i] = str_zone_ifneeded(net_read_string());
		string s = gui_available_maps[i];
		gui_available_maps_count[i] = 0;
		n = 0;
		while (s != "") {
			s = str_cdr(s);
			n++;
		}
		gui_available_maps_count[i] = n;
		gui_available_maps_count_total += n;
	}
}

