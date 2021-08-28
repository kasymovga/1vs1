entity recordlist;
entity recordlist_tail;
float recordlist_tail_offset;
float recordlist_tail_expected_chunk;
float recordlist_last_request;

void(float n1, float n2) recordlist_request_chunk {
	if (recordlist_last_request > time)
		return;

	recordlist_last_request = time + 0.1;
	localcmd(strcat("cmd recordlistchunk ", ftos(n1), " ", ftos(n2), ";"));
}

string(entity e, float n) recordlist_line {
	float p1 = 0, p2 = -1;
	float i;
	for (i = -1; i < n; i++) {
		p1 = p2 + 1;
		p2 = strstrofs(e.message, "\n", p1);
	}
	return substring(e.message, p1, p2 - p1);
}

float(entity e) recordlist_lines_count {
	float p;
	float n = -1;
	for (p = 0; p >= 0;) {
		p = strstrofs(e.message, "\n", p + 1);
		n++;
	}
	return n;
}

string(float i) recordlist_get {
	if not(recordlist) {
		recordlist_request_chunk(0, 0);
		return "[Loading...]";
	}
	if (recordlist_tail_expected_chunk >= 0)
		recordlist_request_chunk(recordlist_tail_offset, recordlist_tail_expected_chunk);

	entity e;
	for (e = recordlist; e; e = e.enemy) {
		if (i >= e.cnt) {
			i -= e.cnt;
			continue;
		}
		return recordlist_line(e, i);
	}
	if (recordlist_tail_expected_chunk >= 0)
		return "[Loading...]";
	else
		return "[END]";
}

void() recordlist_read {
	float n1 = net_read_byte();
	float n2 = net_read_byte();
	string s = net_read_string();
	if (n1 != recordlist_tail_offset)
		return;

	if (n2 != recordlist_tail_expected_chunk)
		return;

	if not(recordlist) {
		recordlist_tail = recordlist = spawn();
		recordlist_size = 1;
	}
	if (s == "") {
		if (recordlist_tail_expected_chunk) {
			recordlist_tail.enemy = spawn();
			recordlist_tail = recordlist_tail.enemy;
			recordlist_tail_offset++;
			recordlist_tail_expected_chunk = 0;
		} else {
			recordlist_tail_expected_chunk = -1;
			recordlist_size--;
		}
	} else {
		recordlist_size -= recordlist_tail.cnt;
		string s2 = str_zone_ifneeded(strcat(recordlist_tail.message, s));
		str_unzone_ifneeded(recordlist_tail.message);
		recordlist_tail.message = s2;
		recordlist_tail_expected_chunk++;
		recordlist_tail.cnt = recordlist_lines_count(recordlist_tail);
		recordlist_size += recordlist_tail.cnt;
	}
}
