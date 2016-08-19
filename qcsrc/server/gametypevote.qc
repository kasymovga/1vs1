float gametypevote_finished;
float gametypevote_start;
entity gametypevote;

float gametypes[MENU_ITEMS_MAXCOUNT];
string gametypes_descr[MENU_ITEMS_MAXCOUNT];
float gametypes_votes[MENU_ITEMS_MAXCOUNT];
float gametypes_count;

.float gametypevote_select;

string GameTypeName(float t) {
	if (t == MAPINFO_TYPE_DEATHMATCH) {
		return "Deathmatch";
	} else if (t == MAPINFO_TYPE_DOMINATION) {
		return "Domination";
	} else if (t == MAPINFO_TYPE_TEAM_DEATHMATCH) {
		return "Team Deathmatch";
	} else if (t == MAPINFO_TYPE_CTF) {
		return "Capture The Flag";
	} else if (t == MAPINFO_TYPE_ASSAULT) {
		return "Assault";
	} else if (t == MAPINFO_TYPE_RUNEMATCH) {
		return "Runematch";
	} else if (t == MAPINFO_TYPE_NEXBALL) {
		return "Nexball";
	} else if (t == MAPINFO_TYPE_ONSLAUGHT) {
		return "Onslaught";
	} else if (t == MAPINFO_TYPE_KEYHUNT) {
		return "Key Hunt";
	} else if (t == MAPINFO_TYPE_LMS) {
		return "Last Man Standing";
	} else if (t == MAPINFO_TYPE_CTS) {
		return "CTS";
	} else if (t == MAPINFO_TYPE_RACE) {
		return "Race";
	} else if (t == MAPINFO_TYPE_ARENA) {
		return "Arena";
	}
	return "WTF";
}

string GameTypeVote_GetDescr(float n) {
	if (gametypes_descr[n] != "")
		strunzone(gametypes_descr[n]);

	gametypes_descr[n] = strzone(strcat(GameTypeName(gametypes[n]), " (", ftos(gametypes_votes[n]), ")"));
	return gametypes_descr[n];
}

float GameTypeVote_Think() {
	float n, i, max_votes, gametype_max_votes, tmp;
	if (nex252_compat_mode)
		return FALSE;

	if (gametypevote_finished) {
		if (gametypevote) {
			Menu_Remove(gametypevote);
			gametypevote = world;
			for (i = 0; i < gametypes_count; i++) {
				print(gametypes_descr[i], "\n");
				if (gametypes_descr[i] != "")
					strunzone(gametypes_descr[i]);
			}
		}
		return FALSE;
	}
	if not(gametypevote) {
		print("Game type vote initialized\n");
		n = tokenizebyseparator(cvar_string("sv_gametypevote"), " ");
		if (n > MENU_ITEMS_MAXCOUNT)
			n = MENU_ITEMS_MAXCOUNT;

		if (n <= 1) {
			gametypevote_finished = TRUE;
			return TRUE;
		}

		gametypevote_start = time;
		gametypevote = Menu_Prepare(world, "gametypevote", "Please select game type for next map:", cvar("sv_gametypevote_time"));
		gametypes_count = n;
		for (i = 0; i < n; i++) {
			gametypes[i] = MapInfo_Type_FromString(argv(i));
			Menu_Add_Item(gametypevote, GameTypeVote_GetDescr(i));
		}
	}
	for (i = 0; i < gametypes_count; i++) {
		if (gametypes_votes[i] > (player_count - currentbots) / 2) {
			MapInfo_SwitchGameType(gametypes[i]);
			gametypevote_finished = TRUE;
			return TRUE;
		}
	}
	if (gametypevote_start + cvar("sv_gametypevote_time") < time) {
		gametype_max_votes = -1;
		max_votes = 0;
		for (i = 0; i < gametypes_count; i++) {
			tmp = gametypes_votes[i];
			if (tmp > 0 && max_votes < tmp) {
				max_votes = tmp;
				gametype_max_votes = i;
			}
		}
		if (gametype_max_votes >= 0) {
			MapInfo_SwitchGameType(gametypes[gametype_max_votes]);
		}
		gametypevote_finished = TRUE;
		return TRUE;
	}

	return TRUE;
}

void GameTypeVote_Select(entity plr, float select) {
	float tmp, prev_select;
	if (select < 0 || select >= gametypes_count)
		return;

	if not(gametypevote)
		return;

	if (plr.gametypevote_select >= 1 && plr.gametypevote_select <= gametypes_count) {
		prev_select = plr.gametypevote_select - 1;
		tmp = gametypes_votes[prev_select];
		gametypes_votes[prev_select] = tmp - 1;
		Menu_Set_Item(gametypevote, prev_select, GameTypeVote_GetDescr(prev_select));
	}
	plr.gametypevote_select = select + 1;
	tmp = gametypes_votes[select] + 1;
	gametypes_votes[select] = tmp;
	Menu_Set_Item(gametypevote, select, GameTypeVote_GetDescr(select));
}
