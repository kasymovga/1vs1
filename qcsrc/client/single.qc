void(vector gameinfo_position, float gameinfo_scale) single_hud {
	vector pos = sbar_position(gameinfo_position, '136 48 0' * gameinfo_scale);
	if (sbar_stat_items & IT_KEY1)
		drawpic(pos + '30 4 0' * gameinfo_scale, "gfx/hud/sb_kh_blue", '20 40 0' * gameinfo_scale, '1.125 1.125 0.75', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (sbar_stat_items & IT_KEY2)
		drawpic(pos + '58 4 0' * gameinfo_scale, "gfx/hud/sb_kh_yellow", '20 40 0' * gameinfo_scale, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (sbar_stat_items & IT_KEY3)
		drawpic(pos + '86 4 0' * gameinfo_scale, "gfx/hud/sb_kh_red", '20 40 0' * gameinfo_scale, '2 0.5 0.5', sbar_alpha_fg, DRAWFLAG_NORMAL);
}
