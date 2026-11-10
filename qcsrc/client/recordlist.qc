float recordlist_offset;
float recordlist_chunk_expected;
string recordlist_chunk_end;
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
	if (recordlist_chunk_expected < 0) return buf_getsize(recordlist);
	return buf_getsize(recordlist) + 1; // for [Loading...]
}

string(float i) recordlist_get {
	if not(recordlist_init_done) {
		recordlist_request_chunk(0, 0);
		return "[Loading...]";
	}
	if (recordlist_chunk_expected >= 0) {
		recordlist_request_chunk(recordlist_offset, recordlist_chunk_expected);
	}
	if (i < buf_getsize(recordlist))
		return bufstr_get(recordlist, i);

	if (recordlist_chunk_expected >= 0)
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
	if (n1 != recordlist_offset)
		return;

	if (n2 != recordlist_chunk_expected)
		return;

	if (s == "") {
		if (recordlist_chunk_expected) {
			recordlist_offset++;
			recordlist_chunk_expected = 0;
		} else {
			recordlist_chunk_expected = -1;
		}
		str_unzone_ifneeded(recordlist_chunk_end);
		recordlist_chunk_end = "";
	} else {
		s = strcat(recordlist_chunk_end, s);
		recordlist_chunk_expected++;
		float p1, p2 = -1;
		for (;;) {
			p1 = p2 + 1;
			p2 = strstrofs(s, "\n", p1);
			if (p2 < 0) {
				str_unzone_ifneeded(recordlist_chunk_end);
				recordlist_chunk_end = str_zone_ifneeded(str_sub(s, p1, -1));
				break;
			}
			bufstr_add(recordlist, str_sub(s, p1, p2 - p1), TRUE);
		}
	}
}
