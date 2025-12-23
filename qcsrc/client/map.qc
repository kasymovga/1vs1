void(void) map_list_read {
	str_unzone_ifneeded(gui_available_maps);
	gui_available_maps = str_zone_ifneeded(net_read_string());
	string s = gui_available_maps;
	gui_available_maps_count = 0;
	while (s != "") {
		s = str_cdr(s);
		gui_available_maps_count++;
	}
}

