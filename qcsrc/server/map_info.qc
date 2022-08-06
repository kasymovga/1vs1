string(string s) map_info_fix_name {
	map_info_find_name(s);
	return map_info_find_name_match;
}

float(string s) map_info_get_game_types {
	float r;
	if (!map_info_get_by_name(s, 1, 0))
		return 0;

	r = map_info_map_supported_game_types;
	map_info_clear_temps();
	return r;
}
