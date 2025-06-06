// campaign cvars:
//   _campaign_index: index of CURRENT map
//   _campaign_name: name of the current campaign
//   g_campaign(name)_index: index of current LAST map (saved)
//   g_campaign_skill: bot skill offset

float campaign_level;
float campaign_won;
string campaign_index_var;
float checkrules_equality;
float g_campaign_skill;

float(string s) campaign_bailout {
	cvar = builtin_cvar;
	cvar_string = builtin_cvar_string;
	cvar_set = builtin_cvar_set;
	cvar_set("g_campaign", "0");
	g_campaign = 0;
	print("campaign initialization failed: ", s, "\n");
	return 1;
}

string campaign_cvar_list; // string of format ; var value; var value; var value;
string(string theCvar) campaign_cvar_string {
	float p, q;
	p = strstrofs(campaign_cvar_list, strcat("; ", theCvar, " "), 0);
	if (p < 0)
		return cvar_defstring(theCvar);

	p += strlen(theCvar) + 3;
	q = strstrofs(campaign_cvar_list, ";", p);
	if (q < 0)
		return cvar_defstring(theCvar);

	return substring(campaign_cvar_list, p, q - p);
}

float(string theCvar) campaign_cvar {
	return stof(campaign_cvar_string(theCvar));
}

void(string theCvar, string theValue) campaign_cvar_set {
	if (campaign_cvar_string(theCvar) == theValue)
		return;

	string s;
	s = campaign_cvar_list;
	campaign_cvar_list = strzone(strcat("; ", theCvar, " ", theValue, s));
	strunzone(s);
}

float(void) campaign_invalid {
	string s = campaign_gametype[campaign_level];
	if (game_type_name(game_type_current()) != s)
		return campaign_bailout("wrong game type!");

	return 0;
}

string(float d) campaign_difficulty_string {
	if (d >= 3) return "^6Insane";
	if (d >= 2) return "^1Hard";
	if (d >= 1) return "^3Medium";
	if (d >= 0) return "^5Easy";
	return "^2Easiest";
}

void(void) campaign_preinit {
	if (builtin_cvar("_restore_game")) { //Hack for load game
		campaign_cvar_list = strzone("; ");
		builtin_cvar_set("sv_public", "0");
		builtin_cvar_set("pausable", "1");
		builtin_cvar_set("_restore_game", "0");
		builtin_cvar_set("g_campaign", "1");
		cvar = campaign_cvar;
		cvar_string = campaign_cvar_string;
		cvar_set = campaign_cvar_set;
		cvar_set("g_campaign", "1");
		game_type_switch(game_type_from_name("single"));
		return;
	}
	CVAR_CACHE(g_campaign);
	if not(g_campaign)
		return;

	float baseskill;
	string title;
	campaign_file_load(cvar_string("_campaign_name"));
	campaign_level = cvar("_campaign_index");
	campaign_index_var = strzone(strcat("g_campaign", campaign_name, "_index"));
	if (campaign_entries < 1) {
		campaign_bailout("unknown map");
		return;
	}
	CVAR_CACHE(g_campaign_skill);
	baseskill = bound(0.2, g_campaign_skill + 1, 4);
	float minskill = max(0, baseskill * 9 - 6);
	float maxskill = baseskill * 10;
	baseskill = bound(minskill, campaign_botskill[campaign_level] * baseskill * 0.5, maxskill);
	cvar_set("sv_public", "0");
	cvar_set("pausable", "1");
	campaign_cvar_list = strzone(strcat("; ", campaign_mutators[campaign_level], "; "));
	cvar = campaign_cvar;
	cvar_string = campaign_cvar_string;
	cvar_set = campaign_cvar_set;
	cvar_set("g_campaign", "1");
	cvar_set("skill", ftos(baseskill));
	cvar_set("bot_number", ftos(campaign_bots[campaign_level]));
	string pm = builtin_cvar_string("_cl_playermodel");
	if (pm != "") {
		cvar_set("campaign_single_g_player_forcemodel", pm);
		cvar_set("campaign_surv_g_player_forcemodel", pm);
	}
	game_type_switch(game_type_from_name(campaign_gametype[campaign_level]));
	if (campaign_invalid())
		return;

	title = campaign_shortdesc[campaign_level];
	title = strzone(strcat("Level ", ftos(campaign_level + 1), ": ", title));
	campaign_message = strzone(strcat("^3Difficulty: ", campaign_difficulty_string(g_campaign_skill), "^7\n\n", campaign_longdesc[campaign_level]));
	strunzone(title);
}

void(void) campaign_postinit {
	if not(g_campaign)
		return;

	// now some sanity checks
	if (campaign_invalid())
		return;

	cvar_set("fraglimit", ftos(campaign_fraglimit[campaign_level]));
	cvar_set("timelimit", "0");
	builtin_cvar_set("fraglimit", ftos(campaign_fraglimit[campaign_level]));
	builtin_cvar_set("timelimit", "0");
}

void(string cvarname, float value) campaign_save_cvar {
	float fh;
	float len;
	string contents;
	string l;
	registercvar(cvarname, ftos(value));
	builtin_cvar_set(cvarname, ftos(value));
	// note: cvarname must be remembered
	fh = fopen("campaign.cfg", FILE_READ);
	contents = "";
	if (fh >= 0) {
		while ((l = fgets(fh))) {
			len = tokenize_console(l);
			if (len != 3)
				continue;

			if (argv(0) != "set")
				continue;

			if (argv(1) == cvarname)
				continue;

			contents = strcat(contents, "set ", argv(1), " ", argv(2), "\n");
		}
		fclose(fh);
	}
	contents = strcat(contents, "set ", cvarname,  " ", ftos(value), "\n");
	fh = fopen("campaign.cfg", FILE_WRITE);
	if (fh >= 0) {
		fputs(fh, contents);
	} else {
		error("Cannot write to campaign file");
	}
}

void(void) campaign_preintermission {
	entity head;
	float won;
	float lost = FALSE;
	string savevar;
	won = 0;
	head = findchain(classname, "player");
	while (head) {
		if (clienttype(head) == CLIENTTYPE_REAL) {
			if (head.winning)
				won = won + 1;
			else
				lost = lost + 1;
		}
		head = head.chain;
	}
	if (won == 1 && lost == 0 && checkrules_equality == 0) {
		campaign_won = 1;
		print_all(PRINT_INFO, "The current level has been WON.", "", "", "");
		// sound!
	} else {
		campaign_won = 0;
		print_all(PRINT_INFO, "The current level has been LOST.", "", "", "");
		// sound!
	}
	if (campaign_won && !campaign_map_transition) {
		if (campaign_level + 1 >= campaign_entries) {
			// I have won
			savevar = strcat("g_campaign", campaign_name, "_won");
			campaign_save_cvar(savevar, 1);
			// advance level (for menu to show it right)
			campaign_save_cvar(campaign_index_var, campaign_level + 1);
		} else if (campaign_level == builtin_cvar(campaign_index_var)) {
			// advance level
			campaign_save_cvar(campaign_index_var, campaign_level + 1);
		}
	}
}

float campaign_postintermission_done;
void(void) campaign_postintermission {
	// NOTE: campaign_won is 0 or 1, that is, points to the next level
	campaign_postintermission_done = 1;
	if (!campaign_map_transition && campaign_won && campaign_level + 1 >= campaign_entries) {
		// last map won!
		localcmd("togglemenu 1\n");
		campaign_file_unload();
		return;
	}
	builtin_cvar_set("g_campaign_skill", ftos(g_campaign_skill));
	if (campaign_map_transition)
		campaign_setup_cvars_only(campaign_level);
	else
		campaign_setup(campaign_level + campaign_won);

	campaign_file_unload();
	strunzone(campaign_message);
	strunzone(campaign_index_var);
}

void(void) campaign_restart {
	if not(g_campaign) return;
	if (campaign_postintermission_done) return;
	registercvar("_campaign_name", "");
	registercvar("_campaign_index", "");
	builtin_cvar_set("g_campaign", "1");
	builtin_cvar_set("_campaign_name", campaign_name);
	builtin_cvar_set("_campaign_index", ftos(campaign_level));
	builtin_cvar_set("g_campaign_skill", ftos(g_campaign_skill));
}
