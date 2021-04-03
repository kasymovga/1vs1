void(void) single_hud {
	if (sbar_stat_items & IT_KEY1)
		drawpic (sbar_bottomleft - '-30 44 0', "gfx/hud/sb_kh_blue", '20 40', '1.125 1.125 0.75', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (sbar_stat_items & IT_KEY2)
		drawpic (sbar_bottomleft - '-58 44 0', "gfx/hud/sb_kh_yellow", '20 40', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	if (sbar_stat_items & IT_KEY3)
		drawpic (sbar_bottomleft - '-86 44 0', "gfx/hud/sb_kh_red", '20 40', '2 0.5 0.5', sbar_alpha_fg, DRAWFLAG_NORMAL);
}
