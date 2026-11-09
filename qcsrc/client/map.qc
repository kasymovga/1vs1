float map_list_init_done;
float map_list;

void(void) map_list_read {
	if (map_list_init_done) {
		map_list_init_done = 1;
	} else {
		buf_del(map_list);
	}
	map_list = buf_create();
	float i, n;
	string s, m;
	for (i = 0; i < CMD_LSMAPS_REPLY_STRINGS_COUNT; i++) {
		s = net_read_string();
		while (s != "") {
			m = str_car(s);
			if (m != "")
				bufstr_add(map_list, m, TRUE);

			s = str_cdr(s);
		}
	}
}

