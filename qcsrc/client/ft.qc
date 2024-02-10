void(vector pos, vector gameinfo_size, float gameinfo_scale) ft_hud {
	rm_hud_game_info_enabled = TRUE;
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '144 32 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	if (team_alive_update) {
		team_alive_red = 0;
		team_alive_blue = 0;
		team_alive_yellow = 0;
		team_alive_pink = 0;
		entity o;
		for (o = player_list.sort_next; o; o = o.sort_next)
			if (o.gotscores)
			if not(o.scores[SP_STATUS_FIELD]) {
				if (o.team == COLOR_TEAM1) team_alive_red++;
				else if (o.team == COLOR_TEAM2) team_alive_blue++;
				else if (o.team == COLOR_TEAM3) team_alive_yellow++;
				else if (o.team == COLOR_TEAM4) team_alive_pink++;
			}
		team_alive_update = 0;
	}
	if not(team_count_no_spectator) return;
	RM({
		float i = 0;
		if (team_count_no_spectator == 2) {
			vector fs = '32 32 0' * gameinfo_scale;
			if (team_slots[COLOR_TEAM1]) {
				sbar_draw_num(pos, team_alive_red, ((team_alive_red > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM1) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				i++;
			}
			if (team_slots[COLOR_TEAM2]) {
				if (i) {
					sbar_draw_num(pos + '80 0 0' * gameinfo_scale, team_alive_blue, 2, 0, fs_x, team_rgb(COLOR_TEAM2) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					return;
				} else
					sbar_draw_num(pos, team_alive_blue, ((team_alive_blue > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM2) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);

				i++;
			}
			if (team_slots[COLOR_TEAM3]) {
				if (i) {
					sbar_draw_num(pos + '80 0 0' * gameinfo_scale, team_alive_yellow, 2, 0, fs_x, team_rgb(COLOR_TEAM3) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					return;
				} else
					sbar_draw_num(pos, team_alive_yellow, ((team_alive_yellow > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM3) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);

				i++;
			}
			if (team_slots[COLOR_TEAM4]) {
				if (i) {
					sbar_draw_num(pos + '80 0 0' * gameinfo_scale, team_alive_pink, 2, 0, fs_x, team_rgb(COLOR_TEAM4) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				} else
					sbar_draw_num(pos, team_alive_pink, ((team_alive_pink > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM4) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
		} else {
			vector fs = '16 16 0' * gameinfo_scale;
			if (team_slots[COLOR_TEAM1]) {
				sbar_draw_num(pos, team_alive_red, ((team_alive_red > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM1) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
			if (team_slots[COLOR_TEAM2]) {
				sbar_draw_num(pos + '0 16 0' * gameinfo_scale, team_alive_blue, ((team_alive_blue > 9) ? 2 : 1), 0, fs_x, team_rgb(COLOR_TEAM2) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
			if (team_slots[COLOR_TEAM3]) {
				sbar_draw_num(pos + '112 0 0' * gameinfo_scale, team_alive_yellow, 2, 0, fs_x, team_rgb(COLOR_TEAM3) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
			if (team_slots[COLOR_TEAM4]) {
				sbar_draw_num(pos + '112 16 0' * gameinfo_scale, team_alive_pink, 2, 0, fs_x, team_rgb(COLOR_TEAM4) * 0.8 + '0.2 0.2 0.2', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
		}
		return;
	})
	vector fs = '32 32 0' * gameinfo_scale / team_count_no_spectator;
	//draw_borderlines(2, pos, '196 48 0' * gameinfo_scale, '0 1 0', 1, DRAWFLAG_NORMAL);
	vector v = '104 0 0' * gameinfo_scale;
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
