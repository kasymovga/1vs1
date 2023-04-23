float translate_db;

string(string s) translate {
	if (translate_db < 0) return s;
	string r = db_get(translate_db, s);
	if (r != "") return r;
	return s;
}

void(void) translate_init {
	string s;
	translate_db = -1;
	string lang = cvar_string("prvm_language");
	if (lang == "" || lang == "en") return;
	s = strcat("common.", lang, ".po");
	float pofile = fopen(s, (extension_DP_RM_FILE ? FILE_READ_NODATA : FILE_READ));
	print("Loading translation\n");
	if (pofile < 0) {
		print("Cannot open ", s, "\n");
		return;
	}
	translate_db = db_create();
	float argc, msgstr_reading = 0;
	string msgid = "", msgstr = "", arg0;
	while ((s = fgets(pofile))) {
		argc = tokenize_console(s);
		if (argc < 1) {
			if (msgstr != "") {
				//print("added translation:\n");
				//print("msgid=", msgid, "\n");
				//print("msgstr=", msgstr, "\n");
				db_put(translate_db, msgid, msgstr);
				msgstr = "";
				msgid = "";
			}
			continue;
		}
		arg0 = argv(0);
		if (arg0 == "msgid") {
			msgstr_reading = 0;
			if (argc > 1)
				msgid = argv(1);
		} else if (arg0 == "msgstr") {
			msgstr_reading = 1;
			if (argc > 1)
				msgstr = argv(1);
		} else {
			if (msgstr_reading) {
				msgstr = strcat(msgstr, arg0);
			} else {
				msgid = strcat(msgstr, arg0);
			}
		}
	}
	fclose(pofile);
	if (msgid != "" && msgstr != "") {
		//print("added translation:\n");
		//print("msgid=", msgid, "\n");
		//print("msgstr=", msgstr, "\n");
		db_put(translate_db, msgid, msgstr);
	}
}


void(void) translate_shutdown {
	if (translate_db >= 0)
		db_close(translate_db);
}
