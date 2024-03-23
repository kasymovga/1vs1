entity noteline;

void(void) noteline_draw;

void(void) noteline_remove {
	entity e;
	if (noteline == self) {
		noteline = noteline.sort_next;
		if (noteline) {
			noteline.draw2dflag = 2;
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
			head = substring(tail, 0, n);
			tail = substring(tail, n + 1, -1);
			noteline_line_draw(head);
		}
	}
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
	noteline.draw2dflag = 2;
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

	self.message = strzone(print_text_prepare(net_read_string(), "", "", ""));
	noteline_add(self);
}
