entity note;

void(void) note_draw;

void(void) note_remove {
	entity e;
	if (note == self) {
		note = note.sort_next;
		if (note) {
			note.draw2dflag = 2;
			note.draw2d = note_draw;
		}
	} else
		for (e = note; e.sort_next; e = e.sort_next) {
			if (e.sort_next == self) {
				e.sort_next = self.sort_next;
				break;
			}
		}
	str_unzone_ifneeded(self.message);
}

vector note_pos;
void(string s) note_line_draw {
	drawfont = sbar_font;
	drawcolorcodedstring(
		note_pos - sbar_fontsize_x * '1 0 0' * (stringwidth(s, TRUE) + 1),
		s,
		sbar_fontsize,
		sbar_alpha_fg,
		0
	);
	note_pos_y += sbar_fontsize_y;
}

void(void) note_draw {
	note_pos_x = CVAR(vid_conwidth);
	note_pos_y = 28;
	entity e;
	string head, tail;
	float n;
	for (e = note; e; e = e.sort_next) {
		note_pos_y += sbar_fontsize_y * 0.5;
		tail = e.message;
		for (;;) {
			n = strstrofs(tail, "\n", 0);
			if (n < 0) {
				note_line_draw(tail);
				break;
			}
			head = substring(tail, 0, n);
			tail = substring(tail, n + 1, -1);
			note_line_draw(head);
		}
	}
}

void(entity e_add) note_add {
	entity e;
	for (e = note; e; e = e.sort_next) {
		if (e == e_add)
			return;
	}
	if (note) {
		e_add.sort_next = note;
		note.draw2dflag = 0;
		note.draw2d = NULL;
	}
	note = e_add;
	note.draw2dflag = 2;
	note.draw2d = note_draw;
}

entity(string m) note_new {
	entity e = spawn();
	e.message = str_zone_ifneeded(m);
	e.entremove = note_remove;
	note_add(e);
	return e;
}

void(float bIsNew) note_read {
	self.entremove = note_remove;
	str_unzone_ifneeded(self.message);
	self.message = str_zone_ifneeded(print_text_prepare(net_read_string(), net_read_string(), net_read_string(), net_read_string()));
	note_add(self);
}
