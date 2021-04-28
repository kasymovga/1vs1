float ctf_redflag_prevframe, ctf_blueflag_prevframe; // status during previous frame
float ctf_redflag_prevstatus, ctf_blueflag_prevstatus; // last remembered status
float ctf_redflag_statuschange_time, ctf_blueflag_statuschange_time; // time when the status changed

void(void) ctf_hud_reset {
	ctf_redflag_prevstatus = ctf_blueflag_prevstatus = ctf_redflag_prevframe = ctf_blueflag_prevframe = ctf_redflag_statuschange_time = ctf_blueflag_statuschange_time = 0;
}

void(void) ctf_hud {
	vector redflag_pos, blueflag_pos, sz;
	float f; // every function should have that
	float redflag, blueflag; // current status
	float redflag_statuschange_elapsedtime, blueflag_statuschange_elapsedtime; // time since the status changed
	redflag = (sbar_stat_items/IT_RED_FLAG_TAKEN) & 3;
	blueflag = (sbar_stat_items/IT_BLUE_FLAG_TAKEN) & 3;
	vector pos = sbar_position(CVAR(sbar_gameinfo_position), 124, 50);
	// when status CHANGES, set old status into prevstatus and current status into status
	if (redflag != ctf_redflag_prevframe) {
		ctf_redflag_statuschange_time = time;
		ctf_redflag_prevstatus = ctf_redflag_prevframe;
		ctf_redflag_prevframe = redflag;
	}
	if (blueflag != ctf_blueflag_prevframe) {
		ctf_blueflag_statuschange_time = time;
		ctf_blueflag_prevstatus = ctf_blueflag_prevframe;
		ctf_blueflag_prevframe = blueflag;
	}
	redflag_statuschange_elapsedtime = time - ctf_redflag_statuschange_time;
	blueflag_statuschange_elapsedtime = time - ctf_blueflag_statuschange_time;
	float BLINK_FACTOR = 0.15;
	float BLINK_BASE = 0.85;
	// note:
	//   RMS = sqrt(BLINK_BASE^2 + 0.5 * BLINK_FACTOR^2)
	// thus
	//   BLINK_BASE = sqrt(RMS^2 - 0.5 * BLINK_FACTOR^2)
	// ensure RMS == 1
	float BLINK_FREQ = 5; // circle frequency, = 2*pi*frequency in hertz
	string red_icon, red_icon_prevstatus;
	float red_alpha, red_alpha_prevstatus;
	red_alpha = red_alpha_prevstatus = 1;
	switch(redflag) {
	case 1: red_icon = "gfx/hud/sb_flag_red_taken"; break;
	case 2: red_icon = "gfx/hud/sb_flag_red_lost"; break;
	case 3: red_icon = "gfx/hud/sb_flag_red_carrying"; red_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if ((sbar_stat_items & IT_CTF_SHIELDED) && (team_my == COLOR_TEAM2))
			red_icon = "gfx/hud/sb_flag_red_shielded";
		else
			red_icon = NULL;

		break;
	}
	switch(ctf_redflag_prevstatus) {
	case 1: red_icon_prevstatus = "gfx/hud/sb_flag_red_taken"; break;
	case 2: red_icon_prevstatus = "gfx/hud/sb_flag_red_lost"; break;
	case 3: red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; red_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if (redflag == 3)
			red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; // make it more visible
		else if ((sbar_stat_items & IT_CTF_SHIELDED) && (team_my == COLOR_TEAM2))
			red_icon_prevstatus = "gfx/hud/sb_flag_red_shielded";
		else
			red_icon_prevstatus = NULL;

		break;
	}
	string blue_icon, blue_icon_prevstatus;
	float blue_alpha, blue_alpha_prevstatus;
	blue_alpha = blue_alpha_prevstatus = 1;
	switch(blueflag) {
	case 1: blue_icon = "gfx/hud/sb_flag_blue_taken"; break;
	case 2: blue_icon = "gfx/hud/sb_flag_blue_lost"; break;
	case 3: blue_icon = "gfx/hud/sb_flag_blue_carrying"; blue_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if ((sbar_stat_items & IT_CTF_SHIELDED) && (team_my == COLOR_TEAM1))
			blue_icon = "gfx/hud/sb_flag_blue_shielded";
		else
			blue_icon = NULL;

		break;
	}
	switch(ctf_blueflag_prevstatus) {
	case 1: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_taken"; break;
	case 2: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_lost"; break;
	case 3: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; blue_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if (blueflag == 3)
			blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; // make it more visible
		else if ((sbar_stat_items & IT_CTF_SHIELDED) && (team_my == COLOR_TEAM1))
			blue_icon_prevstatus = "gfx/hud/sb_flag_blue_shielded";
		else
			blue_icon_prevstatus = NULL;

		break;
	}
	if (team_my == COLOR_TEAM1) { // always draw own flag on left
		redflag_pos = pos + '4 0 0';
		blueflag_pos = pos + '62 0 0';
	} else {
		blueflag_pos = pos + '4 0 0';
		redflag_pos = pos + '62 0 0';
	}
	sz = '52 52 0';
	f = bound(0, redflag_statuschange_elapsedtime*2, 1);
	if (red_icon_prevstatus && f < 1)
		draw_pic_expanding(redflag_pos, red_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * red_alpha_prevstatus, DRAWFLAG_NORMAL, f);

	if (red_icon)
		drawpic(redflag_pos, red_icon, sz, '1 1 1', sbar_alpha_fg * red_alpha * f, DRAWFLAG_NORMAL);

	f = bound(0, blueflag_statuschange_elapsedtime*2, 1);
	if (blue_icon_prevstatus && f < 1)
		draw_pic_expanding(blueflag_pos, blue_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * blue_alpha_prevstatus, DRAWFLAG_NORMAL, f);

	if (blue_icon)
		drawpic(blueflag_pos, blue_icon, sz, '1 1 1', sbar_alpha_fg * blue_alpha * f, DRAWFLAG_NORMAL);
}

