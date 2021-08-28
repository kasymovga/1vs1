entity menu;
float menu_selected;
float menu_choiced;
.string menu_items[MENU_ITEMS_MAXCOUNT];
.entity menu_next;
.string menu_id;
.string menu_title;
.float menu_timeout;

#define MENU_ITEM_HEIGHT 30
#define MENU_ITEM_TOP_MARGIN 20

void(void) menu_draw;

void(void) menu_remove {
	float i;
	for (i = 0; i < self.cnt; i++) {
		str_unzone_ifneeded(self.menu_items[i]);
	}
	str_unzone_ifneeded(self.menu_id);
	str_unzone_ifneeded(self.menu_title);
	if (self == menu) {
		menu = menu.menu_next;
		if (menu) {
			menu.draw2d = menu_draw;
			menu.draw2dflag = 1;
		}
		menu_choiced = -1;
		input_event_callback = NULL;
		return;
	}
	entity e;
	for (e = menu; e.menu_next; e = e.menu_next)
		if (e.menu_next == self) {
			e.menu_next = e.menu_next.menu_next;
			return;
		}
}

void(float bIsNewEntity) menu_read {
	entity e;
	float f;
	float skip_duplicated;
	skip_duplicated = FALSE;
	float i;
	for (e = menu; e; e = e.menu_next)
		if (e == self)
			skip_duplicated = TRUE;

	if not(skip_duplicated) {
		if not(menu) {
			menu = self;
			menu_choiced = -1;
			menu.draw2d = menu_draw;
			menu.draw2dflag = 1;
		} else {
			e = menu;
			while (e.menu_next)
				e = e.menu_next;

			e.menu_next = self;
		}
		self.menu_next = world;
		self.entremove = menu_remove;
	}
	f = net_read_byte();
	self.flags |= f;
	if (f & 8) {
		str_unzone_ifneeded(self.menu_id);
		self.menu_id = str_zone_ifneeded(net_read_string());
	}
	if (f & 4) {
		self.menu_timeout = net_read_coord();
		if (self.menu_timeout)
			self.menu_timeout += time;
	}
	if (f & 2) {
		str_unzone_ifneeded(self.menu_title);
		self.menu_title = str_zone_ifneeded(net_read_string());
	}
	if (f & 1) {
		self.cnt = net_read_byte();
		for (i = 0; i < self.cnt; i++) {
			str_unzone_ifneeded(self.menu_items[i]);
			(self.menu_items[i]) = str_zone_ifneeded(net_read_string());
		}
	}
}

void(void) menu_selected_update {
	vector v = mouse_position();
	menu_selected = floor((v_y - MENU_ITEM_TOP_MARGIN - (MENU_ITEM_HEIGHT * 2)) / MENU_ITEM_HEIGHT);
}

float(float bInputType, float nPrimary, float nSecondary) menu_input_event;
void(void) menu_draw {
	if (sbar_showscores || sbar_showaccuracy)
		return;

	float i;
	string menu_string;
	drawfont = sbar_bigfont;
	vector pos;
	float center;
	float size_scale;
	string item_color;
	sbar_hidescores = TRUE;
	center = (CVAR(vid_conwidth) - 1)/2;
	pos_y = MENU_ITEM_TOP_MARGIN;
	pos_z = 0;
	pos_x = center - stringwidth(self.menu_title, FALSE) * 0.5 * 24;
    drawfill('0 1 0' * MENU_ITEM_TOP_MARGIN, '1 0 0' * CVAR(vid_conwidth) + '0 1 0' * (MENU_ITEM_TOP_MARGIN + MENU_ITEM_HEIGHT * (self.cnt + 1)), '0 0 0', 0.5, DRAWFLAG_NORMAL);
	drawstring(pos, self.menu_title, '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	pos_y += MENU_ITEM_HEIGHT;
	if (self.menu_timeout) {
		i = ceil(max(0, self.menu_timeout - time));
		menu_string = strcat(ftos(i), " seconds left");
		pos_x = center - stringwidth(menu_string, FALSE) * 0.5 * 16;
		drawstring(pos, menu_string, '16 16 0', '0 1 0', 1, DRAWFLAG_NORMAL);
	}
	pos_y += MENU_ITEM_HEIGHT;
	menu_selected_update();
	for (i = 0; i < self.cnt; i++) {
		if (menu_selected == i)
			size_scale = 1.1;
		else
			size_scale = 1;

		if (menu_choiced == i)
			item_color = "^4";
		else if (menu_selected == i)
			item_color = "^3";
		else
			item_color = "^7";

		float subcmd = strstrofs(self.menu_items[i], "|", 0);
		menu_string = strcat(item_color, ftos(i + 1), ". ", substring(self.menu_items[i], 0, subcmd));
		pos_x = center - stringwidth(strdecolorize(menu_string), FALSE) * 0.5 * 24 * size_scale;
		drawcolorcodedstring(pos, strcat(menu_string), '24 24 0' * size_scale, 1, DRAWFLAG_NORMAL);
		pos_y += MENU_ITEM_HEIGHT;
	}
	mouse_enable("");
	input_event_callback = menu_input_event;
}

float(float bInputType, float nPrimary, float nSecondary) menu_input_event {
	float choice;
	choice = -1;
	if (bInputType != 0)
		return FALSE;

	if (nPrimary == K_ESCAPE)
	if (menu.flags & 16)
		choice = menu.cnt;

	if ('0' <= nPrimary)
	if (nPrimary <= '9') {
		choice = nPrimary - '0';
		if (choice == 0)
			choice = 9;
		else
			choice--;
	}
	if (nPrimary == K_MOUSE1) {
		menu_selected_update();
		if (menu_selected < 0)
			choice = menu.cnt;
		else
			choice = min(menu_selected, menu.cnt);
	}
	if (choice >= 0) {
		float subcmd = strstrofs(menu.menu_items[choice], "|", 0);
		if (subcmd >= 0) {
			localcmd(strcat("\n", substring(menu.menu_items[choice], subcmd + 1, -1)));
		}
		localcmd(strcat("\ncmd menu_select ", menu.menu_id, " ", ftos(choice), "\n"));
		menu_choiced = choice;
		return TRUE;
	}
	return FALSE;
}
