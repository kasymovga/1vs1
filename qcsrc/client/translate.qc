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

float translate_db_missed_cb_out;
void(string k, string v) translate_db_missed_cb {
	if (db_get(translate_db, k) != "") return;
	k = strreplace("\n", "\\n", k);
	k = strreplace("\"", "\\\"", k);
	fputs(translate_db_missed_cb_out, "msgid \"");
	fputs(translate_db_missed_cb_out, k);
	fputs(translate_db_missed_cb_out, "\"\n");
	fputs(translate_db_missed_cb_out, "msgstr \"");
	fputs(translate_db_missed_cb_out, k);
	fputs(translate_db_missed_cb_out, "\"\n\n");
}

void(void) translate_shutdown {
	if (translate_db_missed >= 0) {
		float i, j, n, c = buf_getsize(translate_db_missed);
		string s;
		translate_load(translate_db_missed, "missed_translations.po", FALSE);
		translate_db_missed_cb_out = fopen("missed_translations.po", FILE_WRITE);
		if (translate_db_missed_cb_out >= 0) {
			db_for_each_key_like(translate_db_missed, "", "", translate_db_missed_cb);
			fclose(translate_db_missed_cb_out);
		}
		db_close(translate_db_missed);
	}
	if (translate_db >= 0)
		db_close(translate_db);
}
