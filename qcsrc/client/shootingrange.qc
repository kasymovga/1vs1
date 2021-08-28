float shootingrange_round_start;
float shootingrange_round_time;

void(float _ignore) shootingrange_read {
	shootingrange_round_start = net_read_coord();
	shootingrange_round_time = net_read_short();
}

void(void) shootingrange_hud {
	entity me = (view_spectatee_status > 0) ? player_slots[view_spectatee_status - 1] : player_slots[player_localentnum - 1];
	vector pos = sbar_position(CVAR(sbar_gameinfo_position), '96 48 0' * CVAR(sbar_gameinfo_scale));
	float score = me.(scores[ps_secondary]);
	sbar_draw_num(pos, score, 3, 0, 32 * CVAR(sbar_gameinfo_scale), '1 1 0.5', 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
	if (shootingrange_round_start) {
		pos_y += 34 * CVAR(sbar_gameinfo_scale);
		float t = (shootingrange_round_start + shootingrange_round_time) - server_time;
		float w = 92 * (t / shootingrange_round_time) * CVAR(sbar_gameinfo_scale);
		pos_x += (92 - w) * 0.5 + 2 * CVAR(sbar_gameinfo_scale);
		vector r = '1 0 0' * w + '0 12 0' * CVAR(sbar_gameinfo_scale);
		drawfill(pos, r, '1 1 0.5', 0.5, DRAWFLAG_NORMAL);
		draw_borderlines(1, pos, r, '0 0 0', 1, DRAWFLAG_NORMAL);
	}
}
