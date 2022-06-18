entity noteline;

void(void) noteline_draw;

void(void) noteline_remove {
	entity e;
	if (noteline == self) {
		noteline = noteline.sort_next;
		if (noteline) {
			noteline.draw2dflag = 1;
			noteline.draw2d = noteline_draw;
		}
	} else
		for (e = noteline; e.sort_next; e = e.sort_next) {
			if (e.sort_next == self) {
				e.sort_next = self.sort_next;
				break;
			}
		}
	strunzone(self.message);
}

vector noteline_pos;
void(string s) noteline_line_draw {
	drawfont = sbar_font;
	drawcolorcodedstring(
		noteline_pos - sbar_fontsize_x * '1 0 0' * (stringwidth(s, TRUE) + 1),
		s,
		sbar_fontsize,
		sbar_alpha_fg,
		0
	);
	noteline_pos_y += sbar_fontsize_y;
}

void(void) noteline_draw {
	noteline_pos_x = CVAR(vid_conwidth);
	noteline_pos_y = 28;
	entity e;
	string head, tail;
	float n;
	for (e = noteline; e; e = e.sort_next) {
		noteline_pos_y += sbar_fontsize_y * 0.5;
		tail = e.message;
		for (;;) {
			n = strstrofs(tail, "\n", 0);
			if (n < 0) {
				noteline_line_draw(tail);
				break;
			}
			head = substring(tail, 0, n + 1);
			tail = substring(tail, n + 1, -1);
			noteline_line_draw(head);
		}
	}
}

string(string s) noteline_text_prepare {
	float cmdkey, cmdkey_end;
	if (main_isdemo) {
		cmdkey = strstrofs(s, "\n", 0);
		if (cmdkey >= 0)
			s = substring(s, 0, cmdkey);
	}
	for (cmdkey = 0; (cmdkey = strstrofs(s, "{", cmdkey)) >= 0;) {
		cmdkey_end = strstrofs(s, "}", cmdkey);
		if (cmdkey_end < 0)
			break;

		string s1, s2, s3;
		s1 = substring(s, 0, cmdkey);
		if (cmdkey + 1 == cmdkey_end) {
			s2 = "{";
		} else {
			s2 = substring(s, cmdkey + 1, cmdkey_end - cmdkey - 1);
			if (s2 != "")
				s2 = input_command_key(s2, s2);
		}
		s3 = substring(s, cmdkey_end + 1, -1);
		cmdkey = strlen(s1) + strlen(s2);
		s = strcat(s1, s2, s3);
	}
	return s;
}

void(entity e_add) noteline_add {
	entity e;
	for (e = noteline; e; e = e.sort_next) {
		if (e == e_add)
			return;
	}
	if (noteline) {
		e_add.sort_next = noteline;
		noteline.draw2dflag = 0;
		noteline.draw2d = NULL;
	}
	noteline = e_add;
	noteline.draw2dflag = 1;
	noteline.draw2d = noteline_draw;
}

entity(string m) noteline_new {
	entity e = spawn();
	e.message = strzone(m);
	e.entremove = noteline_remove;
	noteline_add(e);
	return e;
}

void(float bIsNew) noteline_read {
	self.entremove = noteline_remove;
	if (self.message)
		strunzone(self.message);

	self.message = strzone(noteline_text_prepare(net_read_string()));
	noteline_add(self);
}
