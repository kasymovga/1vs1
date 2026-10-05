float ctf_redflag_prevframe, ctf_blueflag_prevframe; // status during previous frame
float ctf_redflag_prevstatus, ctf_blueflag_prevstatus; // last remembered status
float ctf_redflag_statuschange_time, ctf_blueflag_statuschange_time; // time when the status changed
float ctf_state_red;
float ctf_state_blue;
float ctf_state_shielded;

void(void) ctf_hud_reset {
	ctf_redflag_prevstatus = ctf_blueflag_prevstatus = ctf_redflag_prevframe = ctf_blueflag_prevframe = ctf_redflag_statuschange_time = ctf_blueflag_statuschange_time = 0;
}

void(vector pos, vector gameinfo_size, float gameinfo_scale) ctf_hud {
	vector redflag_pos, blueflag_pos, sz;
	float f; // every function should have that
	float redflag_statuschange_elapsedtime, blueflag_statuschange_elapsedtime; // time since the status changed
	SBAR_POSITION_AND_SCALE(pos, gameinfo_scale, '124 50 0', gameinfo_size, CVAR(sbar_gameinfo_background))
	// when status CHANGES, set old status into prevstatus and current status into status
	if (ctf_state_red != ctf_redflag_prevframe) {
		ctf_redflag_statuschange_time = time;
		ctf_redflag_prevstatus = ctf_redflag_prevframe;
		ctf_redflag_prevframe = ctf_state_red;
	}
	if (ctf_state_blue != ctf_blueflag_prevframe) {
		ctf_blueflag_statuschange_time = time;
		ctf_blueflag_prevstatus = ctf_blueflag_prevframe;
		ctf_blueflag_prevframe = ctf_state_blue;
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
	switch (ctf_state_red) {
	case CTF_FLAG_CARRY: red_icon = "gfx/hud/sb_flag_red_taken"; break;
	case CTF_FLAG_DROPPED: red_icon = "gfx/hud/sb_flag_red_lost"; break;
	case CTF_FLAG_CARRIED_BY_YOU: red_icon = "gfx/hud/sb_flag_red_carrying"; red_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if (ctf_state_shielded && (team_my == COLOR_TEAM2))
			red_icon = "gfx/hud/sb_flag_red_shielded";
		else
			red_icon = NULL;

		break;
	}
	switch (ctf_redflag_prevstatus) {
	case CTF_FLAG_CARRY: red_icon_prevstatus = "gfx/hud/sb_flag_red_taken"; break;
	case CTF_FLAG_DROPPED: red_icon_prevstatus = "gfx/hud/sb_flag_red_lost"; break;
	case CTF_FLAG_CARRIED_BY_YOU: red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; red_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if (ctf_state_red == CTF_FLAG_CARRIED_BY_YOU)
			red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; // make it more visible
		else if (ctf_state_shielded && (team_my == COLOR_TEAM2))
			red_icon_prevstatus = "gfx/hud/sb_flag_red_shielded";
		else
			red_icon_prevstatus = NULL;

		break;
	}
	string blue_icon, blue_icon_prevstatus;
	float blue_alpha, blue_alpha_prevstatus;
	blue_alpha = blue_alpha_prevstatus = 1;
	switch (ctf_state_blue) {
	case CTF_FLAG_CARRY: blue_icon = "gfx/hud/sb_flag_blue_taken"; break;
	case CTF_FLAG_DROPPED: blue_icon = "gfx/hud/sb_flag_blue_lost"; break;
	case CTF_FLAG_CARRIED_BY_YOU: blue_icon = "gfx/hud/sb_flag_blue_carrying"; blue_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if (ctf_state_shielded && (team_my == COLOR_TEAM1))
			blue_icon = "gfx/hud/sb_flag_blue_shielded";
		else
			blue_icon = NULL;

		break;
	}
	switch (ctf_blueflag_prevstatus) {
	case CTF_FLAG_CARRY: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_taken"; break;
	case CTF_FLAG_DROPPED: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_lost"; break;
	case CTF_FLAG_CARRIED_BY_YOU: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; blue_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
	default:
		if (ctf_state_blue == CTF_FLAG_CARRIED_BY_YOU)
			blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; // make it more visible
		else if (ctf_state_shielded && (team_my == COLOR_TEAM1))
			blue_icon_prevstatus = "gfx/hud/sb_flag_blue_shielded";
		else
			blue_icon_prevstatus = NULL;

		break;
	}
	if (team_my == COLOR_TEAM1) { // always draw own flag on left
		redflag_pos = pos + '4 0 0' * gameinfo_scale;
		blueflag_pos = pos + '62 0 0' * gameinfo_scale;
	} else {
		blueflag_pos = pos + '4 0 0' * gameinfo_scale;
		redflag_pos = pos + '62 0 0' * gameinfo_scale;
	}
	sz = '52 52 0' * gameinfo_scale;
	f = bound(0, redflag_statuschange_elapsedtime*2, 1);
	if (red_icon_prevstatus && f < 1)
		draw_pic_expanding(redflag_pos, red_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * red_alpha_prevstatus, DRAWFLAG_NORMAL, f);

	rm_hud_game_info_enabled = FALSE;
	if (red_icon) {
		rm_hud_game_info_enabled = TRUE;
		drawpic(redflag_pos, red_icon, sz, '1 1 1', sbar_alpha_fg * red_alpha * f, DRAWFLAG_NORMAL);
	}
	f = bound(0, blueflag_statuschange_elapsedtime*2, 1);
	if (blue_icon_prevstatus && f < 1)
		draw_pic_expanding(blueflag_pos, blue_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * blue_alpha_prevstatus, DRAWFLAG_NORMAL, f);

	if (blue_icon) {
		rm_hud_game_info_enabled = TRUE;
		drawpic(blueflag_pos, blue_icon, sz, '1 1 1', sbar_alpha_fg * blue_alpha * f, DRAWFLAG_NORMAL);
	}
}

void(float new) ctf_state_read {
	ctf_state_shielded = net_read_byte();
	ctf_state_red = net_read_byte();
	ctf_state_blue = net_read_byte();
}
