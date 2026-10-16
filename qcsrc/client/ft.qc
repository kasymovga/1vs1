void(vector pos, vector gameinfo_size, float gameinfo_scale) ft_hud {
	rm_hud_game_info_enabled = TRUE;
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '144 32 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	if not(team_count_no_spectator) return;
	float i = 0;
	float stroke, colorfactor;
	if (rm_skin_loaded) {
		stroke = FALSE;
		colorfactor = 0.8;
	} else {
		stroke = TRUE;
		pos += '144 32 0' * 0.125;
		gameinfo_scale *= 0.75;
		colorfactor = 1;
	}
	if (team_count_no_spectator == 2) {
		vector fs = '32 32 0' * gameinfo_scale;
		if (team_slots[COLOR_TEAM1]) {
			sbar_draw_num(pos, team_alive_red, ((team_alive_red > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM1) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
			i++;
		}
		if (team_slots[COLOR_TEAM2]) {
			if (i) {
				sbar_draw_num(pos + '80 0 0' * gameinfo_scale, team_alive_blue, 2, 0, fs_x, team_rgb(COLOR_TEAM2) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
				return;
			} else
				sbar_draw_num(pos, team_alive_blue, ((team_alive_blue > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM2) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);

			i++;
		}
		if (team_slots[COLOR_TEAM3]) {
			if (i) {
				sbar_draw_num(pos + '80 0 0' * gameinfo_scale, team_alive_yellow, 2, 0, fs_x, team_rgb(COLOR_TEAM3) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
				return;
			} else
				sbar_draw_num(pos, team_alive_yellow, ((team_alive_yellow > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM3) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);

			i++;
		}
		if (team_slots[COLOR_TEAM4]) {
			if (i) {
				sbar_draw_num(pos + '80 0 0' * gameinfo_scale, team_alive_pink, 2, 0, fs_x, team_rgb(COLOR_TEAM4) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
			} else
				sbar_draw_num(pos, team_alive_pink, ((team_alive_pink > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM4) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
	} else {
		vector fs = '16 16 0' * gameinfo_scale;
		if (team_slots[COLOR_TEAM1]) {
			sbar_draw_num(pos, team_alive_red, ((team_alive_red > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM1) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
		if (team_slots[COLOR_TEAM2]) {
			sbar_draw_num(pos + '0 16 0' * gameinfo_scale, team_alive_blue, ((team_alive_blue > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM2) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
		if (team_slots[COLOR_TEAM3]) {
			sbar_draw_num(pos + '112 0 0' * gameinfo_scale, team_alive_yellow, 2, 0, fs_x, team_rgb(COLOR_TEAM3) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
		if (team_slots[COLOR_TEAM4]) {
			sbar_draw_num(pos + '112 16 0' * gameinfo_scale, team_alive_pink, 2, 0, fs_x, team_rgb(COLOR_TEAM4) * colorfactor + '0.2 0.2 0.2', stroke, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
	}
	return;
}
