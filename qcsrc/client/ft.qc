void(vector pos, vector gameinfo_size, float gameinfo_scale) ft_hud {
	rm_hud_game_info_enabled = TRUE;
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '196 48 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	if not(team_count_no_spectator) return;
	vector fs = '1 1 0' * gameinfo_size_y / team_count_no_spectator;
	//draw_borderlines(2, pos, '196 48 0' * gameinfo_scale, '0 1 0', 1, DRAWFLAG_NORMAL);
	vector v = '160 0 0' * gameinfo_scale;
	if (team_slots[COLOR_TEAM1]) {
		drawcolorcodedstring(pos, "^1Red alive^7: ", fs, 1, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + v, ftos(team_alive_red), fs, 1, DRAWFLAG_NORMAL);
		pos_y += fs_y;
	}
	if (team_slots[COLOR_TEAM2]) {
		drawcolorcodedstring(pos, "^4Blue alive^7: ", fs, 1, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + v, ftos(team_alive_blue), fs, 1, DRAWFLAG_NORMAL);
		pos_y += fs_y;
	}
	if (team_slots[COLOR_TEAM3]) {
		drawcolorcodedstring(pos, "^3Yellow alive^7: ", fs, 1, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + v, ftos(team_alive_yellow), fs, 1, DRAWFLAG_NORMAL);
		pos_y += fs_y;
	}
	if (team_slots[COLOR_TEAM4]) {
		drawcolorcodedstring(pos, "^6Yellow alive^7: ", fs, 1, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + v, ftos(team_alive_pink), fs, 1, DRAWFLAG_NORMAL);
	}
}
