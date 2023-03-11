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
		net_write_string(MSG_ENTITY, self.message);

	if (sf & 4)
		net_write_coord(MSG_ENTITY, self.delay);

	if (sf & 2)
		net_write_string(MSG_ENTITY, self.netname);

	if (sf & 1) {
		net_write_byte(MSG_ENTITY, self.cnt);
		float i;
		for (i = 0; i < self.cnt; i++)
			net_write_string(MSG_ENTITY, bufstr_get(self.state, i));
	}
	return TRUE;
}

entity(entity plr, string _menu_id, string _menu_title, float timeout, void(float choice) _menu_handler) menu_prepare {
	entity e;
	for (e = _menu_chain; e; e = e.enemy) // Only one menu of one type for player
		if (e.owner == plr)
		if (e.message == _menu_id) {
			backtrace("Duplicated menu");
			return world;
		}

	e = spawn();
	e.state = buf_create();
	e.classname = "menu";
	e.message = _menu_id;
	e.netname = str_zone_ifneeded(_menu_title);
	e.delay = timeout;
	e.menu_handler = _menu_handler;
	e.owner = plr;
	if (plr)
		e.customizeentityforclient = menu_customize;

	net_link_entity(e, FALSE, 0, menu_send);
	e.enemy = _menu_chain;
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

	bufstr_set(menu.state, menu.cnt, name);
	menu.cnt++;
}

void(entity menu, float item, string name) menu_set_item {
	if (item < 0 || item >= menu.cnt)
		return;

	bufstr_set(menu.state, item, name);
	menu.SendFlags |= 1;
}

void(entity menu, string title) menu_set_title {
	if not(menu)
		backtrace("menu_set_title get world entity");

	str_unzone_ifneeded(menu.netname);
	menu.netname = str_zone_ifneeded(title);
	menu.SendFlags |= 2;
}

void(entity menu) menu_remove {
	entity e;
	if (_menu_chain == menu)
		_menu_chain = _menu_chain.enemy;
	else
		for (e = _menu_chain; e.enemy; e = e.enemy)
			if (e.enemy == menu) {
				e.enemy = e.enemy.enemy;
				break;
			}
	str_unzone_ifneeded(menu.netname);
	buf_del(menu.state);
	remove(menu);
}

void(string _menu_id, float choice) menu_select {
	entity e;
	for (e = _menu_chain; e; e = e.enemy)
		if (e.message == _menu_id) {
			e.menu_handler(choice);
			break;
		}
}

void(entity plr, string _menu_id) menu_remove_for {
	entity e;
	for (e = _menu_chain; e; e = e.enemy)
		if (e.owner == plr)
		if (e.message == _menu_id) {
			menu_remove(e);
			return;
		}
}
