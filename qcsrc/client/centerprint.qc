#define CENTERPRINT_MAX_LINES 30
string centerprint_messages[CENTERPRINT_MAX_LINES];
float centerprint_width[CENTERPRINT_MAX_LINES];
vector centerprint_start;
float centerprint_expire;
float centerprint_last;
float centerprint_offset_hint;
vector centerprint_fontsize;
float centerprint_num;

void(string strMessage) centerprint {
	float i, j, n, hcount;
	string s;
	centerprint_fontsize = sbar_font_size(CVAR(scr_centersize));
	centerprint_expire = min(centerprint_expire, time); // if any of the returns happens, this message will fade out
	if (CVAR(scr_centertime) <= 0)
		return;

	if (strMessage == "")
		return;

	// strip trailing newlines
	j = strlen(strMessage) - 1;
	while (substring(strMessage, j, 1) == "\n" && j >= 0)
		j = j - 1;

	strMessage = substring(strMessage, 0, j + 1);

	if (strMessage == "")
		return;

	// strip leading newlines and remember them, they are a hint that the message should be lower on the screen
	j = 0;
	while (substring(strMessage, j, 1) == "\n" && j < strlen(strMessage))
		j = j + 1;

	strMessage = substring(strMessage, j, strlen(strMessage) - j);
	centerprint_offset_hint = j;
	if (strMessage == "")
		return;

	if (centerprint_last + 0.5 <= time)
		centerprint_num = 0;

	n = tokenizebyseparator(strMessage, "\n");
	hcount = 0;
	i = centerprint_num;
	for (j = 0; j < centerprint_num; j++) {
		if (s == "")
			hcount += 0.5;
		else
			hcount += 1;
	}
	for (j = 0; j < n; ++j) {
		str_wrapped_line_remaining = argv(j);
		while (str_wrapped_line_remaining) {
			s = str_wrapped_line(CVAR(vid_conwidth) * 0.75 / centerprint_fontsize_x, str_width_colors);
			if (centerprint_messages[i])
				strunzone(centerprint_messages[i]);

			centerprint_messages[i] = strzone(s);
			centerprint_width[i] = stringwidth(s, TRUE);
			++i;
			// half height for empty lines looks better
			if (s == "")
				hcount += 0.5;
			else
				hcount += 1;

			if (i >= CENTERPRINT_MAX_LINES)
				break;
		}
	}
	float h, havail;
	h = centerprint_fontsize_y*hcount;
	havail = CVAR(vid_conheight);
	if (CVAR(con_chatpos) < 0)
		havail -= (-CVAR(con_chatpos) + CVAR(con_chat)) * CVAR(con_chatsize); // avoid overlapping chat

	if (havail > CVAR(vid_conheight) - 70)
		havail = CVAR(vid_conheight) - 70; // avoid overlapping HUD

	centerprint_start_x = 0;
	centerprint_start_y =
		min(
			max(
				max(scoreboard_bottom, CVAR(vid_conheight) * 0.5 + 16),
				(havail - h)/2
			),
			havail - h
		);
	centerprint_num = i;
	centerprint_expire = time + CVAR(scr_centertime);
	centerprint_last = time;
}

void(void) centerprint_draw {
	float i;
	vector pos;
	string ts;
	float a;
	a = bound(0, 1 - 4 * (time - centerprint_expire), 1);
	if (a <= 0) {
		centerprint_num = 0;
		return;
	}
	pos = centerprint_start;
	for (i=0; i<centerprint_num; i = i + 1) {
		pos_x = (CVAR(vid_conwidth) - centerprint_fontsize_x * centerprint_width[i]) * 0.5;
		ts = centerprint_messages[i];
		if (ts != "") {
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(pos, ts, centerprint_fontsize, a, DRAWFLAG_NORMAL);
			pos_y = pos_y + centerprint_fontsize_y;
		} else
			// half height for empty lines looks better
			pos_y = pos_y + centerprint_fontsize_y * 0.5;
	}
}

// CSQC_Parse_CenterPrint : Provides the centerprint string in the first parameter that the server provided.
void(string strMessage) CSQC_Parse_CenterPrint {
	centerprint(strMessage);
}
