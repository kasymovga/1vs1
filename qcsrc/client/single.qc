void(vector pos, vector gameinfo_size, float gameinfo_scale) single_hud {
	if not((rm_hud_game_info_enabled = (sbar_stat_items & IT_KEYS)))
		return;

	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '136 48 0', gameinfo_size)
	if (sbar_stat_items & IT_KEY1)
		drawpic(pos + '30 4 0' * gameinfo_scale, "gfx/hud/sb_kh_blue", '20 40 0' * gameinfo_scale, '1.125 1.125 0.75', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (sbar_stat_items & IT_KEY2)
		drawpic(pos + '58 4 0' * gameinfo_scale, "gfx/hud/sb_kh_yellow", '20 40 0' * gameinfo_scale, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (sbar_stat_items & IT_KEY3)
		drawpic(pos + '86 4 0' * gameinfo_scale, "gfx/hud/sb_kh_red", '20 40 0' * gameinfo_scale, '2 0.5 0.5', sbar_alpha_fg, DRAWFLAG_NORMAL);
}
