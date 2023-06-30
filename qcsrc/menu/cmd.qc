string cmd_dumptree_space;
void(entity pass, entity me) cmd_dumptree_open {
	string s;
	s = me.toString(me);
	if (s == "")
		s = me.classname;
	else
		s = strcat(me.classname, ": ", s);

	print(cmd_dumptree_space, etos(me), " (", s, ")");
	if (me.firstChild) {
		print(" {\n");
		cmd_dumptree_space = strcat(cmd_dumptree_space, "  ");
	} else
		print("\n");
}

void(entity pass, entity me) cmd_dumptree_close {
	if (me.firstChild) {
		cmd_dumptree_space = substring(cmd_dumptree_space, 0, strlen(cmd_dumptree_space) - 2);
		print(cmd_dumptree_space, "}\n");
	}
}

void(string theCommand) cmd { //called by engine
	float argc;
	argc = tokenize_console(theCommand);
	string s = argv(0);
	if (s == "help" || argc == 0) {
		print("Usage: menu_cmd theCommand..., where possible theCommands are:\n");
		print("  sync - reloads all cvars on the current menu page\n");
		print("  directmenu ITEM - select a menu item as main item\n");
		cmd_generic("help");
	} else if (cmd_generic(theCommand)) {
	} else if (s == "sync") {
		gui_load_all_cvars(main);
	} else if (s == "directmenu" && argc == 2) {
		// switch to a menu item
		if (!isdemo()) // don't allow this command in demos
			menu_goto(argv(1));
	} else if (s == "dumptree") {
		cmd_dumptree_space = "";
		gui_depth_first(main, parent, firstChild, nextSibling, cmd_dumptree_open, cmd_dumptree_close, NULL);
	} else if (s == "dumpserverlist") {
		string s = argv(1);
		if not(s)
			s = "serverlist.txt";

		float f = fopen(s, FILE_WRITE);
		if not(f < 0) {
			float n = gethostcachevalue(SLIST_HOSTCACHEVIEWCOUNT);
			float i;
			for (i = 0; i < n; i++) {
				fputs(f, strcat(gethostcachestring(SLIST_FIELD_CNAME, i), "//", gethostcachestring(SLIST_FIELD_NAME, i), "\n"));
			}
			fclose(f);
		}
	} else if (s == "dlc_reload") {
		dlc_reload(TRUE, TRUE);
	} else if (s == "ui_con_width_height_set") {
		ui_con_width_height_set();
	} else if (s == "skinselect") {
		menu_goto("skinselector");
	} else if (s == "video" && argc == 2) {
		if (argv(1) == "low") lowNexuizVideoSettingsTab(NULL, NULL);
		else if (argv(1) == "medium") mediumNexuizVideoSettingsTab(NULL, NULL);
		else if (argv(1) == "normal") normalNexuizVideoSettingsTab(NULL, NULL);
		else if (argv(1) == "high") highNexuizVideoSettingsTab(NULL, NULL);
		else if (argv(1) == "ultra") ultraNexuizVideoSettingsTab(NULL, NULL);
	} else if (s == "loadfallback" && argc == 2) {
		if (isserver() || clientstate() == CS_CONNECTED) {
			//print("Loading successful\n");
			return;
		}
		print("Loading failed, attempt to fallback\n");
		float f = fopen(argv(1), FILE_READ);
		string mn = "";
		if (f >= 0) {
			registercvar("_campaign_index", "", 0);
			registercvar("_campaign_name", "", 0);
			string line;
			float lineno = 0;
			while ((line = fgets(f))) {
				lineno++;
				if (lineno <= 21) {
					if (lineno == 20) {
						mn = line;
					} else if (lineno >= 3 && lineno <= 18) {
						registercvar(strcat("_override_parm", ftos(lineno - 2)), "", 0);
						cvar_set(strcat("_override_parm", ftos(lineno - 2)), line);
					}
				}
				if (substring(line, 0, 17) == "\"campaign_level\" " && strlen(line) >= 19) {
					cvar_set("_campaign_index", substring(line, 18, strlen(line) - 19));
				}
				if (substring(line, 0, 19) == "\"g_campaign_skill\" " && strlen(line) >= 21) {
					cvar_set("g_campaign_skill", substring(line, 20, strlen(line) - 21));
				}
				if (substring(line, 0, 16) == "\"campaign_name\" " && strlen(line) >= 18) {
					cvar_set("_campaign_name", substring(line, 17, strlen(line) - 18));
				}
				if (line == "}") break;
			}
			fclose(f);
		}
		localcmd(strcat("\n_restore_game 0;maxplayers 1;skill 3;coop 0;deathmatch 0;g_campaign 1;_gametype single;map ", mn, "\n"));
		for (f = 1; f <= 16; f++) {
			localcmd(strcat("unset _override_parm", ftos(f), "\n"));
		}
	} else
		print("Invalid theCommand. For a list of supported theCommands, try menu_cmd help.\n");
}
