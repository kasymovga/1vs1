.string menu_items[MENU_ITEMS_MAXCOUNT];
.string menu_id;
.string menu_title;
.float menu_timeout;
.entity menu_chain;
.void(float choice) menu_handler;
entity _menu_chain;

float(void) menu_customize {
	if not(other == self.owner)
		return FALSE;

	return TRUE;
}

float(entity to, float sf) menu_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_MENU);
	sf &= 15;
	sf |= self.flags;
	net_write_byte(MSG_ENTITY, sf & 255);
	if (sf & 8)
		net_write_string(MSG_ENTITY, self.menu_id);

	if (sf & 4)
		net_write_coord(MSG_ENTITY, self.menu_timeout);

	if (sf & 2)
		net_write_string(MSG_ENTITY, self.menu_title);

	if (sf & 1) {
		net_write_byte(MSG_ENTITY, self.cnt);
		float i;
		for (i = 0; i < self.cnt; i++)
			net_write_string(MSG_ENTITY, self.menu_items[i]);
	}
	return TRUE;
}

entity(entity plr, string _menu_id, string _menu_title, float timeout, void(float choice) _menu_handler) menu_prepare {
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
	e.menu_title = str_zone_ifneeded(_menu_title);
	e.menu_timeout = timeout;
	e.menu_handler = _menu_handler;
	e.owner = plr;
	if (plr)
		e.customizeentityforclient = menu_customize;

	net_link_entity(e, FALSE, 0, menu_send);
	e.menu_chain = _menu_chain;
	_menu_chain = e;
	return e;
}

void(entity menu, float _flags) menu_set_flags {
	if not(menu)
		backtrace("menu_set_flags get world entity");

	menu.flags = _flags;
}

void(entity menu, string name) menu_add_item {
	if not(menu)
		backtrace("menu_add_item get world entity");

	if (menu.cnt >= MENU_ITEMS_MAXCOUNT)
		return;

	(menu.menu_items[menu.cnt]) = str_zone_ifneeded(name);
	menu.cnt++;
}

void(entity menu, float item, string name) menu_set_item {
	if (item < 0 || item >= menu.cnt)
		return;

	str_unzone_ifneeded(menu.menu_items[item]);
	(menu.menu_items[item]) = str_zone_ifneeded(name);
	menu.SendFlags |= 1;
}

void(entity menu, string title) menu_set_title {
	if not(menu)
		backtrace("menu_set_title get world entity");

	str_unzone_ifneeded(menu.menu_title);
	menu.menu_title = str_zone_ifneeded(title);
	menu.SendFlags |= 2;
}

void(entity menu) menu_remove {
	entity e;
	if (_menu_chain == menu)
		_menu_chain = _menu_chain.menu_chain;
	else
		for (e = _menu_chain; e.menu_chain; e = e.menu_chain)
			if (e.menu_chain == menu) {
				e.menu_chain = e.menu_chain.menu_chain;
				break;
			}
	str_unzone_ifneeded(menu.menu_title);
	float i;
	for (i = 0; i < MENU_ITEMS_MAXCOUNT; i++) {
		str_unzone_ifneeded(menu.menu_items[i]);
	}
	remove(menu);
}

void(string _menu_id, float choice) menu_select {
	entity e;
	for (e = _menu_chain; e; e = e.menu_chain)
		if (e.menu_id == _menu_id) {
			e.menu_handler(choice);
			break;
		}
}

void(entity plr, string _menu_id) menu_remove_for {
	entity e;
	for (e = _menu_chain; e; e = e.menu_chain)
		if (e.owner == plr)
		if (e.menu_id == _menu_id) {
			menu_remove(e);
			return;
		}
}
