float translate_db;
float translate_db_missed;

string(string s) translate {
	if (translate_db < 0 || s == "") return s;
	string r = db_get(translate_db, s);
	if (r != "") {
		return r;
	}
	if (translate_db_missed >= 0) {
		db_put(translate_db_missed, s, s);
	}
	return s;
}

string(string s) translate_skip_accents {
	string accent_chars =             "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ";
	string accent_chars_replacement = "AAAAAAACEEEEIIIIDNOOOOOx0UUUUYPBaaaaaaaceeeeiiiionooooo:ouuuuypy";
	float r = regex_match("[À-ÿ]", s, 0, strlen(s), 0);
	if (r >= 0) {
		float i;
		for (i = 0; i < 64; i++) {
			if (strstrofs(s, substring(accent_chars, i, 1), 0) >= 0)
				s = strreplace(substring(accent_chars, i, 1), substring(accent_chars_replacement, i, 1), s);
		}
	}
	return s;
}

void(float db, string path, float nodata) translate_load {
	string s;
	float pofile = fopen(path, ((extension_DP_RM_FILE && nodata) ? FILE_READ_NODATA : FILE_READ));
	if (nodata) print("Loading translation\n");
	if (pofile < 0) {
		if (nodata) print("Cannot open ", path, "\n");
		return;
	}
	float argc, msgstr_reading = 0;
	float skipaccents = (cvar("utf8_oldfont_for_oldchars") && extension_DP_RM_REGEX2);
	string msgid = "", msgstr = "", arg0;
	while ((s = fgets(pofile))) {
		argc = tokenize_console(s);
		if (argc < 1) {
			if (msgstr != "") {
				//print("added translation:\n");
				//print("msgid=", msgid, "\n");
				//print("msgstr=", msgstr, "\n");
				msgid = strreplace("\\n", "\n", msgid);
				msgstr = strreplace("\\n", "\n", msgstr);
				if (skipaccents) msgstr = translate_skip_accents(msgstr);
				if (msgid != "")
					db_put(db, msgid, msgstr);

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
				msgid = strcat(msgid, arg0);
			}
		}
	}
	fclose(pofile);
	if (msgid != "" && msgstr != "") {
		//print("added translation:\n");
		//print("msgid=", msgid, "\n");
		//print("msgstr=", msgstr, "\n");
		msgid = strreplace("\\n", "\n", msgid);
		msgstr = strreplace("\\n", "\n", msgstr);
		if (skipaccents) msgstr = translate_skip_accents(msgstr);
		if (msgid != "")
			db_put(db, msgid, msgstr);
	}
}

void(void) translate_init {
	string s;
	translate_db = -1;
	translate_db_missed = -1;
	string lang = cvar_string("prvm_language");
	if (lang == "" || lang == "en") return;
	translate_db = db_create();
	registercvar("cl_translate_dump_missed", "0", 0);
	if (cvar("cl_translate_dump_missed"))
		translate_db_missed = db_create();

	s = strcat("common.", lang, ".po");
	translate_load(translate_db, s, TRUE);
}


void(void) translate_shutdown {
	if (translate_db_missed >= 0) {
		float i, j, n;
		string s;
		translate_load(translate_db_missed, "missed_translations.po", FALSE);
		float out = fopen("missed_translations.po", FILE_WRITE);
		if (out >= 0) {
			for (i = 0; i < DB_BUCKETS; i++) {
				s = bufstr_get(translate_db_missed, i);
				n = tokenizebyseparator(s, "\\");
				for(j = 2; j < n; j += 2) {
					s = argv(j - 1);
					if (s == "modified") continue;
					if (db_get(translate_db, s) != "") continue;
					s = strreplace("\n", "\\n", s);
					s = strreplace("\"", "\\\"", s);
					fputs(out, "msgid \"");
					fputs(out, s);
					fputs(out, "\"\n");
					fputs(out, "msgstr \"");
					fputs(out, s);
					fputs(out, "\"\n\n");
				}
			}
			fclose(out);
		}
		db_close(translate_db_missed);
	}
	if (translate_db >= 0)
		db_close(translate_db);

}
