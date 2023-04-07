float(entity pl, .float field, float flag, string descr) cheat_assign {
	if (g_campaign) {
		centerprint(pl, "^1No cheats allowed in campaign mode!");
		sprint(pl, "^1No cheats allowed in campaign mode!");
		announce(pl, "player/marine/coms/taunt3.ogg", "^1LOOSER");
		pl.field &= ~flag;
		return FALSE;
	}
	string m;
	if (pl.field & flag) {
		m = strcat("^1Cheat ", descr, " disabled\n");
		pl.field &= ~flag;
	} else {
		m = strcat("^1Cheat ", descr, " enabled...\n");
		announce(pl, "player/marine/coms/taunt1.ogg", "^1PUSSY");
		pl.field |= flag;
	}
	sprint(pl, m);
	return (pl.field & flag);
}

void(void) cheat_init {
	if (builtin_cvar("sv_cheats")) {
		precache_sound("player/marine/coms/taunt1.ogg");
		precache_sound("player/marine/coms/taunt3.ogg");
	}
}
