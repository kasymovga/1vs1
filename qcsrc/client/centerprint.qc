#define CENTERPRINT_MAX_LINES 30
string centerprint_messages[CENTERPRINT_MAX_LINES];
float centerprint_width[CENTERPRINT_MAX_LINES];
vector centerprint_start;
float centerprint_expire;
float centerprint_expires[CENTERPRINT_MAX_LINES];
float centerprint_last;
float centerprint_offset_hint;
vector centerprint_fontsize;
float centerprint_num;

void(string strMessage) centerprint {
	float i, j, n, hcount;
	string s = "";
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

	if (centerprint_num && centerprint_last + 0.5 <= time && !rm_active && !CVAR(rm_simpleeffects))
		centerprint_num = 0;

	n = tokenizebyseparator(strMessage, "\n");
	hcount = 0;
	if (centerprint_num) { //check for duplicates
		float duplicates = 0;
		for (i = 0; i < n; i++) {
			s = argv(i);
			for (j = 0; j < centerprint_num; j++) {
				if (s == centerprint_messages[j]) {
					duplicates++;
					break;
				}
			}
		}
		if (duplicates == n) { //this centerprint presents already
			centerprint_expire = time + CVAR(scr_centertime);
			RM({
				for (i = 0; i < n; i++) {
					s = argv(i);
					for (j = 0; j < centerprint_num; j++) {
						if (s == centerprint_messages[j]) {
							centerprint_expires[j] = time + CVAR(scr_centertime);
							break;
						}
					}
				}
			})
			return;
		}
	}
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
			str_unzone_ifneeded(centerprint_messages[i]);
			centerprint_messages[i] = str_zone_ifneeded(s);
			centerprint_width[i] = stringwidth(s, TRUE);
			RM({
				centerprint_expires[i] = time + CVAR(scr_centertime);
			})
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
	vector pos = centerprint_start;
	string ts;
	float a;
	drawfont = sbar_font;
	if (rm_active && !CVAR(rm_simpleeffects)) {
		if (centerprint_num) {
			if (1 - 4 * (time - centerprint_expires[0]) <= 0) {
				str_unzone_ifneeded(centerprint_messages[0]);
				for (i = 1; i < centerprint_num; i++) {
					centerprint_messages[i - 1] = centerprint_messages[i];
					centerprint_expires[i - 1] = centerprint_expires[i];
					centerprint_width[i - 1] = centerprint_width[i];
				}
				centerprint_num--;
				centerprint_messages[centerprint_num] = "";
				centerprint_expires[centerprint_num] = 0;
				centerprint_width[centerprint_num] = 0;
			}
			for (i = 0; i < centerprint_num; i++) {
				a = bound(0, 1 - 4 * (time - centerprint_expires[i]), 1);
				if (a <= 0) continue;
				pos_x = (CVAR(vid_conwidth) - centerprint_fontsize_x * centerprint_width[i] * a) * 0.5;
				ts = centerprint_messages[i];
				if (ts != "") {
					drawcolorcodedstring(pos, ts, centerprint_fontsize * a, a, DRAWFLAG_NORMAL);
					pos_y = pos_y + centerprint_fontsize_y * a;
				} else
					// half height for empty lines looks better
					pos_y = pos_y + centerprint_fontsize_y * 0.5 * a;
			}
		}
		return;
	}
	a = bound(0, 1 - 4 * (time - centerprint_expire), 1);
	if (a <= 0) {
		centerprint_num = 0;
		return;
	}
	for (i=0; i<centerprint_num; i++) {
		pos_x = (CVAR(vid_conwidth) - centerprint_fontsize_x * centerprint_width[i]) * 0.5;
		ts = centerprint_messages[i];
		if (ts != "") {
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
