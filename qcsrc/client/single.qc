void(vector pos, vector gameinfo_size, float gameinfo_scale) single_hud {
	float secrets_total = getstati(STAT_TOTALSECRETS);
	float have_keys = (sbar_stat_items & IT_KEYS);
	if not((rm_hud_game_info_enabled = (!view_observer_status && (have_keys || secrets_total))))
		return;

	if (rm_skin_loaded) {
		//RM HUD sector size is really thin
		SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '176 48 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	} else {
		SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '88 48 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	}
	if (have_keys) {
		vector v1, v2, v3;
		if (rm_skin_loaded) {
			if (secrets_total)
				v1 = '4 4 0' * gameinfo_scale;
			else
				v1 = '48 4 0' * gameinfo_scale;

			v2 = '20 40 0' * gameinfo_scale;
			v3 = '28 0 0' * gameinfo_scale;
		} else {
			if (secrets_total) {
				v1 = '14 4 0' * gameinfo_scale;
				v2 = '15 30 0' * gameinfo_scale;
				v3 = '28 0 0' * gameinfo_scale;
			} else {
				v1 = '8 4 0' * gameinfo_scale;
				v2 = '20 40 0' * gameinfo_scale;
				v3 = '28 0 0' * gameinfo_scale;
			}
		}
		if (sbar_stat_items & IT_KEY1)
			drawpic(pos + v1, "gfx/hud/sb_kh_blue", v2, '1.125 1.125 0.75', sbar_alpha_fg, DRAWFLAG_NORMAL);

		if (sbar_stat_items & IT_KEY2)
			drawpic(pos + (v1 + v3), "gfx/hud/sb_kh_yellow", v2, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

		if (sbar_stat_items & IT_KEY3)
			drawpic(pos + (v1 + v3 * 2), "gfx/hud/sb_kh_red", v2, '2 0.5 0.5', sbar_alpha_fg, DRAWFLAG_NORMAL);
	}
	if (secrets_total) {
		vector v1, v2;
		float icon_scale;
		string s = strcat(ftos(getstati(STAT_SECRET)), "/", ftos(secrets_total));
		if (rm_skin_loaded) {
			if (have_keys) {
				icon_scale = 2;
				v1 = '98 12 0';
				v2 = '20 20 0';
			} else {
				icon_scale = 2;
				v1 = '40 9 0';
				v2 = '30 30 0';
			}
		} else {
			if (have_keys) {
				v1 = '24 36 0';
				v2 = '12 12 0';
				icon_scale = 1.5;
			} else {
				v1 = '14 18 0';
				v2 = '16 16 0';
				icon_scale = 2;
			}
		}
		v1 -= v2_x * '0.4 0 0' * (strlen(s) - 3);
		drawpic(pos + (v1 - v2_y * '0 0.5 0' * (icon_scale - 1)) * gameinfo_scale, "gfx/hud/single/secret", v2 * gameinfo_scale * icon_scale, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawstring(pos + (v1 + v2_x * '1 0 0' * icon_scale) * gameinfo_scale, strcat(
				ftos(getstati(STAT_SECRET)), "/", ftos(secrets_total)), v2 * gameinfo_scale, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	}
}
