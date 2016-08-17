.string menu_items[MENU_ITEMS_MAXCOUNT];
.string menu_id;
.string menu_title;
.float menu_timeout;

float Menu_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_MENU);
	WriteByte(MSG_ENTITY, sf & 255);
	if (sf & 8)
		WriteString(MSG_ENTITY, self.menu_id);

	if (sf & 4)
		WriteCoord(MSG_ENTITY, self.menu_timeout);

	if (sf & 2)
		WriteString(MSG_ENTITY, self.menu_title);

	if (sf & 1) {
		WriteByte(MSG_ENTITY, self.cnt);
		float i;
		for (i = 0; i < self.cnt; i++)
			WriteString(MSG_ENTITY, self.menu_items[i]);
	}
	return TRUE;
}

entity Menu_Prepare(entity plr, string _menu_id, string _menu_title, float timeout) {
	entity e = spawn();
	e.classname = "menu";
	e.menu_id = _menu_id;
	e.menu_title = _menu_title;
	e.menu_timeout = timeout;
	e.viewmodelforclient = plr;
	e.owner = plr;
	Net_LinkEntity(e, FALSE, 0, Menu_SendEntity);
	return e;
}

void Menu_Add_Item(entity menu, string name) {
	if (menu.cnt >= MENU_ITEMS_MAXCOUNT - 1)
		return;

	(menu.menu_items[menu.cnt]) = name;
	menu.cnt++;
}

void Menu_Set_Item(entity menu, float item, string name) {
	if (item < 0 || item >= menu.cnt)
		return;

	(menu.menu_items[item]) = name;
	menu.SendFlags |= 1;
}

void Menu_Set_Title(entity menu, string title) {
	menu.menu_title = title;
	menu.SendFlags |= 2;
}

void Menu_Remove(entity menu) {
	remove(menu);
}
