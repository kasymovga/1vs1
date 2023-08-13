void(void) notification_read {
	float notification_type = net_read_byte();
	float attacker = net_read_short();
	float target = net_read_short();
	float deathtype = net_read_coord();
	float w = DEATH_WEAPONOF(deathtype);
	string _icon = "";
	if (notification_type == NOTIFICATION_DEATH) {
		if (w) {
			if (DEATH_ISNADGET(w)) {
				_icon = chr2str(0xE100 + w - NADGET_START + 32);
			} else {
				_icon = chr2str(0xE100 + w);
			}
		} else {
			if (deathtype == DEATH_FIRE || deathtype == DEATH_LAVA)
				_icon = chr2str(0xE100 + FONT_ICON_LAVA);
			else if (deathtype == DEATH_SLIME)
				_icon = chr2str(0xE100 + FONT_ICON_SLIME);
			else if (deathtype == DEATH_FALL)
				_icon = chr2str(0xE100 + FONT_ICON_FALL);
			else if (deathtype == DEATH_DROWN)
				_icon = chr2str(0xE100 + FONT_ICON_WATER);
			else if (deathtype == DEATH_HURTTRIGGER)
				_icon = chr2str(0xE100 + FONT_ICON_VOID);
			else
				_icon = chr2str(0xE100 + FONT_ICON_KILL);
		}
	} else {
	}
	string s = "";
	if (attacker != target && attacker > 0)
		s = player_name(attacker - 1);

	string st = player_name(target - 1);
	print(strcat(s, " ", _icon, " ", st, "\n"));
	if (attacker == player_localentnum) {
		if (target != attacker)
			centerprint(strcat("^4You fragged ^7", st));
		else
			centerprint("^1You killed your own dumb self!");
	} else if (target == player_localentnum) {
		if not(attacker)
			centerprint("^1Watch your step!");
		else
			centerprint(strcat("^1You were fragged by ^7", s));
	}
}
