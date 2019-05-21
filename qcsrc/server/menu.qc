.string menu_items[MENU_ITEMS_MAXCOUNT];
.string menu_id;
.string menu_title;
.float menu_timeout;
.entity menu_chain;
.void(float choice) menu_handler;
entity _menu_chain;

float Menu_CustomizeEntityForClient() {
	if not(other == self.owner)
		return FALSE;

	return TRUE;
}

float Menu_SendEntity(entity to, float sf) {
	WriteByte(MSG_ENTITY, ENT_CLIENT_MENU);
	sf &~= MENU_ESCAPE_ENABLE;
	sf |= self.flags;
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

entity Menu_Prepare(entity plr, string _menu_id, string _menu_title, float timeout, void(float choice) _menu_handler) {
	entity e;
	for (e = _menu_chain; e; e = e.menu_chain) // Only one menu of one type for player
		if (e.owner == plr)
		if (e.menu_id == _menu_id) {
			backtrace("Duplicated menu");
			return world;
		}

	e = spawn();
	e.classname = "menu";
	e.menu_id = _menu_id;
	e.menu_title = _menu_title;
	e.menu_timeout = timeout;
	e.menu_handler = _menu_handler;
	e.owner = plr;
	if (plr)
		e.customizeentityforclient = Menu_CustomizeEntityForClient;

	net_link_entity(e, FALSE, 0, Menu_SendEntity);
	e.menu_chain = _menu_chain;
	_menu_chain = e;
	return e;
}

void Menu_Set_Flags(entity menu, float _flags) {
	if not(menu)
		backtrace("Menu_Set_Flags get world entity");

	menu.flags = _flags;
}

void Menu_Add_Item(entity menu, string name) {
	if not(menu)
		backtrace("Menu_Add_Item get world entity");

	if (menu.cnt >= MENU_ITEMS_MAXCOUNT)
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
	if not(menu)
		backtrace("Menu_Set_Title get world entity");

	menu.menu_title = title;
	menu.SendFlags |= 2;
}

void Menu_Remove(entity menu) {
	entity e;
	if (_menu_chain == menu)
		_menu_chain = _menu_chain.menu_chain;
	else
		for (e = _menu_chain; e.menu_chain; e = e.menu_chain)
			if (e.menu_chain == menu) {
				e.menu_chain = e.menu_chain.menu_chain;
				break;
			}
	remove(menu);
}

void Menu_Select(string _menu_id, float choice) {
	entity e;
	for (e = _menu_chain; e; e = e.menu_chain)
		if (e.menu_id == _menu_id) {
			e.menu_handler(choice);
			break;
		}
}

void Menu_Remove_For(entity plr, string _menu_id) {
	entity e;
	for (e = _menu_chain; e; e = e.menu_chain)
		if (e.owner == plr)
		if (e.menu_id == _menu_id) {
			Menu_Remove(e);
			return;
		}
}
