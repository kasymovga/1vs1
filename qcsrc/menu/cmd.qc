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
	if (argv(0) == "help" || argc == 0) {
		print("Usage: menu_cmd theCommand..., where possible theCommands are:\n");
		print("  sync - reloads all cvars on the current menu page\n");
		print("  directmenu ITEM - select a menu item as main item\n");
		cmd_generic("help");
		return;
	}
	if (cmd_generic(theCommand))
		return;

	if (argv(0) == "sync") {
		loadAllCvars(main);
		return;
	}
	if (argv(0) == "directmenu")
	if (argc == 2) {
		// switch to a menu item
		if (!isdemo()) // don't allow this command in demos
			m_goto(argv(1));

		return;
	}
	if (argv(0) == "dumptree") {
		cmd_dumptree_space = "";
		depthfirst(main, parent, firstChild, nextSibling, cmd_dumptree_open, cmd_dumptree_close, NULL);
		return;
	}
	if (argv(0) == "dumpserverlist") {
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
		return;
	}
	if (argv(0) == "dlc_reload") {
		menu_dlc_reload(TRUE, TRUE);
		return;
	}
	if (argv(0) == "ui_con_width_height_set") {
		ui_con_width_height_set();
		return;
	}
	if (argv(0) == "skinselect") {
		m_goto_skin_selector();
		return;
	}
	print("Invalid theCommand. For a list of supported theCommands, try menu_cmd help.\n");
}
