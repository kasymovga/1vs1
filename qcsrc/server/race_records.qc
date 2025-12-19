float race_records_modified;

string(string s) race_records_html_escape {
	s = strreplace("<", "&lt;", s);
	s = strreplace(">", "&gt;", s);
	s = strreplace("&", "&amp;", s);
	float c = strstrofs(s, "^", 0); //look for colorcode symbol
	float spanopened = FALSE;
	string chr, rgb;
	if (c >= 0) {
		string sc = "";
		for (; s != "";) {
			sc = strcat(sc, substring(s, 0, c));
			s = substring(s, c + 1, -1);
			chr = substring(s, 0, 1);
			if (chr == "" || chr == "^") { //nothing or secondary ^
				//print("no color code\n");
				sc = strcat(sc, "^");
				s = substring(s, 1, -1); //skip character (if presented)
			} else if (strstrofs("0123456789", chr, 0) >= 0) { //simple color code
				//print("simple color code\n");
				s = substring(s, 1, -1); //skip character
				rgb = "";
				if (spanopened) sc = strcat(sc, "</span>");
				spanopened = FALSE;
				if (chr == "0") {
					rgb = "444";
				} else if (chr == "1") {
					rgb = "F44";
				} else if (chr == "2") {
					rgb = "4F4";
				} else if (chr == "3") {
					rgb = "BB4";
				} else if (chr == "4") {
					rgb = "44F";
				} else if (chr == "5") {
					rgb = "4DD";
				} else if (chr == "6") {
					rgb = "D4D";
				} else if (chr == "7") {
					//default color
				} else if (chr == "8") {
					rgb = "666";
				} else if (chr == "9") {
					rgb = "888";
				}
				if (rgb != "") {
					sc = strcat(sc, "<span style=\"color: #", rgb, "\">");
					spanopened = TRUE;
				}
			} else if (chr == "x") { //complex color code
				//print("complex color code\n");
				rgb = "";
				chr = substring(s, 1, 1);
				if (chr != "" && strstrofs("0123456789abcdefABCDEF", chr, 0) >= 0) {
					rgb = chr;
					chr = substring(s, 2, 1);
					if (chr != "" && strstrofs("0123456789abcdefABCDEF", chr, 0) >= 0) {
						rgb = strcat(rgb, chr);
						chr = substring(s, 3, 1);
						if (chr != "" && strstrofs("0123456789abcdefABCDEF", chr, 0) >= 0) {
							rgb = strcat(rgb, chr);
							if (spanopened) sc = strcat(sc, "</span>");
							sc = strcat(sc, "<span style=\"color: #", rgb, "\">");
							spanopened = TRUE;
							s = substring(s, 4, -1); //skip character
						} else {
							sc = strcat(sc, "^x");
							s = substring(s, 1, -1); //skip character
						}
					} else {
						sc = strcat(sc, "^x");
						s = substring(s, 1, -1); //skip character
					}
				} else {
					sc = strcat(sc, "^x");
					s = substring(s, 1, -1); //skip character
				}
			} else {
				sc = strcat(sc, "^", chr);
				s = substring(s, 1, -1); //skip character
			}
			c = strstrofs(s, "^", 0);
			if (c < 0) {
				sc = strcat(sc, s);
				break;
			}
		}
		if (spanopened) sc = strcat(sc, "</span>");
		return sc;
	}
	return s;
}

void(void) race_records_to_html {
	if not(cvar_string("sv_cts_records_to_html")) return;
	if not(race_records_modified) {
		if (file_exists("cts_records.html")) return; //nothing to do
	}
	float f = fopen("cts_records.html", FILE_WRITE);
	if (f < 0) {
		print("Saving records to html failed: cannot open cts_records.html\n");
		return;
	}
	fputs(f, "<html>\n");
	fputs(f, "<head>\n");
	fputs(f, "<title>CTS record table</title>\n");
	fputs(f, "<style>\n");
	fputs(f, "body {\n");
	fputs(f, "	background-color: black;\n");
	fputs(f, "	color: white;\n");
	fputs(f, "}\n");
	fputs(f, "</style>\n");
	fputs(f, "</head>\n");
	fputs(f, "<body>\n");
	fputs(f, "<script>\n");
	fputs(f, "function sortTable(column) {\n");
	fputs(f, "	var x, y;\n");
	fputs(f, "	var table = document.getElementById(\"recordTable\");\n");
	fputs(f, "	var rows = table.rows;\n");
	fputs(f, "	for (var i = rows.length - 2; i > 0; i--) {\n");
	fputs(f, "		for (var j = i; j < rows.length - 1; j++) {\n");
	fputs(f, "			x = rows[j].getElementsByTagName(\"TD\")[column];\n");
	fputs(f, "			y = rows[j + 1].getElementsByTagName(\"TD\")[column];\n");
	fputs(f, "			if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {\n");
	fputs(f, "				rows[j].parentNode.insertBefore(rows[j + 1], rows[j]);\n");
	fputs(f, "			} else {\n");
	fputs(f, "				break;\n");
	fputs(f, "			}\n");
	fputs(f, "		}\n");
	fputs(f, "	}\n");
	fputs(f, "}\n");
	fputs(f, "</script>\n");
	fputs(f, "<table  id='recordTable'>\n");
	fputs(f, "<tr>\n");
	fputs(f, "<th><a href='#' onclick=\"sortTable(0)\">Map</a>\n");
	string s;
	float i, j;
	for (i = 0; i < 10; i++) {
		j = i * 2 + 1;
		s = strcat("<th><a href='#' onclick=\"sortTable(", ftos(j), ")\">Time #", ftos(i + 1), "</a>");
		s = strcat(s, "<th><a href='#' onclick=\"sortTable(", ftos(j + 1), ")\">Player #", ftos(i + 1), "</a>\n");
		fputs(f, s);
	}
	map_info_enumerate();
	map_info_filter_game_type(MAP_INFO_TYPE_CTS, map_info_required_flags(), map_info_forbidden_flags(), 1);
	string m, n, id, p;
	float breaked, t;
	for (i = 0; i < map_info_count; ++i) {
		m = map_info_glob_item(map_info_filter_list_lookup(i));
		s = strcat(m, race_records_path);
		fputs(f, strcat("<tr><td>", uri_escape(m), "\n"));
		breaked = FALSE;
		for (j = 0; j < 10; j++) {
			n = "";
			p = "";
			if not(breaked) {
				if (j > 0) p = strcat(ftos(j), "/");
				id = db_get(db_server, strcat(s, p, "id"));
				if (id == "") {
					n = db_get(db_server, strcat(s, p, "netname"));
				} else {
					n = db_get(db_server, strcat("raceid2n/", id));
				}
				if (n == "") breaked = TRUE;
			}
			if (breaked) {
				fputs(f, "<td>\n<td>\n");
			} else {
				t = stof(db_get(db_server, strcat(s, p, "time")));
				fputs(f, strcat("<td>", time_mmssss(t), "\n"));
				fputs(f, strcat("<td>", race_records_html_escape(n), "\n"));
			}
		}
	}
	fputs(f, "</table>\n");
	fputs(f, "</body>\n");
	fputs(f, "</html>\n");
	fclose(f);
}

void(void) race_records_load {
	string s = strcat(mapname, race_records_path);
	string n, id;
	float t, sp;
	id = db_get(db_server, strcat(s, "id"));
	if (id != "") {
		n = db_get(db_server, strcat("raceid2n/", id));
		if (n == "") {
			print("Missed name for id\n");
			n = "<BROKEN>";
		}
	} else
		n = db_get(db_server, strcat(s, "netname"));

	t = stof(db_get(db_server, strcat(s, "time")));
	sp = stof(db_get(db_server, strcat(s, "speed")));
	if (t && (n != "" || id != "")) {
		if not(race_records_put(n, id, t, sp)) {
			if (id != "")
				race_records_id_ref_counter_decrease(id);

			print("Warning: records table line 1 failed\n");
		}
	}
	float i;
	for (i = 1; i < 10; i++) {
		id = db_get(db_server, strcat(s, ftos(i), "/id"));
		if (id != "") {
			n = db_get(db_server, strcat("raceid2n/", id));
			if (n == "") {
				print("Missed name for id\n");
				n = "<BROKEN>";
			}
		} else
			n = db_get(db_server, strcat(s, ftos(i), "/netname"));

		t = stof(db_get(db_server, strcat(s, ftos(i), "/time")));
		sp = stof(db_get(db_server, strcat(s, ftos(i), "/speed")));
		if (t && (n != "" || id != "")) {
			if not(race_records_put(n, id, t, sp)) {
				if (id != "")
					race_records_id_ref_counter_decrease(id);

				print("Warning: records table line ", ftos(i + 1), " failed\n");
			}
		}
	}
	race_records_modified = TRUE;
}

void(void) race_records_save {
	float t, sp;
	string n, id;
	t = race_records_time[0];
	n = race_records_name[0];
	id = race_records_id[0];
	sp = race_records_speed[0];
	db_put(db_server, strcat(mapname, race_records_path, "time"),  ((t > 0) ? ftos(t) : ""));
	if (id != "") {
		db_put(db_server, strcat(mapname, race_records_path, "id"), id);
		db_put(db_server, strcat(mapname, race_records_path, "netname"), "");
	} else {
		db_put(db_server, strcat(mapname, race_records_path, "id"), "");
		db_put(db_server, strcat(mapname, race_records_path, "netname"), n);
	}
	db_put(db_server, strcat(mapname, race_records_path, "speed"), ((sp > 0) ? ftos(sp) : ""));
	float i;
	for (i = 1; i < 10; i++) {
		t = race_records_time[i];
		n = race_records_name[i];
		sp = race_records_speed[i];
		id = race_records_id[i];
		db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/time"), ((t > 0) ? ftos(t) : ""));
		if (id != "") {
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/id"), id);
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/netname"), "");
		} else {
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/id"), "");
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/netname"), n);
		}
		db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/speed"), ((sp > 0) ? ftos(sp) : ""));
	}
}

void(float i) race_records_delete {
	float j;
	string n, id;
	float t, sp;
	n = race_records_name[i];
	id = race_records_id[i];
	if (id != "")
		race_records_id_ref_counter_decrease(id);

	str_unzone_ifneeded(n);
	race_records_name[i] = "";
	str_unzone_ifneeded(id);
	race_records_id[i] = "";
	for (j = i; j < 9; j++) {
		n = race_records_name[j + 1];
		id = race_records_id[j + 1];
		t = race_records_time[j + 1];
		sp = race_records_speed[j + 1];
		race_records_name[j] = n;
		race_records_id[j] = id;
		race_records_time[j] = t;
		race_records_speed[j] = sp;
	}
	race_records_name[9] = "";
	race_records_id[9] = "";
	race_records_time[9] = 0;
	race_records_speed[9] = 0;
	race_records_modified = FALSE;
}

float(entity to, float sf) race_records_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_RACE_RECORDS);
	float i, t, sp;
	string n;
	for (i = 0; i < 10; i++) {
		n = race_records_name[i];
		t = race_records_time[i];
		sp = race_records_speed[i];
		net_write_coord(MSG_ENTITY, t);
		net_write_short(MSG_ENTITY, sp);
		net_write_string(MSG_ENTITY, n);
	}
	return TRUE;
}

void(string m) race_records_clear {
	entity e;
	float i;
	string id;
	bprint(strcat("Clearing records for ", m, "\n"));
	if (m == mapname) {
		for (i = 0; i < 10; i++) {
			id = race_records_id[i];
			if (id != "") race_records_id_ref_counter_decrease(id);
			race_records_id[i] = "";
			race_records_name[i] = "";
			race_records_time[i] = 0;
			race_records_speed[i] = 0;
		}
		race_records_sender.SendFlags = 1;
	} else {
		db_put(db_server, strcat(m, race_records_path, "time"), "");
		db_put(db_server, strcat(m, race_records_path, "netname"), "");
		id = db_get(db_server, strcat(m, race_records_path, "id"));
		db_put(db_server, strcat(m, race_records_path, "id"), "");
		if (id != "") race_records_id_ref_counter_decrease(id);
		db_put(db_server, strcat(m, race_records_path, "speed"), "");
		for (i = 1; i < 10; i++) {
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/time"), "");
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/netname"), "");
			id = db_get(db_server, strcat(m, race_records_path, ftos(i), "/id"));
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/id"), "");
			if (id != "") race_records_id_ref_counter_decrease(id);
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/speed"), "");
		}
	}
}

string race_records_link_name_to_id_cb_arg1;
string race_records_link_name_to_id_cb_arg2;
void(string k, string v) race_records_link_name_to_id_cb {
	if (substring(k, strlen(k) - 8, 8) != "/netname") return;
	float slash = strstrofs(k, "/", 0);
	if (slash < 0) return; //impossible but...
	if (substring(k, 0, slash) == mapname) return;
	if (strstrofs(k, race_records_path, 0) == slash) {
		if (v == race_records_link_name_to_id_cb_arg1) {
			string k_id = strcat(substring(k, 0, strlen(k) - 7), "id");
			if (db_get(db_server, k_id) == "") {
				db_put(db_server, k, "");
				db_put(db_server, k_id, race_records_link_name_to_id_cb_arg2);
				race_records_id_ref_counter_increase(race_records_link_name_to_id_cb_arg2,
						race_records_link_name_to_id_cb_arg1);
				print("Link ", race_records_link_name_to_id_cb_arg1, " on ", k, " to id\n");
			}
		}
	}
}

void(string n, string id) race_records_link_name_to_id {
	race_records_link_name_to_id_cb_arg1 = n;
	race_records_link_name_to_id_cb_arg2 = id;
	db_for_each_key_like(db_server, "/netname", n, race_records_link_name_to_id_cb);
	race_records_link_name_to_id_cb_arg1 = NULL;
	race_records_link_name_to_id_cb_arg2 = NULL;
}

float(string name, string client_id, float checktime, float _speed) race_records_put {
	float t, i, j, sp;
	string n, id;
	float have_id = FALSE;
	if (client_id != "")
		for (i = 0; i < 10; i++) {
			if (race_records_id[i] == client_id)
				have_id = TRUE;
		}
	for (i = 0; i < 10; i++) {
		t = race_records_time[i];
		if (!t || t > checktime) {
			for (j = i; j < 10; j++) {
				n = race_records_name[j];
				id = race_records_id[j];
				if (have_id) {
					if (id == client_id) {
						race_records_delete(j);
						j--;
					}
				} else {
					if (n != "" && n == name && id == "") {
						race_records_delete(j);
						j--;
						if (cvar("sv_cts_records_link_names_to_ids"))
							race_records_link_name_to_id(name, client_id);
					}
				}
			}
			//clearing last position if it's not empty
			race_records_delete(9);
			for (j = 8; j >= i; j--) {
				n = race_records_name[j];
				id = race_records_id[j];
				t = race_records_time[j];
				sp = race_records_speed[j];
				race_records_name[j + 1] = n;
				race_records_id[j + 1] = id;
				race_records_time[j + 1] = t;
				race_records_speed[j + 1] = sp;
			}
			race_records_name[i] = str_zone_ifneeded(name);
			race_records_id[i] = str_zone_ifneeded(client_id);
			race_records_time[i] = checktime;
			race_records_speed[i] = _speed;
			race_records_modified = TRUE;
			return i + 1;
		}
		n = race_records_name[i];
		id = race_records_id[i];
		if (have_id) {
			if (id == client_id) return FALSE;
		} else {
			if (n == name && id == "") return FALSE;
		}
	}
	return FALSE;
}

float race_records_validate_counter;
void(string k, string v) race_records_validate_cb2 {
	float slash = strstrofs(k, "/", 0);
	if (slash < 0) return;
	if (substring(k, slash, 14) != "/cts100record/")
	if (substring(k, slash, 15) != "/race100record/")
		return;

	if (substring(k, strlen(k) - 3, -1) != "/id")
		return;

	race_records_validate_counter++;
}

float race_records_validate_fix;
void(string k, string v) race_records_validate_cb1 {
	if (substring(k, 0, 12) != "raceid2n_rc/") return;
	string id = substring(k, 12, -1);
	race_records_validate_counter = 0;
	db_for_each_key_like(db_server, "/id", id, race_records_validate_cb2);
	string msg = strcat("Validating reference counter for id: ", id, " - ");
	if (race_records_validate_counter != stof(v)) {
		msg = strcat(msg, "FAILED (", ftos(race_records_validate_counter), "/", v, ")");
		if (race_records_validate_fix) {
			msg = strcat(msg, " - FIXED");
			if (race_records_validate_counter)
				db_put(db_server, strcat("raceid2n_rc/", id), ftos(race_records_validate_counter));
			else {
				db_put(db_server, strcat("raceid2n_rc/", id), "");
				db_put(db_server, strcat("raceid2n/", id), "");
			}
		}
	} else
		msg = strcat(msg, "OK (", ftos(race_records_validate_counter), "/", v, ")");

	print(msg, "\n");
}

void(float fix) race_records_validate {
	race_records_save();
	race_records_validate_fix = fix;
	db_for_each_key_like(db_server, "raceid2n_rc/", "", race_records_validate_cb1);
}

float(string cmd, float argc) race_records_cmd {
	if (cmd == "help") {
		print("  clear_records [mapname]\n");
		print("  clear_record <position>\n");
		print("  link_id_to_name <position1> [position2]\n");
		print("  validate [fixflag]\n");
	} else if (cmd == "validate") {
		if (argc > 2) {
			print("usage: sv_cmd validate [fixflag]\n");
			print("       fixflag must be 0 or 1\n");
			return TRUE;
		}
		race_records_validate((argc > 1 && stof(argv(1))));
		return TRUE;
	} else if (cmd == "clear_records") {
		string m;
		if (argc > 1)
			m = argv(1);
		else
			m = mapname;

		race_records_clear(m);
		return TRUE;
	} else if (cmd == "clear_record") {
		if (argc != 2) {
			print("usage: sv_cmd clear_record <position>\n");
			print("       position must be from 1 to 10\n");
			return TRUE;
		}
		float i = stof(argv(1)) - 1;
		if (i < 0 || i > 9) {
			print("position must be from 1 to 10\n");
			return TRUE;
		}
		race_records_delete(i);
		race_records_sender.SendFlags = 1;
		return TRUE;
	} else if (cmd == "test_html" && argc == 2) {
		print(race_records_html_escape(argv(1)), "\n");
		return TRUE;
	} else if (cmd == "link_id_to_name") {
		if (argc < 2 || argc > 3) {
			print("usage: sv_cmd link_id_to_name <position1> [position2]\n");
			print("       position1 and position2 must be from 1 to 10 and have different values\n");
			return TRUE;
		}
		if (argc == 2) {
			float p = floor(stof(argv(1))) - 1;
			if (p < 0 || p > 9) {
				print("position1 must be from 1 to 10 and have different values\n");
				return TRUE;
			}
			string id = race_records_id[p];
			string name = race_records_name[p];
			if (id == "") {
				print(strcat("record with position ", ftos(p), " don't have id\n"));
				return TRUE;
			}
			race_records_link_name_to_id(name, id);
			return TRUE;
		}
		float p1 = floor(stof(argv(1))) - 1;
		float p2 = floor(stof(argv(2))) - 1;
		if (p1 < 0 || p1 > 9 || p2 < 0 || p2 > 9 || p1 == p2) {
			print("position1 and position2 must be from 1 to 10 and have different values\n");
			return TRUE;
		}
		string id1 = race_records_id[p1];
		string id2 = race_records_id[p2];
		string name1 = race_records_name[p1];
		string name2 = race_records_name[p2];
		if (id1 != "" && id2 != "") {
			print("both records linked to different ids\n");
			return TRUE;
		}
		if (id1 == "" && id2 == "") {
			print("both records not linked to any id\n");
			return TRUE;
		}
		if (id1 != "" && p1 < p2) {
			race_records_link_name_to_id(name2, id1);
			race_records_delete(p2);
		}
		if (id2 != "" && p2 < p1) {
			race_records_link_name_to_id(name1, id2);
			race_records_delete(p1);
		}
		if (id1 != "" && p2 < p1) {
			//swaping names and ids
			string tmp;
			tmp = race_records_id[p1];
			race_records_id[p1] = race_records_id[p2];
			race_records_id[p2] = tmp;
			tmp = race_records_name[p1];
			race_records_name[p1] = race_records_name[p2];
			race_records_name[p2] = tmp;
			race_records_link_name_to_id(name2, id1);
			race_records_delete(p1);
		}
		if (id2 != "" && p1 < p2) {
			//swaping names and ids
			string tmp;
			tmp = race_records_id[p1];
			race_records_id[p1] = race_records_id[p2];
			race_records_id[p2] = tmp;
			tmp = race_records_name[p1];
			race_records_name[p1] = race_records_name[p2];
			race_records_name[p2] = tmp;
			race_records_link_name_to_id(name1, id2);
			race_records_delete(p2);
		}
		race_records_sender.SendFlags = 1;
		return TRUE;
	}
	return FALSE;
}

void(string id, string name) race_records_id_ref_counter_increase {
	float c;
	c = stof(db_get(db_server, strcat("raceid2n_rc/", id)));
	db_put(db_server, strcat("raceid2n_rc/", id), ftos(c + 1));
	db_put(db_server, strcat("raceid2n/", id), name);
}

float(string id) race_records_id_ref_counter_decrease {
	float c;
	c = stof(db_get(db_server, strcat("raceid2n_rc/", id))) - 1;
	if (c <= 0) {
		db_put(db_server, strcat("raceid2n_rc/", id), "");
		db_put(db_server, strcat("raceid2n/", id), "");
	} else
		db_put(db_server, strcat("raceid2n_rc/", id), ftos(c));

	return c;
}
