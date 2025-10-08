void(void) db_init {
	db_server = db_load("server.db");
	db_temp = db_create();
}

void(float db, string s_key, string s_value, void(string k, string v) cb) db_for_each_key_like {
	float i, n = buf_getsize(db);
	s_value = uri_escape(s_value);
	string l, k, v;
	float k_e, v_e;
	for (i = 0; i < n; i++) {
		l = bufstr_get(db, i);
		if ((s_key == "" || strstrofs(l, s_key, 1) >= 0)
				&& (s_value == "" || strstrofs(l, s_value, 3) >= 0)) { //first character is always '\'
			k_e = 0;
			v_e = 0;
			while (l != "") {
				k_e = strstrofs(l, "\\", 1);
				if (k_e <= 2) { //empty or not found
					break;
				}
				v_e = strstrofs(l, "\\", k_e + 1);
				if (v_e == k_e + 1) { //empty
					break;
				}
				k = substring(l, 1, k_e - 1);
				if (v_e >= 0)
					v = substring(l, k_e + 1, v_e - k_e - 1);
				else
					v = substring(l, k_e + 1, -1);

				if (v == "") break;
				if ((s_key == "" || strstrofs(k, s_key, 0) >= 0)
						&& (s_value == "" || strstrofs(v, s_value, 0) >= 0))
					cb(k, uri_unescape(v));
				if (v_e >= 0)
					l = substring(l, v_e, -1);
				else
					break;
			}
		}
	}
}

void(void) db_shutdown {
	db_save(db_server, "server.db");
	if(cvar("developer"))
		db_save(db_temp, "server-temp.db");

	db_close(db_server);
	db_close(db_temp);
}
