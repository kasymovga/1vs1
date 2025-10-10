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
	if (t && (n != "" || id != ""))
		race_records_put(n, id, t, sp);

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
		if (t && (n != "" || id != ""))
			race_records_put(n, id, t, sp);
	}
}

void(void) race_records_save {
	float t, sp;
	string n, id;
	print("Saving race records...\n");
	t = race_records_time[0];
	n = race_records_name[0];
	id = race_records_id[0];
	sp = race_records_speed[0];
	db_put(db_server, strcat(mapname, race_records_path, "time"), ftos(t));
	if (id != "")
		db_put(db_server, strcat(mapname, race_records_path, "id"), id);
	else
		db_put(db_server, strcat(mapname, race_records_path, "netname"), n);

	db_put(db_server, strcat(mapname, race_records_path, "speed"), ftos(sp));
	float i;
	for (i = 1; i < 10; i++) {
		t = race_records_time[i];
		n = race_records_name[i];
		sp = race_records_speed[i];
		id = race_records_id[i];
		db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/time"), ftos(t));
		if (id != "") {
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/id"), id);
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/netname"), "");
		} else {
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/id"), "");
			db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/netname"), n);
		}
		db_put(db_server, strcat(mapname, race_records_path, ftos(i), "/speed"), ftos(sp));
	}
}

void(float i) race_records_delete {
	float j;
	string n, id;
	float t, sp;
	id = race_records_name[i];
	n = race_records_id[i];
	if (id != "")
		race_id_ref_counter_decrease(id);

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
			if (id != "") race_id_ref_counter_decrease(id);
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
		if (id != "") race_id_ref_counter_decrease(id);
		db_put(db_server, strcat(m, race_records_path, "speed"), "");
		for (i = 1; i < 10; i++) {
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/time"), "");
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/netname"), "");
			id = db_get(db_server, strcat(m, race_records_path, ftos(i), "/id"));
			db_put(db_server, strcat(m, race_records_path, ftos(i), "/id"), "");
			if (id != "") race_id_ref_counter_decrease(id);
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
				race_id_ref_counter_increase(race_records_link_name_to_id_cb_arg2,
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


