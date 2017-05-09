entity menu;
float menu_selected;
float menu_choiced;
.string menu_items[MENU_ITEMS_MAXCOUNT];
.entity menu_next;
.string menu_id;
.string menu_title;
.float menu_timeout;

#define ITEM_HEIGHT 30
#define ITEM_TOP_MARGIN 20

void Menu_Draw();
void Ent_Menu_Clear(float f) {
	float i;
	f = self.flags & f;
	if (f & 1)
		for (i = 0; i < self.cnt; i++) {
			strunzone(self.menu_items[i]);
		}
	if (f & 8)
		strunzone(self.menu_id);

	if (f & 2)
		strunzone(self.menu_title);
}

void Ent_Menu_Remove() {
	sb_hidescores = TRUE;
	menu.draw2d = world.draw2d;
	Ent_Menu_Clear(255);
	if (self == menu) {
		menu = menu.menu_next;
		if (menu)
			menu.draw2d = Menu_Draw;

		menu_choiced = -1;
		return;
	}
	entity e;
	for (e = menu; e.menu_next; e = e.menu_next)
		if (e.menu_next == self)
		{
			e.menu_next = e.menu_next.menu_next;
			return;
		}
}

void Ent_Menu(float bIsNewEntity) {
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
			menu.draw2d = Menu_Draw;
		} else {
			e = menu;
			while (e.menu_next)
				e = e.menu_next;

			e.menu_next = self;
		}
		self.menu_next = world;
		self.entremove = Ent_Menu_Remove;
	}
	Ent_Menu_Clear(f);
	f = ReadByte();
	self.flags |= f;
	if (f & 8)
		self.menu_id = strzone(ReadString());

	if (f & 4) {
		self.menu_timeout = ReadCoord();
		if (self.menu_timeout)
			self.menu_timeout += time;
	}
	if (f & 2)
		self.menu_title = strzone(ReadString());

	if (f & 1) {
		self.cnt = ReadByte();
		for (i = 0; i < self.cnt; i++)
			(self.menu_items[i]) = strzone(ReadString());
	}
}

float Menu_InputEvent(float bInputType, float nPrimary, float nSecondary);
void Menu_Draw() {
	float i;
	string menu_string;
	vector pos;
	float center;
	float size_scale;
	string item_color;
	sb_hidescores = TRUE;
	center = (CVAR(vid_conwidth) - 1)/2;
	pos_y = ITEM_TOP_MARGIN;
	pos_z = 0;
	pos_x = center - stringwidth(menu.menu_title, false) * 0.5 * 24;
	drawstring(pos, menu.menu_title, '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	pos_y += ITEM_HEIGHT;
	if (menu.menu_timeout) {
		i = ceil(max(0, menu.menu_timeout - time));
		menu_string = strcat(ftos(i), " seconds left");
		pos_x = center - stringwidth(menu_string, false) * 0.5 * 16;
		drawstring(pos, menu_string, '16 16 0', '0 1 0', 1, DRAWFLAG_NORMAL);
	}
	pos_y += ITEM_HEIGHT;
	menu_selected = floor((mouse_pos_y - ITEM_TOP_MARGIN - (ITEM_HEIGHT * 2)) / ITEM_HEIGHT);

	for (i = 0; i < menu.cnt; i++) {
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

		float subcmd = strstrofs(menu.menu_items[i], "|", 0);
		menu_string = strcat(item_color, ftos(i + 1), ". ", substring(menu.menu_items[i], 0, subcmd));
		pos_x = center - stringwidth(strdecolorize(menu_string), false) * 0.5 * 24 * size_scale;
		drawcolorcodedstring(pos, strcat(menu_string), '24 24 0' * size_scale, 1, DRAWFLAG_NORMAL);
		pos_y += ITEM_HEIGHT;
	}

	Mouse_Enable();
	CSQC_InputEvent_Callback = Menu_InputEvent;
}

float Menu_InputEvent(float bInputType, float nPrimary, float nSecondary) {
	float choice;

	if (bInputType != 0)
		return FALSE;

	if (nPrimary == K_ESCAPE)
	if (menu.flags & 16) {
		nPrimary = K_MOUSE1;
		menu_selected = menu.cnt;
	}

	if ('0' <= nPrimary && nPrimary <= '9') {
		choice = nPrimary - '0';
		if (choice == 0)
			choice = 9;
		else
			choice--;

		localcmd(strcat("\ncmd menu_select ", menu.menu_id, " ", ftos(choice), "\n"));
		menu_choiced = choice;
		return TRUE;
	}
	if (nPrimary == K_MOUSE1)
		if (menu_selected >= 0) {
			choice = min(menu_selected, menu.cnt);
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
