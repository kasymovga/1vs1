float shootingrange_round_start;
float shootingrange_round_time;

void(float _ignore) shootingrange_read {
	shootingrange_round_start = net_read_coord();
	shootingrange_round_time = net_read_short();
}

void(vector pos, vector gameinfo_size, float gameinfo_scale) shootingrange_hud {
	entity me = (view_spectatee_status > 0) ? player_slots[view_spectatee_status - 1] : player_slots[player_localentnum - 1];
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '96 48 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	float score = me.(scores[ps_secondary]);
	sbar_draw_num(pos, score, 3, 0, 32 * gameinfo_scale, '1 1 0.5', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
	if (shootingrange_round_time) {
		pos_y += 34 * gameinfo_scale;
		float t = (shootingrange_round_start + shootingrange_round_time) - server_time;
		float w = 92 * (t / shootingrange_round_time) * gameinfo_scale;
		pos_x += (92 - w) * 0.5 + 2 * gameinfo_scale;
		vector r = '1 0 0' * w + '0 12 0' * gameinfo_scale;
		drawfill(pos, r, '1 1 0.5', 0.5, DRAWFLAG_NORMAL);
		draw_borderlines(1, pos, r, '0 0 0', 1, DRAWFLAG_NORMAL);
	}
}
