float kh_runheretime;

void(void) kh_hud_reset {
	kh_runheretime = 0;
}

void(vector gameinfo_position, float gameinfo_scale) kh_hud {
	float kh_keys;
	float keyteam;
	float a, aa;
	vector p, pa, kh_size, kh_asize;
	vector pos = sbar_position(gameinfo_position, '108 48 0' * gameinfo_scale);
	p = pos +'6 11 0' * gameinfo_scale;
	kh_keys = getstati(STAT_KH_KEYS);
	kh_size = '19 34 0' * gameinfo_scale;
	kh_asize = '19 10 0' * gameinfo_scale;
	pa = p + '0 -10 0' * gameinfo_scale;
	float i, key;
	float keycount;
	keycount = 0;
	for (i = 0; i < 4; ++i) {
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		if (keyteam == 30 && keycount <= 4)
			keycount += 4;

		if (keyteam == team_my || keyteam == -1 || keyteam == 30)
			keycount += 1;
	}
	// this yields 8 exactly if "RUN HERE" shows
	if (keycount == 8) {
		if (!kh_runheretime)
			kh_runheretime = time;

		pa_y -= fabs(sin((time - kh_runheretime) * 3.5)) * 6; // make the arrows jump in case of RUN HERE
	} else
		kh_runheretime = 0;

	for (i = 0; i < 4; ++i) {
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		switch(keyteam) {
		case 30: // my key
			keyteam = team_my;
			a = 1;
			aa = 1;
			break;
		case -1: // no key
			a = 0;
			aa = 0;
			break;
		default: // owned or dropped
			a = 0.2;
			aa = 0.5;
			break;
		}
		if (a > 0) {
			switch (keyteam) {
			case COLOR_TEAM1:
				drawpic (pa, "gfx/hud/sb_kh_redarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			case COLOR_TEAM2:
				drawpic (pa, "gfx/hud/sb_kh_bluearrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			case COLOR_TEAM3:
				drawpic (pa, "gfx/hud/sb_kh_yellowarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			case COLOR_TEAM4:
				drawpic (pa, "gfx/hud/sb_kh_pinkarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			default:
				break;
			}
			switch (i) {
			case 0:
				drawpic (p, "gfx/hud/sb_kh_red", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			case 1:
				drawpic (p, "gfx/hud/sb_kh_blue", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			case 2:
				drawpic (p, "gfx/hud/sb_kh_yellow", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			case 3:
				drawpic (p, "gfx/hud/sb_kh_pink", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
				break;
			}
		}
		p_x += 24 * gameinfo_scale;
		pa_x += 24 * gameinfo_scale;
	}
}


