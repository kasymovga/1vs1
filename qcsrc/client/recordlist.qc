float recordlist_tail_offset;
float recordlist_tail_expected_chunk;
float recordlist_last_request;
float recordlist;
float recordlist_init_done;

void(float n1, float n2) recordlist_request_chunk {
	if (recordlist_last_request > time)
		return;

	recordlist_last_request = time + 0.1;
	localcmd(strcat("cmd recordlistchunk ", ftos(n1), " ", ftos(n2), ";"));
}

float(void) recordlist_size {
	if not(recordlist_init_done) return 1;
	if (recordlist_tail_expected_chunk < 0) return buf_getsize(recordlist);
	return buf_getsize(recordlist) + 1; // for [Loading...]
}

string(float i) recordlist_get {
	if not(recordlist_init_done) {
		recordlist_request_chunk(0, 0);
		return "[Loading...]";
	}
	if (recordlist_tail_expected_chunk >= 0) {
		recordlist_request_chunk(recordlist_tail_offset, recordlist_tail_expected_chunk);
	}
	if (i < buf_getsize(recordlist))
		return bufstr_get(recordlist, i);

	if (recordlist_tail_expected_chunk >= 0)
		return "[Loading...]";
	else
		return "[END]";
}

void() recordlist_read {
	float n1 = net_read_byte();
	float n2 = net_read_byte();
	string s = net_read_string();
	if not(recordlist_init_done) {
		recordlist_init_done = TRUE;
		recordlist = buf_create();
	}
	if (n1 != recordlist_tail_offset)
		return;

	if (n2 != recordlist_tail_expected_chunk)
		return;

	if (s == "") {
		if (recordlist_tail_expected_chunk) {
			recordlist_tail_offset++;
			recordlist_tail_expected_chunk = 0;
		} else {
			recordlist_tail_expected_chunk = -1;
		}
	} else {
		recordlist_tail_expected_chunk++;
		float p1, p2 = -1;
		for (;;) {
			p1 = p2 + 1;
			p2 = strstrofs(s, "\n", p1);
			if (p2 < 0) break;
			bufstr_add(recordlist, str_sub(s, p1, p2 - p1), TRUE);
		}
	}
}
