#define PRINT_CENTER_MAX_LINES 30
string print_center_messages[PRINT_CENTER_MAX_LINES];
float print_center_width[PRINT_CENTER_MAX_LINES];
vector print_center_start;
float print_center_expire;
float print_center_expires[PRINT_CENTER_MAX_LINES];
float print_center_last;
float print_center_offset_hint;
vector print_center_fontsize;
float print_center_num;

void(string strMessage) print_center {
	float i, j, n, hcount;
	string s = "";
	print_center_fontsize = sbar_font_size(CVAR(scr_centersize));
	print_center_expire = min(print_center_expire, time); // if any of the returns happens, this message will fade out
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
	print_center_offset_hint = j;
	if (strMessage == "")
		return;

	if (print_center_num && print_center_last + 0.5 <= time && !rm_active && !CVAR(rm_simpleeffects))
		print_center_num = 0;

	n = tokenizebyseparator(strMessage, "\n");
	hcount = 0;
	if (print_center_num) { //check for duplicates
		float duplicates = 0;
		for (i = 0; i < n; i++) {
			s = argv(i);
			for (j = 0; j < print_center_num; j++) {
				if (s == print_center_messages[j]) {
					duplicates++;
					break;
				}
			}
		}
		if (duplicates == n) { //this print_center presents already
			print_center_expire = time + CVAR(scr_centertime);
			RM({
				for (i = 0; i < n; i++) {
					s = argv(i);
					for (j = 0; j < print_center_num; j++) {
						if (s == print_center_messages[j]) {
							print_center_expires[j] = time + CVAR(scr_centertime);
							break;
						}
					}
				}
			})
			return;
		}
	}
	i = print_center_num;
	for (j = 0; j < print_center_num; j++) {
		if (s == "")
			hcount += 0.5;
		else
			hcount += 1;
	}
	for (j = 0; j < n; ++j) {
		str_wrapped_line_remaining = argv(j);
		while (str_wrapped_line_remaining) {
			s = str_wrapped_line(CVAR(vid_conwidth) * 0.75 / print_center_fontsize_x, str_width_colors);
			str_unzone_ifneeded(print_center_messages[i]);
			print_center_messages[i] = str_zone_ifneeded(s);
			print_center_width[i] = stringwidth(s, TRUE);
			RM({
				print_center_expires[i] = time + CVAR(scr_centertime);
			})
			++i;
			// half height for empty lines looks better
			if (s == "")
				hcount += 0.5;
			else
				hcount += 1;

			if (i >= PRINT_CENTER_MAX_LINES)
				break;
		}
	}
	float h, havail;
	h = print_center_fontsize_y*hcount;
	havail = CVAR(vid_conheight);
	if (CVAR(con_chatpos) < 0)
		havail -= (-CVAR(con_chatpos) + CVAR(con_chat)) * CVAR(con_chatsize); // avoid overlapping chat

	if (havail > CVAR(vid_conheight) - 70)
		havail = CVAR(vid_conheight) - 70; // avoid overlapping HUD

	print_center_start_x = 0;
	print_center_start_y =
		min(
			max(
				max(scoreboard_bottom, CVAR(vid_conheight) * 0.5 + 16),
				(havail - h)/2
			),
			havail - h
		);
	print_center_num = i;
	print_center_expire = time + CVAR(scr_centertime);
	print_center_last = time;
}

void(void) print_center_draw {
	float i;
	vector pos = print_center_start;
	string ts;
	float a;
	drawfont = sbar_font;
	if (rm_active && !CVAR(rm_simpleeffects)) {
		if (print_center_num) {
			if (1 - 4 * (time - print_center_expires[0]) <= 0) {
				str_unzone_ifneeded(print_center_messages[0]);
				for (i = 1; i < print_center_num; i++) {
					print_center_messages[i - 1] = print_center_messages[i];
					print_center_expires[i - 1] = print_center_expires[i];
					print_center_width[i - 1] = print_center_width[i];
				}
				print_center_num--;
				print_center_messages[print_center_num] = "";
				print_center_expires[print_center_num] = 0;
				print_center_width[print_center_num] = 0;
			}
			for (i = 0; i < print_center_num; i++) {
				a = bound(0, 1 - 4 * (time - print_center_expires[i]), 1);
				if (a <= 0) continue;
				pos_x = (CVAR(vid_conwidth) - print_center_fontsize_x * print_center_width[i] * a) * 0.5;
				ts = print_center_messages[i];
				if (ts != "") {
					drawcolorcodedstring(pos, ts, print_center_fontsize * a, a, DRAWFLAG_NORMAL);
					pos_y = pos_y + print_center_fontsize_y * a;
				} else
					// half height for empty lines looks better
					pos_y = pos_y + print_center_fontsize_y * 0.5 * a;
			}
		}
		return;
	}
	a = bound(0, 1 - 4 * (time - print_center_expire), 1);
	if (a <= 0) {
		print_center_num = 0;
		return;
	}
	for (i=0; i<print_center_num; i++) {
		pos_x = (CVAR(vid_conwidth) - print_center_fontsize_x * print_center_width[i]) * 0.5;
		ts = print_center_messages[i];
		if (ts != "") {
			drawcolorcodedstring(pos, ts, print_center_fontsize, a, DRAWFLAG_NORMAL);
			pos_y = pos_y + print_center_fontsize_y;
		} else
			// half height for empty lines looks better
			pos_y = pos_y + print_center_fontsize_y * 0.5;
	}
}
